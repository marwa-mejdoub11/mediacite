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

  static Future<void> _ajouterMedias() async {
    print('📚 Ajout médias...');
    final medias = [
      {
        'titre': 'Le Petit Prince',
        'auteur': 'Antoine de Saint-Exupéry',
        'categorie': 'livre',
        'description': 'Un aviateur tombe en panne dans le désert et rencontre un petit prince venu d\'une autre planète.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070612758-L.jpg',
        'disponible': true,
        'note': 4.5,
      },
      {
        'titre': 'Harry Potter',
        'auteur': 'J.K. Rowling',
        'categorie': 'livre',
        'description': 'Un jeune orphelin découvre qu\'il est un sorcier et intègre l\'école de magie Poudlard.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070584628-L.jpg',
        'disponible': true,
        'note': 4.8,
      },
      {
        'titre': 'L\'Alchimiste',
        'auteur': 'Paulo Coelho',
        'categorie': 'livre',
        'description': 'Un jeune berger andalou part à la recherche d\'un trésor enfoui au pied des Pyramides.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782290004241-L.jpg',
        'disponible': true,
        'note': 4.6,
      },
      {
        'titre': 'Inception',
        'auteur': 'Christopher Nolan',
        'categorie': 'film',
        'description': 'Un voleur spécialisé dans l\'extraction de secrets depuis les rêves reçoit une mission impossible.',
        'couverture': 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
        'disponible': true,
        'note': 4.7,
      },
      {
        'titre': 'Interstellar',
        'auteur': 'Christopher Nolan',
        'categorie': 'film',
        'description': 'Un voyage extraordinaire dans l\'espace et le temps pour sauver l\'humanité.',
        'couverture': 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'disponible': false,
        'note': 4.9,
      },
      {
        'titre': 'National Geographic',
        'auteur': 'National Geographic Society',
        'categorie': 'magazine',
        'description': 'Magazine de sciences, nature et découvertes du monde entier.',
        'couverture': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/National_Geographic_Magazine_Cover_-_Sep_2013.jpg/220px-National_Geographic_Magazine_Cover_-_Sep_2013.jpg',
        'disponible': true,
        'note': 4.2,
      },
      {
        'titre': 'Science & Vie',
        'auteur': 'Mondadori',
        'categorie': 'magazine',
        'description': 'Les dernières découvertes scientifiques expliquées simplement.',
        'couverture': 'https://covers.openlibrary.org/b/isbn/9782070612758-L.jpg',
        'disponible': true,
        'note': 4.0,
      },
    ];

    for (final media in medias) {
      await _db.collection('medias').add(media);
      print('✅ Média ajouté: ${media['titre']}');
    }
    print('✅ ${medias.length} médias ajoutés !');
  }

  static Future<void> _ajouterEvenements() async {
    print('🎭 Ajout événements...');
    final evenements = [
      {
        'titre': 'Soirée Lecture Poésie',
        'description': 'Une soirée dédiée à la poésie moderne. Des auteurs locaux liront leurs œuvres.',
        'date': '2025-05-15T18:00:00.000',
        'placesTotal': 30,
        'placesRestantes': 15,
      },
      {
        'titre': 'Atelier Cinéma',
        'description': 'Découvrez l\'art du 7ème art avec nos experts. Projection et analyse de films.',
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
        'description': 'Exposition de photos artistiques réalisées par les membres de la médiathèque.',
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