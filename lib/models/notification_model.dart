class NotificationModel {
  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String type;
  final String? itemId;
  final int createdAtMillis;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    required this.type,
    this.itemId,
    required this.createdAtMillis,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientUid: json['recipientUid'] as String? ?? '',
      title: json['title'] as String? ?? 'LostLink update',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      itemId: json['itemId'] as String?,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt() ?? 0,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipientUid': recipientUid,
    'title': title,
    'body': body,
    'type': type,
    'itemId': itemId,
    'createdAtMillis': createdAtMillis,
    'isRead': isRead,
  };
}
