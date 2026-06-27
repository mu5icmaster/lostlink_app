class AbuseReportModel {
  final String id;
  final String itemId;
  final String itemName;
  final String reporterEmail;
  final String reason;
  final String details;
  final String createdAt;
  String status;

  AbuseReportModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.reporterEmail,
    required this.reason,
    required this.details,
    required this.createdAt,
    this.status = 'Open',
  });

  factory AbuseReportModel.fromJson(Map<String, dynamic> json) {
    return AbuseReportModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      reporterEmail: json['reporterEmail'] as String,
      reason: json['reason'] as String,
      details: json['details'] as String,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String? ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'reporterEmail': reporterEmail,
      'reason': reason,
      'details': details,
      'createdAt': createdAt,
      'status': status,
    };
  }
}
