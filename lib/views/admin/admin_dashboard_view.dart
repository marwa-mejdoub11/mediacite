import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/media_controller.dart';
import '../../models/media_model.dart';
import '../auth/login_view.dart';
import '../../utils/seed_data.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'scan_qr_view.dart'; // ✅ Import du scanner
import 'dart:convert';

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
            Text('Administration', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          // ✅ BOUTON SCANNER QR dans la AppBar
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD4AF37)),
            tooltip: 'Scanner un QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanQrView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthController>().deconnexion();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminAccueil(),
          _GestionMedias(),
          _AdminMessages(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Accueil ───────────────────────────────────────────────────────
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
            const SizedBox(height: 16),

            // ✅ BOUTON SCAN QR RAPIDE (grand bouton visible)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanQrView()),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                label: const Text(
                  '📷 Scanner Emprunt / Retour',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800020),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton nettoyer doublons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF16213E),
                      title: const Text(
                        '🧹 Nettoyer les doublons',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Cette action va fusionner les médias en double en augmentant leur quantité. Continuer ?',
                        style: TextStyle(color: Colors.white60),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Nettoyer',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await SeedData.nettoyerDoublons();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Doublons supprimés !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.cleaning_services, color: Colors.white),
                label: const Text(
                  'Nettoyer les doublons',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats
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
                  valeur:
                      '${mediaCtrl.medias.where((m) => m.disponible).length}',
                  couleur: Colors.green,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('emprunts')
                      .where('statut', isEqualTo: 'en_cours')
                      .snapshots(),
                  builder: (context, snap) {
                    final count =
                        snap.hasData ? snap.data!.docs.length : 0;
                    return _StatCard(
                      icon: Icons.lock,
                      label: 'Empruntés',
                      valeur: '$count',
                      couleur: Colors.orange,
                    );
                  },
                ),
                _StatCard(
                  icon: Icons.menu_book,
                  label: 'Livres',
                  valeur:
                      '${mediaCtrl.medias.where((m) => m.categorie == 'livre').length}',
                  couleur: const Color(0xFFD4AF37),
                ),
              ],
            ),

            _CategorieBar(
              label: 'Magazines',
              count: mediaCtrl.medias
                  .where((m) => m.categorie == 'magazine')
                  .length,
              total: mediaCtrl.medias.length,
              couleur: Colors.teal,
            ),

            const SizedBox(height: 24),
            const Text(
              '📋 Emprunts en cours',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emprunts')
                  .where('statut', isEqualTo: 'en_cours')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun emprunt en cours',
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.book,
                            color: Color(0xFFD4AF37),
                            size: 20,
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['titreMedia'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Retour: ${data['dateRetour'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ✅ BOUTON QR EMPRUNT
                          _QrIconButton(
                            icone: Icons.qr_code,
                            couleur: Colors.white,
                            tooltip: 'QR Emprunt',
                            onTap: () => _afficherQrDialog(
                              context: context,
                              titre: 'QR Code — Emprunt',
                              empruntId: doc.id,
                              mediaId: data['mediaId'] ?? '',
                              type: 'emprunt',
                            ),
                          ),

                          // ✅ BOUTON QR RETOUR
                          _QrIconButton(
                            icone: Icons.qr_code_2,
                            couleur: Colors.green,
                            tooltip: 'QR Retour',
                            onTap: () => _afficherQrDialog(
                              context: context,
                              titre: 'QR Code — Retour',
                              empruntId: doc.id,
                              mediaId: data['mediaId'] ?? '',
                              type: 'retour',
                            ),
                          ),

                          // Badge "En cours"
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'En cours',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche la dialog avec le QR code
void _afficherQrDialog({
  required BuildContext context,
  required String titre,
  required String empruntId,
  required String mediaId,
  required String type, // 'emprunt' ou 'retour'
}) {
  final qrData = jsonEncode({
    'empruntId': empruntId,
    'mediaId': mediaId,
    'type': type,
  });

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: type == 'retour'
              ? Colors.green.withOpacity(0.4)
              : Colors.white24,
        ),
      ),
      title: Row(
        children: [
          Icon(
            type == 'retour' ? Icons.qr_code_2 : Icons.qr_code,
            color: type == 'retour' ? Colors.green : const Color(0xFFD4AF37),
          ),
          const SizedBox(width: 8),
          Text(titre, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrData,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (type == 'retour' ? Colors.green : const Color(0xFFD4AF37))
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type == 'retour'
                  ? '📦 Présenter au retour du média'
                  : '📚 Présenter lors de la remise du média',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: type == 'retour' ? Colors.green : const Color(0xFFD4AF37),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer', style: TextStyle(color: Colors.white60)),
        ),
      ],
    ),
  );
}

/// Petit bouton icône pour afficher un QR
class _QrIconButton extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String tooltip;
  final VoidCallback onTap;

  const _QrIconButton({
    required this.icone,
    required this.couleur,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: couleur.withOpacity(0.3)),
          ),
          child: Icon(icone, color: couleur, size: 18),
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────
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
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Catégorie Bar ────────────────────────────────────────────────────────────
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
              Text(
                '$count',
                style: TextStyle(
                    color: couleur, fontWeight: FontWeight.bold),
              ),
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

// ── Gestion Médias CRUD ──────────────────────────────────────────────────────
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
    final couvertureCtrl =
        TextEditingController(text: media?.couverture ?? '');
    final quantiteCtrl = TextEditingController(
      text: media?.quantite.toString() ?? '1',
    );
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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media == null
                      ? '➕ Ajouter un média'
                      : '✏️ Modifier le média',
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
                _ChampTexte(
                    controller: couvertureCtrl, label: 'URL Couverture'),
                const SizedBox(height: 12),
                _ChampTexte(
                  controller: quantiteCtrl,
                  label: 'Nombre d\'exemplaires',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Text('Catégorie',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 8),
                Row(
                  children: ['livre', 'film', 'magazine'].map((cat) {
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => categorie = cat),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disponible',
                        style: TextStyle(color: Colors.white60)),
                    Switch(
                      value: disponible,
                      onChanged: (v) =>
                          setModalState(() => disponible = v),
                      activeColor: const Color(0xFFD4AF37),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ctrl = context.read<MediaController>();
                      final qte =
                          int.tryParse(quantiteCtrl.text) ?? 1;
                      final nouveauMedia = MediaModel(
                        id: media?.id ?? '',
                        titre: titreCtrl.text.trim(),
                        auteur: auteurCtrl.text.trim(),
                        categorie: categorie,
                        description: descCtrl.text.trim(),
                        couverture: couvertureCtrl.text.trim(),
                        disponible: disponible,
                        note: media?.note ?? 0,
                        quantite: qte,
                        quantiteDisponible: media == null
                            ? qte
                            : media.quantiteDisponible,
                      );
                      if (media == null) {
                        await ctrl.ajouterMedia(nouveauMedia);
                      } else {
                        await ctrl.modifierMedia(
                            media.id, nouveauMedia);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              media == null
                                  ? '✅ Média ajouté !'
                                  : '✅ Média modifié !',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
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
              child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37)))
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
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: media.couverture.isNotEmpty
                              ? Image.network(
                                  media.couverture,
                                  width: 40,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    media.categorie == 'film'
                                        ? Icons.movie
                                        : media.categorie == 'magazine'
                                            ? Icons.newspaper
                                            : Icons.book,
                                    color: const Color(0xFFD4AF37),
                                    size: 32,
                                  ),
                                )
                              : Icon(
                                  media.categorie == 'film'
                                      ? Icons.movie
                                      : media.categorie == 'magazine'
                                          ? Icons.newspaper
                                          : Icons.book,
                                  color: const Color(0xFFD4AF37),
                                  size: 32,
                                ),
                        ),
                        title: Text(
                          media.titre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.auteur,
                              style:
                                  const TextStyle(color: Colors.white60),
                            ),
                            Text(
                              '${media.quantiteDisponible}/${media.quantite} exemplaire(s)',
                              style: TextStyle(
                                color: media.quantiteDisponible > 0
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await FirebaseFirestore.instance
                                        .collection('medias')
                                        .doc(media.id)
                                        .update({
                                      'quantite': media.quantite + 1,
                                      'quantiteDisponible':
                                          media.quantiteDisponible + 1,
                                      'disponible': true,
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${media.quantiteDisponible}/${media.quantite}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFD4AF37), size: 20),
                              onPressed: () =>
                                  _afficherFormulaireAjout(media: media),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor:
                                        const Color(0xFF16213E),
                                    title: const Text('Confirmer',
                                        style: TextStyle(
                                            color: Colors.white)),
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
  final TextInputType? keyboardType;

  const _ChampTexte({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
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

// ── Admin Messages ───────────────────────────────────────────────────────────
class _AdminMessages extends StatefulWidget {
  const _AdminMessages();

  @override
  State<_AdminMessages> createState() => _AdminMessagesState();
}

class _AdminMessagesState extends State<_AdminMessages>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Annonces'),
            Tab(icon: Icon(Icons.message), text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminAnnonces(),
          _AdminMessagesList(),
        ],
      ),
    );
  }
}

