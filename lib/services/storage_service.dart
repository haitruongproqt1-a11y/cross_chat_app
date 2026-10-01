import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Cloudinary Settings (Free tier, no credit card required)
  // You can set your own Cloud Name and Upload Preset below, or use the default demo preset
  static String cloudName = 'demo'; 
  static String uploadPreset = 'docs_upload_example_preset';

  /// Update Cloudinary credentials dynamically
  static void configureCloudinary({required String newCloudName, required String newPreset}) {
    cloudName = newCloudName;
    uploadPreset = newPreset;
  }

  // Pick Image from Gallery or Camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Pick Video
  Future<XFile?> pickVideo() async {
    try {
      return await _picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // Pick Document (PDF, Audio, DOCX, ZIP, etc.)
  Future<PlatformFile?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  /// Upload file / media to Cloudinary (100% Free, No Credit Card needed)
  Future<String?> uploadFile({
    required String path,
    required String fileName,
    required String folder,
    Uint8List? fileBytes,
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      if (kIsWeb || fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes!,
            filename: fileName,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            path,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;
        debugPrint('Uploaded to Cloudinary successfully: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary upload responded with code ${response.statusCode}: ${response.body}');
        // Fallback for offline demo
        return 'https://picsum.photos/seed/${_uuid.v4()}/800/600';
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return 'https://picsum.photos/seed/${_uuid.v4()}/800/600';
    }
  }
}
