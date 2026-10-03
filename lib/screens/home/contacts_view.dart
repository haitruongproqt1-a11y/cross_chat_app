import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/create_group_screen.dart';
import '../nearby/nearby_friends_screen.dart';
import '../contacts/search_friends_screen.dart';
import '../wall/user_wall_screen.dart';
import '../../models/call_model.dart';
import '../call/call_screen.dart';

class ContactsView extends StatefulWidget {
  final Function(ChatRoomModel)? onRoomSelected;
  final bool embeddedInHomeScreen;

  const ContactsView({
    super.key,
    this.onRoomSelected,
    this.embeddedInHomeScreen = false,
  });

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startDirectChat(UserModel targetUser) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    final roomId = await _chatService.getOrCreateDirectRoom(
      currentUser: currentUser,
      otherUser: targetUser,
    );

    final room = ChatRoomModel(
      id: roomId,
      name: targetUser.displayName,
      photoUrl: targetUser.photoUrl,
      type: ChatRoomType.direct,
      memberIds: [currentUser.uid, targetUser.uid],
      createdAt: DateTime.now(),
    );

    if (!mounted) return;

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

  void _startCallWithUser(UserModel targetUser, CallType type) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final roomId = await _chatService.getOrCreateDirectRoom(
      currentUser: currentUser,
      otherUser: targetUser,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callId: 'call_${roomId}_${DateTime.now().millisecondsSinceEpoch}',
          remoteUserName: targetUser.displayName,
          callType: type,
          isCaller: true,
          callerId: currentUser.uid,
          callerName: currentUser.displayName,
          receiverId: targetUser.uid,
          roomId: roomId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final loc = Provider.of<LocalizationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: widget.embeddedInHomeScreen
          ? null
          : AppBar(
              title: Text(loc.t('tab_contacts'), style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0284C7)),
                  tooltip: 'Tìm kết bạn (Gmail / ID / QR)',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchFriendsScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.radar, color: Color(0xFF0284C7)),
                  tooltip: 'Tìm bạn quanh đây',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NearbyFriendsScreen()),
                    );
                  },
                ),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Khung tìm kiếm Stitch UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: loc.isVietnamese ? 'Tìm kiếm danh bạ hoặc bạn bè...' : 'Search contacts or friends...',
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
                      : null,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),

          // 2. Hai thẻ phím tắt Stitch UI nhanh: Thêm bạn mới & Nhóm KINI CHAT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                // Thêm bạn mới
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchFriendsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isVietnamese ? 'Thêm bạn mới' : 'Add New Friend',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.isVietnamese ? 'Qua số điện thoại, QR code hoặc Radar' : 'Via phone, QR code or Nearby Radar',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Danh sách nhóm KINI CHAT
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.groups_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isVietnamese ? 'Danh sách nhóm KINI CHAT' : 'KINI Groups & Channels',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                loc.isVietnamese ? 'Tạo hoặc quản lý nhóm kèm Key Trưởng nhóm' : 'Create or manage groups with owner keys',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Tiêu đề danh sách bạn bè
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getFriendsStream(currentUser.uid),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Text(
                  loc.isVietnamese ? 'BẠN BÈ ($count)' : 'FRIENDS ($count)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                );
              },
            ),
          ),

          // 4. Danh sách bạn bè
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getFriendsStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];
                final filtered = users.where((u) => u.displayName.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.people_outline_rounded, size: 32, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.isVietnamese ? 'Chưa có bạn bè trong danh bạ' : 'No friends in contacts yet',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loc.isVietnamese
                                ? 'Nhấn "Thêm bạn mới" ở trên để kết bạn qua Gmail, ID hoặc Radar quanh đây.'
                                : 'Tap "Add New Friend" above to connect via Gmail, ID or Radar.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 20 : 6),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UserWallScreen(targetUser: user)),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AvatarWidget(
                                name: user.displayName,
                                photoUrl: user.photoUrl,
                                radius: 22,
                              ),
                              if (user.isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(
                          user.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          user.isOnline
                              ? (loc.isVietnamese ? 'Đang hoạt động' : 'Online')
                              : (user.statusMessage.isNotEmpty ? user.statusMessage : user.email),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: user.isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            fontWeight: user.isOnline ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0284C7), size: 19),
                              tooltip: loc.t('tab_messages'),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () => _startDirectChat(user),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined, color: Color(0xFF0284C7), size: 19),
                              tooltip: loc.t('voice_call'),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () => _startCallWithUser(user, CallType.audio),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.videocam_outlined, color: Color(0xFF0284C7), size: 20),
                              tooltip: loc.t('video_call'),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () => _startCallWithUser(user, CallType.video),
                            ),
                            const SizedBox(width: 2),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 19),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onSelected: (val) async {
                                if (val == 'wall') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => UserWallScreen(targetUser: user)),
                                  );
                                } else if (val == 'remove') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(loc.isVietnamese ? 'Xóa bạn bè' : 'Remove Friend'),
                                      content: Text(
                                        loc.isVietnamese
                                            ? 'Bạn có chắc chắn muốn xóa ${user.displayName} khỏi danh bạ?'
                                            : 'Are you sure you want to remove ${user.displayName} from contacts?',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('cancel'))),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: Text(loc.t('delete')),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _chatService.removeFriend(
                                      currentUserId: currentUser.uid,
                                      friendUserId: user.uid,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã xóa ${user.displayName} khỏi danh bạ')),
                                      );
                                    }
                                  }
                                } else if (val == 'block') {
                                  await _chatService.blockUser(
                                    currentUserId: currentUser.uid,
                                    targetUserId: user.uid,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đã chặn ${user.displayName}')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'wall',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF0284C7), size: 18),
                                      const SizedBox(width: 8),
                                      Text(loc.isVietnamese ? 'Xem tường nhà' : 'View Wall', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_remove_outlined, color: Colors.orange, size: 18),
                                      const SizedBox(width: 8),
                                      Text(loc.isVietnamese ? 'Xóa bạn bè' : 'Remove Friend', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'block',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.block, color: Colors.redAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text(loc.isVietnamese ? 'Chặn người này' : 'Block User', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _startDirectChat(user),
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
