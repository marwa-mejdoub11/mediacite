class MediaModel {
  final String id;
  final String titre;
  final String auteur;
  final String categorie; // 'livre', 'magazine', 'film'
  final String description;
  final String couverture;
  final bool disponible;
  final double note;
  final int quantite;
  final int quantiteDisponible;

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

  /// 🔹 FROM FIRESTORE (sécurisé)
  factory MediaModel.fromMap(Map<String, dynamic> map, String id) {
    return MediaModel(
      id: id,
      titre: map['titre'] ?? '',
      auteur: map['auteur'] ?? '',
      categorie: map['categorie'] ?? 'livre',
      description: map['description'] ?? '',
      couverture: map['couverture'] ?? '',
      disponible: map['disponible'] ?? true,

      // ✅ Correction importante pour éviter crash
      note: (map['note'] is int)
          ? (map['note'] as int).toDouble()
          : (map['note'] ?? 0.0),

      // ✅ Sécuriser les entiers
      quantite: (map['quantite'] ?? 1) is int
          ? map['quantite']
          : int.tryParse(map['quantite'].toString()) ?? 1,

      quantiteDisponible: (map['quantiteDisponible'] ?? 1) is int
          ? map['quantiteDisponible']
          : int.tryParse(map['quantiteDisponible'].toString()) ?? 1,
    );
  }

  /// 🔹 TO FIRESTORE
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

  /// 🔹 COPY WITH (très utile pour update)
  MediaModel copyWith({
    String? id,
    String? titre,
    String? auteur,
    String? categorie,
    String? description,
    String? couverture,
    bool? disponible,
    double? note,
    int? quantite,
    int? quantiteDisponible,
  }) {
    return MediaModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      auteur: auteur ?? this.auteur,
      categorie: categorie ?? this.categorie,
      description: description ?? this.description,
      couverture: couverture ?? this.couverture,
      disponible: disponible ?? this.disponible,
      note: note ?? this.note,
      quantite: quantite ?? this.quantite,
      quantiteDisponible:
          quantiteDisponible ?? this.quantiteDisponible,
    );
  }
}