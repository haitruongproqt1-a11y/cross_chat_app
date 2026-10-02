import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isOnline;
  final bool showBadge;

  const AvatarWidget({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.isOnline = false,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Text(
                      initials,
                      style: TextStyle(
                        fontSize: radius * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                )
              : Text(
                  initials,
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget hiển thị Avatar người dùng theo thời gian thực (Realtime Avatar)
/// Tự động lấy avatar mới nhất từ Firestore khi user vừa cập nhật
class DirectUserAvatar extends StatelessWidget {
  final String userId;
  final String fallbackName;
  final String? fallbackPhotoUrl;
  final double radius;
  final bool showBadge;

  const DirectUserAvatar({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.fallbackPhotoUrl,
    this.radius = 24,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return AvatarWidget(
        photoUrl: fallbackPhotoUrl,
        name: fallbackName,
        radius: radius,
        showBadge: showBadge,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = (data?['photoUrl'] as String?)?.isNotEmpty == true
            ? data!['photoUrl'] as String
            : fallbackPhotoUrl;
        final name = (data?['displayName'] as String?)?.isNotEmpty == true
            ? data!['displayName'] as String
            : fallbackName;
        final isOnline = data?['isOnline'] as bool? ?? false;

        return AvatarWidget(
          photoUrl: photoUrl,
          name: name,
          radius: radius,
          isOnline: isOnline,
          showBadge: showBadge,
        );
      },
    );
  }
}

