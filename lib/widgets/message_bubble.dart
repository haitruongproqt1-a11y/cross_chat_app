import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = widget.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? theme.colorScheme.primary : theme.cardTheme.color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
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
                      color: theme.colorScheme.primary,
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
                  if (isMe) ...[
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
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final msg = widget.message;
    final isMe = widget.isMe;
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
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill, size: 54, color: Colors.white),
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
          onTap: () {
            // Open or download file
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
        return Text(
          msg.content,
          style: TextStyle(fontSize: 15, color: textColor),
        );
    }
  }
}
