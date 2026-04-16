import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────────────────
  // 📚 MEDIAS
  // ───────────────────────────────

  Stream<List<MediaModel>> getMedias() {
    return _db.collection('medias').snapshots().map(
          (snap) => snap.docs
              .map((doc) => MediaModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ✅ Ajouter média (gestion doublon + incrément sécurisé)
  Future<void> ajouterMedia(MediaModel media) async {
    try {
      final existing = await _db
          .collection('medias')
          .where('titre', isEqualTo: media.titre)
          .where('auteur', isEqualTo: media.auteur)
          .get();

      if (existing.docs.isNotEmpty) {
        final docId = existing.docs.first.id;

        await _db.collection('medias').doc(docId).update({
          'quantite': FieldValue.increment(1),
          'quantiteDisponible': FieldValue.increment(1),
          'disponible': true,
        });
      } else {
        await _db.collection('medias').add(media.toMap());
      }
    } catch (e) {
      print("❌ ajouterMedia error: $e");
      rethrow;
    }
  }

  Future<void> modifierMedia(String id, MediaModel media) async {
    await _db.collection('medias').doc(id).update(media.toMap());
  }

  Future<void> supprimerMedia(String id) async {
    await _db.collection('medias').doc(id).delete();
  }

  // ───────────────────────────────
  // 📅 EVENEMENTS
  // ───────────────────────────────

  Stream<List<EventModel>> getEvenements() {
    return _db.collection('evenements').snapshots().map(
          (snap) => snap.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> ajouterEvenement(EventModel event) async {
    await _db.collection('evenements').add(event.toMap());
  }

  // ───────────────────────────────
  // 📖 EMPRUNTS
  // ───────────────────────────────

  Stream<List<Map<String, dynamic>>> getEmpruntsUser(String userId) {
    return _db
        .collection('emprunts')
        .where('userId', isEqualTo: userId)
        .orderBy('dateEmprunt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return {
                'id': doc.id,
                'mediaId': d['mediaId'],
                'titre': d['titre'],
                'statut': d['statut'],
                'dateEmprunt': d['dateEmprunt'],
                'dateRetour': d['dateRetour'],
              };
            }).toList());
  }

  // ✅ Emprunter média (transaction safe)
  Future<void> emprunterMedia(
    String userId,
    String mediaId, {
    String? titre,
    int dureeJours = 14,
  }) async {
    final mediaRef = _db.collection('medias').doc(mediaId);
    final empruntRef = _db.collection('emprunts').doc();

    await _db.runTransaction((tx) async {
      final mediaSnap = await tx.get(mediaRef);
      if (!mediaSnap.exists) throw Exception("Média introuvable");

      final data = mediaSnap.data()!;
      final dispo = (data['quantiteDisponible'] ?? 0) as int;

      if (dispo <= 0) {
        throw Exception("Aucune copie disponible");
      }

      tx.update(mediaRef, {
        'quantiteDisponible': FieldValue.increment(-1),
        'disponible': dispo - 1 > 0,
      });

      final now = DateTime.now();

      tx.set(empruntRef, {
        'userId': userId,
        'mediaId': mediaId,
        'titre': titre ?? data['titre'],
        'dateEmprunt': now.toIso8601String(),
        'dateRetour':
            now.add(Duration(days: dureeJours)).toIso8601String(),
        'statut': 'en_cours',
      });
    });
  }

  // ✅ Retour média
  Future<void> retournerMedia(String empruntId) async {
    final empruntRef = _db.collection('emprunts').doc(empruntId);
    final snap = await empruntRef.get();

    if (!snap.exists) return;

    final data = snap.data()!;
    final mediaId = data['mediaId'];

    final mediaRef = _db.collection('medias').doc(mediaId);

    await _db.runTransaction((tx) async {
      tx.update(empruntRef, {
        'statut': 'rendu',
        'dateRetourEffectif': DateTime.now().toIso8601String(),
      });

      final mediaSnap = await tx.get(mediaRef);
      if (mediaSnap.exists) {
        tx.update(mediaRef, {
          'quantiteDisponible': FieldValue.increment(1),
          'disponible': true,
        });
      }
    });

    await traiterQueue(mediaId);
  }

  // ───────────────────────────────
  // 🔁 RESERVATION (QUEUE)
  // ───────────────────────────────

  Future<void> reserverMedia(String userId, String mediaId) async {
    await _db.collection('reservations').add({
      'userId': userId,
      'mediaId': mediaId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> traiterQueue(String mediaId) async {
    final q = await _db
        .collection('reservations')
        .where('mediaId', isEqualTo: mediaId)
        .orderBy('createdAt')
        .limit(1)
        .get();

    if (q.docs.isEmpty) return;

    final reservation = q.docs.first;
    final userId = reservation['userId'];

    final mediaSnap = await _db.collection('medias').doc(mediaId).get();
    if (!mediaSnap.exists) return;

    final media = mediaSnap.data()!;
    final dispo = media['quantiteDisponible'] ?? 0;

    if (dispo <= 0) return;

    await _db.collection('emprunts').add({
      'userId': userId,
      'mediaId': mediaId,
      'titre': media['titre'],
      'dateEmprunt': DateTime.now().toIso8601String(),
      'dateRetour':
          DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      'statut': 'en_cours',
    });

    await reservation.reference.delete();

    await _db.collection('medias').doc(mediaId).update({
      'quantiteDisponible': FieldValue.increment(-1),
      'disponible': false,
    });
  }

  // ───────────────────────────────
  // ⭐ FAVORIS
  // ───────────────────────────────

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
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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

  // ───────────────────────────────
  // 📊 STATS USER
  // ───────────────────────────────

  Stream<Map<String, int>> getStatsUtilisateur(String userId) {
    return _db.collection('emprunts').snapshots().map((snap) {
      final emprunts =
          snap.docs.where((d) => d['userId'] == userId).length;

      return {
        'emprunts': emprunts,
        'favoris': 0,
        'evenements': 0,
      };
    });
  }

  // ───────────────────────────────
  // ⚙️ LIMITS
  // ───────────────────────────────

  Future<void> setEmpruntLimit(String userId, int limit) async {
    await _db
        .collection('utilisateurs')
        .doc(userId)
        .set({'empruntLimit': limit}, SetOptions(merge: true));
  }
}