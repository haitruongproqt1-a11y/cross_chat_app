import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String roomId;
  final VoidCallback? onRecall;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.roomId,
    this.onRecall,
    this.onDelete,
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (!msg.isRecalled && (msg.type == MessageType.text || msg.content.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blueAccent),
                title: const Text('Sao chép nội dung'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn vào bộ nhớ tạm')),
                  );
                },
              ),
            if (widget.isMe && !msg.isRecalled)
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.orange),
                title: const Text('Thu hồi tin nhắn'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onRecall?.call();
                },
              ),
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      widget.message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isRecalled ? Colors.grey : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                _buildMessageContent(context),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.formatTimestamp(widget.message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    if (isMe && !isRecalled) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: widget.message.isRead ? Colors.cyanAccent : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: msg.mediaUrl != null
              ? CachedNetworkImage(
                  imageUrl: msg.mediaUrl!,
                  placeholder: (context, url) => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                )
              : const SizedBox.shrink(),
        );

      case MessageType.video:
        return InkWell(
          onTap: () async {
            if (msg.mediaUrl != null) {
              final uri = Uri.parse(msg.mediaUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
                Positioned(
                  bottom: 10,
                  child: Text('Nhấn để phát video', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
        );

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
