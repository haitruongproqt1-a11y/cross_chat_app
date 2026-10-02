import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';

class TikTokViewerScreen extends StatefulWidget {
  final String? initialUrl;
  final Function(String link)? onShareToChat; // Gọi lại khi bấm chia sẻ link vào chat

  const TikTokViewerScreen({
    super.key,
    this.initialUrl,
    this.onShareToChat,
  });

  @override
  State<TikTokViewerScreen> createState() => _TikTokViewerScreenState();
}

class _TikTokViewerScreenState extends State<TikTokViewerScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentTab = 0; // 0: Dành cho bạn, 1: Khám phá, 2: LIVE

  static const String _urlForYou = 'https://www.tiktok.com';
  static const String _urlExplore = 'https://www.tiktok.com/explore';
  static const String _urlLive = 'https://www.tiktok.com/live';

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    final String startUrl = widget.initialUrl ?? _urlForYou;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _injectAntiModalScript();
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            // Ngăn chặn các scheme ứng dụng bên ngoài như snssdk1233://, intent://, market://, tiktok://
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              debugPrint('Prevented deep link scheme: ${request.url}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            final desc = error.description.toLowerCase();
            // Bỏ qua hoàn toàn các lỗi scheme deep link hoặc tracker bị chặn
            if (desc.contains('err_unknown_url_scheme') ||
                desc.contains('err_blocked_by') ||
                desc.contains('err_connection_refused')) {
              return;
            }
            // Chỉ hiển thị thông báo nếu thực sự mất kết nối mạng
            if (error.isForMainFrame == true &&
                (desc.contains('err_name_not_resolved') ||
                 desc.contains('err_internet_disconnected') ||
                 desc.contains('err_connection_timed_out'))) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Không thể kết nối Internet: ${error.description}';
                  _isLoading = false;
                });
              }
            }
          },
        ),
      );

    // Kích hoạt phát media tự động trên Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.loadRequest(Uri.parse(startUrl));
  }

  void _switchTab(int index) {
    if (_currentTab == index) return;
    setState(() {
      _currentTab = index;
    });

    String targetUrl = _urlForYou;
    if (index == 1) {
      targetUrl = _urlExplore;
    } else if (index == 2) {
      targetUrl = _urlLive;
    }
    _controller.loadRequest(Uri.parse(targetUrl));
  }

  Future<void> _shareCurrentLink() async {
    final currentUrl = await _controller.currentUrl();
    if (currentUrl == null || currentUrl.isEmpty) return;

    if (widget.onShareToChat != null) {
      widget.onShareToChat!(currentUrl);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi liên kết TikTok vào đoạn chat!'),
            backgroundColor: Color(0xFF00F2FE),
          ),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: currentUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép liên kết TikTok vào bộ nhớ tạm'),
            backgroundColor: Color(0xFF00F2FE),
          ),
        );
      }
    }
  }

  void _injectAntiModalScript() {
    const script = '''
(function() {
  if (!document.getElementById('tiktok-bypass-css')) {
    const style = document.createElement('style');
    style.id = 'tiktok-bypass-css';
    style.innerHTML = `
      [class*="login-modal"],
      [class*="LoginModal"],
      [class*="mask-wrapper"],
      [class*="modal-mask"],
      [class*="DivLoginModalContainer"],
      [class*="DivModalContainer"],
      [class*="DivBannerContainer"],
      [class*="DivMobileDownloadBanner"],
      [class*="DivOpenApp"],
      [class*="tiktok-modal"],
      div[role="dialog"] {
        display: none !important;
        opacity: 0 !important;
        pointer-events: none !important;
        visibility: hidden !important;
      }
      html, body {
        overflow: auto !important;
        position: static !important;
        touch-action: pan-y !important;
      }
    `;
    document.head.appendChild(style);
  }

  function purgeTikTokModals() {
    try {
      const selectors = [
        '[class*="login-modal"]',
        '[class*="LoginModal"]',
        '[class*="mask-wrapper"]',
        '[class*="modal-mask"]',
        '[class*="DivLoginModalContainer"]',
        '[class*="DivModalContainer"]',
        '[class*="DivBannerContainer"]',
        '[class*="DivMobileDownloadBanner"]',
        '[class*="DivOpenApp"]',
        'div[role="dialog"]'
      ];
      selectors.forEach(sel => {
        document.querySelectorAll(sel).forEach(el => el.remove());
      });
      if (document.body) {
        document.body.style.overflow = 'auto';
        document.body.style.position = 'static';
        document.body.classList.remove('tiktok-modal-open');
      }
      if (document.documentElement) {
        document.documentElement.style.overflow = 'auto';
        document.documentElement.classList.remove('tiktok-modal-open');
      }
      const videos = document.querySelectorAll('video');
      videos.forEach(v => {
        if (v.paused && v.readyState >= 2) {
          v.play().catch(() => {});
        }
      });
    } catch(e) {}
  }

  purgeTikTokModals();
  if (!window.__tiktok_purge_interval) {
    window.__tiktok_purge_interval = setInterval(purgeTikTokModals, 1000);
  }
})();
''';
    _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x6600F2FE), offset: Offset(-1, -1), blurRadius: 4),
                  BoxShadow(color: Color(0x66FE0979), offset: Offset(1, 1), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'TikTok & LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFFFE0979), size: 24),
            tooltip: 'Đăng nhập TikTok (Xem & Thả tim không giới hạn)',
            onPressed: () {
              _controller.loadRequest(Uri.parse('https://www.tiktok.com/login'));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Làm mới',
            onPressed: () => _controller.reload(),
          ),
          if (widget.onShareToChat != null)
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF00F2FE), size: 22),
              tooltip: 'Gửi link vào cuộc trò chuyện',
              onPressed: _shareCurrentLink,
            )
          else
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 22),
              tooltip: 'Sao chép liên kết',
              onPressed: _shareCurrentLink,
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white70, size: 22),
            tooltip: 'Mở bằng trình duyệt ngoài',
            onPressed: () async {
              final url = await _controller.currentUrl();
              if (url != null) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Column(
            children: [
              // Thanh chọn chuyên mục: Dành cho bạn | Khám phá | Trực tiếp LIVE
              Container(
                height: 40,
                color: const Color(0xFF161616),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Dành Cho Bạn', Icons.home_filled),
                    _buildTabItem(1, 'Khám Phá', Icons.explore_outlined),
                    _buildTabItem(2, 'Trực Tiếp LIVE', Icons.sensors, isLive: true),
                  ],
                ),
              ),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFFE0979),
                  minHeight: 2,
                )
              else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_errorMessage != null)
            Container(
              color: Colors.black.withAlpha(220),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE0979),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _controller.reload();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 48,
        color: const Color(0xFF121212),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
                  tooltip: 'Trang trước',
                  onPressed: () async {
                    if (await _controller.canGoBack()) {
                      await _controller.goBack();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                  tooltip: 'Trang kế',
                  onPressed: () async {
                    if (await _controller.canGoForward()) {
                      await _controller.goForward();
                    }
                  },
                ),
              ],
            ),
            const Text(
              '❤️ Thả tim & 💬 Bình luận trực tiếp',
              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (widget.onShareToChat != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE).withAlpha(40),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.send_rounded, color: Color(0xFF00F2FE), size: 15),
                label: const Text(
                  'Gửi vào chat',
                  style: TextStyle(color: Color(0xFF00F2FE), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: _shareCurrentLink,
              )
            else
              IconButton(
                icon: const Icon(Icons.content_copy, color: Colors.white70, size: 18),
                tooltip: 'Sao chép link',
                onPressed: _shareCurrentLink,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon, {bool isLive = false}) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTab(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? (isLive ? const Color(0xFFFE0979) : const Color(0xFF00F2FE))
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE0979),
                    shape: BoxShape.circle,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? const Color(0xFF00F2FE) : Colors.white54,
                ),
              if (!isLive) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
