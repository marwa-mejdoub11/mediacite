class EmpruntModel {
  final String id;
  final String userId;
  final String mediaId;
  final String titreMedia;
  final String couverture;

  final String dateEmprunt;
  final String dateRetour;
  final String? dateRetourEffectif;

  final String statut; // en_cours, rendu
  final bool prolonge;
  final bool notificationEnvoyee;

  EmpruntModel({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.titreMedia,
    required this.couverture,
    required this.dateEmprunt,
    required this.dateRetour,
    this.dateRetourEffectif,
    required this.statut,
    required this.prolonge,
    required this.notificationEnvoyee,
  });

  // ─────────────────────────────────────────────
  // FROM FIRESTORE
  // ─────────────────────────────────────────────
  factory EmpruntModel.fromMap(Map<String, dynamic> map, String id) {
    return EmpruntModel(
      id: id,
      userId: map['userId'] ?? '',
      mediaId: map['mediaId'] ?? '',
      titreMedia: map['titreMedia'] ?? '',
      couverture: map['couverture'] ?? '',

      dateEmprunt: map['dateEmprunt'] ?? '',
      dateRetour: map['dateRetour'] ?? '',
      dateRetourEffectif: map['dateRetourEffectif'],

      statut: map['statut'] ?? 'en_cours',
      prolonge: map['prolonge'] ?? false,
      notificationEnvoyee: map['notificationEnvoyee'] ?? false,
    );
  }

  // ─────────────────────────────────────────────
  // TO FIRESTORE
  // ─────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaId': mediaId,
      'titreMedia': titreMedia,
      'couverture': couverture,

      'dateEmprunt': dateEmprunt,
      'dateRetour': dateRetour,
      'dateRetourEffectif': dateRetourEffectif,

      'statut': statut,
      'prolonge': prolonge,
      'notificationEnvoyee': notificationEnvoyee,
    };
  }
}