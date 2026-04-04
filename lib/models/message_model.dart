class MessageModel {
  final String id;
  final String senderId;
  final String senderNom;
  final String contenu;
  final String date;
  final bool lu;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderNom,
    required this.contenu,
    required this.date,
    required this.lu,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderNom: map['senderNom'] ?? '',
      contenu: map['contenu'] ?? '',
      date: map['date'] ?? '',
      lu: map['lu'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderNom': senderNom,
      'contenu': contenu,
      'date': date,
      'lu': lu,
    };
  }
}