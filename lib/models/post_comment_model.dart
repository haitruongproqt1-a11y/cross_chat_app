class PostCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  PostCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PostCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return PostCommentModel(
      id: id,
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Người dùng',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      createdAt: () {
        final val = map['createdAt'];
        if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }(),
    );
  }
}
