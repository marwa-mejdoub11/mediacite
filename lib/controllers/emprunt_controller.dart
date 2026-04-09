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

  // ── Emprunter ────────────────────────────────
  Future<String> emprunterMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      // Vérifier limite 3 emprunts
      final empruntsActifs = await _db
          .collection('emprunts')
          .where('userId', isEqualTo: userId)
          .where('statut', isEqualTo: 'en_cours')
          .get();

      if (empruntsActifs.docs.length >= 3) {
        return 'limite';
      }

      // Vérifier quantité disponible
      final mediaDoc = await _db.collection('medias').doc(media.id).get();
      final data = mediaDoc.data() as Map<String, dynamic>;
      final quantiteDispo = data['quantiteDisponible'] ?? 0;

      if (quantiteDispo <= 0) {
        return 'indisponible';
      }

      final dateEmprunt = DateTime.now();
      final dateRetour = dateEmprunt.add(const Duration(days: 14));

      // Créer l'emprunt
      await _db.collection('emprunts').add({
        'userId': userId,
        'mediaId': media.id,
        'titreMedia': media.titre,
        'couverture': media.couverture,
        'dateEmprunt': _formatDate(dateEmprunt),
        'dateRetour': _formatDate(dateRetour),
        'statut': 'en_cours',
        'prolonge': false,
      });

      // Décrémenter la quantité disponible
      final nouvelleQte = quantiteDispo - 1;
      await _db.collection('medias').doc(media.id).update({
        'quantiteDisponible': nouvelleQte,
        'disponible': nouvelleQte > 0,
      });

      print('✅ Emprunt créé — $nouvelleQte exemplaire(s) restant(s)');
      return 'success';
    } catch (e) {
      print('❌ Erreur emprunt: $e');
      return 'erreur';
    }
  }

  // ── Réserver (file d'attente) ────────────────
  Future<bool> reserverMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      // Vérifier si déjà en file d'attente
      final dejaReserve = await _db
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('mediaId', isEqualTo: media.id)
          .where('statut', isEqualTo: 'en_attente')
          .get();

      if (dejaReserve.docs.isNotEmpty) {
        return false; // déjà en file
      }

      // Compter position dans la file
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

      print('✅ Réservation créée — position $position dans la file');
      return true;
    } catch (e) {
      print('❌ Erreur réservation: $e');
      return false;
    }
  }

  // ── Retourner ────────────────────────────────
  Future<bool> retournerMedia({
    required String empruntId,
    required String mediaId,
  }) async {
    try {
      await _db.collection('emprunts').doc(empruntId).update({
        'statut': 'rendu',
        'dateRetourEffectif': _formatDate(DateTime.now()),
      });

      // Incrémenter la quantité disponible
      final mediaDoc = await _db.collection('medias').doc(mediaId).get();
      final data = mediaDoc.data() as Map<String, dynamic>;
      final quantiteDispo = (data['quantiteDisponible'] ?? 0) + 1;
      final quantiteTotal = data['quantite'] ?? 1;

      await _db.collection('medias').doc(mediaId).update({
        'quantiteDisponible': quantiteDispo,
        'disponible': true,
      });

      print('✅ Média retourné — $quantiteDispo/$quantiteTotal disponible(s)');
      return true;
    } catch (e) {
      print('❌ Erreur retour: $e');
      return false;
    }
  }

  // ── Prolonger ────────────────────────────────
  Future<bool> prolongerEmprunt(String empruntId) async {
    try {
      // Vérifier si déjà prolongé
      final doc = await _db.collection('emprunts').doc(empruntId).get();
      final data = doc.data() as Map<String, dynamic>;

      if (data['prolonge'] == true) {
        return false; // Déjà prolongé
      }

      final nouvelleDateRetour = DateTime.now().add(const Duration(days: 7));
      await _db.collection('emprunts').doc(empruntId).update({
        'dateRetour': _formatDate(nouvelleDateRetour),
        'prolonge': true,
      });

      print('✅ Emprunt prolongé de 7 jours');
      return true;
    } catch (e) {
      print('❌ Erreur prolongation: $e');
      return false;
    }
  }

  // ── Vérifier emprunts en retard ──────────────
  Future<List<Map<String, dynamic>>> getEmpruntsEnRetard(String userId) async {
    try {
      final snap = await _db
          .collection('emprunts')
          .where('userId', isEqualTo: userId)
          .where('statut', isEqualTo: 'en_cours')
          .get();

      final aujourd = DateTime.now();
      final enRetard = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final dateRetourStr = data['dateRetour'] as String;
        final parts = dateRetourStr.split('/');
        if (parts.length == 3) {
          final dateRetour = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          if (aujourd.isAfter(dateRetour)) {
            enRetard.add({...data, 'id': doc.id});
          }
        }
      }

      return enRetard;
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}