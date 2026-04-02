import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── MEDIAS ──────────────────────────────

  // Récupérer tous les médias
  Stream<List<MediaModel>> getMedias() {
    return _db.collection('medias').snapshots().map((snap) =>
        snap.docs.map((doc) =>
            MediaModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Ajouter un média (admin)
  Future<void> ajouterMedia(MediaModel media) async {
    await _db.collection('medias').add(media.toMap());
  }

  // Modifier un média (admin)
  Future<void> modifierMedia(String id, MediaModel media) async {
    await _db.collection('medias').doc(id).update(media.toMap());
  }

  // Supprimer un média (admin)
  Future<void> supprimerMedia(String id) async {
    await _db.collection('medias').doc(id).delete();
  }

  // ── EVENEMENTS ──────────────────────────

  // Récupérer tous les événements
  Stream<List<EventModel>> getEvenements() {
    return _db.collection('evenements').snapshots().map((snap) =>
        snap.docs.map((doc) =>
            EventModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Ajouter un événement (admin)
  Future<void> ajouterEvenement(EventModel event) async {
    await _db.collection('evenements').add(event.toMap());
  }

  // ── EMPRUNTS ────────────────────────────

  // Emprunter un média
  Future<void> emprunterMedia(String userId, String mediaId) async {
    await _db.collection('emprunts').add({
      'userId': userId,
      'mediaId': mediaId,
      'dateEmprunt': DateTime.now().toIso8601String(),
      'dateRetour': DateTime.now().add(
        const Duration(days: 14)).toIso8601String(),
      'statut': 'en_cours',
    });

    // Marquer le média comme non disponible
    await _db.collection('medias').doc(mediaId).update({
      'disponible': false,
    });
  }

  // Historique emprunts d'un utilisateur
  Stream<List<Map<String, dynamic>>> getEmpruntsUser(String userId) {
    return _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}