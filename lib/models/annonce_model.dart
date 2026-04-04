class AnnonceModel {
  final String id;
  final String titre;
  final String contenu;
  final String auteur;
  final String date;
  final String type; // 'info', 'urgent', 'evenement'

  AnnonceModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.auteur,
    required this.date,
    required this.type,
  });

  factory AnnonceModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnonceModel(
      id: id,
      titre: map['titre'] ?? '',
      contenu: map['contenu'] ?? '',
      auteur: map['auteur'] ?? '',
      date: map['date'] ?? '',
      type: map['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'contenu': contenu,
      'auteur': auteur,
      'date': date,
      'type': type,
    };
  }
}