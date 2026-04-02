import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/event_controller.dart';

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
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
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
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Color(0xFFD4AF37), size: 14),
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
                              Text(
                                '${event.placesRestantes} places restantes',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: event.placesRestantes > 0
                                  ? () {}
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF800020),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                event.placesRestantes > 0
                                    ? 'S\'inscrire'
                                    : 'Complet',
                                style: const TextStyle(color: Colors.white),
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