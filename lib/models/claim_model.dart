import 'item_model.dart';

class ClaimModel {
  final String id;
  final ItemModel item;
  final String claimantName;
  final String claimantEmail;
  final String claimantUid;
  final String itemOwnerUid;
  final String studentId;
  final String contactInfo;
  final String proofDescription;
  final String? linkedLostItemId;
  String status; // Pending, Approved, Rejected
  final int? createdAtMillis;

  ClaimModel({
    required this.id,
    required this.item,
    required this.claimantName,
    this.claimantEmail = '',
    this.claimantUid = '',
    this.itemOwnerUid = '',
    required this.studentId,
    this.contactInfo = '',
    required this.proofDescription,
    this.linkedLostItemId,
    required this.status,
    this.createdAtMillis,
  });

  factory ClaimModel.fromJson(
    Map<String, dynamic> json,
    List<ItemModel> items,
  ) {
    final itemId = json['itemId'] as String;
    final item = items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => ItemModel.fromJson(json['item'] as Map<String, dynamic>),
    );

    return ClaimModel(
      id: json['id'] as String,
      item: item,
      claimantName: json['claimantName'] as String,
      claimantEmail: json['claimantEmail'] as String? ?? '',
      claimantUid: json['claimantUid'] as String? ?? '',
      itemOwnerUid: json['itemOwnerUid'] as String? ?? item.reporterUid,
      studentId: json['studentId'] as String,
      contactInfo: json['contactInfo'] as String? ?? '',
      proofDescription: json['proofDescription'] as String,
      linkedLostItemId: json['linkedLostItemId'] as String?,
      status: json['status'] as String,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': item.id,
      'claimantName': claimantName,
      'claimantEmail': claimantEmail,
      'claimantUid': claimantUid,
      'itemOwnerUid': itemOwnerUid,
      'studentId': studentId,
      'contactInfo': contactInfo,
      'proofDescription': proofDescription,
      'linkedLostItemId': linkedLostItemId,
      'status': status,
      'createdAtMillis': createdAtMillis,
    };
  }
}
