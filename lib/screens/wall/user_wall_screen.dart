import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/wall_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card_widget.dart';
import 'create_post_screen.dart';
import '../tiktok/tiktok_viewer_screen.dart';

class UserWallScreen extends StatelessWidget {
  final UserModel? targetUser; // null = Bảng tin chung (Feed), khác null = Tường nhà của user đó

  const UserWallScreen({super.key, this.targetUser});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.currentUser;
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
      appBar: AppBar(
        title: Text(
          isFeed
              ? 'Nhật Ký & Tường Nhà'
              : (isOwnWall ? 'Tường Nhà Của Tôi' : 'Tường Nhà ${wallUser.displayName}'),
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
            tooltip: 'Lướt TikTok & LIVE',
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
          // Wall Header (nếu xem tường cá nhân)
          if (!isFeed)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withAlpha(20),
                      Colors.blue.withAlpha(10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withAlpha(30)),
                ),
                child: Column(
                  children: [
                    AvatarWidget(
                      name: wallUser.displayName,
                      photoUrl: wallUser.photoUrl,
                      radius: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      wallUser.displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wallUser.statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (wallUser.gender.isNotEmpty && wallUser.gender != 'Chưa xác định')
                          Chip(
                            avatar: Icon(
                              wallUser.gender == 'Nam' ? Icons.male : Icons.female,
                              size: 16,
                              color: Colors.blueAccent,
                            ),
                            label: Text(wallUser.gender, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.blue.withAlpha(20),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (wallUser.birthYear != null && wallUser.birthYear! > 1900)
                          Chip(
                            avatar: const Icon(Icons.cake, size: 16, color: Colors.orange),
                            label: Text(
                              '${wallUser.birthYear} (${DateTime.now().year - wallUser.birthYear!} tuổi)',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.orange.withAlpha(20),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (wallUser.hometown.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            label: Text(wallUser.hometown, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.red.withAlpha(20),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Thanh đăng bài nhanh (Quick post prompt)
          if (isFeed || isOwnWall)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        AvatarWidget(
                          name: currentUser.displayName,
                          photoUrl: currentUser.photoUrl,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Bạn đang nghĩ gì? Chia sẻ ngay...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.photo_library, color: Colors.green, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Stream danh sách bài viết
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.feed_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 12),
                        Text(
                          isFeed
                              ? 'Chưa có bài viết nào trên bảng tin.\nHãy là người đầu tiên chia sẻ!'
                              : 'Tường nhà chưa có bài viết nào.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return PostCardWidget(
                      post: post,
                      currentUser: currentUser,
                      onAuthorTap: () {
                        if (post.authorId != wallUser.uid) {
                          // Xem tường tác giả
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
