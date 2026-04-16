import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Vue de scan QR pour emprunts et retours.
/// À appeler depuis le dashboard admin :
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQrView()));
class ScanQrView extends StatefulWidget {
  const ScanQrView({super.key});

  @override
  State<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<ScanQrView> {
  final MobileScannerController _controller = MobileScannerController();
  bool _traitement = false; // évite les doubles scans

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Traitement du QR scanné ──────────────────
  Future<void> _traiterQr(String rawValue) async {
    if (_traitement) return;
    setState(() => _traitement = true);
    await _controller.stop();

    try {
      final Map<String, dynamic> qrData = jsonDecode(rawValue);
      final String empruntId = qrData['empruntId'] ?? '';
      final String type = qrData['type'] ?? '';

      if (empruntId.isEmpty) {
        _afficherErreur('QR invalide : empruntId manquant.');
        return;
      }

      // Vérifier que l'emprunt existe
      final docRef = FirebaseFirestore.instance
          .collection('emprunts')
          .doc(empruntId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        _afficherErreur('Emprunt introuvable (ID: $empruntId).');
        return;
      }

      final empruntData = docSnap.data()!;

      if (type == 'emprunt') {
        await _traiterEmprunt(docRef, empruntData, empruntId);
      } else if (type == 'retour') {
        await _traiterRetour(docRef, empruntData, empruntId, qrData['mediaId'] ?? '');
      } else {
        _afficherErreur('Type QR inconnu : $type');
      }
    } catch (e) {
      _afficherErreur('Erreur lors du scan : $e');
    }
  }

  // ── Valider un emprunt ───────────────────────
  Future<void> _traiterEmprunt(
    DocumentReference docRef,
    Map<String, dynamic> data,
    String empruntId,
  ) async {
    if (data['statut'] == 'en_cours') {
      _afficherResultat(
        succes: false,
        titre: 'Déjà emprunté',
        message: '"${data['titreMedia']}" est déjà en cours d\'emprunt.',
        icone: Icons.warning_amber_rounded,
        couleur: Colors.orange,
      );
      return;
    }

    await docRef.update({'statut': 'en_cours'});

    _afficherResultat(
      succes: true,
      titre: '✅ Emprunt validé !',
      message:
          '"${data['titreMedia']}" emprunté par ${data['utilisateurNom'] ?? 'l\'utilisateur'}.\n'
          'Retour prévu : ${data['dateRetour'] ?? 'non défini'}',
      icone: Icons.check_circle_rounded,
      couleur: Colors.green,
    );
  }

  // ── Valider un retour ────────────────────────
  Future<void> _traiterRetour(
    DocumentReference docRef,
    Map<String, dynamic> data,
    String empruntId,
    String mediaId,
  ) async {
    if (data['statut'] == 'retourne') {
      _afficherResultat(
        succes: false,
        titre: 'Déjà retourné',
        message: '"${data['titreMedia']}" a déjà été retourné.',
        icone: Icons.info_rounded,
        couleur: Colors.blue,
      );
      return;
    }

    // Batch : mettre à jour emprunt + incrémenter quantité du média
    final batch = FirebaseFirestore.instance.batch();

    batch.update(docRef, {
      'statut': 'retourne',
      'dateRetourEffectif': DateTime.now().toIso8601String(),
    });

    if (mediaId.isNotEmpty) {
      final mediaRef = FirebaseFirestore.instance
          .collection('medias')
          .doc(mediaId);
      final mediaSnap = await mediaRef.get();
      if (mediaSnap.exists) {
        final mediaData = mediaSnap.data()!;
        final int qteDisponible = (mediaData['quantiteDisponible'] ?? 0) + 1;
        batch.update(mediaRef, {
          'quantiteDisponible': qteDisponible,
          'disponible': true,
        });
      }
    }

    await batch.commit();

    _afficherResultat(
      succes: true,
      titre: '✅ Retour validé !',
      message:
          '"${data['titreMedia']}" retourné avec succès.\n'
          'Stock mis à jour automatiquement.',
      icone: Icons.assignment_return_rounded,
      couleur: const Color(0xFFD4AF37),
    );
  }

