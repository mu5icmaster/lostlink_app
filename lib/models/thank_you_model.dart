class ThankYouModel {
  final String id;
  final String itemId;
  final String itemName;
  final String fromName;
  final String fromUid;
  final String toUid;
  final String toName;
  final String message;
  final String createdAt;
  final int createdAtMillis;

  ThankYouModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.fromName,
    this.fromUid = '',
    this.toUid = '',
    required this.toName,
    required this.message,
    required this.createdAt,
    int? createdAtMillis,
  }) : createdAtMillis =
           createdAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  factory ThankYouModel.fromJson(Map<String, dynamic> json) {
    return ThankYouModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      fromName: json['fromName'] as String,
      fromUid: json['fromUid'] as String? ?? '',
      toUid: json['toUid'] as String? ?? '',
      toName: json['toName'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'fromName': fromName,
      'fromUid': fromUid,
      'toUid': toUid,
      'toName': toName,
      'message': message,
      'createdAt': createdAt,
      'createdAtMillis': createdAtMillis,
    };
  }
}
