
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/media_controller.dart';
import 'media_detail_view.dart';

class CatalogueView extends StatefulWidget {
  const CatalogueView({super.key});

  @override
  State<CatalogueView> createState() => _CatalogueViewState();
}

class _CatalogueViewState extends State<CatalogueView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MediaController>().chargerMedias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MediaController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Catalogue',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Barre recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: ctrl.rechercher,
              decoration: InputDecoration(
                hintText: 'Rechercher un média...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFD4AF37),
                ),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🎯 Filtres catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['tous', 'livre', 'film', 'magazine'].map((cat) {
                final selected = ctrl.categorieFiltre == cat;
                return GestureDetector(
                  onTap: () => ctrl.filtrerCategorie(cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF800020)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat[0].toUpperCase() + cat.substring(1),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 📚 Liste médias
          Expanded(
            child: ctrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  )
                : ctrl.medias.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun média trouvé',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ctrl.medias.length,
                        itemBuilder: (context, index) {
                          final media = ctrl.medias[index];

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MediaDetailView(media: media),
                              ),
                            ),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      media.quantiteDisponible > 0
                                          ? Colors.white10
                                          : Colors.orange
                                              .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 📷 Image ou icône
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: media.couverture.isNotEmpty
                                        ? Image.network(
                                            media.couverture,
                                            width: 55,
                                            height: 75,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) =>
                                                    _iconeMedia(
                                                        media.categorie),
                                          )
                                        : _iconeMedia(
                                            media.categorie),
                                  ),
                                  const SizedBox(width: 12),

                                  // 📝 Infos
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          media.titre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          media.auteur,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            // 🏷 Catégorie
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                          horizontal:
                                                              8,
                                                          vertical:
                                                              2),
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    Colors.white10,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            8),
                                              ),
                                              child: Text(
                                                media.categorie[0]
                                                        .toUpperCase() +
                                                    media.categorie
                                                        .substring(1),
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.white60,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            // ⭐ Note
                                            const Icon(
                                              Icons.star,
                                              color: Color(
                                                  0xFFD4AF37),
                                              size: 12,
                                            ),
                                            Text(
                                              ' ${media.note}',
                                              style:
                                                  const TextStyle(
                                                color: Color(
                                                    0xFFD4AF37),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        // ✅ Statut avec quantité
                                        Row(
                                          children: [
                                            Icon(
                                              media.quantiteDisponible >
                                                      0
                                                  ? Icons
                                                      .check_circle
                                                  : Icons.access_time,
                                              color:
                                                  media.quantiteDisponible >
                                                          0
                                                      ? Colors.green
                                                      : Colors.orange,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              media.quantiteDisponible >
                                                      0
                                                  ? '${media.quantiteDisponible}/${media.quantite} disponible(s)'
                                                  : 'Non disponible — Réserver',
                                              style: TextStyle(
                                                color: media
                                                            .quantiteDisponible >
                                                        0
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ⚡ Action rapide
                                  Column(
                                    children: [
                                      Icon(
                                        media.quantiteDisponible > 0
                                            ? Icons.book
                                            : Icons.bookmark_add,
                                        color:
                                            media.quantiteDisponible >
                                                    0
                                                ? const Color(
                                                    0xFF800020)
                                                : const Color(
                                                    0xFFD4AF37),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white38,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 🎨 Icône par catégorie
  Widget _iconeMedia(String categorie) {
    return Container(
      width: 55,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        categorie == 'film'
            ? Icons.movie
            : categorie == 'magazine'
                ? Icons.newspaper
                : Icons.book,
        color: const Color(0xFFD4AF37),
        size: 30,
      ),
    );
  }
}
