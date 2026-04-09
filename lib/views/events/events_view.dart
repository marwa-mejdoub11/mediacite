import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/event_controller.dart';
import '../../controllers/auth_controller.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  @override
  void initState() {
    super.initState();
    context.read<EventController>().chargerEvenements();
  }

  Future<void> _inscrire(String eventId, int placesRestantes, String titre) async {
    final auth = context.read<AuthController>();

    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour vous inscrire !'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Vérifier si déjà inscrit
      final dejaInscrit = await FirebaseFirestore.instance
          .collection('inscriptions')
          .where('userId', isEqualTo: auth.user!.uid)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (dejaInscrit.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Vous êtes déjà inscrit à cet événement !'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Ajouter l'inscription
      await FirebaseFirestore.instance.collection('inscriptions').add({
        'userId': auth.user!.uid,
        'userNom': auth.user!.nom,
        'eventId': eventId,
        'titreEvent': titre,
        'dateInscription': DateTime.now().toIso8601String(),
      });

      // Décrémenter les places
      await FirebaseFirestore.instance
          .collection('evenements')
          .doc(eventId)
          .update({'placesRestantes': placesRestantes - 1});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inscrit à "$titre" avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<EventController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Événements',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ctrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : ctrl.evenements.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun événement prévu',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ctrl.evenements.length,
                  itemBuilder: (context, index) {
                    final event = ctrl.evenements[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            event.titre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date + places
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFD4AF37),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.date.day}/${event.date.month}/${event.date.year}',
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // Places avec barre de progression
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: Colors.white60,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${event.placesRestantes}/${event.placesTotal} places',
                                    style: TextStyle(
                                      color: event.placesRestantes > 0
                                          ? Colors.white60
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Barre de progression des places
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.placesTotal > 0
                                  ? event.placesRestantes / event.placesTotal
                                  : 0,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event.placesRestantes > 5
                                    ? Colors.green
                                    : event.placesRestantes > 0
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bouton inscription
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: event.placesRestantes > 0
                                  ? () => _inscrire(
                                        event.id,
                                        event.placesRestantes,
                                        event.titre,
                                      )
                                  : null,
                              icon: Icon(
                                event.placesRestantes > 0
                                    ? Icons.how_to_reg
                                    : Icons.block,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                event.placesRestantes > 0
                                    ? 'S\'inscrire'
                                    : 'Complet',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: event.placesRestantes > 0
                                    ? const Color(0xFF800020)
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}