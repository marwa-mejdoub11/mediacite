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
          // Barre recherche
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

          // Filtres catégories
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
                      horizontal: 16,
                      vertical: 8,
                    ),
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

          // Liste médias
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
                            // ← Cliquable pour ouvrir le détail
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MediaDetailView(media: media),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.white10),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: media.disponible
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      media.disponible
                                          ? 'Disponible'
                                          : 'Emprunté',
                                      style: TextStyle(
                                        color: media.disponible
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white38,
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
}