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
import '../chat/wallpaper_picker_screen.dart';
import '../tiktok/tiktok_viewer_screen.dart';
import '../../services/localization_service.dart';

class ChatListView extends StatefulWidget {
  final Function(ChatRoomModel)? onRoomSelected;
  final bool embeddedInHomeScreen;

  const ChatListView({
    super.key,
    this.onRoomSelected,
    this.embeddedInHomeScreen = false,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = '';
  String _activeCategory = 'all'; // 'all', 'unread', 'groups'

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
    final loc = Provider.of<LocalizationService>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(loc.t('confirm_delete_title')),
          ],
        ),
        content: Text(
          loc.isVietnamese
              ? 'Bạn có chắc chắn muốn xóa cuộc trò chuyện "$displayName"?\nToàn bộ nội dung tin nhắn sẽ bị xóa vĩnh viễn và không thể khôi phục.'
              : 'Are you sure you want to delete conversation "$displayName"?\nAll message history will be permanently deleted and cannot be recovered.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('delete')),
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
          SnackBar(content: Text(loc.isVietnamese ? 'Đã xóa cuộc trò chuyện với $displayName' : 'Deleted conversation with $displayName')),
        );
      }
      return true;
    }
    return false;
  }

  // Menu tùy chọn khi dí tay giữ lâu hoặc bấm nút 3 chấm (Google Stitch ChatBottomSheet 100%)
  void _showChatLongPressMenu(
    BuildContext context,
    ChatRoomModel room,
    String currentUserId,
    String displayName,
  ) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final otherUserId = room.type == ChatRoomType.direct
        ? room.memberIds.firstWhere((id) => id != currentUserId, orElse: () => '')
        : '';
    final isPinned = room.isPinnedFor(currentUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 4),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo drag handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ hồ sơ đối tượng (Profile Card Header Stitch UI)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0F2FE)),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        room.type == ChatRoomType.direct
                            ? DirectUserAvatar(
                                userId: otherUserId,
                                fallbackName: displayName,
                                fallbackPhotoUrl: room.photoUrl,
                                radius: 24,
                              )
                            : AvatarWidget(
                                photoUrl: room.photoUrl,
                                name: displayName,
                                radius: 24,
                              ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                room.type == ChatRoomType.direct
                                    ? (loc.isVietnamese ? 'Đang hoạt động' : 'Active now')
                                    : '${room.memberIds.length} ${loc.t('members_suffix')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách hành động nhóm (Grouped Actions List)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    // 1. Đánh dấu đã đọc
                    _buildSheetActionItem(
                      icon: Icons.visibility_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: loc.isVietnamese ? 'Đánh dấu đã đọc' : 'Mark as read',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.isVietnamese ? 'Đã đánh dấu đã đọc cuộc trò chuyện' : 'Marked as read')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFE2E8F0)),

                    // 2. Ghim / Bỏ ghim cuộc trò chuyện
                    _buildSheetActionItem(
                      icon: Icons.push_pin_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: isPinned
                          ? (loc.isVietnamese ? 'Bỏ ghim cuộc trò chuyện' : 'Unpin chat')
                          : (loc.isVietnamese ? 'Ghim cuộc trò chuyện lên đầu' : 'Pin chat to top'),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _chatService.togglePinRoom(room.id, currentUserId, !isPinned);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isPinned
                                  ? (loc.isVietnamese ? 'Đã bỏ ghim cuộc trò chuyện' : 'Unpinned chat')
                                  : (loc.isVietnamese ? 'Đã ghim cuộc trò chuyện lên đầu' : 'Pinned chat to top')),
                              backgroundColor: const Color(0xFFD97706),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFE2E8F0)),

                    // 3. Tắt thông báo
                    _buildSheetActionItem(
                      icon: Icons.notifications_off_outlined,
                      iconColor: const Color(0xFF64748B),
                      title: loc.isVietnamese ? 'Tắt thông báo (Bật im lặng)' : 'Mute notifications',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.isVietnamese ? 'Đã tắt thông báo cho $displayName' : 'Muted notifications for $displayName')),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 48, color: Color(0xFFE2E8F0)),

                    // 4. Cài đặt & Tùy chỉnh nhóm
                    _buildSheetActionItem(
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFF334155),
                      title: room.type == ChatRoomType.group
                          ? (loc.isVietnamese ? 'Cài đặt & Tùy chỉnh nhóm' : 'Chat & Group Settings')
                          : (loc.isVietnamese ? 'Tùy chỉnh & Hình nền' : 'Wallpaper & Customization'),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (room.type == ChatRoomType.group) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GroupSettingsScreen(room: room)),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WallpaperPickerScreen(
                                roomId: room.id,
                                currentWallpaperType: room.wallpaperType ?? 'preset',
                                currentWallpaperValue: room.wallpaperValue ?? 'default',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Nút xóa cuộc trò chuyện màu đỏ rộng toàn màn hình
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteConversation(context, room, currentUserId, displayName);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 19),
                      const SizedBox(width: 8),
                      Text(
                        loc.isVietnamese
                            ? 'Xóa cuộc trò chuyện (Không thể khôi phục)'
                            : 'Delete conversation (Permanent)',
                        style: const TextStyle(
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final loc = Provider.of<LocalizationService>(context);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.embeddedInHomeScreen
          ? null
          : AppBar(
              title: Text(loc.t('tab_messages'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  tooltip: loc.t('tiktok_viewer'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TikTokViewerScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: loc.isVietnamese ? 'Tạo Nhóm Mới' : 'Create Group',
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
          // Khung tìm kiếm Stitch UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: loc.t('search_chat_hint'),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.tune_rounded, size: 18, color: Color(0xFF94A3B8)),
                              ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                ),
                if (widget.embeddedInHomeScreen) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7).withAlpha(40)),
                      ),
                      child: const Icon(Icons.group_add_outlined, color: Color(0xFF0284C7), size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Danh sách phòng chat & Story Carousel
          Expanded(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: chatProvider.getRooms(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data ?? [];
                final unreadTotal = rooms.where((r) => r.unreadCount > 0).length;
                final groupsTotal = rooms.where((r) => r.type == ChatRoomType.group).length;

                final filteredRooms = rooms.where((r) {
                  final name = r.getDisplayName(currentUser.uid).toLowerCase();
                  final matchesSearch = name.contains(_searchQuery) ||
                      (r.lastMessage ?? '').toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;
                  if (_activeCategory == 'unread') return r.unreadCount > 0;
                  if (_activeCategory == 'groups') return r.type == ChatRoomType.group;
                  return true;
                }).toList();

                filteredRooms.sort((a, b) {
                  final aPinned = a.isPinnedFor(currentUser.uid);
                  final bPinned = b.isPinnedFor(currentUser.uid);
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;
                  final aTime = a.lastMessageTime ?? a.createdAt;
                  final bTime = b.lastMessageTime ?? b.createdAt;
                  return bTime.compareTo(aTime);
                });

                return Column(
                  children: [
                    // Category Filter Chips
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip(
                              label: loc.t('all_filter'),
                              count: null,
                              isSelected: _activeCategory == 'all',
                              onTap: () => setState(() => _activeCategory = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              label: loc.t('unread_filter'),
                              count: unreadTotal,
                              isSelected: _activeCategory == 'unread',
                              onTap: () => setState(() => _activeCategory = 'unread'),
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              label: loc.t('groups_filter'),
                              count: groupsTotal,
                              isSelected: _activeCategory == 'groups',
                              onTap: () => setState(() => _activeCategory = 'groups'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Story Carousel Row
                    Container(
                      height: 84,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Add Story Button
                          InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.isVietnamese ? 'Tạo tin mới vào Nhật ký' : 'Create new moment on Wall')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFF1F5F9),
                                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                                    ),
                                    child: const Icon(Icons.add, color: Color(0xFF0284C7), size: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.t('add_story'),
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Stories from active rooms
                          ...rooms.take(6).map((r) {
                            final dName = r.getDisplayName(currentUser.uid);
                            final isUnread = r.unreadCount > 0;
                            return InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () => _openChat(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isUnread
                                            ? const LinearGradient(
                                                colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF6366F1)],
                                              )
                                            : null,
                                        border: isUnread ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                      ),
                                      child: AvatarWidget(
                                        photoUrl: r.photoUrl,
                                        name: dName,
                                        radius: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 54,
                                      child: Text(
                                        dName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Chat List
                    Expanded(
                      child: filteredRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.mark_chat_unread_outlined, size: 54, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    loc.t('no_chats'),
                                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 15),
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
                                    label: Text(loc.t('start_new_group')),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredRooms.length,
                              separatorBuilder: (_, __) => const Divider(indent: 72, height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final room = filteredRooms[index];
                                final isSelected = chatProvider.activeRoom?.id == room.id;
                                final displayName = room.getDisplayName(currentUser.uid);

                                final otherUserId = room.type == ChatRoomType.direct
                                    ? room.memberIds.firstWhere((id) => id != currentUser.uid, orElse: () => '')
                                    : '';

                                final isOwner = room.type == ChatRoomType.group && room.isOwner(currentUser.uid);
                                final isDeputy = room.type == ChatRoomType.group && room.isDeputy(currentUser.uid);
                                final isPinned = room.isPinnedFor(currentUser.uid) || (room.pinnedMessageId != null && room.pinnedMessageId!.isNotEmpty);

                                return Dismissible(
                                  key: ValueKey('room_${room.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red.shade600,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.delete_forever, color: Colors.white, size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          loc.t('delete_swipe'),
                                          style: const TextStyle(
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
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                              fontSize: 14.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isOwner) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFCD34D)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.vpn_key, size: 10, color: Color(0xFFB45309)),
                                                SizedBox(width: 2),
                                                Text('Key', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                              ],
                                            ),
                                          ),
                                        ] else if (isDeputy) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.shield, size: 10, color: Color(0xFF1D4ED8)),
                                                SizedBox(width: 2),
                                                Text('Phó', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (isPinned) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.push_pin, size: 13, color: Color(0xFFF59E0B)),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      room.lastMessage ?? 'Chưa có tin nhắn',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: room.unreadCount > 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                        fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (room.lastMessageTime != null)
                                              Text(
                                                AppConstants.formatTimestamp(room.lastMessageTime!),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            const SizedBox(height: 3),
                                            if (room.unreadCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0284C7),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${room.unreadCount}',
                                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            else
                                              const Icon(Icons.done_all, size: 15, color: Color(0xFF0284C7)),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showChatLongPressMenu(context, room, currentUser.uid, displayName),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openChat(room),
                                    onLongPress: () => _showChatLongPressMenu(context, room, currentUser.uid, displayName),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF0284C7).withAlpha(40), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
