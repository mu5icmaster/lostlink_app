class ChatMessageModel {
  final String id;
  final String itemId;
  final String sender;
  final String message;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.itemId,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      sender: json['sender'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'sender': sender,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
