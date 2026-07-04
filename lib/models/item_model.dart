class ItemModel {
  final String id;
  final String name;
  final String category;
  final String color;
  final String location;
  final String description;
  final String date;
  final String type; // lost or found
  String status;
  final String imageEmoji;
  final String? imageUrl;
  final String? cloudinaryPublicId;
  final String? localImagePath;
  final String reporterName;
  final String reporterEmail;
  final String reporterUid;
  final String reporterRole;
  final String contactInfo;
  final String? keptAt;
  final int? createdAtMillis;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.location,
    required this.description,
    required this.date,
    required this.type,
    required this.status,
    required this.imageEmoji,
    this.imageUrl,
    this.cloudinaryPublicId,
    this.localImagePath,
    this.reporterName = '',
    this.reporterEmail = '',
    this.reporterUid = '',
    this.reporterRole = '',
    this.contactInfo = '',
    this.keptAt,
    this.createdAtMillis,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      name: (json['name'] ?? json['title']) as String,
      category: json['category'] as String? ?? 'Others',
      color: json['color'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? 'lost',
      status: json['status'] as String? ?? 'Missing',
      imageEmoji: json['imageEmoji'] as String? ?? '\u{1F4E6}',
      imageUrl: json['imageUrl'] as String?,
      cloudinaryPublicId: json['cloudinaryPublicId'] as String?,
      localImagePath: json['localImagePath'] as String?,
      reporterName: json['reporterName'] as String? ?? '',
      reporterEmail: json['reporterEmail'] as String? ?? '',
      reporterUid:
          json['reporterUid'] as String? ?? json['createdBy'] as String? ?? '',
      reporterRole: json['reporterRole'] as String? ?? '',
      contactInfo: json['contactInfo'] as String? ?? '',
      keptAt: json['keptAt'] as String?,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt(),
    );
  }

  ItemModel copyWith({
    String? imageUrl,
    String? cloudinaryPublicId,
    String? localImagePath,
  }) {
    return ItemModel(
      id: id,
      name: name,
      category: category,
      color: color,
      location: location,
      description: description,
      date: date,
      type: type,
      status: status,
      imageEmoji: imageEmoji,
      imageUrl: imageUrl ?? this.imageUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      localImagePath: localImagePath ?? this.localImagePath,
      reporterName: reporterName,
      reporterEmail: reporterEmail,
      reporterUid: reporterUid,
      reporterRole: reporterRole,
      contactInfo: contactInfo,
      keptAt: keptAt,
      createdAtMillis: createdAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'location': location,
      'description': description,
      'date': date,
      'type': type,
      'status': status,
      'imageEmoji': imageEmoji,
      'imageUrl': imageUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'localImagePath': localImagePath,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'reporterUid': reporterUid,
      'reporterRole': reporterRole,
      'contactInfo': contactInfo,
      'keptAt': keptAt,
      'createdAtMillis': createdAtMillis,
    };
  }
}
