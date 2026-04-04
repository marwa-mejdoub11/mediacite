import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../models/annonce_model.dart';
import '../../models/message_model.dart';

class CommunicationView extends StatefulWidget {
  const CommunicationView({super.key});

  @override
  State<CommunicationView> createState() => _CommunicationViewState();
}

class _CommunicationViewState extends State<CommunicationView>
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        automaticallyImplyLeading: false,
        title: const Text(
          'Communication',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
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
          _MurAnnonces(),
          _Messagerie(),
        ],
      ),
    );
  }
}

// ── Mur d'Annonces ────────────────────────────
class _MurAnnonces extends StatelessWidget {
  const _MurAnnonces();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton(
              onPressed: () => _afficherFormulaireAnnonce(context),
              backgroundColor: const Color(0xFF800020),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('annonces')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Aucune annonce pour le moment',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          final annonces = snapshot.data!.docs.map((doc) {
            return AnnonceModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final annonce = annonces[index];
              return _AnnonceCard(annonce: annonce, isAdmin: auth.isAdmin);
            },
          );
        },
      ),
    );
  }

  void _afficherFormulaireAnnonce(BuildContext context) {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();
    String type = 'info';
    final auth = context.read<AuthController>();

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

                // Titre
                TextField(
                  controller: titreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Titre',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Contenu
                TextField(
                  controller: contenuCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Contenu',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type
                const Text(
                  'Type',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TypeChip(
                      label: 'Info',
                      selected: type == 'info',
                      couleur: Colors.blue,
                      onTap: () => setModalState(() => type = 'info'),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Urgent',
                      selected: type == 'urgent',
                      couleur: Colors.red,
                      onTap: () => setModalState(() => type = 'urgent'),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Événement',
                      selected: type == 'evenement',
                      couleur: const Color(0xFFD4AF37),
                      onTap: () => setModalState(() => type = 'evenement'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bouton publier
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titreCtrl.text.isEmpty || contenuCtrl.text.isEmpty) {
                        return;
                      }
                      try {
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
                      } catch (e) {
                        print('Erreur annonce: $e');
                      }
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
}

// ── Carte Annonce ─────────────────────────────
class _AnnonceCard extends StatelessWidget {
  final AnnonceModel annonce;
  final bool isAdmin;

  const _AnnonceCard({required this.annonce, required this.isAdmin});

  Color get _couleurType {
    switch (annonce.type) {
      case 'urgent':
        return Colors.red;
      case 'evenement':
        return const Color(0xFFD4AF37);
      default:
        return Colors.blue;
    }
  }

  IconData get _iconeType {
    switch (annonce.type) {
      case 'urgent':
        return Icons.warning;
      case 'evenement':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _couleurType.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header annonce
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _couleurType.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_iconeType, color: _couleurType, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    annonce.titre,
                    style: TextStyle(
                      color: _couleurType,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white38,
                      size: 18,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('annonces')
                          .doc(annonce.id)
                          .delete();
                    },
                  ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annonce.contenu,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👤 ${annonce.auteur}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      annonce.date.length > 10
                          ? annonce.date.substring(0, 10)
                          : annonce.date,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color couleur;
  final VoidCallback onTap;

  const _TypeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? couleur : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Messagerie ────────────────────────────────
class _Messagerie extends StatefulWidget {
  const _Messagerie();

  @override
  State<_Messagerie> createState() => _MessagerieState();
}

class _MessagerieState extends State<_Messagerie> {
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerMessage(String userId, String nom) async {
    if (_messageCtrl.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': userId,
        'senderNom': nom,
        'contenu': _messageCtrl.text.trim(),
        'date': DateTime.now().toIso8601String(),
        'lu': false,
      });
      _messageCtrl.clear();
    } catch (e) {
      print('Erreur message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          // Liste messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message,
                          color: Colors.white24,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucun message pour le moment',
                          style: TextStyle(color: Colors.white60),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Soyez le premier à écrire !',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;
                    final estMoi = data['senderId'] == auth.user?.uid;

                    return _BulleMessage(
                      message: MessageModel.fromMap(data, messages[index].id),
                      estMoi: estMoi,
                      isAdmin: auth.isAdmin,
                      onDelete: auth.isAdmin
                          ? () async {
                              await FirebaseFirestore.instance
                                  .collection('messages')
                                  .doc(messages[index].id)
                                  .delete();
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Zone de saisie
          if (auth.isConnecte)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF800020),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _envoyerMessage(
                        auth.user?.uid ?? '',
                        auth.user?.nom ?? 'Anonyme',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF16213E),
              child: const Text(
                '🔐 Connectez-vous pour envoyer des messages',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bulle Message ─────────────────────────────
class _BulleMessage extends StatelessWidget {
  final MessageModel message;
  final bool estMoi;
  final bool isAdmin;
  final VoidCallback? onDelete;

  const _BulleMessage({
    required this.message,
    required this.estMoi,
    required this.isAdmin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF800020),
              child: Text(
                message.senderNom.isNotEmpty
                    ? message.senderNom[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: estMoi
                    ? const Color(0xFF800020)
                    : const Color(0xFF16213E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(estMoi ? 16 : 4),
                  bottomRight: Radius.circular(estMoi ? 4 : 16),
                ),
                border: estMoi
                    ? null
                    : Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: estMoi
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!estMoi)
                    Text(
                      message.senderNom,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    message.contenu,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.date.length > 10
                            ? message.date.substring(11, 16)
                            : message.date,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      if (isAdmin && onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white38,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (estMoi) const SizedBox(width: 8),
        ],
      ),
    );
  }
}