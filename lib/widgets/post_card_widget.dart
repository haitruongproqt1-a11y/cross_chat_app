import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../models/post_comment_model.dart';
import '../../models/user_model.dart';
import '../../services/wall_service.dart';
import '../../utils/constants.dart';
import 'avatar_widget.dart';
import 'video_player_screen.dart';

class PostCardWidget extends StatelessWidget {
  final PostModel post;
  final UserModel currentUser;
  final VoidCallback? onAuthorTap;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.currentUser,
    this.onAuthorTap,
  });

  void _showCommentsBottomSheet(BuildContext context) {
    final wallService = WallService();
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bình luận (${post.commentsCount})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<List<PostCommentModel>>(
                    stream: wallService.getCommentsStream(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return const Center(
                          child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AvatarWidget(name: c.authorName, photoUrl: c.authorAvatar, radius: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(8),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 3),
                                      Text(c.content, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppConstants.formatTimestamp(c.createdAt),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận...',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.black.withAlpha(10),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        commentController.clear();
                        await wallService.addComment(
                          postId: post.id,
                          author: currentUser,
                          content: text,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMediaViewer(BuildContext context, String url, bool isVideo) {
    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            videoUrl: url,
            title: 'Video của ${post.authorName}',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.white),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    final wallService = WallService();
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    final userReaction = post.reactions[currentUser.uid] ?? (post.likes.contains(currentUser.uid) ? '❤️' : null);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bày tỏ cảm xúc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  final isSelected = userReaction == emoji;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isSelected) {
                        wallService.removeReaction(postId: post.id, userId: currentUser.uid);
                      } else {
                        wallService.addReaction(postId: post.id, userId: currentUser.uid, emoji: emoji);
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withAlpha(40) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userReaction = post.reactions[currentUser.uid] ?? (post.likes.contains(currentUser.uid) ? '❤️' : null);
    final hasReacted = userReaction != null;
    final isAuthor = post.authorId == currentUser.uid;
    final wallService = WallService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: AvatarWidget(name: post.authorName, photoUrl: post.authorAvatar, radius: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onAuthorTap,
                        child: Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            AppConstants.formatTimestamp(post.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            post.privacy == PostPrivacy.public
                                ? Icons.public
                                : post.privacy == PostPrivacy.friends
                                    ? Icons.people
                                    : Icons.lock,
                            size: 13,
                            color: Colors.grey,
                          ),
                          if (post.blockedUserIds.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.block, size: 13, color: Colors.redAccent),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc muốn xóa bài viết này khỏi tường nhà không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await wallService.deletePost(post.id);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Content
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(post.content, style: const TextStyle(fontSize: 15, height: 1.35)),
            ],

            // Media
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (post.mediaType == PostMediaType.video)
                GestureDetector(
                  onTap: () => _showMediaViewer(context, post.mediaUrls.first, true),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                        Positioned(
                          bottom: 12,
                          child: Text('Chạm để mở phát video', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (post.mediaUrls.length == 1)
                GestureDetector(
                  onTap: () => _showMediaViewer(context, post.mediaUrls.first, false),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: CachedNetworkImage(
                        imageUrl: post.mediaUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(height: 200, color: Colors.black12),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: post.mediaUrls.length,
                  itemBuilder: (ctx, idx) {
                    final url = post.mediaUrls[idx];
                    return GestureDetector(
                      onTap: () => _showMediaViewer(context, url, false),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
            ],

            // Thống kê cảm xúc & bình luận trước dòng kẻ
            Builder(
              builder: (context) {
                final allEmojis = <String>{};
                for (var e in post.reactions.values) {
                  allEmojis.add(e);
                }
                if (allEmojis.isEmpty && post.likes.isNotEmpty) {
                  allEmojis.add('❤️');
                }
                final totalReactions = post.likes.length > post.reactions.length ? post.likes.length : post.reactions.length;

                if (totalReactions == 0 && post.commentsCount == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (totalReactions > 0)
                        Row(
                          children: [
                            Text(allEmojis.take(3).join(''), style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('$totalReactions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      if (post.commentsCount > 0)
                        Text('${post.commentsCount} bình luận', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // Actions: Like/Reaction, Comment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onLongPress: () => _showReactionPicker(context),
                  child: TextButton.icon(
                    onPressed: () {
                      if (hasReacted) {
                        wallService.removeReaction(postId: post.id, userId: currentUser.uid);
                      } else {
                        wallService.addReaction(postId: post.id, userId: currentUser.uid, emoji: '❤️');
                      }
                    },
                    icon: hasReacted
                        ? Text(userReaction, style: const TextStyle(fontSize: 18))
                        : const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                    label: Text(
                      hasReacted ? 'Đã thích' : 'Thích',
                      style: TextStyle(
                        color: hasReacted ? Colors.redAccent : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCommentsBottomSheet(context),
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
                  label: Text(
                    post.commentsCount == 0 ? 'Bình luận' : '${post.commentsCount}',
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
