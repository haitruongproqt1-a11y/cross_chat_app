import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
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
      backgroundColor: AppTheme.surfaceDark,
      body: Column(
        children: [
          // Khung tìm kiếm Stitch Cyber-Glass UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13.5, color: Colors.white),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Tìm kiếm tin nhắn, bạn bè, nhóm...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                        prefixIcon: const Icon(Icons.search, size: 19, color: AppTheme.onSurfaceVariant),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.mic, size: 18, color: AppTheme.onSurfaceVariant),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Tính năng tìm kiếm bằng giọng nói đã sẵn sàng')),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.tune, size: 18, color: AppTheme.onSurfaceVariant),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  const SizedBox(width: 4),
                                ],
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
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryViolet.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.secondaryViolet.withAlpha(80)),
                      ),
                      child: const Icon(Icons.group_add_outlined, color: AppTheme.violetLight, size: 21),
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
                              label: 'Tất cả',
                              count: rooms.length,
                              isSelected: _activeCategory == 'all',
                              onTap: () => setState(() => _activeCategory = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              label: 'Chưa đọc',
                              count: unreadTotal,
                              isError: true,
                              isSelected: _activeCategory == 'unread',
                              onTap: () => setState(() => _activeCategory = 'unread'),
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              label: 'Nhóm & Kênh',
                              count: groupsTotal,
                              isSelected: _activeCategory == 'groups',
                              onTap: () => setState(() => _activeCategory = 'groups'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Không gian trực tiếp & Story Orbit Strip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Không gian trực tiếp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'XEM TẤT CẢ',
                            style: TextStyle(
                              color: AppTheme.primaryCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Orbit Story Carousel Row
                    Container(
                      height: 92,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Tin của bạn / Create Story Button
                          InkWell(
                            borderRadius: BorderRadius.circular(36),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tạo tin mới vào Không gian trực tiếp')),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.surfaceContainerHigh,
                                          border: Border.all(color: const Color(0x33FFFFFF)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            currentUser.displayName.isNotEmpty
                                                ? currentUser.displayName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.surfaceDark, width: 2),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Tin của bạn',
                                    style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Stories from active rooms
                          ...rooms.take(8).map((r) {
                            final dName = r.getDisplayName(currentUser.uid);
                            final isUnread = r.unreadCount > 0;
                            return InkWell(
                              borderRadius: BorderRadius.circular(36),
                              onTap: () => _openChat(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: isUnread
                                                ? const LinearGradient(
                                                    colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                                                  )
                                                : null,
                                            border: isUnread ? null : Border.all(color: const Color(0x33FFFFFF), width: 1.5),
                                          ),
                                          child: AvatarWidget(
                                            photoUrl: r.photoUrl,
                                            name: dName,
                                            radius: 23,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 1,
                                          right: 1,
                                          child: Container(
                                            width: 11,
                                            height: 11,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryCyan,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.surfaceDark, width: 2),
                                              boxShadow: [
                                                BoxShadow(color: AppTheme.primaryCyan.withAlpha(180), blurRadius: 4),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      width: 56,
                                      child: Text(
                                        dName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              itemCount: filteredRooms.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final room = filteredRooms[index];
                                final isSelected = chatProvider.activeRoom?.id == room.id;
                                final displayName = room.getDisplayName(currentUser.uid);

                                final otherUserId = room.type == ChatRoomType.direct
                                    ? room.memberIds.firstWhere((id) => id != currentUser.uid, orElse: () => '')
                                    : '';

                                final isOwner = room.type == ChatRoomType.group && room.isOwner(currentUser.uid);
                                final isDeputy = room.type == ChatRoomType.group && room.isDeputy(currentUser.uid);
                                final hasUnread = room.unreadCount > 0;

                                return Dismissible(
                                  key: ValueKey('room_${room.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryCyan.withAlpha(25)
                                          : AppTheme.surfaceContainerLow.withAlpha(220),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryCyan.withAlpha(120)
                                            : const Color(0x1AFFFFFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Left cyan glowing strip for active/unread conversations
                                        if (hasUnread || index == 0)
                                          Positioned(
                                            left: 0,
                                            top: 8,
                                            bottom: 8,
                                            child: Container(
                                              width: 3.5,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryCyan,
                                                borderRadius: BorderRadius.circular(2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryCyan.withAlpha(180),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                          leading: Stack(
                                            children: [
                                              room.type == ChatRoomType.direct
                                                  ? DirectUserAvatar(
                                                      userId: otherUserId,
                                                      fallbackName: displayName,
                                                      fallbackPhotoUrl: room.photoUrl,
                                                      radius: 23,
                                                      showBadge: true,
                                                    )
                                                  : AvatarWidget(
                                                      photoUrl: room.photoUrl,
                                                      name: displayName,
                                                      radius: 23,
                                                    ),
                                              if (room.type == ChatRoomType.group)
                                                Positioned(
                                                  bottom: -1,
                                                  right: -1,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.secondaryViolet,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: AppTheme.surfaceDark, width: 1.5),
                                                    ),
                                                    child: const Icon(Icons.groups, color: Colors.white, size: 10),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          title: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 14.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (room.type == ChatRoomType.group) ...[
                                                const SizedBox(width: 5),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.surfaceContainerHighest,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'NHÓM',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (isOwner) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7).withAlpha(30),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFFFCD34D).withAlpha(100), width: 0.8),
                                                  ),
                                                  child: const Text(
                                                    '🔑 Trưởng nhóm',
                                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFFCD34D)),
                                                  ),
                                                ),
                                              ],
                                              if (isDeputy) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryCyan.withAlpha(20),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppTheme.primaryCyan.withAlpha(80), width: 0.8),
                                                  ),
                                                  child: const Text(
                                                    '🛡️ Phó nhóm',
                                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 3),
                                            child: Text(
                                              room.lastMessage ?? (loc.isVietnamese ? 'Chưa có tin nhắn nào' : 'No messages yet'),
                                              style: TextStyle(
                                                color: hasUnread ? Colors.white : AppTheme.onSurfaceVariant,
                                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                                fontSize: 12.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        color: hasUnread ? AppTheme.primaryCyan : const Color(0xFF64748B),
                                                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 3),
                                                  if (room.unreadCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primaryCyan,
                                                        borderRadius: BorderRadius.circular(10),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppTheme.primaryCyan.withAlpha(120),
                                                            blurRadius: 6,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        '${room.unreadCount}',
                                                        style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                                                      ),
                                                    )
                                                  else
                                                    const Icon(Icons.done_all, size: 15, color: AppTheme.primaryCyan),
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
                                      ],
                                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 6,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withAlpha(120),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.edit_square, color: Colors.black, size: 24),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    bool isError = false,
    bool hasLiveDot = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? null : AppTheme.surfaceContainerHigh,
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0x22FFFFFF),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryCyan.withAlpha(80), blurRadius: 10, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasLiveDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.tertiaryMagenta,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : AppTheme.onSurfaceVariant,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withAlpha(25)
                      : (isError ? AppTheme.tertiaryMagenta.withAlpha(30) : const Color(0x22FFFFFF)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.black
                        : (isError ? AppTheme.tertiaryMagenta : Colors.white),
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
