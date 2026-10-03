import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/wall_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card_widget.dart';
import 'create_post_screen.dart';
import '../tiktok/tiktok_viewer_screen.dart';

class UserWallScreen extends StatelessWidget {
  final UserModel? targetUser; // null = Bảng tin chung (Feed), khác null = Tường nhà của user đó
  final bool embeddedInHomeScreen;

  const UserWallScreen({
    super.key,
    this.targetUser,
    this.embeddedInHomeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final loc = Provider.of<LocalizationService>(context);
    final currentUser = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFeed = targetUser == null;
    final isOwnWall = targetUser != null && targetUser!.uid == currentUser.uid;
    final wallUser = targetUser ?? currentUser;
    final wallService = WallService();

    final Stream<List<PostModel>> postStream = isFeed
        ? wallService.getFeedStream(
            currentUserId: currentUser.uid,
            friendIds: currentUser.friends,
          )
        : wallService.getUserWallStream(
            targetUserId: wallUser.uid,
            currentUserId: currentUser.uid,
            viewerFriendIds: currentUser.friends,
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: embeddedInHomeScreen
          ? null
          : AppBar(
              title: Text(
                isFeed
                    ? loc.t('tab_wall')
                    : (isOwnWall ? (loc.isVietnamese ? 'Tường Nhà Của Tôi' : 'My Wall') : wallUser.displayName),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x5500F2FE), offset: Offset(-1, -1), blurRadius: 3),
                        BoxShadow(color: Color(0x55FE0979), offset: Offset(1, 1), blurRadius: 3),
                      ],
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 16),
                  ),
                  tooltip: 'TikTok & LIVE',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TikTokViewerScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.post_add, size: 26),
                  tooltip: 'Đăng bài viết mới',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                  },
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          // 1. Cover Photo Banner & Profile Card (Google Stitch UI style)
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Ảnh bìa hồ sơ
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF4F46E5), Color(0xFF065F46)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.35,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topRight,
                                radius: 1.2,
                                colors: [Colors.white24, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.isVietnamese ? 'Cập nhật ảnh bìa mới' : 'Update cover photo')),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(80),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Đổi ảnh bìa',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card thông tin cá nhân đè lên ảnh bìa
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 105, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar với viền trắng và chấm online
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4),
                                  ],
                                ),
                                child: AvatarWidget(
                                  name: wallUser.displayName,
                                  photoUrl: wallUser.photoUrl,
                                  radius: 30,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Nút tạo bài viết hoặc chỉnh sửa
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                                  );
                                },
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: Text(
                                  loc.isVietnamese ? 'Đăng tin' : 'Post',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tên & Key Role
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              wallUser.displayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.vpn_key, size: 10, color: Color(0xFFB45309)),
                                SizedBox(width: 3),
                                Text(
                                  'Key chính',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tiểu sử (Bio)
                      if (wallUser.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          wallUser.bio,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Thanh đăng bài nhanh (Quick post prompt)
          if (isFeed || isOwnWall)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 20 : 6),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      AvatarWidget(
                        name: currentUser.displayName,
                        photoUrl: currentUser.photoUrl,
                        radius: 17,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.isVietnamese ? 'Bạn đang nghĩ gì? Chia sẻ ngay...' : "What's on your mind? Share now...",
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image_outlined, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Stream danh sách bài viết
          StreamBuilder<List<PostModel>>(
            stream: postStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.feed_outlined, size: 54, color: Colors.grey.withAlpha(120)),
                          const SizedBox(height: 12),
                          Text(
                            isFeed
                                ? (loc.isVietnamese
                                    ? 'Chưa có bài viết nào trên bảng tin.\nHãy là người đầu tiên chia sẻ!'
                                    : 'No posts on feed yet.\nBe the first to share!')
                                : (loc.isVietnamese ? 'Tường nhà chưa có bài viết nào.' : 'No posts on wall.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: PostCardWidget(
                          post: post,
                          currentUser: currentUser,
                          onAuthorTap: () {
                            if (post.authorId != wallUser.uid) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserWallScreen(
                                    targetUser: UserModel(
                                      uid: post.authorId,
                                      email: '',
                                      displayName: post.authorName,
                                      photoUrl: post.authorAvatar,
                                      lastSeen: DateTime.now(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                );
            },
          ),
        ],
      ),
    );
  }
}
