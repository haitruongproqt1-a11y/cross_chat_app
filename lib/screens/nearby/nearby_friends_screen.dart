import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';

class NearbyFriendsScreen extends StatefulWidget {
  const NearbyFriendsScreen({super.key});

  @override
  State<NearbyFriendsScreen> createState() => _NearbyFriendsScreenState();
}

class _NearbyFriendsScreenState extends State<NearbyFriendsScreen> {
  final ChatService _chatService = ChatService();
  final LocationService _locationService = LocationService();

  String _selectedGender = 'Tất cả';
  String _hometownFilter = '';
  int? _minBirthYear;
  int? _maxBirthYear;
  bool _isLocating = false;

  void _updateMyLocation() async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    setState(() => _isLocating = true);
    final pos = await _locationService.getCurrentLocation();
    setState(() => _isLocating = false);

    if (pos != null) {
      await _chatService.updateUserLocation(currentUser.uid, pos.latitude, pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật vị trí GPS thành công!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy vị trí. Vui lòng bật GPS và cấp quyền.')),
        );
      }
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
      if (Navigator.canPop(context)) Navigator.pop(context);
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
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Bạn Quanh Đây'),
        actions: [
          IconButton(
            icon: _isLocating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            tooltip: 'Cập nhật vị trí của tôi',
            onPressed: _isLocating ? null : _updateMyLocation,
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Bộ lọc tìm kiếm',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner trạng thái vị trí
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primary.withAlpha(25),
            child: Row(
              children: [
                Icon(Icons.radar, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentUser.latitude != null
                        ? 'Đang tìm kiếm quanh tọa độ của bạn (Bộ lọc: $_selectedGender)'
                        : 'Bạn chưa bật định vị GPS. Nhấn biểu tượng định vị ở góc trên để cập nhật.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách bạn bè tìm kiếm
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getAllUsers(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data ?? [];

                // Lọc theo giới tính
                if (_selectedGender != 'Tất cả') {
                  users = users.where((u) => u.gender == _selectedGender).toList();
                }

                // Lọc theo quê quán
                if (_hometownFilter.trim().isNotEmpty) {
                  final query = _hometownFilter.trim().toLowerCase();
                  users = users.where((u) => u.hometown.toLowerCase().contains(query)).toList();
                }

                // Lọc theo năm sinh
                if (_minBirthYear != null) {
                  users = users.where((u) => (u.birthYear ?? 0) >= _minBirthYear!).toList();
                }
                if (_maxBirthYear != null) {
                  users = users.where((u) => (u.birthYear ?? 9999) <= _maxBirthYear!).toList();
                }

                // Tính khoảng cách và sắp xếp từ gần đến xa
                final userDistances = <String, double>{};
                if (currentUser.latitude != null && currentUser.longitude != null) {
                  for (var u in users) {
                    if (u.latitude != null && u.longitude != null) {
                      final dist = ChatService.calculateDistanceKm(
                        currentUser.latitude!,
                        currentUser.longitude!,
                        u.latitude!,
                        u.longitude!,
                      );
                      userDistances[u.uid] = dist;
                    } else {
                      userDistances[u.uid] = 999999; // Chưa có vị trí xếp sau
                    }
                  }

                  users.sort((a, b) {
                    final d1 = userDistances[a.uid] ?? 999999;
                    final d2 = userDistances[b.uid] ?? 999999;
                    return d1.compareTo(d2);
                  });
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('Không tìm thấy bạn bè nào phù hợp với bộ lọc.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final dist = userDistances[user.uid];
                    final distanceText = (dist != null && dist < 99999)
                        ? (dist < 1 ? '${(dist * 1000).toInt()} m' : '${dist.toStringAsFixed(1)} km')
                        : 'Chưa có vị trí';

                    return ListTile(
                      leading: AvatarWidget(
                        name: user.displayName,
                        photoUrl: user.photoUrl,
                        isOnline: user.isOnline,
                        showBadge: true,
                        radius: 24,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              distanceText,
                              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (user.gender != 'Chưa xác định') ...[
                                Text(user.gender, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 8),
                              ],
                              if (user.birthYear != null) ...[
                                Text('Năm sinh: ${user.birthYear}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 8),
                              ],
                              if (user.hometown.isNotEmpty) ...[
                                Text('Quê: ${user.hometown}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ],
                          ),
                          Text(user.statusMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => _openChatWithUser(user),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Nhắn tin', style: TextStyle(fontSize: 12)),
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

  void _showFilterDialog() {
    String tempGender = _selectedGender;
    final hometownCtrl = TextEditingController(text: _hometownFilter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bộ Lọc Bạn Bè Quanh Đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: ['Tất cả', 'Nam', 'Nữ', 'Khác'].map((g) {
                      return ChoiceChip(
                        label: Text(g),
                        selected: tempGender == g,
                        onSelected: (val) {
                          if (val) setModalState(() => tempGender = g);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hometownCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quê quán / Tỉnh thành',
                      hintText: 'Ví dụ: Hà Nội, Đà Nẵng, TP.HCM...',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGender = 'Tất cả';
                              _hometownFilter = '';
                              _minBirthYear = null;
                              _maxBirthYear = null;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGender = tempGender;
                              _hometownFilter = hometownCtrl.text;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
