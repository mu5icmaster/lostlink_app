import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String? publicId;

  const CloudinaryUploadResult({required this.secureUrl, this.publicId});
}

class CloudinaryService {
  static Future<CloudinaryUploadResult> uploadImage(File imageFile) async {
    if (cloudinaryCloudName.startsWith('PASTE_') ||
        cloudinaryUploadPreset.startsWith('PASTE_')) {
      throw StateError('Cloudinary cloud name and upload preset are not set');
    }

    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message'] as String?
          : null;
      throw StateError(message ?? 'Cloudinary upload failed');
    }

    final secureUrl = decoded['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary did not return an image URL');
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: decoded['public_id'] as String?,
    );
  }
}
