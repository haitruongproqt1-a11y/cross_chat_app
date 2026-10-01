import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
import '../call/call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatRoomModel room;

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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    _textController.clear();

    await _chatService.sendMessage(
      roomId: widget.room.id,
      sender: currentUser,
      content: text,
      type: MessageType.text,
    );
  }

  void _handleAttachmentAction(AttachmentAction action) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    if (action == AttachmentAction.camera || action == AttachmentAction.gallery) {
      final xfile = await _storageService.pickImage(
        source: action == AttachmentAction.camera ? ImageSource.camera : ImageSource.gallery,
      );
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
            fileName: xfile.name,
          );
        }
      }
    } else if (action == AttachmentAction.video) {
      final xfile = await _storageService.pickVideo();
      if (xfile != null) {
        setState(() => _isUploading = true);
        final bytes = await xfile.readAsBytes();
        final url = await _storageService.uploadFile(
          path: xfile.path,
          fileName: xfile.name,
          folder: 'chat_videos/${widget.room.id}',
          fileBytes: bytes,
        );
        setState(() => _isUploading = false);

        if (url != null) {
          await _chatService.sendMessage(
            roomId: widget.room.id,
            sender: currentUser,
            content: 'Video',
            type: MessageType.video,
            mediaUrl: url,
            fileName: xfile.name,
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
    }
  }

  void _startCall(CallType type) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: 'call_${widget.room.id}_${DateTime.now().millisecondsSinceEpoch}',
          remoteUserName: widget.room.name,
          callType: type,
          isCaller: true,
          callerId: currentUser.uid,
          callerName: currentUser.displayName,
          receiverId: receiverId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(
              photoUrl: widget.room.photoUrl,
              name: widget.room.name,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.room.type == ChatRoomType.group
                        ? '${widget.room.memberIds.length} thành viên'
                        : 'Đang hoạt động',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
            onSelected: (value) {
              if (value == 'clear') {
                _chatService.deleteRoom(widget.room.id);
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => [
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
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(minHeight: 3),

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

          // Khung nhập tin nhắn
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
    );
  }
}
