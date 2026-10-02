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
import '../tiktok/tiktok_viewer_screen.dart';
import '../../models/wallpaper_model.dart';
import '../../widgets/chat_wallpaper_widget.dart';
import 'bubble_theme_picker_screen.dart';
import 'wallpaper_picker_screen.dart';

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
                            ? '${widget.room.memberIds.length} thành viên'
                            : (isBlockedByMe ? 'Đã bị chặn' : 'Đang hoạt động'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isBlockedByMe ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ],
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
                tooltip: 'Lướt TikTok & LIVE',
                onPressed: _openTikTok,
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                tooltip: 'Gọi thoại',
                onPressed: () => _startCall(CallType.audio),
              ),
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                tooltip: 'Gọi Video',
                onPressed: () => _startCall(CallType.video),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (currentUser == null) return;
                  if (value == 'add_friend') {
                    await _chatService.addFriend(currentUserId: currentUser.uid, friendUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thêm bạn bè thành công!')),
                      );
                    }
                  } else if (value == 'remove_friend') {
                    await _chatService.removeFriend(currentUserId: currentUser.uid, friendUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa khỏi danh bạ bạn bè')),
                      );
                    }
                  } else if (value == 'block') {
                    await _chatService.blockUser(currentUserId: currentUser.uid, targetUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chặn tin nhắn và cuộc gọi của người này')),
                      );
                    }
                  } else if (value == 'unblock') {
                    await _chatService.unblockUser(currentUserId: currentUser.uid, targetUserId: otherUserId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã bỏ chặn thành công')),
                      );
                    }
                  } else if (value == 'bubble_theme') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BubbleThemePickerScreen(
                          roomId: widget.room.id,
                          currentThemeId: currentRoom.bubbleThemeId ?? 'default',
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
                  } else if (value == 'clear') {
                    _chatService.deleteRoom(widget.room.id);
                    Navigator.pop(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'bubble_theme',
                    child: Row(
                      children: [
                        Icon(Icons.bubble_chart_outlined, color: Color(0xFFFE0979)),
                        SizedBox(width: 8),
                        Text('Đổi kiểu bong bóng chat'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'wallpaper',
                    child: Row(
                      children: [
                        Icon(Icons.wallpaper, color: Color(0xFF0084FF)),
                        SizedBox(width: 8),
                        Text('Cài đặt hình nền'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (isDirect && otherUserId.isNotEmpty) ...[
                    if (!isFriend)
                      const PopupMenuItem(
                        value: 'add_friend',
                        child: Row(
                          children: [
                            Icon(Icons.person_add_outlined, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Thêm vào danh bạ (Kết bạn)'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'remove_friend',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove_outlined, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Xóa khỏi danh bạ bạn bè'),
                          ],
                        ),
                      ),
                    if (!isBlockedByMe)
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Chặn người này'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'unblock',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Bỏ chặn người này'),
                          ],
                        ),
                      ),
                  ],
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Xóa cuộc trò chuyện', style: TextStyle(color: Colors.redAccent)),
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

              // Thanh ghim tin nhắn Zalo
              if (currentRoom.pinnedMessageText != null && currentRoom.pinnedMessageText!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(35),
                    border: Border(bottom: BorderSide(color: Colors.amber.withAlpha(80), width: 1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tin nhắn đã ghim ${currentRoom.pinnedMessageSenderName != null ? '(${currentRoom.pinnedMessageSenderName})' : ''}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            Text(
                              currentRoom.pinnedMessageText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Gỡ ghim',
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
                          bubbleThemeId: currentRoom.bubbleThemeId,
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
                      const Expanded(
                        child: Text(
                          'Bạn đã chặn người dùng này.',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                                const SnackBar(content: Text('Đã bỏ chặn người dùng này')),
                              );
                            }
                          }
                        },
                        child: const Text('Bỏ chặn', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        offset: const Offset(0, -1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Đính kèm tệp, ảnh hoặc vị trí',
                          color: theme.colorScheme.primary,
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
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn bảo mật...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              filled: true,
                            ),
                            onSubmitted: (_) => _sendTextMessage(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            tooltip: 'Gửi',
                            onPressed: _sendTextMessage,
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
}
