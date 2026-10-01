import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/avatar_widget.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nhóm chat')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thành viên tham gia nhóm')),
      );
      return;
    }

    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.createGroupChat(
        groupName: name,
        creator: currentUser,
        selectedMembers: _selectedUsers,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo nhóm: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Nhóm Trò Chuyện'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tạo nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Icon(Icons.group, size: 28, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên nhóm trò chuyện...',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Chọn Thành Viên (${_selectedUsers.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: currentUser == null
                ? const SizedBox.shrink()
                : StreamBuilder<List<UserModel>>(
                    stream: _chatService.getAllUsers(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return const Center(child: Text('Không có liên hệ nào để thêm.', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelected = _selectedUsers.any((u) => u.uid == user.uid);

                          return ListTile(
                            leading: AvatarWidget(
                              name: user.displayName,
                              photoUrl: user.photoUrl,
                              isOnline: user.isOnline,
                              showBadge: true,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text(user.statusMessage, maxLines: 1),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUsers.add(user);
                                  } else {
                                    _selectedUsers.removeWhere((u) => u.uid == user.uid);
                                  }
                                });
                              },
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
