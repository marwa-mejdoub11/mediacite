import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email et mot de passe admin fixes
  static const String _adminEmail = 'admin@mediacite.com';
  static const String _adminPassword = 'admin123456';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Inscription usager ───────────────────────
  Future<UserModel?> inscription({
    required String nom,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        uid: result.user!.uid,
        nom: nom,
        email: email,
        role: 'usager',
        statut: 'actif',
      );

      try {
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(user.toMap());
      } catch (e) {
        print('⚠️ Firestore non disponible: $e');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Erreur inscription: ${e.code}');
      return null;
    }
  }

  // ── Connexion usager ─────────────────────────
  Future<UserModel?> connexion({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Essaie de récupérer le profil depuis Firestore
      try {
        final doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('⚠️ Firestore non disponible: $e');
      }

      // Profil par défaut si Firestore indisponible
      return UserModel(
        uid: result.user!.uid,
        nom: email.split('@')[0],
        email: email,
        role: 'usager',
        statut: 'actif',
      );
    } on FirebaseAuthException catch (e) {
      print('Erreur connexion: ${e.code}');
      return null;
    }
  }

  // ── Connexion Admin ──────────────────────────
  Future<UserModel?> connexionAdmin({
    required String email,
    required String password,
  }) async {
    if (email != _adminEmail || password != _adminPassword) {
      return null;
    }

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return UserModel(
        uid: result.user!.uid,
        nom: 'Administrateur',
        email: email,
        role: 'admin',
        statut: 'actif',
      );
    } on FirebaseAuthException catch (e) {
      // Si le compte admin n'existe pas encore, on le crée
      if (e.code == 'user-not-found') {
        try {
          UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          return UserModel(
            uid: result.user!.uid,
            nom: 'Administrateur',
            email: email,
            role: 'admin',
            statut: 'actif',
          );
        } catch (e) {
          print('Erreur création admin: $e');
          return null;
        }
      }
      print('Erreur connexion admin: ${e.code}');
      return null;
    }
  }

  // ── Déconnexion ──────────────────────────────
  Future<void> deconnexion() async {
    await _auth.signOut();
  }

  // ── Récupérer profil ─────────────────────────
  Future<UserModel?> getProfil(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur getProfil: $e');
      return null;
    }
  }
}