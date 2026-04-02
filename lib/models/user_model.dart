class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String role; // 'visiteur', 'usager', 'admin'
  final String statut; // 'actif', 'en_attente', 'suspendu'

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.role,
    required this.statut,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'usager',
      statut: map['statut'] ?? 'en_attente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nom': nom,
      'email': email,
      'role': role,
      'statut': statut,
    };
  }
}