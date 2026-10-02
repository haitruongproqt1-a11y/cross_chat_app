import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/avatar_widget.dart';
import '../wall/user_wall_screen.dart';
import 'chat_detail_screen.dart';

class GroupSettingsScreen extends StatefulWidget {
  final ChatRoomModel room;

  const GroupSettingsScreen({super.key, required this.room});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchMemberController = TextEditingController();
  String _memberQuery = '';

  @override
  void dispose() {
    _searchMemberController.dispose();
    super.dispose();
  }

  // Chỉnh sửa tên nhóm (Chỉ Quản trị viên: Trưởng/Phó nhóm)
  void _editGroupName(ChatRoomModel currentRoom) {
    final nameCtrl = TextEditingController(text: currentRoom.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên nhóm'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Nhập tên nhóm mới',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await _chatService.updateGroupSettings(roomId: currentRoom.id, name: newName);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Thêm thành viên vào nhóm
  void _openAddMembersDialog(ChatRoomModel currentRoom, UserModel currentUser) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        final List<UserModel> selectedToAdd = [];
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thêm thành viên vào nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ElevatedButton(
                            onPressed: selectedToAdd.isEmpty
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(sheetContext);
                                    await _chatService.addMembersToGroup(
                                      roomId: currentRoom.id,
                                      admin: currentUser,
                                      newMembers: selectedToAdd,
                                    );
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Đã thêm ${selectedToAdd.length} thành viên vào nhóm')),
                                      );
                                    }
                                  },
                            child: Text('Thêm (${selectedToAdd.length})'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: StreamBuilder<List<UserModel>>(
                        stream: _chatService.getAllUsers(currentUser.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final allUsers = snapshot.data ?? [];
                          final nonMembers = allUsers.where((u) => !currentRoom.memberIds.contains(u.uid)).toList();

                          if (nonMembers.isEmpty) {
                            return const Center(child: Text('Tất cả bạn bè đã ở trong nhóm này.'));
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: nonMembers.length,
                            itemBuilder: (context, idx) {
                              final user = nonMembers[idx];
                              final isSelected = selectedToAdd.any((u) => u.uid == user.uid);

                              return ListTile(
                                leading: AvatarWidget(name: user.displayName, photoUrl: user.photoUrl, isOnline: user.isOnline, showBadge: true),
                                title: Text(user.displayName),
                                subtitle: Text(user.statusMessage, maxLines: 1),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selectedToAdd.add(user);
                                      } else {
                                        selectedToAdd.removeWhere((u) => u.uid == user.uid);
                                      }
                                    });
                                  },
                                ),
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedToAdd.removeWhere((u) => u.uid == user.uid);
                                    } else {
                                      selectedToAdd.add(user);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Tùy chọn cho một thành viên
  void _showMemberActions(ChatRoomModel currentRoom, UserModel currentUser, String targetUid, String targetName) {
    if (targetUid == currentUser.uid) {
      return; // Không tự thao tác trên chính mình ở đây
    }

    final isCurrentUserOwner = currentRoom.isOwner(currentUser.uid);
    final isCurrentUserDeputy = currentRoom.isDeputy(currentUser.uid);
    final isTargetOwner = currentRoom.isOwner(targetUid);
    final isTargetDeputy = currentRoom.isDeputy(targetUid);

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
                leading: const Icon(Icons.person_pin_outlined, color: Colors.blue),
                title: const Text('Xem trang cá nhân'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserWallScreen(
                        targetUser: UserModel(
                          uid: targetUid,
                          displayName: targetName,
                          email: '',
                          photoUrl: '',
                          lastSeen: DateTime.now(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
                title: const Text('Nhắn tin riêng'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final directRoomId = await _chatService.getOrCreateDirectRoom(
                    currentUser: currentUser,
                    otherUser: UserModel(
                      uid: targetUid,
                      displayName: targetName,
                      email: '',
                      photoUrl: '',
                      lastSeen: DateTime.now(),
                    ),
                  );
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          room: ChatRoomModel(
                            id: directRoomId,
                            name: targetName,
                            type: ChatRoomType.direct,
                            memberIds: [currentUser.uid, targetUid],
                            createdAt: DateTime.now(),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),

              // Thao tác chỉ dành cho Trưởng nhóm
              if (isCurrentUserOwner) ...[
                const Divider(),
                // Chuyển giao Trưởng nhóm
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, color: Colors.amber),
                  title: const Text('Chuyển giao quyền Trưởng nhóm (Key chính)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmTransferOwnership(currentRoom, currentUser, targetUid, targetName);
                  },
                ),
                // Bổ nhiệm / Gỡ Phó nhóm
                if (isTargetDeputy)
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: Colors.orange),
                    title: const Text('Gỡ quyền Phó nhóm'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _chatService.revokeDeputy(
                        roomId: currentRoom.id,
                        currentOwnerId: currentUser.uid,
                        targetUserId: targetUid,
                        targetUserName: targetName,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã gỡ quyền Phó nhóm của $targetName')),
                        );
                      }
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.shield, color: Colors.blueAccent),
                    title: Text('Bổ nhiệm làm Phó nhóm (${currentRoom.deputyIds.length}/10)'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (currentRoom.deputyIds.length >= 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã đạt giới hạn tối đa 10 Phó nhóm!')),
                        );
                        return;
                      }
                      await _chatService.appointDeputy(
                        roomId: currentRoom.id,
                        currentOwnerId: currentUser.uid,
                        targetUserId: targetUid,
                        targetUserName: targetName,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cấp key Phó nhóm cho $targetName')),
                        );
                      }
                    },
                  ),
                // Xóa khỏi nhóm
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                  title: const Text('Mời ra khỏi nhóm', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmKickMember(currentRoom, currentUser, targetUid, targetName);
                  },
                ),
              ],

              // Thao tác dành cho Phó nhóm đối với thành viên thường
              if (isCurrentUserDeputy && !isTargetOwner && !isTargetDeputy) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                  title: const Text('Mời ra khỏi nhóm', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmKickMember(currentRoom, currentUser, targetUid, targetName);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Xác nhận chuyển quyền Trưởng nhóm
  void _confirmTransferOwnership(ChatRoomModel currentRoom, UserModel currentUser, String targetUid, String targetName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chuyển giao quyền Trưởng nhóm'),
        content: Text('Bạn có chắc chắn muốn trao lại Key Trưởng nhóm cho "$targetName"?\nSau khi chuyển, bạn sẽ trở thành thành viên thông thường.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatService.transferGroupOwnership(
                roomId: currentRoom.id,
                currentOwnerId: currentUser.uid,
                currentOwnerName: currentUser.displayName,
                newOwnerId: targetUid,
                newOwnerName: targetName,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã chuyển giao Trưởng nhóm cho $targetName')),
                );
              }
            },
            child: const Text('Đồng ý trao Key'),
          ),
        ],
      ),
    );
  }

  // Xác nhận đuổi thành viên
  void _confirmKickMember(ChatRoomModel currentRoom, UserModel currentUser, String targetUid, String targetName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mời ra khỏi nhóm'),
        content: Text('Bạn có chắc chắn muốn mời "$targetName" rời khỏi nhóm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatService.removeMemberFromGroup(
                roomId: currentRoom.id,
                admin: currentUser,
                targetUserId: targetUid,
                targetUserName: targetName,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa $targetName khỏi nhóm')),
                );
              }
            },
            child: const Text('Mời ra'),
          ),
        ],
      ),
    );
  }

  // Tự rời nhóm
  void _handleLeaveGroup(ChatRoomModel currentRoom, UserModel currentUser) {
    final isOwner = currentRoom.isOwner(currentUser.uid);
    final remainingMembers = currentRoom.memberIds.where((id) => id != currentUser.uid).toList();

    if (!isOwner) {
      // Thành viên hoặc phó nhóm rời nhóm bình thường
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rời khỏi nhóm?'),
          content: const Text('Bạn sẽ không thể tiếp tục nhận hoặc gửi tin nhắn trong nhóm này nữa.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx); // đóng dialog
                await _chatService.leaveGroup(
                  roomId: currentRoom.id,
                  userId: currentUser.uid,
                  userName: currentUser.displayName,
                );
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Rời nhóm'),
            ),
          ],
        ),
      );
      return;
    }

    // Trường hợp Trưởng nhóm rời nhóm:
    if (remainingMembers.isEmpty) {
      // Là thành viên duy nhất
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Giải tán nhóm?'),
          content: const Text('Bạn là thành viên duy nhất. Khi bạn rời đi, nhóm này sẽ bị giải tán hoàn toàn.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                await _chatService.leaveGroup(
                  roomId: currentRoom.id,
                  userId: currentUser.uid,
                  userName: currentUser.displayName,
                );
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Giải tán & Rời'),
            ),
          ],
        ),
      );
      return;
    }

    // Trưởng nhóm phải chuyển giao Key hoặc chọn ngẫu nhiên
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.amber),
            SizedBox(width: 8),
            Text('Chuyển giao quyền Trưởng nhóm'),
          ],
        ),
        content: const Text(
          'Bạn đang là Trưởng nhóm. Trước khi rời nhóm, bạn cần chọn người tiếp quản giữ Key Trưởng nhóm, hoặc để hệ thống tự động chọn ngẫu nhiên một thành viên còn lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Rời và để hệ thống chọn ngẫu nhiên
              await _chatService.leaveGroup(
                roomId: currentRoom.id,
                userId: currentUser.uid,
                userName: currentUser.displayName,
                newOwnerId: null, // Sẽ tự động shuffle ngẫu nhiên
              );
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Rời & Chọn ngẫu nhiên'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _showPickSuccessorDialog(currentRoom, currentUser, remainingMembers);
            },
            child: const Text('Tự chọn người tiếp quản'),
          ),
        ],
      ),
    );
  }

  // Chọn thành viên kế nhiệm Key Trưởng nhóm trước khi rời
  void _showPickSuccessorDialog(ChatRoomModel currentRoom, UserModel currentUser, List<String> remainingUids) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn Trưởng nhóm mới'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: remainingUids.length,
            itemBuilder: (context, index) {
              final uid = remainingUids[index];
              final name = currentRoom.memberNames[uid] ?? 'Thành viên $uid';
              final isDeputy = currentRoom.isDeputy(uid);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: isDeputy ? const Text('🛡️ Phó nhóm', style: TextStyle(color: Colors.blueAccent)) : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final nav = Navigator.of(context);
                  Navigator.pop(ctx);
                  await _chatService.leaveGroup(
                    roomId: currentRoom.id,
                    userId: currentUser.uid,
                    userName: currentUser.displayName,
                    newOwnerId: uid,
                  );
                  if (mounted) {
                    nav.popUntil((route) => route.isFirst);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.room.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final room = ChatRoomModel.fromMap(snapshot.data!.data()!, snapshot.data!.id);
        final isOwner = room.isOwner(currentUser.uid);
        final isAdmin = room.isAdmin(currentUser.uid);
        final canAddMembers = !room.onlyAdminsCanAddMembers || isAdmin;

        final filteredMemberIds = room.memberIds.where((uid) {
          final name = room.memberNames[uid] ?? '';
          return name.toLowerCase().contains(_memberQuery);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cài Đặt Nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // Thông tin Header nhóm
              Container(
                color: Theme.of(context).cardTheme.color,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AvatarWidget(
                          photoUrl: room.photoUrl,
                          name: room.name,
                          radius: 46,
                        ),
                        if (isAdmin)
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            room.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Đổi tên nhóm',
                            onPressed: () => _editGroupName(room),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.memberIds.length} thành viên • ${room.deputyIds.length}/10 Phó nhóm',
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tùy chọn quyền nhóm Zalo (Chỉ Trưởng & Phó nhóm mới chỉnh được)
              if (isAdmin) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    'QUYỀN QUẢN TRỊ VIÊN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.lock_person_outlined, color: Colors.indigo),
                        title: const Text('Chỉ Trưởng/Phó nhóm được gửi tin nhắn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Thành viên thường chỉ được xem, không thể gửi tin nhắn', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: room.onlyAdminsCanMessage,
                        onChanged: (val) async {
                          await _chatService.updateGroupSettings(roomId: room.id, onlyAdminsCanMessage: val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.group_add_outlined, color: Colors.teal),
                        title: const Text('Chỉ Trưởng/Phó nhóm được thêm người', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Ngăn thành viên thường tự ý mời người lạ vào nhóm', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        value: room.onlyAdminsCanAddMembers,
                        onChanged: (val) async {
                          await _chatService.updateGroupSettings(roomId: room.id, onlyAdminsCanAddMembers: val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Danh sách thành viên
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'THÀNH VIÊN (${room.memberIds.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    if (canAddMembers)
                      TextButton.icon(
                        onPressed: () => _openAddMembersDialog(room, currentUser),
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Thêm thành viên', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

              // Tìm thành viên
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchMemberController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thành viên trong nhóm...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _memberQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchMemberController.clear();
                              setState(() => _memberQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _memberQuery = val.trim().toLowerCase()),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredMemberIds.length,
                  separatorBuilder: (_, __) => const Divider(indent: 68, height: 1),
                  itemBuilder: (context, idx) {
                    final uid = filteredMemberIds[idx];
                    final name = room.memberNames[uid] ?? 'Thành viên $uid';
                    final isMemberOwner = room.isOwner(uid);
                    final isMemberDeputy = room.isDeputy(uid);
                    final isMe = uid == currentUser.uid;

                    return ListTile(
                      leading: AvatarWidget(
                        name: name,
                        radius: 20,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMe ? '$name (Bạn)' : name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isMemberOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade700, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('👑', style: TextStyle(fontSize: 10)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Trưởng nhóm',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ),
                            )
                          else if (isMemberDeputy)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade600, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🛡️', style: TextStyle(fontSize: 10)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Phó nhóm',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      subtitle: isMe
                          ? const Text('Tài khoản hiện tại', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                          : null,
                      trailing: isMe
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onPressed: () => _showMemberActions(room, currentUser, uid, name),
                            ),
                      onTap: () {
                        if (!isMe) {
                          _showMemberActions(room, currentUser, uid, name);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Nút Rời nhóm (Đỏ - Zalo style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(
                    isOwner ? 'Rời nhóm & Trao lại Key' : 'Rời khỏi nhóm',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () => _handleLeaveGroup(room, currentUser),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
