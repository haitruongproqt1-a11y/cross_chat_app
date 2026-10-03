import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../utils/app_theme.dart';
import '../nearby/nearby_friends_screen.dart';
import '../wall/user_wall_screen.dart';
import 'contacts_view.dart';
import '../tiktok/tiktok_viewer_screen.dart';

class ExploreHubView extends StatefulWidget {
  final bool embeddedInHomeScreen;

  const ExploreHubView({super.key, this.embeddedInHomeScreen = true});

  @override
  State<ExploreHubView> createState() => _ExploreHubViewState();
}

class _ExploreHubViewState extends State<ExploreHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: Column(
        children: [
          // Cyber Segmented Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest.withAlpha(200),
              border: const Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryCyan,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withAlpha(80),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.black,
                      unselectedLabelColor: AppTheme.onSurfaceVariant,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.radar, size: 16),
                              const SizedBox(width: 4),
                              Text(loc.isVietnamese ? 'Radar' : 'Radar'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.newspaper_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(loc.isVietnamese ? 'Nhật ký' : 'Wall'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(loc.isVietnamese ? 'Danh bạ' : 'Contacts'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // TikTok & LIVE Quick Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TikTokViewerScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.tertiaryMagenta.withAlpha(150), width: 1),
                      boxShadow: const [
                        BoxShadow(color: Color(0x44FF007A), blurRadius: 8),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, color: AppTheme.primaryCyan, size: 14),
                        SizedBox(width: 3),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NearbyFriendsScreen(embeddedInHomeScreen: true),
                UserWallScreen(embeddedInHomeScreen: true),
                ContactsView(embeddedInHomeScreen: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
