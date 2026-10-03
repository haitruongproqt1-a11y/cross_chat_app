import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/call_model.dart';
import '../call/call_screen.dart';
import '../call/screen_share_viewer_screen.dart';

class CallsView extends StatefulWidget {
  final bool embeddedInHomeScreen;

  const CallsView({
    super.key,
    this.embeddedInHomeScreen = false,
  });

  @override
  State<CallsView> createState() => _CallsViewState();
}

class _CallsViewState extends State<CallsView> {
  String _activeFilter = 'all'; // 'all', 'missed', 'screenshare'
  bool _isCopied = false;

  void _copyMeetingLink() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final roomId = user?.uid.substring(0, 6) ?? 'alex-89k';
    final link = 'https://kinichat.me/r/$roomId';

    Clipboard.setData(ClipboardData(text: link));
    setState(() => _isCopied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryCyan, size: 20),
            const SizedBox(width: 8),
            Text('Đã sao chép liên kết phòng $link vào clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.surfaceContainerHighest,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _startInstantStream() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScreenShareViewerScreen(
          remoteUserName: 'Bạn',
          streamTitle: 'Phòng phát trực tiếp P2P cá nhân',
        ),
      ),
    );
  }

  void _showDialpadDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.dialpad, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('Bàn Phím Quay Số', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Nhập ID hoặc số gọi...',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'].map((digit) {
                return InkWell(
                  onTap: () {
                    controller.text += digit;
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      digit,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.call),
            label: const Text('Gọi'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang kết nối tới ${controller.text}...')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final roomId = user?.uid.substring(0, 6) ?? 'alex-89k';

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ambient Light Card: Tạo Phòng Chia Sẻ Nhanh (P2P Ultra Stream)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x22FFFFFF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withAlpha(20),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  // Glow orbs
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryCyan.withAlpha(25),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status / Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest.withAlpha(200),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'P2P ULTRA STREAM',
                                  style: TextStyle(
                                    color: AppTheme.primaryCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: AppTheme.primaryCyan),
                              SizedBox(width: 4),
                              Text(
                                'Bảo mật E2EE',
                                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title & Icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryCyan.withAlpha(80),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.screen_share, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tạo Phòng Chia Sẻ Nhanh',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Bắt đầu stream màn hình hoặc gọi video tức thì, mời bạn bè bằng liên kết bảo mật P2P.',
                                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // CTA Buttons
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: const Color(0xFF0B0F19),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: AppTheme.primaryCyan.withAlpha(100),
                        ),
                        icon: const Icon(Icons.present_to_all_rounded, size: 20),
                        label: const Text('Bắt đầu ngay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        onPressed: _startInstantStream,
                      ),
                      const SizedBox(height: 8),

                      // Link Copy Button
                      InkWell(
                        onTap: _copyMeetingLink,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest.withAlpha(180),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 18, color: AppTheme.primaryCyan),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'kinichat.me/r/$roomId',
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _isCopied ? 'Đã chép!' : 'Sao chép',
                                    style: TextStyle(
                                      color: _isCopied ? Colors.greenAccent : AppTheme.primaryCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isCopied ? Icons.check : Icons.copy,
                                    size: 15,
                                    color: _isCopied ? Colors.greenAccent : AppTheme.primaryCyan,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action Grid (4 Columns)
            Row(
              children: [
                _buildQuickActionItem(
                  icon: Icons.add_link,
                  iconColor: AppTheme.primaryCyan,
                  label: 'Tạo link gọi',
                  onTap: _copyMeetingLink,
                ),
                const SizedBox(width: 8),
                _buildQuickActionItem(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppTheme.violetLight,
                  label: 'Lên lịch họp',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng lên lịch họp đã được kích hoạt')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionItem(
                  icon: Icons.dialpad,
                  iconColor: AppTheme.onSurfaceVariant,
                  label: 'Bàn phím',
                  onTap: _showDialpadDialog,
                ),
                const SizedBox(width: 8),
                _buildQuickActionItem(
                  icon: Icons.cast_connected,
                  iconColor: AppTheme.primaryCyan,
                  label: 'Cast màn hình',
                  onTap: _startInstantStream,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả', count: '18'),
                  const SizedBox(width: 8),
                  _buildFilterChip('missed', 'Cuộc gọi nhỡ', count: '2', isError: true),
                  const SizedBox(width: 8),
                  _buildFilterChip('screenshare', 'Phiên Screen Share', hasDot: true),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LỊCH SỬ CUỘC GỌI GẦN ĐÂY',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã làm mới nhật ký cuộc gọi')),
                    );
                  },
                  child: const Text('Làm mới', style: TextStyle(color: AppTheme.primaryCyan, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // List of Call History Items
            _buildCallItem(
              name: 'Lan Anh',
              subtitle: 'Phiên chia sẻ màn hình 1:1',
              timestamp: 'Hôm nay, 14:15 • 42 phút • 4.8 MB/s',
              tag: '1080p 60fps',
              isScreenShare: true,
              type: 'screenshare',
              actionIcon: Icons.present_to_all_rounded,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreenShareViewerScreen(
                      remoteUserName: 'Lan Anh',
                      streamTitle: 'Figma Review UX • Wireflows v2',
                      resolution: '1080p 60fps',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildCallItem(
              name: 'Nhóm Kỹ Thuật KiniDex',
              subtitle: 'Cuộc gọi video & Trình chiếu thiết kế',
              timestamp: 'Hôm qua, 20:30 • 1 giờ 15 phút',
              tag: '7 thành viên',
              isGroup: true,
              type: 'all',
              actionIcon: Icons.videocam,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      callId: 'call_group_${DateTime.now().millisecondsSinceEpoch}',
                      remoteUserName: 'Nhóm Kỹ Thuật KiniDex',
                      callType: CallType.video,
                      isCaller: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildCallItem(
              name: 'Minh Khang',
              subtitle: 'Cuộc gọi thoại nhỡ',
              timestamp: 'Hôm qua, 18:04',
              tag: 'Nhỡ 2 lần',
              isMissed: true,
              type: 'missed',
              actionIcon: Icons.phone_in_talk,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      callId: 'call_${DateTime.now().millisecondsSinceEpoch}',
                      remoteUserName: 'Minh Khang',
                      callType: CallType.audio,
                      isCaller: true,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildCallItem(
              name: 'Hoàng Nam',
              subtitle: 'Screen Share • Kiểm thử Prototype',
              timestamp: '22 Tháng 10 • 28 phút',
              tag: 'Senior UI/UX',
              isScreenShare: true,
              type: 'screenshare',
              actionIcon: Icons.play_arrow_rounded,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreenShareViewerScreen(
                      remoteUserName: 'Hoàng Nam',
                      streamTitle: 'Mobile Prototype Test Room',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String filterKey,
    String label, {
    String? count,
    bool isError = false,
    bool hasDot = false,
  }) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCyan : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryCyan : const Color(0x22FFFFFF),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withAlpha(80),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryCyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withAlpha(20)
                      : (isError ? AppTheme.tertiaryMagenta.withAlpha(40) : const Color(0x33FFFFFF)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : (isError ? AppTheme.tertiaryMagenta : Colors.white),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallItem({
    required String name,
    required String subtitle,
    required String timestamp,
    required String tag,
    required String type,
    required IconData actionIcon,
    required VoidCallback onActionTap,
    bool isScreenShare = false,
    bool isMissed = false,
    bool isGroup = false,
  }) {
    if (_activeFilter != 'all' && _activeFilter != type) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isGroup
                      ? AppTheme.secondaryViolet.withAlpha(40)
                      : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isScreenShare
                        ? AppTheme.primaryCyan.withAlpha(100)
                        : const Color(0x22FFFFFF),
                  ),
                ),
                child: Center(
                  child: isGroup
                      ? const Icon(Icons.diversity_2, color: AppTheme.violetLight, size: 22)
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: isMissed ? AppTheme.tertiaryMagenta : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isMissed
                        ? AppTheme.tertiaryMagenta
                        : (isScreenShare ? AppTheme.primaryCyan : AppTheme.surfaceContainerLowest),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceDark, width: 2),
                  ),
                  child: Icon(
                    isScreenShare
                        ? Icons.screen_share
                        : (isMissed ? Icons.call_missed : Icons.videocam),
                    color: (isScreenShare || isMissed) ? Colors.black : AppTheme.primaryCyan,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isMissed ? AppTheme.tertiaryMagenta : Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isMissed
                            ? AppTheme.tertiaryMagenta.withAlpha(30)
                            : AppTheme.primaryCyan.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isMissed ? AppTheme.tertiaryMagenta : AppTheme.primaryCyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isScreenShare
                          ? Icons.screen_share
                          : (isMissed ? Icons.call_missed_outgoing : Icons.video_call),
                      size: 13,
                      color: isScreenShare
                          ? AppTheme.primaryCyan
                          : (isMissed ? AppTheme.tertiaryMagenta : AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: isScreenShare
                              ? AppTheme.primaryCyan
                              : (isMissed ? AppTheme.tertiaryMagenta : AppTheme.onSurfaceVariant),
                          fontSize: 11.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                ),
              ],
            ),
          ),

          // Quick Action button
          IconButton(
            onPressed: onActionTap,
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isMissed
                    ? AppTheme.tertiaryMagenta.withAlpha(30)
                    : AppTheme.primaryCyan.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMissed
                      ? AppTheme.tertiaryMagenta.withAlpha(80)
                      : AppTheme.primaryCyan.withAlpha(80),
                ),
              ),
              child: Icon(
                actionIcon,
                color: isMissed ? AppTheme.tertiaryMagenta : AppTheme.primaryCyan,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
