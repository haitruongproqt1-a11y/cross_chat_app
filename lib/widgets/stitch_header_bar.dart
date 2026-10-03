import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../utils/constants.dart';
import '../widgets/avatar_widget.dart';

class StitchHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String? customTitle;
  final VoidCallback? onBrandTap;
  final VoidCallback? onRadarTap;
  final VoidCallback? onDiaryTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onTikTokTap;

  const StitchHeaderBar({
    super.key,
    this.customTitle,
    this.onBrandTap,
    this.onRadarTap,
    this.onDiaryTap,
    this.onSettingsTap,
    this.onTikTokTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _showRoleInfoDialog(BuildContext context, LocalizationService loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.vpn_key, color: Color(0xFFB45309), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              loc.isVietnamese ? 'Chức Danh E2EE' : 'E2EE Role & Keys',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🔑 Key chính', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      const Spacer(),
                      Text(loc.isVietnamese ? 'Trưởng nhóm' : 'Group Owner', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Text('🛡️ Phó nhóm', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                      const Spacer(),
                      Text(loc.isVietnamese ? 'Tối đa 10 Key phụ' : 'Up to 10 Deputies', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.isVietnamese
                  ? 'Mã khóa E2EE phân quyền được bảo vệ bằng mật mã Argon2id. Chỉ Trưởng nhóm mới có quyền chỉ định Phó nhóm hoặc bàn giao quyền sở hữu.'
                  : 'Role-based E2EE permissions are secured by Argon2id cryptography. Only group owners can appoint deputies or transfer group ownership.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.isVietnamese ? 'Đã hiểu' : 'Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final loc = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = customTitle ?? AppConstants.appName;

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 10,
        right: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withAlpha(245) : const Color(0xFFF8FAFC).withAlpha(250),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo KINI & Status
          InkWell(
            onTap: onBrandTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withAlpha(80),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      // Emerald active dot
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withAlpha(50),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'v${AppConstants.appVersion}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 10, color: Color(0xFF10B981)),
                          const SizedBox(width: 3),
                          Text(
                            loc.isVietnamese ? 'Đã kết nối bảo mật' : 'E2EE Secured',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Right Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Badge Pill (Interactive)
              InkWell(
                onTap: () => _showRoleInfoDialog(context, loc),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔑 Key chính',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Radar quick button
              if (onRadarTap != null)
                IconButton(
                  icon: const Icon(Icons.radar_rounded, size: 19, color: Color(0xFF0284C7)),
                  tooltip: 'Quanh đây (Radar)',
                  onPressed: onRadarTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

              // Diary / Post quick button
              if (onDiaryTap != null)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 21, color: Color(0xFF475569)),
                  tooltip: 'Đăng Nhật ký',
                  onPressed: onDiaryTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

              // TikTok button
              if (onTikTokTap != null)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(color: Color(0x5500F2FE), offset: Offset(-1, -1), blurRadius: 2),
                        BoxShadow(color: Color(0x55FE0979), offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 13),
                  ),
                  tooltip: 'TikTok & LIVE',
                  onPressed: onTikTokTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

              const SizedBox(width: 2),

              // User Avatar with emerald status dot
              if (user != null)
                InkWell(
                  onTap: onSettingsTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AvatarWidget(
                          photoUrl: user.photoUrl,
                          name: user.displayName,
                          radius: 14,
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
