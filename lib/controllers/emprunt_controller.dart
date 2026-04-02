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

  // Charger emprunts d'un utilisateur
  void chargerEmprunts(String userId) {
    _isLoading = true;
    notifyListeners();

    _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      _emprunts = snap.docs
          .map((doc) => EmpruntModel.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print('❌ Erreur emprunts: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  // Emprunter un média
  Future<bool> emprunterMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      final dateEmprunt = DateTime.now();
      final dateRetour = dateEmprunt.add(const Duration(days: 14));

      final emprunt = EmpruntModel(
        id: '',
        userId: userId,
        mediaId: media.id,
        titrMedia: media.titre,
        dateEmprunt: _formatDate(dateEmprunt),
        dateRetour: _formatDate(dateRetour),
        statut: 'en_cours',
      );

      // Ajouter l'emprunt
      await _db.collection('emprunts').add(emprunt.toMap());

      // Marquer le média comme non disponible
      await _db.collection('medias').doc(media.id).update({
        'disponible': false,
      });

      print('✅ Emprunt créé pour ${media.titre}');
      return true;
    } catch (e) {
      print('❌ Erreur emprunt: $e');
      return false;
    }
  }

  // Réserver un média (file d'attente)
  Future<bool> reserverMedia({
    required String userId,
    required MediaModel media,
  }) async {
    try {
      final dateReservation = DateTime.now();

      await _db.collection('reservations').add({
        'userId': userId,
        'mediaId': media.id,
        'titreMedia': media.titre,
        'dateReservation': _formatDate(dateReservation),
        'statut': 'en_attente',
      });

      print('✅ Réservation créée pour ${media.titre}');
      return true;
    } catch (e) {
      print('❌ Erreur réservation: $e');
      return false;
    }
  }

  // Retourner un média
  Future<bool> retournerMedia({
    required String empruntId,
    required String mediaId,
  }) async {
    try {
      // Mettre à jour le statut de l'emprunt
      await _db.collection('emprunts').doc(empruntId).update({
        'statut': 'rendu',
        'dateRetourEffectif': _formatDate(DateTime.now()),
      });

      // Remettre le média disponible
      await _db.collection('medias').doc(mediaId).update({
        'disponible': true,
      });

      print('✅ Média retourné');
      return true;
    } catch (e) {
      print('❌ Erreur retour: $e');
      return false;
    }
  }

  // Prolonger un emprunt
  Future<bool> prolongerEmprunt(String empruntId) async {
    try {
      final nouvelleDateRetour = DateTime.now().add(const Duration(days: 7));
      await _db.collection('emprunts').doc(empruntId).update({
        'dateRetour': _formatDate(nouvelleDateRetour),
        'prolonge': true,
      });
      return true;
    } catch (e) {
      print('❌ Erreur prolongation: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}