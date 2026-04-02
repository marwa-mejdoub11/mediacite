import 'package:flutter/material.dart';
import '../models/media_model.dart';
import '../services/firestore_service.dart';

class MediaController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<MediaModel> _medias = [];
  List<MediaModel> _mediasFiltres = [];
  bool _isLoading = false;
  bool _initialise = false;
  String _recherche = '';
  String _categorieFiltre = 'tous';

  List<MediaModel> get medias => _mediasFiltres;
  bool get isLoading => _isLoading;
  String get categorieFiltre => _categorieFiltre;

  void chargerMedias() {
    // Evite de charger plusieurs fois
    if (_initialise) return;
    _initialise = true;

    _isLoading = true;
    notifyListeners();

    _firestoreService.getMedias().listen((medias) {
      print('📚 Médias reçus: ${medias.length}');
      _medias = medias;
      _appliquerFiltres();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      print('❌ Erreur chargement médias: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void rechercher(String query) {
    _recherche = query.toLowerCase();
    _appliquerFiltres();
    notifyListeners();
  }

  void filtrerCategorie(String categorie) {
    _categorieFiltre = categorie;
    _appliquerFiltres();
    notifyListeners();
  }

  void _appliquerFiltres() {
    _mediasFiltres = _medias.where((media) {
      final matchRecherche = _recherche.isEmpty ||
          media.titre.toLowerCase().contains(_recherche) ||
          media.auteur.toLowerCase().contains(_recherche);

      final matchCategorie = _categorieFiltre == 'tous' ||
          media.categorie == _categorieFiltre;

      return matchRecherche && matchCategorie;
    }).toList();
  }

  Future<void> ajouterMedia(MediaModel media) async {
    await _firestoreService.ajouterMedia(media);
  }

  Future<void> supprimerMedia(String id) async {
    await _firestoreService.supprimerMedia(id);
  }
  Future<void> modifierMedia(String id, MediaModel media) async {
  await _firestoreService.modifierMedia(id, media);
}
}