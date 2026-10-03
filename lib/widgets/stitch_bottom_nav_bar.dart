import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        color: isDark ? const Color(0xFF0F172A).withAlpha(245) : Colors.white.withAlpha(250),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: const Color(0xFF0284C7).withAlpha(30),
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
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF0284C7).withAlpha(isDark ? 40 : 25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                size: 22,
                                color: isActive
                                    ? const Color(0xFF0284C7)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                            // Badge đếm số tin chưa đọc
                            if (item.badgeCount != null)
                              Positioned(
                                right: -4,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 3),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF43F5E),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            // Cờ Việt Nam ở tab Cài đặt
                            if (item.hasFlag)
                              const Positioned(
                                right: -4,
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
                                ? const Color(0xFF0284C7)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
