class MediaModel {
  final String id;
  final String titre;
  final String auteur;
  final String categorie; // 'livre', 'magazine', 'film'
  final String description;
  final String couverture;
  final bool disponible;
  final double note;
   final int quantite;           // ← Total exemplaires
  final int quantiteDisponible; // ← Disponibles actuellement

  MediaModel({
    required this.id,
    required this.titre,
    required this.auteur,
    required this.categorie,
    required this.description,
    required this.couverture,
    required this.disponible,
    required this.note,
       this.quantite = 1,
    this.quantiteDisponible = 1,
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
        quantite: map['quantite'] ?? 1,
      quantiteDisponible: map['quantiteDisponible'] ?? 1,
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
       'quantite': quantite,
      'quantiteDisponible': quantiteDisponible,
    };
  }
  
}