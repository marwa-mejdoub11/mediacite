import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emprunt_model.dart';
import '../models/media_model.dart';

class EmpruntController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<EmpruntModel> _emprunts = [];
  bool _isLoading = false;

  List<EmpruntModel> get emprunts => _emprunts;
  bool get isLoading => _isLoading;

  // ─────────────────────────────────────────────
  // Charger emprunts utilisateur
  // ─────────────────────────────────────────────
  void chargerEmprunts(String userId) {
    _isLoading = true;
    notifyListeners();

    _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      _emprunts = snap.docs
          .map((doc) => EmpruntModel.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print('❌ Erreur emprunts: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────
  // Emprunter un média (VERSION AMÉLIORÉE)
  // ─────────────────────────────────────────────
  Future<String> emprunterMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      // 🔹 1. Limite dynamique depuis Firestore
      final configDoc =
          await _db.collection('settings').doc('config').get();

      final maxEmprunts = configDoc.data()?['max_emprunts'] ?? 3;

      // 🔹 2. Vérifier emprunts actifs
      final empruntsActifs = await _db
          .collection('emprunts')
          .where('userId', isEqualTo: userId)
          .where('statut', isEqualTo: 'en_cours')
          .get();

      if (empruntsActifs.docs.length >= maxEmprunts) {
        return 'limite';
      }

      // 🔹 3. Vérifier disponibilité
      final mediaDoc = await _db.collection('medias').doc(media.id).get();
      final data = mediaDoc.data() as Map<String, dynamic>;
      final quantiteDispo = data['quantiteDisponible'] ?? 0;

      if (quantiteDispo <= 0) {
        return 'indisponible';
      }

      // 🔹 4. Dates
      final dateEmprunt = DateTime.now();
      final dateRetour = dateEmprunt.add(const Duration(days: 14));

      // 🔹 5. Création emprunt
      await _db.collection('emprunts').add({
        'userId': userId,
        'mediaId': media.id,
        'titreMedia': media.titre,
        'couverture': media.couverture,
        'dateEmprunt': _formatDate(dateEmprunt),
        'dateRetour': _formatDate(dateRetour),
        'statut': 'en_cours',
        'prolonge': false,
        'notificationEnvoyee': false,
      });

      // 🔹 6. Mise à jour stock
      final nouvelleQte = quantiteDispo - 1;
      await _db.collection('medias').doc(media.id).update({
        'quantiteDisponible': nouvelleQte,
        'disponible': nouvelleQte > 0,
      });

      print('✅ Emprunt créé — $nouvelleQte restant(s)');
      return 'success';
    } catch (e) {
      print('❌ Erreur emprunt: $e');
      return 'erreur';
    }
  }

  // ─────────────────────────────────────────────
  // Réserver (file d'attente)
  // ─────────────────────────────────────────────
  Future<bool> reserverMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      final dejaReserve = await _db
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('mediaId', isEqualTo: media.id)
          .where('statut', isEqualTo: 'en_attente')
          .get();

      if (dejaReserve.docs.isNotEmpty) {
        return false;
      }

      final fileAttente = await _db
          .collection('reservations')
          .where('mediaId', isEqualTo: media.id)
          .where('statut', isEqualTo: 'en_attente')
          .get();

      final position = fileAttente.docs.length + 1;

      await _db.collection('reservations').add({
        'userId': userId,
        'mediaId': media.id,
        'titreMedia': media.titre,
        'couverture': media.couverture,
        'dateReservation': _formatDate(DateTime.now()),
        'statut': 'en_attente',
        'position': position,
      });

      print('✅ Réservation — position $position');
      return true;
    } catch (e) {
      print('❌ Erreur réservation: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Retourner média + gérer file d'attente
  // ─────────────────────────────────────────────
  Future<bool> retournerMedia({
    required String empruntId,
    required String mediaId,
  }) async {
    try {
      await _db.collection('emprunts').doc(empruntId).update({
        'statut': 'rendu',
        'dateRetourEffectif': _formatDate(DateTime.now()),
      });

      // 🔹 Mise à jour stock
      final mediaDoc = await _db.collection('medias').doc(mediaId).get();
      final data = mediaDoc.data() as Map<String, dynamic>;
      final quantiteDispo = (data['quantiteDisponible'] ?? 0) + 1;

      await _db.collection('medias').doc(mediaId).update({
        'quantiteDisponible': quantiteDispo,
        'disponible': true,
      });

      // 🔥 Donner au prochain dans la file
      final reservations = await _db
          .collection('reservations')
          .where('mediaId', isEqualTo: mediaId)
          .where('statut', isEqualTo: 'en_attente')
          .orderBy('position')
          .limit(1)
          .get();

      if (reservations.docs.isNotEmpty) {
        await _db
            .collection('reservations')
            .doc(reservations.docs.first.id)
            .update({'statut': 'disponible'});
      }

      print('✅ Média retourné');
      return true;
    } catch (e) {
      print('❌ Erreur retour: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Prolonger
  // ─────────────────────────────────────────────
  Future<bool> prolongerEmprunt(String empruntId) async {
    try {
      final doc = await _db.collection('emprunts').doc(empruntId).get();
      final data = doc.data() as Map<String, dynamic>;

      if (data['prolonge'] == true) return false;

      final nouvelleDateRetour = DateTime.now().add(const Duration(days: 7));

      await _db.collection('emprunts').doc(empruntId).update({
        'dateRetour': _formatDate(nouvelleDateRetour),
        'prolonge': true,
      });

      print('✅ Prolongé');
      return true;
    } catch (e) {
      print('❌ Erreur prolongation: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Emprunts en retard
  // ─────────────────────────────────────────────
  Future<List<EmpruntModel>> getEmpruntsEnRetard(String userId) async {
    final snap = await _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_cours')
        .get();

    final aujourd = DateTime.now();
    final result = <EmpruntModel>[];

    for (var doc in snap.docs) {
      final data = doc.data();
      final parts = data['dateRetour'].split('/');

      final dateRetour = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      if (aujourd.isAfter(dateRetour)) {
        result.add(EmpruntModel.fromMap(data, doc.id));
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // Emprunts proches retour (notifications)
  // ─────────────────────────────────────────────
  Future<List<EmpruntModel>> getEmpruntsProchesRetour(
      String userId) async {
    final snap = await _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_cours')
        .get();

    final aujourd = DateTime.now();
    final result = <EmpruntModel>[];

    for (var doc in snap.docs) {
      final data = doc.data();
      final parts = data['dateRetour'].split('/');

      final dateRetour = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );

      if (dateRetour.difference(aujourd).inDays == 1) {
        result.add(EmpruntModel.fromMap(data, doc.id));
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}