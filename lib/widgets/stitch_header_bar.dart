import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_widget.dart';

class StitchHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String? customTitle;
  final String? subTitle;
  final VoidCallback? onBrandTap;
  final VoidCallback? onRadarTap;
  final VoidCallback? onDiaryTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onTikTokTap;

  const StitchHeaderBar({
    super.key,
    this.customTitle,
    this.subTitle,
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
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.vpn_key, color: Color(0xFFFCD34D), size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              loc.isVietnamese ? 'Chức Danh E2EE' : 'E2EE Role & Keys',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
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
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🔑 Key chính', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFCD34D))),
                      const Spacer(),
                      Text(loc.isVietnamese ? 'Trưởng nhóm' : 'Group Owner', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.onSurface)),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0x22FFFFFF)),
                  Row(
                    children: [
                      const Text('🛡️ Phó nhóm', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryCyan)),
                      const Spacer(),
                      Text(loc.isVietnamese ? 'Tối đa 10 Key phụ' : 'Up to 10 Deputies', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.onSurface)),
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
              style: const TextStyle(fontSize: 12.5, color: AppTheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
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

    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withAlpha(245),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo KINI & Brand Title
          InkWell(
            onTap: onBrandTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unified Registration Screen Logo with Cyan Glow Halo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withAlpha(120),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/kini_logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'KiniChat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryCyan,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          // Live pulsating indicator beacon
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        subTitle ?? customTitle ?? (loc.isVietnamese ? 'ĐOẠN CHAT' : 'CHATS'),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppTheme.onSurfaceVariant,
                        ),
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
              // E2EE Role Key Pill
              InkWell(
                onTap: () => _showRoleInfoDialog(context, loc),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D).withAlpha(120), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔑 Key E2EE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFCD34D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Radar action button
              if (onRadarTap != null)
                IconButton(
                  icon: const Icon(Icons.radar_rounded, size: 20, color: AppTheme.primaryCyan),
                  tooltip: 'Tìm bạn quanh đây (Radar)',
                  onPressed: onRadarTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

              // Diary / Wall quick button
              if (onDiaryTap != null)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppTheme.violetLight),
                  tooltip: 'Nhật ký & Trạng thái',
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
                      border: Border.all(color: AppTheme.tertiaryMagenta.withAlpha(180), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Color(0x5500F2FE), offset: Offset(-1, -1), blurRadius: 2),
                        BoxShadow(color: Color(0x55FF007A), offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 13),
                  ),
                  tooltip: 'TikTok & LIVE',
                  onPressed: onTikTokTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),

              const SizedBox(width: 4),

              // User Avatar with glowing status dot
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
                              color: AppTheme.primaryCyan,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.surfaceDark,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryCyan.withAlpha(180),
                                  blurRadius: 4,
                                ),
                              ],
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
