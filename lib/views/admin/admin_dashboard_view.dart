import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/media_controller.dart';
import '../../models/media_model.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text(
              'Administration',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthController>().deconnexion();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminAccueil(),
          _GestionMedias(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF16213E),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Médias',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Accueil ─────────────────────────
class _AdminAccueil extends StatelessWidget {
  const _AdminAccueil();

  @override
  Widget build(BuildContext context) {
    final mediaCtrl = context.watch<MediaController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👋 Bonjour Admin !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Stats cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _StatCard(
                  icon: Icons.library_books,
                  label: 'Total Médias',
                  valeur: '${mediaCtrl.medias.length}',
                  couleur: const Color(0xFF800020),
                ),
                _StatCard(
                  icon: Icons.check_circle,
                  label: 'Disponibles',
                  valeur: '${mediaCtrl.medias.where((m) => m.disponible).length}',
                  couleur: Colors.green,
                ),
                _StatCard(
                  icon: Icons.lock,
                  label: 'Empruntés',
                  valeur: '${mediaCtrl.medias.where((m) => !m.disponible).length}',
                  couleur: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.menu_book,
                  label: 'Livres',
                  valeur: '${mediaCtrl.medias.where((m) => m.categorie == 'livre').length}',
                  couleur: const Color(0xFFD4AF37),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              '📊 Répartition par catégorie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _CategorieBar(
              label: 'Livres',
              count: mediaCtrl.medias.where((m) => m.categorie == 'livre').length,
              total: mediaCtrl.medias.length,
              couleur: const Color(0xFFD4AF37),
            ),
            _CategorieBar(
              label: 'Films',
              count: mediaCtrl.medias.where((m) => m.categorie == 'film').length,
              total: mediaCtrl.medias.length,
              couleur: const Color(0xFF800020),
            ),
            _CategorieBar(
              label: 'Magazines',
              count: mediaCtrl.medias.where((m) => m.categorie == 'magazine').length,
              total: mediaCtrl.medias.length,
              couleur: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;
  final Color couleur;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.valeur,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: couleur, size: 36),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              color: couleur,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorieBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color couleur;

  const _CategorieBar({
    required this.label,
    required this.count,
    required this.total,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text('$count', style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(couleur),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// ── Gestion Médias CRUD ───────────────────────
class _GestionMedias extends StatefulWidget {
  const _GestionMedias();

  @override
  State<_GestionMedias> createState() => _GestionMediasState();
}

class _GestionMediasState extends State<_GestionMedias> {
  @override
  void initState() {
    super.initState();
    context.read<MediaController>().chargerMedias();
  }

  void _afficherFormulaireAjout({MediaModel? media}) {
    final titreCtrl = TextEditingController(text: media?.titre ?? '');
    final auteurCtrl = TextEditingController(text: media?.auteur ?? '');
    final descCtrl = TextEditingController(text: media?.description ?? '');
    String categorie = media?.categorie ?? 'livre';
    bool disponible = media?.disponible ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media == null ? '➕ Ajouter un média' : '✏️ Modifier le média',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ChampTexte(controller: titreCtrl, label: 'Titre'),
                const SizedBox(height: 12),
                _ChampTexte(controller: auteurCtrl, label: 'Auteur'),
                const SizedBox(height: 12),
                _ChampTexte(controller: descCtrl, label: 'Description'),
                const SizedBox(height: 12),

                // Catégorie
                const Text('Catégorie', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 8),
                Row(
                  children: ['livre', 'film', 'magazine'].map((cat) {
                    return GestureDetector(
                      onTap: () => setModalState(() => categorie = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: categorie == cat
                              ? const Color(0xFF800020)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat[0].toUpperCase() + cat.substring(1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Disponible
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disponible',
                        style: TextStyle(color: Colors.white60)),
                    Switch(
                      value: disponible,
                      onChanged: (v) => setModalState(() => disponible = v),
                      activeColor: const Color(0xFFD4AF37),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bouton sauvegarder
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ctrl = context.read<MediaController>();
                      final nouveauMedia = MediaModel(
                        id: media?.id ?? '',
                        titre: titreCtrl.text.trim(),
                        auteur: auteurCtrl.text.trim(),
                        categorie: categorie,
                        description: descCtrl.text.trim(),
                        couverture: '',
                        disponible: disponible,
                        note: media?.note ?? 0,
                      );

                      if (media == null) {
                        await ctrl.ajouterMedia(nouveauMedia);
                      } else {
                        await ctrl.modifierMedia(media.id, nouveauMedia);
                      }

                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800020),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      media == null ? 'Ajouter' : 'Modifier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MediaController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherFormulaireAjout(),
        backgroundColor: const Color(0xFF800020),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ctrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : ctrl.medias.isEmpty
              ? const Center(
                  child: Text('Aucun média',
                      style: TextStyle(color: Colors.white60)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.medias.length,
                  itemBuilder: (context, index) {
                    final media = ctrl.medias[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          media.categorie == 'film'
                              ? Icons.movie
                              : media.categorie == 'magazine'
                                  ? Icons.newspaper
                                  : Icons.book,
                          color: const Color(0xFFD4AF37),
                          size: 32,
                        ),
                        title: Text(
                          media.titre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          media.auteur,
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Badge disponibilité
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
                                media.disponible ? '✅' : '🔒',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Modifier
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFD4AF37), size: 20),
                              onPressed: () =>
                                  _afficherFormulaireAjout(media: media),
                            ),
                            // Supprimer
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF16213E),
                                    title: const Text('Confirmer',
                                        style:
                                            TextStyle(color: Colors.white)),
                                    content: Text(
                                      'Supprimer "${media.titre}" ?',
                                      style: const TextStyle(
                                          color: Colors.white60),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Supprimer',
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await context
                                      .read<MediaController>()
                                      .supprimerMedia(media.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _ChampTexte({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}