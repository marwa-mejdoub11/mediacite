import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/media_controller.dart';
import '../auth/login_view.dart';
import '../auth/register_view.dart';

class VisiteurView extends StatefulWidget {
  const VisiteurView({super.key});

  @override
  State<VisiteurView> createState() => _VisiteurViewState();
}

class _VisiteurViewState extends State<VisiteurView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AccueilVisiteur(),
          _CatalogueVisiteur(),
          _InfoMediatheque(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF16213E),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'À propos',
          ),
        ],
      ),
    );
  }
}

// ── Accueil Visiteur ──────────────────────────
class _AccueilVisiteur extends StatelessWidget {
  const _AccueilVisiteur();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.library_books,
              size: 80,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bienvenue à Mediacité !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre médiathèque numérique moderne',
              style: TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bannière visiteur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.visibility, color: Color(0xFFD4AF37), size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Mode Visiteur',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vous avez accès limité au catalogue.\nInscrivez-vous pour profiter de toutes les fonctionnalités !',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Ce que le visiteur peut faire
            const Text(
              '✅ Accès visiteur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _AccessItem(
              icon: Icons.library_books,
              text: 'Consulter une partie du catalogue',
              allowed: true,
            ),
            _AccessItem(
              icon: Icons.info,
              text: 'Informations sur la médiathèque',
              allowed: true,
            ),
            _AccessItem(
              icon: Icons.person_add,
              text: 'Créer un compte usager',
              allowed: true,
            ),
            _AccessItem(
              icon: Icons.bookmark,
              text: 'Réserver des médias',
              allowed: false,
            ),
            _AccessItem(
              icon: Icons.event,
              text: 'S\'inscrire aux événements',
              allowed: false,
            ),
            _AccessItem(
              icon: Icons.history,
              text: 'Voir l\'historique d\'emprunts',
              allowed: false,
            ),
            const SizedBox(height: 32),

            // Boutons connexion / inscription
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterView()),
                ),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800020),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                ),
                icon: const Icon(Icons.login, color: Color(0xFFD4AF37)),
                label: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool allowed;

  const _AccessItem({
    required this.icon,
    required this.text,
    required this.allowed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.cancel,
            color: allowed ? Colors.green : Colors.red.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: allowed ? Colors.white70 : Colors.white30,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Catalogue Visiteur (limité) ───────────────
class _CatalogueVisiteur extends StatefulWidget {
  const _CatalogueVisiteur();

  @override
  State<_CatalogueVisiteur> createState() => _CatalogueVisiteurState();
}

class _CatalogueVisiteurState extends State<_CatalogueVisiteur> {
  @override
  void initState() {
    super.initState();
    context.read<MediaController>().chargerMedias();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MediaController>();
    // Visiteur voit seulement 3 médias
    final mediasLimites = ctrl.medias.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: const Text(
          'Catalogue (aperçu)',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Bannière limitation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF800020).withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aperçu limité — Inscrivez-vous pour voir tout le catalogue',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterView()),
                  ),
                  child: const Text(
                    'S\'inscrire',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste limitée
          Expanded(
            child: ctrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mediasLimites.length,
                    itemBuilder: (context, index) {
                      final media = mediasLimites[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              media.categorie == 'film'
                                  ? Icons.movie
                                  : media.categorie == 'magazine'
                                      ? Icons.newspaper
                                      : Icons.book,
                              color: const Color(0xFFD4AF37),
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    media.titre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    media.auteur,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: media.disponible
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                media.disponible ? 'Disponible' : 'Emprunté',
                                style: TextStyle(
                                  color: media.disponible
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Infos Médiathèque ─────────────────────────
class _InfoMediatheque extends StatelessWidget {
  const _InfoMediatheque();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: const Text(
          'À propos',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.library_books,
                size: 60,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Médiathèque Mediacité',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _InfoCard(
              icon: Icons.access_time,
              titre: 'Horaires',
              contenu: 'Lundi - Vendredi : 9h00 - 18h00\nSamedi : 9h00 - 13h00\nDimanche : Fermé',
            ),
            _InfoCard(
              icon: Icons.location_on,
              titre: 'Adresse',
              contenu: '123 Rue de la Culture\n75000 Paris, France',
            ),
            _InfoCard(
              icon: Icons.phone,
              titre: 'Contact',
              contenu: 'Tél: +33 1 23 45 67 89\nEmail: contact@mediacite.fr',
            ),
            _InfoCard(
              icon: Icons.info,
              titre: 'À propos',
              contenu: 'Mediacité est une médiathèque moderne offrant livres, films et magazines. Rejoignez notre communauté culturelle !',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String contenu;

  const _InfoCard({
    required this.icon,
    required this.titre,
    required this.contenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contenu,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}