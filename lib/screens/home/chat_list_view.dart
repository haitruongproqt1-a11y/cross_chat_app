import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/constants.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/create_group_screen.dart';
import '../chat/group_settings_screen.dart';
import '../tiktok/tiktok_viewer_screen.dart';

class ChatListView extends StatefulWidget {
  final Function(ChatRoomModel)? onRoomSelected;

  const ChatListView({super.key, this.onRoomSelected});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(ChatRoomModel room) {
    if (widget.onRoomSelected != null) {
      widget.onRoomSelected!(room);
    } else if (ResponsiveLayout.isDesktop(context)) {
      Provider.of<ChatProvider>(context, listen: false).setActiveRoom(room);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(room: room)),
      );
    }
  }

  // Xác nhận xóa cuộc trò chuyện (Zalo-style)
  Future<bool> _confirmDeleteConversation(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String displayName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Xóa cuộc trò chuyện?'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa cuộc trò chuyện "$displayName"?\nToàn bộ nội dung tin nhắn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _chatService.deleteConversation(
        roomId: room.id,
        userId: currentUserId,
        isDirect: room.type == ChatRoomType.direct,
      );

      // Nếu đang mở phòng chat này trên Desktop, bỏ active room
      if (mounted) {
        if (chatProvider.activeRoom?.id == room.id) {
          chatProvider.setActiveRoom(null);
        }
        messenger.showSnackBar(
          SnackBar(content: Text('Đã xóa cuộc trò chuyện với $displayName')),
        );
      }
      return true;
    }
    return false;
  }

  // Menu tùy chọn khi dí tay giữ lâu vào tên người dùng (Long Press Menu)
  void _showChatLongPressMenu(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String displayName,
  ) {
    final otherUserId = room.type == ChatRoomType.direct
        ? room.memberIds.firstWhere((id) => id != currentUserId, orElse: () => '')
        : '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: room.type == ChatRoomType.direct
                    ? DirectUserAvatar(
                        userId: otherUserId,
                        fallbackName: displayName,
                        fallbackPhotoUrl: room.photoUrl,
                        radius: 20,
                      )
                    : AvatarWidget(
                        photoUrl: room.photoUrl,
                        name: displayName,
                        radius: 20,
                      ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(
                  room.type == ChatRoomType.direct ? 'Trò chuyện cá nhân' : '${room.memberIds.length} thành viên',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              const Divider(),
              if (room.type == ChatRoomType.group)
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Colors.blueAccent),
                  title: const Text('Cài đặt nhóm'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupSettingsScreen(room: room)),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.mark_chat_read_outlined, color: Colors.teal),
                title: const Text('Đánh dấu đã đọc'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
                title: Text(
                  'Xóa cuộc trò chuyện',
                  style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Xóa toàn bộ nội dung tin nhắn của cuộc trò chuyện này', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteConversation(context, room, currentUserId, displayName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin Nhắn', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x5500F2FE), offset: Offset(-1, -1), blurRadius: 3),
                  BoxShadow(color: Color(0x55FE0979), offset: Offset(1, 1), blurRadius: 3),
                ],
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 16),
            ),
            tooltip: 'Lướt TikTok & LIVE',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TikTokViewerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Tạo Nhóm Mới',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Khung tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện hoặc tin nhắn...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Danh sách phòng chat
          Expanded(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: chatProvider.getRooms(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data ?? [];
                final filteredRooms = rooms.where((r) {
                  final name = r.getDisplayName(currentUser.uid).toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_chat_unread_outlined, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có cuộc trò chuyện nào',
                          style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Bắt Đầu Nhóm Mới'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredRooms.length,
                  separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    final isSelected = chatProvider.activeRoom?.id == room.id;
                    final displayName = room.getDisplayName(currentUser.uid);

                    final otherUserId = room.type == ChatRoomType.direct
                        ? room.memberIds.firstWhere((id) => id != currentUser.uid, orElse: () => '')
                        : '';

                    return Dismissible(
                      key: ValueKey('room_${room.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade600,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_forever, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'XÓA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await _confirmDeleteConversation(context, room, currentUser.uid, displayName);
                      },
                      child: ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                        leading: room.type == ChatRoomType.direct
                            ? DirectUserAvatar(
                                userId: otherUserId,
                                fallbackName: displayName,
                                fallbackPhotoUrl: room.photoUrl,
                                radius: 24,
                                showBadge: true,
                              )
                            : AvatarWidget(
                                photoUrl: room.photoUrl,
                                name: displayName,
                                radius: 24,
                              ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          room.lastMessage ?? 'Chưa có tin nhắn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: room.unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF334155),
                            fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (room.lastMessageTime != null)
                              Text(
                                AppConstants.formatTimestamp(room.lastMessageTime!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (room.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  '${room.unreadCount}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () => _openChat(room),
                        onLongPress: () => _showChatLongPressMenu(context, room, currentUser.uid, displayName),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
