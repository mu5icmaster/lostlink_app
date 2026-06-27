class ThankYouModel {
  final String id;
  final String itemId;
  final String itemName;
  final String fromName;
  final String toName;
  final String message;
  final String createdAt;

  ThankYouModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.fromName,
    required this.toName,
    required this.message,
    required this.createdAt,
  });

  factory ThankYouModel.fromJson(Map<String, dynamic> json) {
    return ThankYouModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'fromName': fromName,
      'toName': toName,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
