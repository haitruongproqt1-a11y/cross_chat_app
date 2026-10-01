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

  static const String githubRepo = 'haitruongproqt1-a11y/cross_chat_app';
  static const String versionCheckUrl = 'https://raw.githubusercontent.com/$githubRepo/main/version.json';

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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String? latestVersion;
      String? releaseNotes;
      String? otaUrl;

      // 1. Kiểm tra qua raw.githubusercontent.com (có chống cache)
      try {
        final rawUri = Uri.parse('$versionCheckUrl?t=$timestamp');
        final response = await http.get(
          rawUri,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'User-Agent': 'KINI-Chat-Updater',
          },
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          latestVersion = data['version'];
          releaseNotes = data['changelog'] ?? data['release_notes'];
          if (Platform.isAndroid && data['apk_url'] != null) {
            otaUrl = data['apk_url'];
          } else {
            otaUrl = data['ota_package_url'] ?? data['download_url'];
          }
        }
      } catch (_) {}

      // 2. Fallback: Nếu version.json bị cache cũ hoặc lỗi, truy vấn trực tiếp GitHub Releases API
      if (latestVersion == null || !_isNewerVersion(latestVersion, AppConstants.appVersion)) {
        try {
          final relApiUri = Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest?t=$timestamp');
          final relResponse = await http.get(
            relApiUri,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'KINI-Chat-Updater',
            },
          ).timeout(const Duration(seconds: 6));

          if (relResponse.statusCode == 200) {
            final relData = jsonDecode(utf8.decode(relResponse.bodyBytes));
            final tag = (relData['tag_name'] as String? ?? '').replaceAll('v', '').trim();
            if (tag.isNotEmpty && _isNewerVersion(tag, AppConstants.appVersion)) {
              latestVersion = tag;
              releaseNotes = relData['body'] ?? 'Bản cập nhật mới trên GitHub.';
              final assets = relData['assets'] as List? ?? [];
              for (var a in assets) {
                final name = a['name'] as String? ?? '';
                if (name.endsWith('.apk')) {
                  otaUrl = a['browser_download_url'];
                  break;
                }
              }
              otaUrl ??= 'https://github.com/$githubRepo/releases/download/v$tag/app-arm64-v8a-release.apk';
            }
          }
        } catch (_) {}
      }

      if (context.mounted) Navigator.pop(context); // Đóng loading dialog

      if (latestVersion != null && _isNewerVersion(latestVersion, AppConstants.appVersion)) {
        otaUrl ??= 'https://github.com/$githubRepo/releases';
        if (context.mounted) {
          _showUpdateAvailableDialog(context, latestVersion, releaseNotes ?? 'Bản vá lỗi và tối ưu hiệu suất.', otaUrl);
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
            const Text('Nội dung cập nhật:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(changelog, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
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
            label: const Text('Cập nhật ngay'),
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
      builder: (dialogCtx) {
        double progress = 0.0;
        int receivedBytes = 0;
        int totalBytes = 0;
        String statusText = 'Đang kết nối đến máy chủ GitHub...';
        bool isDone = false;
        bool isCancelled = false;
        bool hasError = false;
        HttpClientRequest? activeRequest;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Khởi chạy tác vụ tải tệp một lần duy nhất
            Future.microtask(() async {
              if (activeRequest != null) return;

              try {
                final httpClient = HttpClient();
                httpClient.userAgent = 'Mozilla/5.0 (Android; Mobile; rv:128.0) KINI-Chat';
                httpClient.connectionTimeout = const Duration(seconds: 15);
                httpClient.badCertificateCallback = (cert, host, port) => true;

                final request = await httpClient.getUrl(Uri.parse(downloadUrl));
                activeRequest = request;
                request.followRedirects = true;
                request.maxRedirects = 10;

                final response = await request.close().timeout(const Duration(seconds: 20));

                totalBytes = response.contentLength;
                if (totalBytes <= 0) totalBytes = 35 * 1024 * 1024; // Ước tính nếu server trả chunked

                final tempDir = Directory.systemTemp;
                final isApk = downloadUrl.endsWith('.apk');
                final fileName = isApk ? 'cross_chat_update_v$version.apk' : 'cross_chat_update_v$version.zip';
                final file = File('${tempDir.path}/$fileName');
                if (await file.exists()) {
                  await file.delete();
                }
                final sink = file.openWrite();

                await for (var chunk in response) {
                  if (isCancelled) break;
                  receivedBytes += chunk.length;
                  sink.add(chunk);

                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
                      final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
                      final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
                      final pct = (progress * 100).toInt();
                      statusText = 'Đang tải: $recMb MB / $totMb MB ($pct%)';
                    });
                  }
                }

                await sink.flush();
                await sink.close();

                if (isCancelled) return;

                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isDone = true;
                    statusText = 'Tải hoàn tất 100%! Đang mở trình cài đặt...';
                  });
                }

                await Future.delayed(const Duration(milliseconds: 600));
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                // Mở file để cài đặt ngay bằng OpenFilex
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
                if (isCancelled) return;
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    hasError = true;
                    statusText = 'Không thể tải trực tiếp. Nhấn bên dưới để mở trình duyệt tải về.';
                  });
                }
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle
                        : (hasError ? Icons.error_outline : Icons.cloud_download),
                    color: isDone ? Colors.green : (hasError ? Colors.redAccent : Colors.blueAccent),
                  ),
                  const SizedBox(width: 10),
                  const Text('Cập Nhật Trực Tiếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: hasError ? Colors.red : null)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: hasError ? 0.0 : (progress > 0 ? progress : null),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : (hasError ? Colors.red : Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tải trực tiếp tốc độ cao trong ứng dụng.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                if (!isDone && !hasError)
                  TextButton(
                    onPressed: () {
                      isCancelled = true;
                      activeRequest?.abort();
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('Hủy'),
                  ),
                if (hasError) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Đóng'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Mở trình duyệt tải về'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      final uri = Uri.parse(downloadUrl);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {}
                    },
                  ),
                ],
              ],
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
