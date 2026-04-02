import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'register_view.dart';
import '../home/home_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../visiteur/visiteur_view.dart';
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _modeAdmin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    final auth = context.read<AuthController>();

    if (_modeAdmin) {
      final success = await auth.connexionAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardView()),
        );
      }
    } else {
      final success = await auth.connexion(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Logo
              const Icon(
                Icons.library_books,
                size: 80,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mediacité',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const Text(
                'Votre médiathèque numérique',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Toggle Admin / Usager
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _modeAdmin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_modeAdmin
                                ? const Color(0xFF800020)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '👤 Usager',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _modeAdmin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _modeAdmin
                                ? const Color(0xFFD4AF37)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🔐 Admin',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: _modeAdmin ? 'Email admin' : 'Email',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.email,
                      color: Color(0xFFD4AF37)),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.lock,
                      color: Color(0xFFD4AF37)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white60,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Info admin
              if (_modeAdmin)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '🔐 Email: admin@mediacite.com\nMot de passe: admin123456',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),

              const SizedBox(height: 12),

              // Erreur
              if (auth.erreur != null)
                Text(
                  auth.erreur!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 24),
// Bouton Visiteur
const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VisiteurView()),
      );
    },
    icon: const Icon(Icons.visibility, color: Colors.white60),
    label: const Text(
      'Continuer en tant que Visiteur',
      style: TextStyle(color: Colors.white60),
    ),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
              // Bouton connexion
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _connexion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _modeAdmin
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF800020),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _modeAdmin
                              ? '🔐 Connexion Admin'
                              : 'Se connecter',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Lien inscription (seulement mode usager)
              if (!_modeAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas de compte ? ',
                      style: TextStyle(color: Colors.white60),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterView()),
                      ),
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}