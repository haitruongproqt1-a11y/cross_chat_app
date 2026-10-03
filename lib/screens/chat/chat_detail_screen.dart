import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/media_attachment_sheet.dart';
import '../../widgets/avatar_widget.dart';
import '../../models/user_model.dart';
import '../wall/user_wall_screen.dart';
import '../call/call_screen.dart';
import '../call/screen_share_viewer_screen.dart';
import '../tiktok/tiktok_viewer_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../widgets/chat_wallpaper_widget.dart';
import 'bubble_theme_picker_screen.dart';
import 'wallpaper_picker_screen.dart';
import 'group_settings_screen.dart';
import '../../services/localization_service.dart';
import '../../utils/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatRoomModel room;
  static String? activeRoomId;

  const ChatDetailScreen({super.key, required this.room});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  bool _isUploading = false;
  bool _showScreenShareAlert = true;
  MessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    ChatDetailScreen.activeRoomId = widget.room.id;
  }

  @override
  void dispose() {
    if (ChatDetailScreen.activeRoomId == widget.room.id) {
      ChatDetailScreen.activeRoomId = null;
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    final replyMsg = _replyingToMessage;
    setState(() {
      _replyingToMessage = null;
    });

    _textController.clear();

    await _chatService.sendMessage(
      roomId: widget.room.id,
      sender: currentUser,
      content: text,
      type: MessageType.text,
      replyToMessageId: replyMsg?.id,
      replyToContent: replyMsg != null ? (replyMsg.content.isNotEmpty ? replyMsg.content : '[Tệp/Phương tiện]') : null,
      replyToSenderName: replyMsg?.senderName,
    );
  }

  Future<void> _handleReaction(MessageModel msg, String emoji) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    if (msg.reactions[currentUser.uid] == emoji) {
      await _chatService.removeMessageReaction(
        roomId: widget.room.id,
        messageId: msg.id,
        userId: currentUser.uid,
      );
    } else {
      await _chatService.addMessageReaction(
        roomId: widget.room.id,
        messageId: msg.id,
        userId: currentUser.uid,
        emoji: emoji,
      );
    }
  }

  Future<void> _handlePin(MessageModel msg) async {
    String preview = msg.content;
    if (msg.type == MessageType.image) preview = '📷 [Hình ảnh]';
    if (msg.type == MessageType.video) preview = '🎥 [Video]';
    if (msg.type == MessageType.audio) preview = '🎤 [Tin nhắn thoại]';
    if (msg.type == MessageType.file) preview = '📎 ${msg.fileName ?? "Tệp tin"}';
    if (msg.type == MessageType.location) preview = '📍 [Vị trí ghim]';

    await _chatService.pinMessage(
      roomId: widget.room.id,
      messageId: msg.id,
      text: preview,
      senderName: msg.senderName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghim tin nhắn lên đầu cuộc trò chuyện')),
      );
    }
  }

  void _handleAttachmentAction(AttachmentAction action) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    if (action == AttachmentAction.camera) {
      final xfile = await _storageService.pickImage(source: ImageSource.camera);
      if (xfile != null) {
        setState(() => _isUploading = true);
        final bytes = await xfile.readAsBytes();
        final url = await _storageService.uploadFile(
          path: xfile.path,
          fileName: xfile.name,
          folder: 'chat_images/${widget.room.id}',
          fileBytes: bytes,
        );
        setState(() => _isUploading = false);

        if (url != null) {
          await _chatService.sendMessage(
            roomId: widget.room.id,
            sender: currentUser,
            content: 'Hình ảnh',
            type: MessageType.image,
            mediaUrl: url,
            mediaUrls: [url],
            mediaTypes: ['image'],
            fileName: xfile.name,
          );
        }
      }
    } else if (action == AttachmentAction.gallery) {
      final xfiles = await _storageService.pickMultiImage(maxImages: 10);
      if (xfiles.isNotEmpty) {
        setState(() => _isUploading = true);
        final List<String> uploadedUrls = [];

        for (var i = 0; i < xfiles.length; i++) {
          final xf = xfiles[i];
          final bytes = await xf.readAsBytes();
          final url = await _storageService.uploadFile(
            path: xf.path,
            fileName: xf.name,
            folder: 'chat_images/${widget.room.id}',
            fileBytes: bytes,
          );
          if (url != null && url.isNotEmpty) {
            uploadedUrls.add(url);
          }
        }

        setState(() => _isUploading = false);

        if (uploadedUrls.isNotEmpty) {
          await _chatService.sendMessage(
            roomId: widget.room.id,
            sender: currentUser,
            content: uploadedUrls.length > 1 ? '[${uploadedUrls.length} hình ảnh]' : 'Hình ảnh',
            type: MessageType.image,
            mediaUrl: uploadedUrls.first,
            mediaUrls: uploadedUrls,
            mediaTypes: List.filled(uploadedUrls.length, 'image'),
          );
        }
      }
    } else if (action == AttachmentAction.video) {
      final pfiles = await _storageService.pickMultiVideo(maxVideos: 10);
      if (pfiles.isNotEmpty) {
        setState(() => _isUploading = true);
        final List<String> uploadedUrls = [];

        for (var i = 0; i < pfiles.length; i++) {
          final pf = pfiles[i];
          final url = await _storageService.uploadFile(
            path: pf.path ?? '',
            fileName: pf.name,
            folder: 'chat_videos/${widget.room.id}',
            fileBytes: pf.bytes,
          );
          if (url != null && url.isNotEmpty) {
            uploadedUrls.add(url);
          }
        }

        setState(() => _isUploading = false);

        if (uploadedUrls.isNotEmpty) {
          await _chatService.sendMessage(
            roomId: widget.room.id,
            sender: currentUser,
            content: uploadedUrls.length > 1 ? '[${uploadedUrls.length} video]' : 'Video',
            type: MessageType.video,
            mediaUrl: uploadedUrls.first,
            mediaUrls: uploadedUrls,
            mediaTypes: List.filled(uploadedUrls.length, 'video'),
          );
        }
      }
    } else if (action == AttachmentAction.document) {
      final doc = await _storageService.pickDocument();
      if (doc != null) {
        setState(() => _isUploading = true);
        final url = await _storageService.uploadFile(
          path: doc.path ?? '',
          fileName: doc.name,
          folder: 'chat_files/${widget.room.id}',
          fileBytes: doc.bytes,
        );
        setState(() => _isUploading = false);

        if (url != null) {
          await _chatService.sendMessage(
            roomId: widget.room.id,
            sender: currentUser,
            content: doc.name,
            type: MessageType.file,
            mediaUrl: url,
            fileName: doc.name,
            fileSize: doc.size,
          );
        }
      }
    } else if (action == AttachmentAction.location) {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        await _chatService.sendMessage(
          roomId: widget.room.id,
          sender: currentUser,
          content: 'Vị trí ghim',
          type: MessageType.location,
          latitude: position.latitude,
          longitude: position.longitude,
          locationAddress: 'Tọa độ: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể lấy tọa độ GPS. Vui lòng kiểm tra quyền truy cập vị trí.')),
          );
        }
      }
    } else if (action == AttachmentAction.tiktok) {
      _openTikTok();
    }
  }

  void _openTikTok() {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TikTokViewerScreen(
          onShareToChat: (link) async {
            if (currentUser != null && link.isNotEmpty) {
              await _chatService.sendMessage(
                roomId: widget.room.id,
                sender: currentUser,
                content: link,
                type: MessageType.text,
              );
            }
          },
        ),
      ),
    );
  }

  void _startCall(CallType type) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    String receiverId = widget.room.memberIds.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (receiverId.isEmpty && widget.room.memberNames.isNotEmpty) {
      receiverId = widget.room.memberNames.keys.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );
    }

    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy người nhận để thực hiện cuộc gọi.')),
      );
      return;
    }

    // Kiểm tra xem có bị chặn hay không
    final myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final myBlocked = List<String>.from(myDoc.data()?['blockedUsers'] ?? []);
    if (myBlocked.contains(receiverId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã chặn người này. Hãy bỏ chặn trước khi gọi.')),
        );
      }
      return;
    }

    final otherDoc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
    final otherBlocked = List<String>.from(otherDoc.data()?['blockedUsers'] ?? []);
    if (otherBlocked.contains(currentUser.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gọi cho người này.')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: 'call_${widget.room.id}_${DateTime.now().millisecondsSinceEpoch}',
          remoteUserName: widget.room.getDisplayName(currentUser.uid),
          callType: type,
          isCaller: true,
          callerId: currentUser.uid,
          callerName: currentUser.displayName,
          receiverId: receiverId,
          roomId: widget.room.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    final isDirect = widget.room.type == ChatRoomType.direct;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.room.id).snapshots(),
      builder: (context, roomSnap) {
        final roomData = roomSnap.data?.data() as Map<String, dynamic>?;
        final currentRoom = roomData != null ? ChatRoomModel.fromMap(roomData, widget.room.id) : widget.room;
        final otherUserId = isDirect
            ? currentRoom.memberIds.firstWhere((id) => id != currentUser?.uid, orElse: () => '')
            : '';
        final roomDisplayName = currentRoom.getDisplayName(currentUser?.uid ?? '');

        return StreamBuilder<DocumentSnapshot>(
          stream: currentUser != null
              ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
              : null,
          builder: (context, mySnapshot) {
            final myData = mySnapshot.data?.data() as Map<String, dynamic>?;
            final myFriends = List<String>.from(myData?['friends'] ?? []);
            final myBlocked = List<String>.from(myData?['blockedUsers'] ?? []);
            final isFriend = myFriends.contains(otherUserId);
            final isBlockedByMe = myBlocked.contains(otherUserId);
            final myBubbleThemeId = myData?['bubbleThemeId'] as String? ?? currentUser?.bubbleThemeId;

            return Scaffold(
              appBar: AppBar(
                titleSpacing: 0,
                title: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isDirect && otherUserId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserWallScreen(
                                targetUser: UserModel(
                                  uid: otherUserId,
                                  email: '',
                                  displayName: roomDisplayName,
                                  photoUrl: currentRoom.photoUrl ?? '',
                                  lastSeen: DateTime.now(),
                                ),
                              ),
                            ),
                          );
                        } else if (!isDirect) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupSettingsScreen(room: currentRoom),
                            ),
                          );
                        }
                      },
                      child: isDirect
                          ? DirectUserAvatar(
                              userId: otherUserId,
                              fallbackName: roomDisplayName,
                              fallbackPhotoUrl: currentRoom.photoUrl,
                              radius: 18,
                              showBadge: true,
                            )
                          : AvatarWidget(
                              photoUrl: currentRoom.photoUrl,
                              name: roomDisplayName,
                              radius: 18,
                            ),
                    ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!isDirect) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupSettingsScreen(room: currentRoom),
                          ),
                        );
                      } else if (otherUserId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserWallScreen(
                              targetUser: UserModel(
                                uid: otherUserId,
                                email: '',
                                displayName: roomDisplayName,
                                photoUrl: currentRoom.photoUrl ?? '',
                                lastSeen: DateTime.now(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomDisplayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.room.type == ChatRoomType.group
                              ? '${currentRoom.memberIds.length} ${loc.t('members_suffix')}'
                              : (isBlockedByMe ? loc.t('blocked_notice') : loc.t('active_now')),
                          style: TextStyle(
                            fontSize: 12,
                            color: isBlockedByMe ? Colors.redAccent : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFE0979).withAlpha(150), width: 1),
                  ),
                  child: const Icon(Icons.music_note, color: Color(0xFF00F2FE), size: 16),
                ),
                tooltip: loc.t('tiktok_viewer'),
                onPressed: _openTikTok,
              ),
              IconButton(
                icon: const Icon(Icons.screen_share_outlined, color: AppTheme.primaryCyan),
                tooltip: 'Chia sẻ màn hình',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScreenShareViewerScreen(
                        remoteUserName: roomDisplayName,
                        remoteUserAvatar: currentRoom.photoUrl,
                        streamTitle: '$roomDisplayName • Live Stream 4K',
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                tooltip: loc.t('voice_call'),
                onPressed: () => _startCall(CallType.audio),
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                tooltip: loc.t('video_call'),
                onPressed: () => _startCall(CallType.video),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (currentUser == null) return;
                  if (value == 'add_friend') {
                    await _chatService.addFriend(currentUserId: currentUser.uid, friendUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.isVietnamese ? 'Đã thêm bạn bè thành công!' : 'Friend added successfully!')),
                      );
                    }
                  } else if (value == 'remove_friend') {
                    await _chatService.removeFriend(currentUserId: currentUser.uid, friendUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.isVietnamese ? 'Đã xóa khỏi danh bạ bạn bè' : 'Removed from friends')),
                      );
                    }
                  } else if (value == 'block') {
                    await _chatService.blockUser(currentUserId: currentUser.uid, targetUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.isVietnamese ? 'Đã chặn tin nhắn và cuộc gọi của người này' : 'Blocked messages and calls from this user')),
                      );
                    }
                  } else if (value == 'unblock') {
                    await _chatService.unblockUser(currentUserId: currentUser.uid, targetUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.isVietnamese ? 'Đã bỏ chặn thành công' : 'Unblocked successfully')),
                      );
                    }
                  } else if (value == 'bubble_theme') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BubbleThemePickerScreen(
                          roomId: widget.room.id,
                          currentThemeId: myBubbleThemeId ?? currentRoom.bubbleThemeId ?? 'default',
                          userId: currentUser.uid,
                        ),
                      ),
                    );
                  } else if (value == 'wallpaper') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperPickerScreen(
                          roomId: widget.room.id,
                          currentWallpaperType: currentRoom.wallpaperType ?? 'preset',
                          currentWallpaperValue: currentRoom.wallpaperValue ?? 'default',
                        ),
                      ),
                    );
                  } else if (value == 'group_settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupSettingsScreen(room: currentRoom),
                      ),
                    );
                  } else if (value == 'clear') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.t('confirm_delete_title')),
                        content: Text(loc.t('confirm_delete_desc')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('cancel'))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(loc.t('delete')),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await _chatService.deleteConversation(
                        roomId: widget.room.id,
                        userId: currentUser.uid,
                        isDirect: isDirect,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (!isDirect) ...[
                    PopupMenuItem(
                      value: 'group_settings',
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(loc.t('group_settings')),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  PopupMenuItem(
                    value: 'bubble_theme',
                    child: Row(
                      children: [
                        const Icon(Icons.bubble_chart_outlined, color: Color(0xFFFE0979)),
                        const SizedBox(width: 8),
                        Text(loc.t('bubble_theme')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'wallpaper',
                    child: Row(
                      children: [
                        const Icon(Icons.wallpaper, color: Color(0xFF0084FF)),
                        const SizedBox(width: 8),
                        Text(loc.t('wallpaper')),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (isDirect && otherUserId.isNotEmpty) ...[
                    if (!isFriend)
                      PopupMenuItem(
                        value: 'add_friend',
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_outlined, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(loc.t('add_friend')),
                          ],
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: 'remove_friend',
                        child: Row(
                          children: [
                            const Icon(Icons.person_remove_outlined, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(loc.t('remove_friend')),
                          ],
                        ),
                      ),
                    if (!isBlockedByMe)
                      PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(loc.t('block_user')),
                          ],
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: 'unblock',
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(loc.t('unblock_user_action')),
                          ],
                        ),
                      ),
                  ],
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(loc.t('delete_chat'), style: const TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ChatWallpaperWidget(
            wallpaper: currentRoom.wallpaperType == 'custom'
                ? WallpaperThemes.getWallpaper('custom', customUrl: currentRoom.wallpaperValue)
                : WallpaperThemes.getWallpaper(currentRoom.wallpaperValue),
            child: Column(
            children: [
              if (_isUploading)
                const LinearProgressIndicator(minHeight: 3),

              // Pinned Screen Share Broadcast Notification (Cyber-Glass UI)
              if (_showScreenShareAlert)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B26).withAlpha(240),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryCyan.withAlpha(80), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryCyan.withAlpha(30),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryCyan.withAlpha(90)),
                        ),
                        child: const Icon(Icons.screen_share, color: AppTheme.primaryCyan, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TRỰC TIẾP 4K',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryCyan,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Figma Canvas',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$roomDisplayName đang sẵn sàng chia sẻ màn hình',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScreenShareViewerScreen(
                                remoteUserName: roomDisplayName,
                                remoteUserAvatar: currentRoom.photoUrl,
                                streamTitle: '$roomDisplayName • Live Stream 4K',
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withAlpha(80),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xem ngay',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward, size: 14, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _showScreenShareAlert = false),
                        child: const Icon(Icons.close, size: 16, color: Colors.white54),
                      ),
                    ],
                  ),
                ),

              // Thanh ghim tin nhắn (Stitch UI style)
              if (currentRoom.pinnedMessageText != null && currentRoom.pinnedMessageText!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F9FF),
                    border: Border(bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.push_pin, size: 16, color: Color(0xFF0369A1)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${loc.t('pinned_message_title').toUpperCase()} ${currentRoom.pinnedMessageSenderName != null ? '• ${currentRoom.pinnedMessageSenderName}' : ''}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              currentRoom.pinnedMessageText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                        tooltip: loc.t('unpin'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _chatService.unpinMessage(widget.room.id),
                      ),
                    ],
                  ),
                ),

              // Banner kết bạn nếu chưa có trong danh bạ
              if (isDirect && otherUserId.isNotEmpty && !isFriend && currentUser != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.withAlpha(25),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt, size: 20, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Người này chưa có trong danh bạ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Kết bạn', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          await _chatService.addFriend(
                            currentUserId: currentUser.uid,
                            friendUserId: otherUserId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã thêm vào danh bạ bạn bè thành công!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // Danh sách tin nhắn Realtime
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.getMessages(widget.room.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Chưa có tin nhắn nào. Hãy gửi lời chào đầu tiên!', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUser?.uid;
                        return MessageBubble(
                          message: msg,
                          isMe: isMe,
                          roomId: widget.room.id,
                          currentUserId: currentUser?.uid ?? '',
                          bubbleThemeId: isMe ? (myBubbleThemeId ?? currentUser?.bubbleThemeId) : null,
                          onReply: () {
                            setState(() {
                              _replyingToMessage = msg;
                            });
                          },
                          onPin: () => _handlePin(msg),
                          onReact: (emoji) => _handleReaction(msg, emoji),
                          onRecall: () async {
                            await _chatService.recallMessage(widget.room.id, msg.id);
                          },
                          onDelete: () async {
                            await _chatService.deleteMessage(widget.room.id, msg.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Thanh xem trước trả lời tin nhắn (Reply preview bar)
              if (_replyingToMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(right: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang trả lời ${_replyingToMessage!.senderName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _replyingToMessage!.content.isNotEmpty ? _replyingToMessage!.content : '[Tệp/Phương tiện]',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Hủy trả lời',
                        onPressed: () {
                          setState(() {
                            _replyingToMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // Khung nhập tin nhắn hoặc Thông báo chặn
              if (isBlockedByMe)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.withAlpha(20),
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.t('you_blocked_user'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (currentUser != null) {
                            await _chatService.unblockUser(
                              currentUserId: currentUser.uid,
                              targetUserId: otherUserId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.isVietnamese ? 'Đã bỏ chặn người dùng này' : 'Unblocked this user')),
                              );
                            }
                          }
                        },
                        child: Text(loc.t('unblock_user'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else if (currentUser != null && !currentRoom.canSendMessage(currentUser.uid))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: Colors.amber.withAlpha(25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          loc.t('admin_lock_message_notice'),
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F131D),
                    border: Border(top: BorderSide(color: Color(0xFF262A35), width: 1)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Smart Quick Action Chips Horizontal List (matching Stitch)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              _buildQuickChip('👍 Tuyệt vời', onTap: () {
                                _textController.text = 'Tuyệt vời! 👍';
                              }),
                              const SizedBox(width: 8),
                              _buildQuickChip('🔥 Xem ngay', onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScreenShareViewerScreen(
                                      remoteUserName: roomDisplayName,
                                      remoteUserAvatar: currentRoom.photoUrl,
                                      streamTitle: '$roomDisplayName • Live Stream 4K',
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              _buildQuickChip('🎙 Bật Mic', icon: Icons.mic, isAccent: true, onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Micro đã bật sẵn sàng cho cuộc trò chuyện')),
                                );
                              }),
                              const SizedBox(width: 8),
                              _buildQuickChip('🖥 Chia sẻ màn hình', icon: Icons.screen_share, isAccent: true, onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScreenShareViewerScreen(
                                      remoteUserName: roomDisplayName,
                                      remoteUserAvatar: currentRoom.photoUrl,
                                      streamTitle: '$roomDisplayName • Live Stream 4K',
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              _buildQuickChip('🚀 Gửi phản hồi', onTap: () {
                                _textController.text = 'Đã nhận và đang xem lại nhé! 🚀';
                              }),
                            ],
                          ),
                        ),
                        // Primary Input Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                          child: Row(
                            children: [
                              // Attachment Sheet Button (+)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF313540)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: AppTheme.primaryCyan, size: 22),
                                  tooltip: loc.isVietnamese ? 'Đính kèm tệp, ảnh hoặc vị trí' : 'Attach file, image, or location',
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => MediaAttachmentSheet(
                                        onActionSelected: _handleAttachmentAction,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Audio Mic button
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF313540)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.mic, color: Color(0xFFB9CACB), size: 20),
                                  tooltip: 'Ghi âm nhanh',
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Micro đã bật sẵn sàng cho tin nhắn thoại')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Message Composer Input Box
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF171B26),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF313540)),
                                  ),
                                  child: TextField(
                                    controller: _textController,
                                    textCapitalization: TextCapitalization.sentences,
                                    maxLines: 4,
                                    minLines: 1,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập tin nhắn bảo mật mã hóa...',
                                      hintStyle: TextStyle(color: Color(0xFF849495), fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onSubmitted: (_) => _sendTextMessage(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Quick Screen Share button
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryCyan.withAlpha(60)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.screen_share, color: AppTheme.primaryCyan, size: 20),
                                  tooltip: 'Chia sẻ màn hình',
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScreenShareViewerScreen(
                                          remoteUserName: roomDisplayName,
                                          remoteUserAvatar: currentRoom.photoUrl,
                                          streamTitle: '$roomDisplayName • Live Stream 4K',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Glowing Send Button
                              GestureDetector(
                                onTap: _sendTextMessage,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryCyan.withAlpha(90),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.send, color: Colors.black, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        );
      },
    );
  },
);
  }

  Widget _buildQuickChip(String label, {IconData? icon, bool isAccent = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAccent ? AppTheme.primaryCyan.withAlpha(35) : const Color(0xFF1C1F2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAccent ? AppTheme.primaryCyan.withAlpha(100) : const Color(0xFF313540),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isAccent ? AppTheme.primaryCyan : Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAccent ? FontWeight.bold : FontWeight.w500,
                color: isAccent ? AppTheme.primaryCyan : const Color(0xFFDFE2F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
