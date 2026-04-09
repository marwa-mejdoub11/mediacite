import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── MEDIAS ──────────────────────────────────

  // Récupérer tous les médias
  Stream<List<MediaModel>> getMedias() {
    return _db.collection('medias').snapshots().map((snap) =>
        snap.docs
            .map((doc) => MediaModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ✅ Ajouter un média — vérifie les doublons
  Future<void> ajouterMedia(MediaModel media) async {
    try {
      // Cherche si titre + auteur existent déjà
      final existing = await _db
          .collection('medias')
          .where('titre', isEqualTo: media.titre)
          .where('auteur', isEqualTo: media.auteur)
          .get();

      if (existing.docs.isNotEmpty) {
        // Média existe → incrémenter quantité
        final doc = existing.docs.first;
        final data = doc.data();
        final ancienneQte = data['quantite'] ?? 1;
        final ancienneDispo = data['quantiteDisponible'] ?? 1;

        await _db.collection('medias').doc(doc.id).update({
          'quantite': ancienneQte + 1,
          'quantiteDisponible': ancienneDispo + 1,
          'disponible': true,
        });

        print('✅ "${media.titre}" — quantité: ${ancienneQte + 1}');
      } else {
        // Nouveau média → créer
        await _db.collection('medias').add(media.toMap());
        print('✅ Nouveau média: ${media.titre}');
      }
    } catch (e) {
      print('❌ Erreur ajouterMedia: $e');
      rethrow;
    }
  }

  // Modifier un média
  Future<void> modifierMedia(String id, MediaModel media) async {
    await _db.collection('medias').doc(id).update(media.toMap());
  }

  // Supprimer un média
  Future<void> supprimerMedia(String id) async {
    await _db.collection('medias').doc(id).delete();
  }

  // ── EVENEMENTS ──────────────────────────────

  Stream<List<EventModel>> getEvenements() {
    return _db.collection('evenements').snapshots().map((snap) =>
        snap.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> ajouterEvenement(EventModel event) async {
    await _db.collection('evenements').add(event.toMap());
  }

  // ── EMPRUNTS ────────────────────────────────

  Stream<List<Map<String, dynamic>>> getEmpruntsUser(String userId) {
    return _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ── FAVORIS ─────────────────────────────────

  Future<void> ajouterFavori(String userId, MediaModel media) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favoris')
        .doc(media.id)
        .set({
      'mediaId': media.id,
      'titre': media.titre,
      'auteur': media.auteur,
      'categorie': media.categorie,
      'dateAjout': DateTime.now().toIso8601String(),
    });
  }

  Future<void> supprimerFavori(String userId, String mediaId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favoris')
        .doc(mediaId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getFavoris(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favoris')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<bool> estFavori(String userId, String mediaId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favoris')
        .doc(mediaId)
        .get();
    return doc.exists;
  }
}