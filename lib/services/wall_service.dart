import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/post_comment_model.dart';
import '../models/user_model.dart';

class WallService {
  static final WallService _instance = WallService._internal();
  factory WallService() => _instance;
  WallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo bài đăng mới
  Future<String> createPost({
    required UserModel author,
    required String content,
    List<String> mediaUrls = const [],
    PostMediaType mediaType = PostMediaType.none,
    PostPrivacy privacy = PostPrivacy.public,
    List<String> blockedUserIds = const [],
  }) async {
    final docRef = _firestore.collection('posts').doc();
    final post = PostModel(
      id: docRef.id,
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.photoUrl,
      content: content,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      privacy: privacy,
      blockedUserIds: blockedUserIds,
      likes: [],
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toMap());
    return docRef.id;
  }

  // Xóa bài đăng
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Thích hoặc bỏ thích bài đăng
  Future<void> toggleLike({required String postId, required String userId}) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final doc = await postRef.get();
    if (!doc.exists) return;

    final data = doc.data();
    final likes = List<String>.from(data?['likes'] ?? []);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await postRef.update({'likes': likes});
  }

  // Thêm bình luận
  Future<void> addComment({
    required String postId,
    required UserModel author,
    required String content,
  }) async {
    final commentRef = _firestore.collection('posts').doc(postId).collection('comments').doc();
    final comment = PostCommentModel(
      id: commentRef.id,
      postId: postId,
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.photoUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    await commentRef.set(comment.toMap());
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // Lắng nghe bình luận của một bài đăng
  Stream<List<PostCommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostCommentModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Lắng nghe dòng thời gian (Bảng tin chung)
  Stream<List<PostModel>> getFeedStream({
    required String currentUserId,
    required List<String> friendIds,
  }) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) => post.isVisibleTo(currentUserId, friendIds))
          .toList();
    });
  }

  // Lắng nghe tường nhà của một cá nhân
  Stream<List<PostModel>> getUserWallStream({
    required String targetUserId,
    required String currentUserId,
    required List<String> viewerFriendIds,
  }) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) => post.isVisibleTo(currentUserId, viewerFriendIds))
          .toList();
    });
  }
}
