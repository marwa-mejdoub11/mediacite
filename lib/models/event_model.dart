class EventModel {
  final String id;
  final String titre;
  final String description;
  final DateTime date;
  final int placesTotal;
  final int placesRestantes;

  EventModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.date,
    required this.placesTotal,
    required this.placesRestantes,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      placesTotal: map['placesTotal'] ?? 0,
      placesRestantes: map['placesRestantes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'date': date.toIso8601String(),
      'placesTotal': placesTotal,
      'placesRestantes': placesRestantes,
    };
  }
}