import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String _searchType = 'all'; // 'all', 'email', 'name', 'id'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await _chatService.searchUsers(
      currentUserId: currentUser.uid,
      query: q,
    );

    // Lọc theo searchType nếu có
    final filtered = results.where((u) {
      if (_searchType == 'email') return u.email.toLowerCase().contains(q.toLowerCase());
      if (_searchType == 'name') return u.displayName.toLowerCase().contains(q.toLowerCase());
      if (_searchType == 'id') return u.uid.toLowerCase().contains(q.toLowerCase());
      return true;
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    }
  }

  void _openChatWithUser(UserModel targetUser) async {
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

    if (ResponsiveLayout.isDesktop(context)) {
      Provider.of<ChatProvider>(context, listen: false).setActiveRoom(room);
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(room: room)),
      );
    }
  }

  void _showMyQrCode(UserModel currentUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mã QR Cá Nhân', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=kini:${currentUser.uid}',
                  width: 180,
                  height: 180,
                  placeholder: (_, __) => const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.qr_code, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(currentUser.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(currentUser.email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID: ${currentUser.uid.substring(0, currentUser.uid.length > 12 ? 12 : currentUser.uid.length)}...', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Sao chép ID đầy đủ',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: currentUser.uid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép ID cá nhân vào bộ nhớ tạm')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Kiếm & Kết Bạn', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
            tooltip: 'Mã QR của tôi',
            onPressed: () => _showMyQrCode(currentUser),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thẻ thông tin ID cá nhân & nút chia sẻ QR
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary.withAlpha(20), theme.colorScheme.primary.withAlpha(5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
            ),
            child: Row(
              children: [
                AvatarWidget(name: currentUser.displayName, photoUrl: currentUser.photoUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Gmail: ${currentUser.email}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('ID: ${currentUser.uid}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Mã QR', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showMyQrCode(currentUser),
                ),
              ],
            ),
          ),

          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập Gmail, Tên hoặc ID người dùng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) => _performSearch(val),
              onSubmitted: (val) => _performSearch(val),
            ),
          ),

          // Bộ lọc loại tìm kiếm (Chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _searchType == 'all',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _searchType = 'all');
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Theo Gmail'),
                    selected: _searchType == 'email',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _searchType = 'email');
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Theo Tên'),
                    selected: _searchType == 'name',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _searchType = 'name');
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Theo ID Cá Nhân'),
                    selected: _searchType == 'id',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _searchType = 'id');
                        _performSearch(_searchController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 20),

          // Danh sách kết quả tìm kiếm
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.trim().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Nhập Gmail, Tên hoặc ID để tìm kiếm bạn bè',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy người dùng phù hợp với "${_searchController.text}"',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: AvatarWidget(
                                  name: user.displayName,
                                  photoUrl: user.photoUrl,
                                  radius: 24,
                                ),
                                title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Gmail: ${user.email}', style: const TextStyle(fontSize: 12)),
                                    Text('ID: ${user.uid}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.chat, size: 16),
                                  label: const Text('Nhắn tin'),
                                  onPressed: () => _openChatWithUser(user),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
