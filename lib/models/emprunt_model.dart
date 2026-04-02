class EmpruntModel {
  final String id;
  final String userId;
  final String mediaId;
  final String titrMedia;
  final String dateEmprunt;
  final String dateRetour;
  final String statut; // 'en_cours', 'rendu', 'en_attente'

  EmpruntModel({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.titrMedia,
    required this.dateEmprunt,
    required this.dateRetour,
    required this.statut,
  });

  factory EmpruntModel.fromMap(Map<String, dynamic> map, String id) {
    return EmpruntModel(
      id: id,
      userId: map['userId'] ?? '',
      mediaId: map['mediaId'] ?? '',
      titrMedia: map['titreMedia'] ?? '',
      dateEmprunt: map['dateEmprunt'] ?? '',
      dateRetour: map['dateRetour'] ?? '',
      statut: map['statut'] ?? 'en_attente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'titreMedia': titrMedia,
      'dateEmprunt': dateEmprunt,
      'dateRetour': dateRetour,
      'statut': statut,
    };
  }
}