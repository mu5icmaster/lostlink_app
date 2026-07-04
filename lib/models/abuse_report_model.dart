class AbuseReportModel {
  final String id;
  final String itemId;
  final String itemName;
  final String reporterEmail;
  final String reporterUid;
  final String reason;
  final String details;
  final String createdAt;
  final int createdAtMillis;
  String status;

  AbuseReportModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.reporterEmail,
    this.reporterUid = '',
    required this.reason,
    required this.details,
    required this.createdAt,
    int? createdAtMillis,
    this.status = 'Open',
  }) : createdAtMillis =
           createdAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  factory AbuseReportModel.fromJson(Map<String, dynamic> json) {
    return AbuseReportModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      reporterEmail: json['reporterEmail'] as String,
      reporterUid: json['reporterUid'] as String? ?? '',
      reason: json['reason'] as String,
      details: json['details'] as String,
      createdAt: json['createdAt'] as String,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'reporterEmail': reporterEmail,
      'reporterUid': reporterUid,
      'reason': reason,
      'details': details,
      'createdAt': createdAt,
      'createdAtMillis': createdAtMillis,
      'status': status,
    };
  }
}
