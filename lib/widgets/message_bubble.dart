import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';
import 'zalo_media_grid.dart';
import 'avatar_widget.dart';
import '../models/user_model.dart';
import '../screens/wall/user_wall_screen.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String roomId;
  final String currentUserId;
  final VoidCallback? onRecall;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onPin;
  final Function(String emoji)? onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.roomId,
    required this.currentUserId,
    this.onRecall,
    this.onDelete,
    this.onReply,
    this.onPin,
    this.onReact,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio(String? url) async {
    if (url == null) return;
    if (_isPlayingAudio) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() => _isPlayingAudio = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    }
  }

  void _showContextMenu(BuildContext context) {
    final msg = widget.message;
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    final myReaction = msg.reactions[widget.currentUserId];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            // Thanh thả cảm xúc Zalo
            if (!msg.isRecalled)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis.map((emoji) {
                    final isSelected = myReaction == emoji;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onReact?.call(emoji);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withAlpha(40) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const Divider(height: 1),

            // Trả lời tin nhắn
            if (!msg.isRecalled)
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Colors.blueAccent),
                title: const Text('Trả lời tin nhắn'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReply?.call();
                },
              ),

            // Ghim tin nhắn
            if (!msg.isRecalled)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined, color: Colors.orange),
                title: const Text('Ghim tin nhắn'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPin?.call();
                },
              ),

            // Sao chép nội dung
            if (!msg.isRecalled && (msg.type == MessageType.text || msg.content.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.teal),
                title: const Text('Sao chép nội dung'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn vào bộ nhớ tạm')),
                  );
                },
              ),

            // Thu hồi tin nhắn
            if (widget.isMe && !msg.isRecalled)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.deepOrange),
                title: const Text('Thu hồi tin nhắn'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onRecall?.call();
                },
              ),

            // Xóa ở phía tôi
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Xóa tin nhắn ở phía tôi'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = widget.isMe;
    final isRecalled = widget.message.isRecalled;
    final msg = widget.message;

    final uniqueEmojis = msg.reactions.values.toSet().toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserWallScreen(
                      targetUser: UserModel(
                        uid: msg.senderId,
                        email: '',
                        displayName: msg.senderName,
                        photoUrl: msg.senderAvatar ?? '',
                        lastSeen: DateTime.now(),
                      ),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                child: DirectUserAvatar(
                  userId: msg.senderId,
                  fallbackName: msg.senderName,
                  fallbackPhotoUrl: msg.senderAvatar,
                  radius: 15,
                ),
              ),
            ),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              child: GestureDetector(
                onLongPress: () => _showContextMenu(context),
                onDoubleTap: !isRecalled ? () => widget.onReact?.call('❤️') : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        left: 4,
                        right: 4,
                        top: 2,
                        bottom: msg.reactions.isNotEmpty ? 14 : 2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isRecalled
                      ? Colors.grey.withAlpha(50)
                      : (isMe ? theme.colorScheme.primary : theme.cardTheme.color),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isRecalled ? Border.all(color: Colors.grey.shade400, width: 0.5) : null,
                  boxShadow: isRecalled
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isRecalled ? Colors.grey : theme.colorScheme.primary,
                          ),
                        ),
                      ),

                    // Trích dẫn tin nhắn trả lời (Reply quote)
                    if (msg.replyToContent != null && msg.replyToContent!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withAlpha(35) : Colors.black.withAlpha(12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replyToSenderName ?? 'Người dùng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.replyToContent!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildMessageContent(context),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConstants.formatTimestamp(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        if (isMe && !isRecalled) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: msg.isRead ? Colors.cyanAccent : Colors.white70,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            msg.isRead ? 'Đã xem' : 'Đã gửi',
                            style: TextStyle(
                              fontSize: 9,
                              color: msg.isRead ? Colors.cyanAccent : Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chip hiển thị cảm xúc (Reactions badge)
              if (msg.reactions.isNotEmpty)
                Positioned(
                  bottom: 0,
                  right: isMe ? 18 : null,
                  left: isMe ? null : 18,
                  child: GestureDetector(
                    onTap: () => _showContextMenu(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(60), width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(uniqueEmojis.take(3).join(''), style: const TextStyle(fontSize: 12)),
                          if (msg.reactions.length > 1) ...[
                            const SizedBox(width: 3),
                            Text(
                              '${msg.reactions.length}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ],
),
);
  }

  Widget _buildMessageContent(BuildContext context) {
    final msg = widget.message;
    final isMe = widget.isMe;

    if (msg.isRecalled) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo, size: 16, color: Colors.grey),
          SizedBox(width: 6),
          Text(
            'Tin nhắn đã được thu hồi',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      );
    }

    final textColor = isMe ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color;

    switch (msg.type) {
      case MessageType.image:
      case MessageType.video:
        final urls = msg.mediaUrls.isNotEmpty
            ? msg.mediaUrls
            : (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty ? [msg.mediaUrl!] : <String>[]);
        final types = msg.mediaTypes.isNotEmpty
            ? msg.mediaTypes
            : List<String>.filled(urls.length, msg.type == MessageType.video ? 'video' : 'image');

        if (urls.isNotEmpty) {
          return ZaloMediaGrid(
            mediaUrls: urls,
            mediaTypes: types,
            senderName: msg.senderName,
          );
        }
        return const SizedBox.shrink();

      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill),
              color: isMe ? Colors.white : Theme.of(context).colorScheme.primary,
              iconSize: 36,
              onPressed: () => _toggleAudio(msg.mediaUrl),
            ),
            Text(
              'Tin nhắn thoại (${msg.audioDurationSec ?? 0}s)',
              style: TextStyle(color: textColor),
            ),
          ],
        );

      case MessageType.file:
        return InkWell(
          onTap: () async {
            if (msg.mediaUrl != null) {
              final uri = Uri.parse(msg.mediaUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.blueGrey, size: 36),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.fileName ?? 'Tệp đính kèm',
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      AppConstants.formatFileSize(msg.fileSize ?? 0),
                      style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.location:
        return InkWell(
          onTap: () {
            if (msg.latitude != null && msg.longitude != null) {
              LocationService().openMap(msg.latitude!, msg.longitude!);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.map, size: 48, color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    msg.locationAddress ?? 'Vị trí đã chia sẻ',
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ],
              ),
            ],
          ),
        );

      case MessageType.call:
        final isVideo = msg.content.toLowerCase().contains('video');
        final isMissed = msg.content.toLowerCase().contains('nhỡ') || (msg.audioDurationSec == 0 || msg.audioDurationSec == null);
        final iconColor = isMissed ? Colors.redAccent : (isMe ? Colors.white : Colors.green);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isMissed ? Colors.red : Colors.green).withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo
                    ? (isMissed ? Icons.missed_video_call : Icons.videocam)
                    : (isMissed ? Icons.phone_missed : Icons.phone),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Text(
                    isMissed ? 'Cuộc gọi không được trả lời' : 'Cuộc gọi đã hoàn tất',
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case MessageType.text:
        return _buildRichTextWithLinks(msg.content, textColor ?? Colors.black);
    }
  }

  // Nhận diện và hiển thị liên kết URL có thể nhấn được
  Widget _buildRichTextWithLinks(String text, Color textColor) {
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 15, color: textColor),
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(fontSize: 15, color: textColor),
        ));
      }

      final url = match.group(0)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            url,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.lightBlueAccent,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(fontSize: 15, color: textColor),
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
