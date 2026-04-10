import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/event_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/event_model.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<EventModel>> _evenementsParDate = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<EventController>().chargerEvenements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Normalise la date (sans heure)
  DateTime _normaliserDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Construit la map événements par date
  void _construireMap(List<EventModel> evenements) {
    _evenementsParDate = {};
    for (final event in evenements) {
      final date = _normaliserDate(event.date);
      _evenementsParDate.putIfAbsent(date, () => []).add(event);
    }
  }

  List<EventModel> _getEvenementsJour(DateTime day) {
    return _evenementsParDate[_normaliserDate(day)] ?? [];
  }

  Future<void> _inscrire(EventModel event) async {
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
          .where('eventId', isEqualTo: event.id)
          .get();

      if (dejaInscrit.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Vous êtes déjà inscrit !'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Ajouter inscription
      await FirebaseFirestore.instance.collection('inscriptions').add({
        'userId': auth.user!.uid,
        'userNom': auth.user!.nom,
        'eventId': event.id,
        'titreEvent': event.titre,
        'dateEvent': event.date.toIso8601String(),
        'dateInscription': DateTime.now().toIso8601String(),
      });

      // Décrémenter places
      await FirebaseFirestore.instance
          .collection('evenements')
          .doc(event.id)
          .update({'placesRestantes': event.placesRestantes - 1});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Inscrit à "${event.titre}" !'),
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

    // Construire la map à chaque rebuild
    _construireMap(ctrl.evenements);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: const Text(
          'Événements',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Liste'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendrier'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Onglet Liste ──────────────────
          _buildListe(ctrl),
          // ── Onglet Calendrier ─────────────
          _buildCalendrier(ctrl),
        ],
      ),
    );
  }

  // ── Liste des événements ──────────────────────
  Widget _buildListe(EventController ctrl) {
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
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
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.evenements.length,
      itemBuilder: (context, index) {
        final event = ctrl.evenements[index];
        return _CarteEvenement(
          event: event,
          onInscrire: () => _inscrire(event),
        );
      },
    );
  }

  // ── Calendrier ────────────────────────────────
  Widget _buildCalendrier(EventController ctrl) {
    final evenementsJour = _selectedDay != null
        ? _getEvenementsJour(_selectedDay!)
        : [];

    return Column(
      children: [
        // Calendrier
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: TableCalendar<EventModel>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEvenementsJour,
            calendarStyle: CalendarStyle(
              // Jour normal
              defaultTextStyle: const TextStyle(color: Colors.white70),
              weekendTextStyle: const TextStyle(color: Colors.white54),
              outsideTextStyle: const TextStyle(color: Colors.white24),

              // Jour sélectionné
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF800020),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),

              // Aujourd'hui
              todayDecoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),

              // Marqueur événement
              markerDecoration: const BoxDecoration(
                color: Color(0xFFD4AF37),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,

              // Fond
              defaultDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Color(0xFFD4AF37),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Color(0xFFD4AF37),
              ),
              headerPadding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
        ),

        // Événements du jour sélectionné
        if (_selectedDay != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 6),
                Text(
                  evenementsJour.isEmpty
                      ? 'Aucun événement ce jour'
                      : '${evenementsJour.length} événement(s) ce jour',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: evenementsJour.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun événement ce jour',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: evenementsJour.length,
                    itemBuilder: (context, index) {
                      final event = evenementsJour[index] as EventModel;
                      return _CarteEvenement(
                        event: event,
                        onInscrire: () => _inscrire(event),
                      );
                    },
                  ),
          ),
        ] else
          const Expanded(
            child: Center(
              child: Text(
                '👆 Sélectionnez un jour pour voir les événements',
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Carte Événement ───────────────────────────
class _CarteEvenement extends StatefulWidget {
  final EventModel event;
  final VoidCallback onInscrire;

  const _CarteEvenement({
    required this.event,
    required this.onInscrire,
  });

  @override
  State<_CarteEvenement> createState() => _CarteEvenementState();
}

class _CarteEvenementState extends State<_CarteEvenement> {
  bool _dejaInscrit = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _verifierInscription();
  }

  Future<void> _verifierInscription() async {
    final auth = context.read<AuthController>();
    if (auth.user == null) {
      setState(() => _loading = false);
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('inscriptions')
        .where('userId', isEqualTo: auth.user!.uid)
        .where('eventId', isEqualTo: widget.event.id)
        .get();

    setState(() {
      _dejaInscrit = snap.docs.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final pctPlaces = event.placesTotal > 0
        ? event.placesRestantes / event.placesTotal
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _dejaInscrit
              ? const Color(0xFFD4AF37).withOpacity(0.4)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _dejaInscrit
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFD4AF37),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.date.day}/${event.date.month}/${event.date.year} à ${event.date.hour.toString().padLeft(2, '0')}h${event.date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_dejaInscrit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Inscrit',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Places
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${event.placesRestantes}/${event.placesTotal} places',
                          style: TextStyle(
                            color: event.placesRestantes > 3
                                ? Colors.white60
                                : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      event.placesRestantes == 0
                          ? 'Complet'
                          : event.placesRestantes <= 3
                              ? '⚠️ Dernières places !'
                              : '',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Barre progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pctPlaces,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pctPlaces > 0.5
                          ? Colors.green
                          : pctPlaces > 0.2
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
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            height: 36,
                            width: 36,
                            child: CircularProgressIndicator(
                              color: Color(0xFFD4AF37),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : _dejaInscrit
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Color(0xFFD4AF37),
                                size: 18,
                              ),
                              label: const Text(
                                'Déjà inscrit',
                                style: TextStyle(color: Color(0xFFD4AF37)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFD4AF37),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: event.placesRestantes > 0
                                  ? () async {
                                      widget.onInscrire();
                                      setState(() => _dejaInscrit = true);
                                    }
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}