class MediaModel {
  final String id;
  final String titre;
  final String auteur;
  final String categorie; // 'livre', 'magazine', 'film'
  final String description;
  final String couverture;
  final bool disponible;
  final double note;

  MediaModel({
    required this.id,
    required this.titre,
    required this.auteur,
    required this.categorie,
    required this.description,
    required this.couverture,
    required this.disponible,
    required this.note,
  });

  factory MediaModel.fromMap(Map<String, dynamic> map, String id) {
    return MediaModel(
      id: id,
      titre: map['titre'] ?? '',
      auteur: map['auteur'] ?? '',
      categorie: map['categorie'] ?? '',
      description: map['description'] ?? '',
      couverture: map['couverture'] ?? '',
      disponible: map['disponible'] ?? true,
      note: (map['note'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'auteur': auteur,
      'categorie': categorie,
      'description': description,
      'couverture': couverture,
      'disponible': disponible,
      'note': note,
    };
  }
}