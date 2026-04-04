import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/media_controller.dart';
import '../../controllers/event_controller.dart';
import '../communication/communication_view.dart';
import '../catalogue/catalogue_view.dart';
import '../events/events_view.dart';
import '../profile/profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _AccueilPage(),
    const CatalogueView(),
    const EventsView(),
    const CommunicationView(),
    const ProfileView(),
   
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            icon: Icon(Icons.event),
            label: 'Événements',
          ),
          BottomNavigationBarItem(
             icon: Icon(Icons.message),
             label: 'Messages',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
            label: 'Profil',
 
),  
        ],
      ),
    );
  }
}

class _AccueilPage extends StatelessWidget {
  const _AccueilPage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final mediaCtrl = context.read<MediaController>();
    final eventCtrl = context.read<EventController>();

    mediaCtrl.chargerMedias();
    eventCtrl.chargerEvenements();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bonjour 👋',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      auth.user?.nom ?? 'Visiteur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.library_books,
                  color: Color(0xFFD4AF37),
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 16),



            // Statistiques rapides
            Row(
              children: [
                _StatCard(
                  icon: Icons.book,
                  label: 'Médias',
                  valeur: '120+',
                  couleur: const Color(0xFF800020),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.event,
                  label: 'Événements',
                  valeur: '8',
                  couleur: const Color(0xFFD4AF37),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.people,
                  label: 'Membres',
                  valeur: '250+',
                  couleur: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Section Nouveautés
            const Text(
              '📚 Nouveautés',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<MediaController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  );
                }
                if (ctrl.medias.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun média disponible',
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ctrl.medias.take(5).length,
                    itemBuilder: (context, index) {
                      final media = ctrl.medias[index];
                      return _MediaCard(
                        titre: media.titre,
                        auteur: media.auteur,
                        categorie: media.categorie,
                        disponible: media.disponible,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Section Événements
            const Text(
              '🎭 Prochains Événements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<EventController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  );
                }
                if (ctrl.evenements.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun événement prévu',
                      style: TextStyle(color: Colors.white60),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ctrl.evenements.take(3).length,
                  itemBuilder: (context, index) {
                    final event = ctrl.evenements[index];
                    return _EventCard(
                      titre: event.titre,
                      date: event.date,
                      places: event.placesRestantes,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: couleur.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: couleur.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: couleur, size: 28),
            const SizedBox(height: 6),
            Text(
              valeur,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String titre;
  final String auteur;
  final String categorie;
  final bool disponible;

  const _MediaCard({
    required this.titre,
    required this.auteur,
    required this.categorie,
    required this.disponible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            categorie == 'film'
                ? Icons.movie
                : categorie == 'magazine'
                    ? Icons.newspaper
                    : Icons.book,
            size: 48,
            color: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              titre,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            auteur,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: disponible
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              disponible ? 'Disponible' : 'Emprunté',
              style: TextStyle(
                color: disponible ? Colors.green : Colors.red,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String titre;
  final DateTime date;
  final int places;

  const _EventCard({
    required this.titre,
    required this.date,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFF800020).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event,
              color: Color(0xFF800020),
            ),
          ),
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
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$places places',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}