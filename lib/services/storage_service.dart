import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();

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

  // Chọn nhiều ảnh từ Thư viện (Tối đa 10 ảnh chuẩn Zalo)
  Future<List<XFile>> pickMultiImage({int maxImages = 10}) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        limit: maxImages,
      );
      return images.take(maxImages).toList();
    } catch (e) {
      debugPrint('Lỗi chọn nhiều ảnh: $e');
      return [];
    }
  }

  // Pick Video from Gallery
  Future<XFile?> pickVideo() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // Chọn nhiều video từ Thư viện (Tối đa 10 video chuẩn Zalo)
  Future<List<PlatformFile>> pickMultiVideo({int maxVideos = 10}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.take(maxVideos).toList();
      }
    } catch (e) {
      debugPrint('Lỗi chọn nhiều video: $e');
    }
    return [];
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

  /// Tải tệp lên máy chủ lưu trữ vĩnh viễn, miễn phí 100% (Hình ảnh, Video, Âm thanh, Tài liệu)
  Future<String?> uploadFile({
    required String path,
    required String fileName,
    required String folder,
    Uint8List? fileBytes,
  }) async {
    // 1. Phương thức chính: Catbox API (Lưu trữ ảnh & video gốc vĩnh viễn, không giới hạn, không cần tài khoản)
    try {
      final url = Uri.parse('https://catbox.moe/user/api.php');
      final request = http.MultipartRequest('POST', url);
      request.fields['reqtype'] = 'fileupload';

      if (kIsWeb || fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'fileToUpload',
            fileBytes!,
            filename: fileName,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'fileToUpload',
            path,
            filename: fileName,
          ),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final resultUrl = response.body.trim();
        if (resultUrl.startsWith('http://') || resultUrl.startsWith('https://')) {
          debugPrint('Upload tệp thành công lên Catbox: $resultUrl');
          return resultUrl;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải tệp lên Catbox: $e');
    }

    // 2. Dự phòng: TmpFiles API (Hỗ trợ tải trực tiếp mọi loại file)
    try {
      final url = Uri.parse('https://tmpfiles.org/api/v1/upload');
      final request = http.MultipartRequest('POST', url);

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

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawUrl = data['data']?['url'] as String?;
        if (rawUrl != null && rawUrl.isNotEmpty) {
          final directUrl = rawUrl.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
          debugPrint('Upload tệp thành công lên TmpFiles: $directUrl');
          return directUrl;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải tệp lên TmpFiles: $e');
    }

    return null;
  }
}