  // ── Dialog résultat ──────────────────────────
  void _afficherResultat({
    required bool succes,
    required String titre,
    required String message,
    required IconData icone,
    required Color couleur,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: couleur.withOpacity(0.4)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: couleur, size: 60),
            const SizedBox(height: 16),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: couleur,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ferme dialog
              Navigator.pop(context); // retour au dashboard
            },
            child: const Text(
              'Retour au dashboard',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _traitement = false);
              _controller.start();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: couleur,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Scanner encore',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog erreur ────────────────────────────
  void _afficherErreur(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Erreur', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _traitement = false);
              _controller.start();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF800020),
            ),
            child: const Text('Réessayer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('Scanner QR', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          // Bouton torche
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Switcher caméra
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Caméra ──────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                _traiterQr(barcode.rawValue!);
              }
            },
          ),

          // ── Overlay avec viseur ──────────────
          _ScanOverlay(),

          // ── Label bas d'écran ────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pointez le QR code d\'emprunt ou de retour',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendeBadge(
                      couleur: Colors.white,
                      icone: Icons.book,
                      label: 'Emprunt',
                    ),
                    const SizedBox(width: 16),
                    _LegendeBadge(
                      couleur: Colors.green,
                      icone: Icons.assignment_return,
                      label: 'Retour',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Spinner si traitement ────────────
          if (_traitement)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Overlay viseur QR ────────────────────────
class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const scanSize = 260.0;
    final top = (size.height - scanSize) / 2 - 40;
    final left = (size.width - scanSize) / 2;

    return Stack(
      children: [
        // Fond semi-transparent autour du viseur
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: scanSize,
                  height: scanSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Coins du viseur
        Positioned(
          top: top,
          left: left,
          child: _Corners(size: scanSize),
        ),
      ],
    );
  }
}

class _Corners extends StatelessWidget {
  final double size;
  const _Corners({required this.size});

  @override
  Widget build(BuildContext context) {
    const cornerSize = 28.0;
    const strokeWidth = 4.0;
    const color = Color(0xFFD4AF37);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Coin haut-gauche
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              painter: _CornerPainter(
                  topLeft: true, color: color, size: cornerSize, strokeWidth: strokeWidth),
              size: const Size(cornerSize, cornerSize),
            ),
          ),
          // Coin haut-droit
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              painter: _CornerPainter(
                  topRight: true, color: color, size: cornerSize, strokeWidth: strokeWidth),
              size: const Size(cornerSize, cornerSize),
            ),
          ),
          // Coin bas-gauche
          Positioned(
            bottom: 0,
            left: 0,
            child: CustomPaint(
              painter: _CornerPainter(
                  bottomLeft: true, color: color, size: cornerSize, strokeWidth: strokeWidth),
              size: const Size(cornerSize, cornerSize),
            ),
          ),
          // Coin bas-droit
          Positioned(
            bottom: 0,
            right: 0,
            child: CustomPaint(
              painter: _CornerPainter(
                  bottomRight: true, color: color, size: cornerSize, strokeWidth: strokeWidth),
              size: const Size(cornerSize, cornerSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color color;
  final double size, strokeWidth;

  const _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(Offset(0, size), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(s.width - size, 0), Offset(s.width, 0), paint);
      canvas.drawLine(Offset(s.width, 0), Offset(s.width, size), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, s.height - size), Offset(0, s.height), paint);
      canvas.drawLine(Offset(0, s.height), Offset(size, s.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
          Offset(s.width - size, s.height), Offset(s.width, s.height), paint);
      canvas.drawLine(
          Offset(s.width, s.height - size), Offset(s.width, s.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendeBadge extends StatelessWidget {
  final Color couleur;
  final IconData icone;
  final String label;

  const _LegendeBadge({
    required this.couleur,
    required this.icone,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: couleur, fontSize: 12)),
        ],
      ),
    );
  }
}
