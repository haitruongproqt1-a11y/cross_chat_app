import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
