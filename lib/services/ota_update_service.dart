import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class OtaUpdateService {
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  // URL kiểm tra version mặc định trên GitHub (người dùng có thể tùy chỉnh)
  static String githubRepo = 'haitruongproqt1-a11y/cross_chat_app';
  static String versionCheckUrl = 'https://raw.githubusercontent.com/$githubRepo/main/version.json';

  Future<void> checkUpdate(BuildContext context, {bool showNoUpdateDialog = false}) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Đang kiểm tra bản cập nhật trên GitHub...'),
                ],
              ),
            ),
          ),
        ),
      );

      final response = await http.get(Uri.parse(versionCheckUrl)).timeout(const Duration(seconds: 8));

      if (context.mounted) Navigator.pop(context); // Đóng loading dialog

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final latestVersion = data['version'] ?? '1.0.0';
        final releaseNotes = data['changelog'] ?? data['release_notes'] ?? 'Bản vá lỗi và tối ưu hiệu suất.';
        
        // Trên Android ưu tiên link tải file APK trực tiếp để cài đặt ngay
        String otaUrl;
        if (Platform.isAndroid && data['apk_url'] != null) {
          otaUrl = data['apk_url'];
        } else {
          otaUrl = data['ota_package_url'] ?? data['download_url'] ?? 'https://github.com/$githubRepo/releases';
        }

        if (_isNewerVersion(latestVersion, AppConstants.appVersion)) {
          if (context.mounted) {
            _showUpdateAvailableDialog(context, latestVersion, releaseNotes, otaUrl);
          }
        } else {
          if (showNoUpdateDialog && context.mounted) {
            _showUpToDateDialog(context);
          }
        }
      } else {
        if (showNoUpdateDialog && context.mounted) {
          _showUpToDateDialog(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst || route.settings.name != null);
        if (showNoUpdateDialog) {
          _showUpToDateDialog(context);
        }
      }
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.replaceAll('v', '').split('.').map(int.parse).toList();
      final currentParts = current.replaceAll('v', '').split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return latest != current;
    }
  }

  void _showUpdateAvailableDialog(
    BuildContext context,
    String newVersion,
    String changelog,
    String downloadUrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_alt, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text('Có Bản Cập Nhật Mới (v$newVersion)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phiên bản hiện tại: v${AppConstants.appVersion}', style: TextStyle(color: Colors.grey)),
            Text('Phiên bản mới nhất: v$newVersion', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 12),
            const Text('Nội dung cập nhật (Changelog):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(changelog, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Cập nhật OTA ngay'),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang mở liên kết tải bản cập nhật mới nhất...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              final uri = Uri.parse(downloadUrl);
              try {
                final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!launched) {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              } catch (_) {
                try {
                  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                } catch (err) {
                  debugPrint('Could not launch update URL: $err');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUpToDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('Đã Là Bản Mới Nhất'),
          ],
        ),
        content: const Text('Bạn đang sử dụng phiên bản KINI CHAT mới nhất (v${AppConstants.appVersion}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }
}
