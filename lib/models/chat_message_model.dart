class ChatMessageModel {
  final String id;
  final String itemId;
  final String sender;
  final String senderUid;
  final String senderEmail;
  final String message;
  final String createdAt;
  final int createdAtMillis;

  ChatMessageModel({
    required this.id,
    required this.itemId,
    required this.sender,
    this.senderUid = '',
    this.senderEmail = '',
    required this.message,
    required this.createdAt,
    int? createdAtMillis,
  }) : createdAtMillis =
           createdAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      sender: json['sender'] as String,
      senderUid: json['senderUid'] as String? ?? '',
      senderEmail: json['senderEmail'] as String? ?? '',
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'sender': sender,
      'senderUid': senderUid,
      'senderEmail': senderEmail,
      'message': message,
      'createdAt': createdAt,
      'createdAtMillis': createdAtMillis,
    };
  }
}
