import 'item_model.dart';

class ClaimModel {
  final String id;
  final ItemModel item;
  final String claimantName;
  final String studentId;
  final String contactInfo;
  final String proofDescription;
  String status; // Pending, Approved, Rejected

  ClaimModel({
    required this.id,
    required this.item,
    required this.claimantName,
    required this.studentId,
    this.contactInfo = '',
    required this.proofDescription,
    required this.status,
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
      studentId: json['studentId'] as String,
      contactInfo: json['contactInfo'] as String? ?? '',
      proofDescription: json['proofDescription'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': item.id,
      'item': item.toJson(),
      'claimantName': claimantName,
      'studentId': studentId,
      'contactInfo': contactInfo,
      'proofDescription': proofDescription,
      'status': status,
    };
  }
}
