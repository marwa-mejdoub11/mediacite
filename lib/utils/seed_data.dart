import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> initialiserDonnees() async {
    print('🚀 Début initialisation...');
    try {
      await _ajouterMedias();
      await _ajouterEvenements();
      print('✅ Tout ajouté avec succès !');
    } catch (e, stack) {
      print('❌ Erreur: $e');
      print('Stack: $stack');
    }
  }
  // Dans seed_data.dart — Ajoute cette méthode
static Future<void> nettoyerDoublons() async {
  print('🧹 Nettoyage des doublons...');
  try {
    final snap = await _db.collection('medias').get();
    
    // Regrouper par titre+auteur
    final Map<String, List<QueryDocumentSnapshot>> groupes = {};
    
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cle = '${data['titre']}_${data['auteur']}';
      groupes.putIfAbsent(cle, () => []).add(doc);
    }

    // Traiter chaque groupe
    for (final entry in groupes.entries) {
      final docs = entry.value;
      if (docs.length <= 1) continue; // Pas de doublon

      print('🔄 Fusion de ${docs.length} doublons pour "${entry.key}"');
      
      // Garder le premier document, supprimer les autres
      final premier = docs.first;
      final data = premier.data() as Map<String, dynamic>;
      
      // Calculer la quantité totale
      int qteTotal = 0;
      for (final doc in docs) {
        final d = doc.data() as Map<String, dynamic>;
        qteTotal += (d['quantite'] as int? ?? 1);
      }

      // Mettre à jour le premier document
      await _db.collection('medias').doc(premier.id).update({
        'quantite': qteTotal,
        'quantiteDisponible': qteTotal,
        'disponible': true,
      });

      // Supprimer les doublons
      for (int i = 1; i < docs.length; i++) {
        await _db.collection('medias').doc(docs[i].id).delete();
        print('🗑️ Doublon supprimé: ${docs[i].id}');
      }
    }

    print('✅ Nettoyage terminé !');
  } catch (e) {
    print('❌ Erreur nettoyage: $e');
    rethrow;
  }
}

  static Future<void> _ajouterMedias() async {
    // ✅ Vérifie si les médias existent déjà
    final existing = await _db.collection('medias').limit(1).get();
    if (existing.docs.isNotEmpty) {
      print('⚠️ Médias déjà initialisés — ignoré');
      return;
    }

    print('📚 Ajout médias...');
    final medias = [
      {
        'titre': 'Le Petit Prince',
        'auteur': 'Antoine de Saint-Exupéry',
        'categorie': 'livre',
        'description': 'Un aviateur tombe en panne dans le désert et rencontre un petit prince venu d\'une autre planète.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070612758-L.jpg',
        'disponible': true,
        'quantite': 3,        // ← Nombre d'exemplaires
        'quantiteDisponible': 3,
        'note': 4.5,
      },
      {
        'titre': 'Harry Potter',
        'auteur': 'J.K. Rowling',
        'categorie': 'livre',
        'description': 'Un jeune orphelin découvre qu\'il est un sorcier et intègre l\'école de magie Poudlard.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070584628-L.jpg',
        'disponible': true,
        'quantite': 2,
        'quantiteDisponible': 2,
        'note': 4.8,
      },
      {
        'titre': 'L\'Alchimiste',
        'auteur': 'Paulo Coelho',
        'categorie': 'livre',
        'description': 'Un jeune berger andalou part à la recherche d\'un trésor enfoui au pied des Pyramides.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782290004241-L.jpg',
        'disponible': true,
        'quantite': 4,
        'quantiteDisponible': 4,
        'note': 4.6,
      },
      {
        'titre': 'Inception',
        'auteur': 'Christopher Nolan',
        'categorie': 'film',
        'description': 'Un voleur spécialisé dans l\'extraction de secrets depuis les rêves.',
        'couverture': 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        'disponible': true,
        'quantite': 2,
        'quantiteDisponible': 2,
        'note': 4.7,
      },
      {
        'titre': 'Interstellar',
        'auteur': 'Christopher Nolan',
        'categorie': 'film',
        'description': 'Un voyage dans l\'espace et le temps pour sauver l\'humanité.',
        'couverture': 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'disponible': true,
        'quantite': 1,
        'quantiteDisponible': 0,  // ← 0 disponible = emprunté
        'note': 4.9,
      },
      {
        'titre': 'National Geographic',
        'auteur': 'National Geographic Society',
        'categorie': 'magazine',
        'description': 'Magazine de sciences, nature et découvertes.',
        'couverture': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/National_Geographic_Magazine_Cover_-_Sep_2013.jpg/220px-National_Geographic_Magazine_Cover_-_Sep_2013.jpg',
        'disponible': true,
        'quantite': 5,
        'quantiteDisponible': 5,
        'note': 4.2,
      },
      {
        'titre': 'Science & Vie',
        'auteur': 'Mondadori',
        'categorie': 'magazine',
        'description': 'Les dernières découvertes scientifiques expliquées simplement.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070612758-L.jpg',
        'disponible': true,
        'quantite': 3,
        'quantiteDisponible': 3,
        'note': 4.0,
      },
      {
  'titre': '1984',
  'auteur': 'George Orwell',
  'categorie': 'livre',
  'description': 'Un homme tente de résister à un régime totalitaire où tout est surveillé.',
  'couverture': 'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
  'quantite': 3,
  'quantiteDisponible': 3,
  'note': 4.7,
}
    ];

    for (final media in medias) {
      await _db.collection('medias').add(media);
      print('✅ Média ajouté: ${media['titre']}');
    }
    print('✅ ${medias.length} médias ajoutés !');
  }

  static Future<void> _ajouterEvenements() async {
    // ✅ Vérifie si les événements existent déjà
    final existing = await _db.collection('evenements').limit(1).get();
    if (existing.docs.isNotEmpty) {
      print('⚠️ Événements déjà initialisés — ignoré');
      return;
    }

    print('🎭 Ajout événements...');
    final evenements = [
      {
        'titre': 'Soirée Lecture Poésie',
        'description': 'Une soirée dédiée à la poésie moderne.',
        'date': '2025-05-15T18:00:00.000',
        'placesTotal': 30,
        'placesRestantes': 15,
      },
      {
        'titre': 'Atelier Cinéma',
        'description': 'Découvrez l\'art du 7ème art avec nos experts.',
        'date': '2025-05-20T14:00:00.000',
        'placesTotal': 20,
        'placesRestantes': 8,
      },
      {
        'titre': 'Club de Lecture',
        'description': 'Discussion autour du livre du mois : Le Petit Prince.',
        'date': '2025-06-01T10:00:00.000',
        'placesTotal': 15,
        'placesRestantes': 15,
      },
      {
        'titre': 'Exposition Photos',
        'description': 'Exposition de photos artistiques des membres.',
        'date': '2025-06-10T09:00:00.000',
        'placesTotal': 50,
        'placesRestantes': 40,
      },
    ];

    for (final event in evenements) {
      await _db.collection('evenements').add(event);
      print('✅ Événement ajouté: ${event['titre']}');
    }
    print('✅ ${evenements.length} événements ajoutés !');
  }
}