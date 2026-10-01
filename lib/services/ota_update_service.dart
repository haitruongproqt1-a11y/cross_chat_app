import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
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
            onPressed: () {
              Navigator.pop(ctx);
              _startInAppDownload(context, downloadUrl, newVersion);
            },
          ),
        ],
      ),
    );
  }

  void _startInAppDownload(BuildContext context, String downloadUrl, String version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double progress = 0.0;
        int receivedBytes = 0;
        int totalBytes = 0;
        String statusText = 'Đang kết nối đến máy chủ GitHub...';
        bool isDone = false;

        // Bắt đầu tải tệp ngay trong nền
        Future.microtask(() async {
          try {
            final client = http.Client();
            final request = http.Request('GET', Uri.parse(downloadUrl));
            final response = await client.send(request);

            totalBytes = response.contentLength ?? 0;
            final tempDir = Directory.systemTemp;
            final isApk = downloadUrl.endsWith('.apk');
            final fileName = isApk ? 'cross_chat_update_v$version.apk' : 'cross_chat_update_v$version.zip';
            final file = File('${tempDir.path}/$fileName');
            final sink = file.openWrite();

            await response.stream.listen(
              (chunk) {
                receivedBytes += chunk.length;
                sink.add(chunk);
                if (totalBytes > 0 && ctx.mounted) {
                  progress = receivedBytes / totalBytes;
                  final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                  final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                  final pct = (progress * 100).toInt();
                  statusText = 'Đang tải: $recMb MB / $totMb MB ($pct%)';
                  (ctx as Element).markNeedsBuild();
                }
              },
              cancelOnError: true,
            ).asFuture();

            await sink.close();
            isDone = true;
            statusText = 'Tải hoàn tất 100%! Đang mở cài đặt...';
            if (ctx.mounted) (ctx as Element).markNeedsBuild();

            await Future.delayed(const Duration(milliseconds: 500));
            if (ctx.mounted) Navigator.pop(ctx);

            // Mở file để cài đặt ngay bằng OpenFilex (tránh mở Chrome tải lại)
            if (isApk && Platform.isAndroid) {
              final result = await OpenFilex.open(file.path);
              if (result.type != ResultType.done) {
                final uri = Uri.parse(downloadUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
            } else {
              final uri = Uri.parse(downloadUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            }
          } catch (e) {
            if (ctx.mounted) Navigator.pop(ctx);
            // Fallback mở trình duyệt tải về
            final uri = Uri.parse(downloadUrl);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        });

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(isDone ? Icons.check_circle : Icons.cloud_download, color: isDone ? Colors.green : Colors.blueAccent),
                  const SizedBox(width: 10),
                  const Text('Cập Nhật Trực Tiếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(isDone ? Colors.green : Colors.blueAccent),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tải trực tiếp tốc độ cao trong ứng dụng, không cần mở Chrome.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
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