// ── Annonces ─────────────────────────────────────────────────────────────────
class _AdminAnnonces extends StatelessWidget {
  const _AdminAnnonces();

  void _afficherFormulaireAnnonce(
      BuildContext context, AuthController auth) {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    String type = 'info';

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
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📢 Nouvelle Annonce',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    labelStyle:
                        const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contenuCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Contenu',
                    labelStyle:
                        const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Type',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TypeBtn(
                      label: 'Info',
                      selected: type == 'info',
                      couleur: Colors.blue,
                      onTap: () =>
                          setModalState(() => type = 'info'),
                    ),
                    const SizedBox(width: 8),
                    _TypeBtn(
                      label: 'Urgent',
                      selected: type == 'urgent',
                      couleur: Colors.red,
                      onTap: () =>
                          setModalState(() => type = 'urgent'),
                    ),
                    const SizedBox(width: 8),
                    _TypeBtn(
                      label: 'Événement',
                      selected: type == 'evenement',
                      couleur: const Color(0xFFD4AF37),
                      onTap: () =>
                          setModalState(() => type = 'evenement'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titreCtrl.text.isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('annonces')
                          .add({
                        'titre': titreCtrl.text.trim(),
                        'contenu': contenuCtrl.text.trim(),
                        'auteur': auth.user?.nom ?? 'Admin',
                        'date': DateTime.now().toIso8601String(),
                        'type': type,
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800020),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Publier',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
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
    final auth = context.read<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherFormulaireAnnonce(context, auth),
        backgroundColor: const Color(0xFF800020),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('annonces')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFD4AF37)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Aucune annonce',
                    style: TextStyle(color: Colors.white60)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'info';
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
                      type == 'urgent'
                          ? Icons.warning
                          : type == 'evenement'
                              ? Icons.event
                              : Icons.info,
                      color: type == 'urgent'
                          ? Colors.red
                          : type == 'evenement'
                              ? const Color(0xFFD4AF37)
                              : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['titre'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data['contenu'] ?? '',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.redAccent),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('annonces')
                            .doc(doc.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color couleur;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? couleur : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Messages Admin ────────────────────────────────────────────────────────────
class _AdminMessagesList extends StatefulWidget {
  const _AdminMessagesList();

  @override
  State<_AdminMessagesList> createState() => _AdminMessagesListState();
}

class EmpruntQrCode extends StatelessWidget {
  final String empruntId;
  final String mediaId;
  final String type;

  const EmpruntQrCode({
    super.key,
    required this.empruntId,
    required this.mediaId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final data = jsonEncode({
      'empruntId': empruntId,
      'mediaId': mediaId,
      'type': type,
    });
    return QrImageView(
      data: data,
      size: 180,
      backgroundColor: Colors.white,
    );
  }
}

class _AdminMessagesListState extends State<_AdminMessagesList> {
  final _reponseCtrl = TextEditingController();

  @override
  void dispose() {
    _reponseCtrl.dispose();
    super.dispose();
  }

  void _afficherReponse(BuildContext context, String messageId,
      String senderNom, String messageContenu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '↩️ Répondre',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👤 $senderNom',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    messageContenu,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reponseCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Votre réponse...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_reponseCtrl.text.trim().isEmpty) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .add({
                      'senderId': 'admin',
                      'senderNom': '🔐 Admin',
                      'contenu': _reponseCtrl.text.trim(),
                      'date': DateTime.now().toIso8601String(),
                      'lu': false,
                      'reponseA': senderNom,
                    });
                    _reponseCtrl.clear();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Erreur réponse: $e');
                  }
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'Envoyer la réponse',
                  style:
                      TextStyle(color: Colors.white, fontSize: 16),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Aucun message',
                  style: TextStyle(color: Colors.white60)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final estAdmin = data['senderId'] == 'admin';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: estAdmin
                    ? const Color(0xFF800020).withOpacity(0.15)
                    : const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: estAdmin
                      ? const Color(0xFF800020).withOpacity(0.3)
                      : Colors.white10,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: estAdmin
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF800020),
                            child: Text(
                              estAdmin
                                  ? '🔐'
                                  : (data['senderNom'] ?? 'U')[0]
                                      .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['senderNom'] ?? 'Anonyme',
                                style: TextStyle(
                                  color: estAdmin
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (data['reponseA'] != null)
                                Text(
                                  '↩️ En réponse à ${data['reponseA']}',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        (data['date'] ?? '').length > 16
                            ? (data['date'] as String)
                                .substring(11, 16)
                            : '',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['contenu'] ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!estAdmin)
                        GestureDetector(
                          onTap: () => _afficherReponse(
                            context,
                            doc.id,
                            data['senderNom'] ?? 'Anonyme',
                            data['contenu'] ?? '',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF800020)
                                  .withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.reply,
                                    color: Color(0xFF800020),
                                    size: 14),
                                SizedBox(width: 4),
                                Text('Répondre',
                                    style: TextStyle(
                                      color: Color(0xFF800020),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(doc.id)
                              .delete();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.delete,
                                  color: Colors.redAccent,
                                  size: 14),
                              SizedBox(width: 4),
                              Text('Supprimer',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
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
