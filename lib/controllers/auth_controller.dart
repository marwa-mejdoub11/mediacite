import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _erreur;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get erreur => _erreur;
  bool get isConnecte => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isUsager => _user?.role == 'usager';

  // ── Inscription ──────────────────────────────
  Future<bool> inscription({
    required String nom,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    _user = await _authService.inscription(
      nom: nom,
      email: email,
      password: password,
    );

    _isLoading = false;

    if (_user == null) {
      _erreur = 'Erreur lors de l\'inscription';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  // ── Connexion Usager ─────────────────────────
  Future<bool> connexion({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    _user = await _authService.connexion(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (_user == null) {
      _erreur = 'Email ou mot de passe incorrect';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  // ── Connexion Admin ──────────────────────────
  Future<bool> connexionAdmin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _erreur = null;
    notifyListeners();

    _user = await _authService.connexionAdmin(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (_user == null) {
      _erreur = 'Identifiants admin incorrects';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  // ── Déconnexion ──────────────────────────────
  Future<void> deconnexion() async {
    await _authService.deconnexion();
    _user = null;
    notifyListeners();
  }

  // ── Rafraîchir profil ────────────────────────
  Future<void> rafraichirProfil() async {
    if (_user == null) return;
    final profil = await _authService.getProfil(_user!.uid);
    if (profil != null) {
      _user = profil;
      notifyListeners();
    }
  }
}