import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';
import '../nearby/nearby_friends_screen.dart';
import '../contacts/search_friends_screen.dart';
import '../wall/user_wall_screen.dart';

class ContactsView extends StatefulWidget {
  final Function(ChatRoomModel)? onRoomSelected;

  const ContactsView({super.key, this.onRoomSelected});

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

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Bạ Bạn Bè', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
            tooltip: 'Tìm kết bạn (Gmail / ID / QR)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchFriendsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.radar, color: Colors.blue),
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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bạn bè theo tên...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.explore, color: Colors.white),
              ),
              title: const Text('Tìm Bạn Bè Quanh Đây (GPS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Khám phá bạn bè gần bạn, lọc theo giới tính, quê quán', style: TextStyle(color: Colors.white70, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyFriendsScreen()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withAlpha(40)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person_search, color: Colors.white),
              ),
              title: const Text('Tìm Kiếm & Kết Bạn', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tìm bạn bằng Gmail, Tên, ID cá nhân hoặc quét mã QR', style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchFriendsScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getAllUsers(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];
                final filtered = users.where((u) => u.displayName.toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Chưa có liên hệ nào trong danh bạ.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserWallScreen(targetUser: user)),
                          );
                        },
                        child: AvatarWidget(
                          name: user.displayName,
                          photoUrl: user.photoUrl,
                          isOnline: user.isOnline,
                          showBadge: true,
                          radius: 22,
                        ),
                      ),
                      title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        user.isOnline ? 'Đang hoạt động' : user.statusMessage,
                        maxLines: 1,
                        style: TextStyle(color: user.isOnline ? Colors.green : Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_outlined, color: Colors.blue),
                            tooltip: 'Nhắn tin',
                            onPressed: () => _startDirectChat(user),
                          ),
                          PopupMenuButton<String>(
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
                                    title: const Text('Xóa bạn bè'),
                                    content: Text('Bạn có chắc chắn muốn xóa ${user.displayName} khỏi danh bạ?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
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
                              const PopupMenuItem(
                                value: 'wall',
                                child: Row(
                                  children: [
                                    Icon(Icons.dashboard_customize_outlined, color: Colors.blueAccent, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xem tường nhà'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove_outlined, color: Colors.orange, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xóa bạn bè'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: Row(
                                  children: [
                                    Icon(Icons.block, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 8),
                                    Text('Chặn người này', style: TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _startDirectChat(user),
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
