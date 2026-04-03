import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/firestore_service.dart';
import '../auth/login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header profil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFF800020),
                        child: Text(
                          user?.nom.isNotEmpty == true
                              ? user!.nom[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nom
                  Text(
                    user?.nom ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Badge rôle + statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(
                        label: user?.role.toUpperCase() ?? 'USAGER',
                        couleur: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: user?.statut.toUpperCase() ?? 'ACTIF',
                        couleur: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatProfil(label: 'Emprunts', valeur: '0'),
                      _StatProfil(label: 'Favoris', valeur: '0'),
                      _StatProfil(label: 'Événements', valeur: '0'),
                    ],
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD4AF37),
              labelColor: const Color(0xFFD4AF37),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.history), text: 'Historique'),
                Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
                Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoriqueTab(userId: user?.uid ?? ''),
                  _FavorisTab(userId: user?.uid ?? ''),
                  _ParametresTab(user: user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color couleur;

  const _Badge({required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: couleur,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Stat Profil ───────────────────────────────
class _StatProfil extends StatelessWidget {
  final String label;
  final String valeur;

  const _StatProfil({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valeur,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Tab Historique ────────────────────────────
class _HistoriqueTab extends StatelessWidget {
  final String userId;

  const _HistoriqueTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Center(
        child: Text(
          'Connectez-vous pour voir votre historique',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getEmpruntsUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          );
        }

        final emprunts = snapshot.data ?? [];

        if (emprunts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history,
                  color: Colors.white24,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun emprunt pour le moment',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Empruntez des médias pour les voir ici',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: emprunts.length,
          itemBuilder: (context, index) {
            final emprunt = emprunts[index];
            final statut = emprunt['statut'] ?? 'en_cours';
            final dateEmprunt = emprunt['dateEmprunt'] ?? '';
            final dateRetour = emprunt['dateRetour'] ?? '';

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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statut == 'en_cours'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statut == 'en_cours' ? Icons.book : Icons.check_circle,
                      color: statut == 'en_cours' ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emprunt['mediaId'] ?? 'Média',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emprunté le: $dateEmprunt',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Retour: $dateRetour',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statut == 'en_cours'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statut == 'en_cours' ? 'En cours' : 'Rendu',
                      style: TextStyle(
                        color: statut == 'en_cours'
                            ? Colors.orange
                            : Colors.green,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab Favoris ───────────────────────────────

class _FavorisTab extends StatelessWidget {
  final String userId;

  const _FavorisTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Center(
        child: Text(
          'Connectez-vous pour voir vos favoris',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getFavoris(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
          );
        }

        final favoris = snapshot.data ?? [];

        if (favoris.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, color: Colors.white24, size: 64),
                SizedBox(height: 16),
                Text(
                  'Aucun favori pour le moment',
                  style: TextStyle(color: Colors.white60),
                ),
                SizedBox(height: 8),
                Text(
                  'Ajoutez des médias depuis le catalogue',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoris.length,
          itemBuilder: (context, index) {
            final favori = favoris[index];
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
                    favori['categorie'] == 'film'
                        ? Icons.movie
                        : favori['categorie'] == 'magazine'
                            ? Icons.newspaper
                            : Icons.book,
                    color: const Color(0xFFD4AF37),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favori['titre'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          favori['auteur'] ?? '',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.redAccent),
                    onPressed: () async {
                      await FirestoreService().supprimerFavori(
                        userId,
                        favori['mediaId'],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Tab Paramètres ────────────────────────────
class _ParametresTab extends StatelessWidget {
  final dynamic user;

  const _ParametresTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mon compte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _OptionTile(
            icon: Icons.person,
            label: 'Modifier mon profil',
            onTap: () {},
          ),
          _OptionTile(
            icon: Icons.lock,
            label: 'Changer le mot de passe',
            onTap: () {},
          ),
          _OptionTile(
            icon: Icons.notifications,
            label: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: const Color(0xFFD4AF37),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          const Text(
            'Préférences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _OptionTile(
            icon: Icons.dark_mode,
            label: 'Mode sombre',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: const Color(0xFFD4AF37),
            ),
            onTap: () {},
          ),
          _OptionTile(
            icon: Icons.language,
            label: 'Langue',
            trailing: const Text(
              'Français',
              style: TextStyle(color: Colors.white38),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          const Text(
            'À propos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _OptionTile(
            icon: Icons.info,
            label: 'Version de l\'app',
            trailing: const Text(
              'v1.0.0',
              style: TextStyle(color: Colors.white38),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // Bouton déconnexion
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await auth.deconnexion();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800020),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}