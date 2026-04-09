import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/media_model.dart';
import '../../services/firestore_service.dart';

class MediaDetailView extends StatefulWidget {
  final MediaModel media;

  const MediaDetailView({super.key, required this.media});

  @override
  State<MediaDetailView> createState() => _MediaDetailViewState();
}

class _MediaDetailViewState extends State<MediaDetailView> {
  bool _isLoading = false;
  bool _estFavori = false;
  bool _loadingFavori = true;

  @override
  void initState() {
    super.initState();
    _verifierFavori();
  }

  Future<void> _verifierFavori() async {
    final auth = context.read<AuthController>();
    if (auth.user == null) {
      setState(() => _loadingFavori = false);
      return;
    }
    final result = await FirestoreService()
        .estFavori(auth.user!.uid, widget.media.id);
    setState(() {
      _estFavori = result;
      _loadingFavori = false;
    });
  }

  Future<void> _toggleFavori() async {
    final auth = context.read<AuthController>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour ajouter aux favoris'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final service = FirestoreService();
    if (_estFavori) {
      await service.supprimerFavori(auth.user!.uid, widget.media.id);
      setState(() => _estFavori = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💔 Retiré des favoris'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } else {
      await service.ajouterFavori(auth.user!.uid, widget.media);
      setState(() => _estFavori = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❤️ Ajouté aux favoris !'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _emprunter() async {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour emprunter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await empruntCtrl.emprunterMedia(
      userId: auth.user!.uid,
      media: widget.media,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      String message;
      Color couleur;

      switch (result) {
        case 'success':
          message = '✅ "${widget.media.titre}" emprunté avec succès !';
          couleur = Colors.green;
          break;
        case 'limite':
          message = '❌ Limite de 3 emprunts atteinte !';
          couleur = Colors.red;
          break;
        case 'indisponible':
          message = '❌ Plus d\'exemplaire disponible !';
          couleur = Colors.orange;
          break;
        default:
          message = '❌ Erreur lors de l\'emprunt';
          couleur = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: couleur,
          duration: const Duration(seconds: 4),
        ),
      );

      if (result == 'success') Navigator.pop(context);
    }
  }

  Future<void> _reserver() async {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour réserver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await empruntCtrl.reserverMedia(
      userId: auth.user!.uid,
      media: widget.media,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Réservation confirmée ! Vous serez notifié quand disponible.'
                : '⚠️ Vous êtes déjà en file d\'attente pour ce média.',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );

      if (success) Navigator.pop(context);
    }
  }

  Future<void> _prolonger(String empruntId) async {
    final empruntCtrl = context.read<EmpruntController>();
    final success = await empruntCtrl.prolongerEmprunt(empruntId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Emprunt prolongé de 7 jours !'
                : '❌ Déjà prolongé — impossible de prolonger à nouveau.',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final disponible = media.quantiteDisponible > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          media.titre,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          _loadingFavori
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _estFavori ? Icons.favorite : Icons.favorite_border,
                    color: _estFavori ? Colors.redAccent : Colors.white60,
                  ),
                  onPressed: _toggleFavori,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header image ──────────────────
            Container(
              width: double.infinity,
              height: 250,
              color: const Color(0xFF16213E),
              child: Stack(
                children: [
                  // Image
                  Center(
                    child: media.couverture.isNotEmpty
                        ? Image.network(
                            media.couverture,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              media.categorie == 'film'
                                  ? Icons.movie
                                  : media.categorie == 'magazine'
                                      ? Icons.newspaper
                                      : Icons.book,
                              size: 80,
                              color: const Color(0xFFD4AF37),
                            ),
                          )
                        : Icon(
                            media.categorie == 'film'
                                ? Icons.movie
                                : media.categorie == 'magazine'
                                    ? Icons.newspaper
                                    : Icons.book,
                            size: 80,
                            color: const Color(0xFFD4AF37),
                          ),
                  ),

                  // Badge disponibilité
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: disponible
                            ? Colors.green.withOpacity(0.9)
                            : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        disponible
                            ? '${media.quantiteDisponible}/${media.quantite} dispo'
                            : '🔒 File d\'attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre + auteur ────────────
                  Text(
                    media.titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    media.auteur,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Chips infos ───────────────
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.category,
                        label: media.categorie[0].toUpperCase() +
                            media.categorie.substring(1),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.star,
                        label: '${media.note}/5',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.copy,
                        label: '${media.quantite} ex.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Description ───────────────
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    media.description.isNotEmpty
                        ? media.description
                        : 'Aucune description disponible.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Infos emprunt ─────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _InfoEmprunt(
                          icon: Icons.calendar_today,
                          label: 'Durée d\'emprunt',
                          valeur: '14 jours',
                        ),
                        const Divider(color: Colors.white10),
                        _InfoEmprunt(
                          icon: Icons.refresh,
                          label: 'Prolongation',
                          valeur: '+7 jours (1 fois)',
                        ),
                        const Divider(color: Colors.white10),
                        _InfoEmprunt(
                          icon: Icons.library_books,
                          label: 'Limite emprunts',
                          valeur: '3 médias max',
                        ),
                        const Divider(color: Colors.white10),
                        _InfoEmprunt(
                          icon: Icons.inventory,
                          label: 'Exemplaires',
                          valeur: '${media.quantiteDisponible}/${media.quantite} disponible(s)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Bouton Emprunter ou Réserver ──
                  if (disponible) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _emprunter,
                        icon: const Icon(Icons.book, color: Colors.white),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Emprunter maintenant',
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
                  ] else ...[
                    // File d'attente
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tous les exemplaires sont empruntés. Réservez pour être notifié !',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _reserver,
                        icon: const Icon(
                          Icons.bookmark_add,
                          color: Colors.white,
                        ),
                        label: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Rejoindre la file d\'attente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Bouton Favoris ────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loadingFavori ? null : _toggleFavori,
                      icon: Icon(
                        _estFavori
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        _estFavori
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoEmprunt extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;

  const _InfoEmprunt({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white60)),
        const Spacer(),
        Text(
          valeur,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}