enum PostPrivacy {
  public, // Công khai
  friends, // Bạn bè
  private, // Chỉ mình tôi
  custom, // Chặn một số người
}

enum PostMediaType {
  none,
  image,
  video,
}

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> mediaUrls;
  final PostMediaType mediaType;
  final PostPrivacy privacy;
  final List<String> blockedUserIds;
  final List<String> likes;
  final int commentsCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.mediaType = PostMediaType.none,
    this.privacy = PostPrivacy.public,
    this.blockedUserIds = const [],
    this.likes = const [],
    this.commentsCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.name,
      'privacy': privacy.name,
      'blockedUserIds': blockedUserIds,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Người dùng',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaType: PostMediaType.values.firstWhere(
        (e) => e.name == map['mediaType'],
        orElse: () => PostMediaType.none,
      ),
      privacy: PostPrivacy.values.firstWhere(
        (e) => e.name == map['privacy'],
        orElse: () => PostPrivacy.public,
      ),
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      commentsCount: map['commentsCount'] is int ? map['commentsCount'] : 0,
      createdAt: () {
        final val = map['createdAt'];
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }(),
    );
  }

  bool isVisibleTo(String viewerId, List<String> viewerFriendIds) {
    // Tác giả luôn xem được bài viết của chính mình
    if (authorId == viewerId) return true;

    // Nếu người xem nằm trong danh sách bị chặn của bài này
    if (blockedUserIds.contains(viewerId)) return false;

    switch (privacy) {
      case PostPrivacy.public:
      case PostPrivacy.custom:
        return true;
      case PostPrivacy.friends:
        return viewerFriendIds.contains(authorId);
      case PostPrivacy.private:
        return false;
    }
  }
}
