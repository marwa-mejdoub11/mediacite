import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';

class EventController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<EventModel> _evenements = [];
  bool _isLoading = false;

  List<EventModel> get evenements => _evenements;
  bool get isLoading => _isLoading;

  // Charger les événements
  void chargerEvenements() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getEvenements().listen((evenements) {
      _evenements = evenements;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Ajouter événement (admin)
  Future<void> ajouterEvenement(EventModel event) async {
    await _firestoreService.ajouterEvenement(event);
    notifyListeners();
  }
}