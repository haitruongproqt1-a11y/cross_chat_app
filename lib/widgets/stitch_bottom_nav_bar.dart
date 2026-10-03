import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../utils/app_theme.dart';

class StitchBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadChatsCount;
  final bool hasDiaryUpdate;

  const StitchBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadChatsCount = 0,
    this.hasDiaryUpdate = true,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    final items = [
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: loc.t('tab_messages'),
        badgeCount: unreadChatsCount > 0 ? unreadChatsCount : null,
      ),
      _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: loc.t('tab_contacts'),
      ),
      _NavItem(
        icon: Icons.radar_outlined,
        activeIcon: Icons.radar_rounded,
        label: loc.t('tab_nearby'),
      ),
      _NavItem(
        icon: Icons.newspaper_outlined,
        activeIcon: Icons.newspaper_rounded,
        label: loc.t('tab_wall'),
        hasDot: hasDiaryUpdate,
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: loc.t('tab_settings'),
        hasFlag: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withAlpha(240),
        border: const Border(
          top: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: AppTheme.primaryCyan.withAlpha(30),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primaryCyan.withAlpha(30)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                size: 22,
                                color: isActive
                                    ? AppTheme.primaryCyan
                                    : AppTheme.onSurfaceVariant,
                              ),
                            ),
                            // Badge đếm số tin chưa đọc
                            if (item.badgeCount != null)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryViolet,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.surfaceDark,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondaryViolet.withAlpha(150),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            // Dấu chấm đỏ thông báo nhật ký
                            if (item.hasDot && item.badgeCount == null)
                              Positioned(
                                right: 6,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.tertiaryMagenta,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.surfaceDark,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.tertiaryMagenta.withAlpha(160),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Cờ Việt Nam ở tab Cài đặt
                            if (item.hasFlag)
                              const Positioned(
                                right: 0,
                                bottom: -2,
                                child: Text('🇻🇳', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? AppTheme.primaryCyan
                                : AppTheme.onSurfaceVariant,
                            letterSpacing: isActive ? 0.2 : 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
  final bool hasDot;
  final bool hasFlag;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
    this.hasDot = false,
    this.hasFlag = false,
  });
}
