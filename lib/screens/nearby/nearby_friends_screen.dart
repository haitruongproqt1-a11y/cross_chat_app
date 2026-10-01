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
  String _selectedAgeGroup = 'Tất cả';
  String _hometownFilter = 'Tất cả';
  bool _isLocating = false;

  static const List<String> vietnamProvinces = [
    'Tất cả',
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
    'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
    'Bình Thuận', 'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông',
    'Điện Biên', 'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang',
    'Hà Nam', 'Hà Tĩnh', 'Hải Dương', 'Hậu Giang', 'Hòa Bình',
    'Hưng Yên', 'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu',
    'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
    'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên',
    'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị',
    'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên',
    'Thanh Hóa', 'Thừa Thiên Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái'
  ];

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
                if (_hometownFilter.trim().isNotEmpty && _hometownFilter != 'Tất cả') {
                  final query = _hometownFilter.trim().toLowerCase();
                  users = users.where((u) => u.hometown.toLowerCase().contains(query)).toList();
                }

                // Lọc theo độ tuổi
                if (_selectedAgeGroup != 'Tất cả') {
                  final nowYear = DateTime.now().year;
                  users = users.where((u) {
                    if (u.birthYear == null) return false;
                    final age = nowYear - u.birthYear!;
                    if (_selectedAgeGroup == '18 - 25 tuổi') return age >= 18 && age <= 25;
                    if (_selectedAgeGroup == '26 - 35 tuổi') return age >= 26 && age <= 35;
                    if (_selectedAgeGroup == '36 - 50 tuổi') return age >= 36 && age <= 50;
                    if (_selectedAgeGroup == 'Trên 50 tuổi') return age > 50;
                    return true;
                  }).toList();
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
    String tempAge = _selectedAgeGroup;
    String tempProvince = _hometownFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Bộ Lọc Bạn Bè Quanh Đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Lọc theo Giới tính
                        const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['Tất cả', 'Nam', 'Nữ', 'Khác'].map((g) {
                            final isSel = tempGender == g;
                            return ChoiceChip(
                              label: Text(g),
                              selected: isSel,
                              selectedColor: Colors.blueAccent,
                              labelStyle: TextStyle(color: isSel ? Colors.white : null),
                              onSelected: (val) {
                                if (val) setModalState(() => tempGender = g);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Lọc theo Độ tuổi
                        const Text('Độ tuổi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Tất cả', '18 - 25 tuổi', '26 - 35 tuổi', '36 - 50 tuổi', 'Trên 50 tuổi'].map((a) {
                            final isSel = tempAge == a;
                            return ChoiceChip(
                              label: Text(a),
                              selected: isSel,
                              selectedColor: Colors.blueAccent,
                              labelStyle: TextStyle(color: isSel ? Colors.white : null),
                              onSelected: (val) {
                                if (val) setModalState(() => tempAge = a);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Lọc theo Tỉnh thành phố (63 tỉnh thành VN)
                        const Text('Quê quán / Tỉnh thành:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400, width: 0.8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: vietnamProvinces.contains(tempProvince) ? tempProvince : 'Tất cả',
                              icon: const Icon(Icons.arrow_drop_down),
                              items: vietnamProvinces.map((prov) {
                                return DropdownMenuItem<String>(
                                  value: prov,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_city, size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Text(prov),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => tempProvince = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nút Đặt lại và Áp dụng (Có đệm phím ảo chuẩn Android)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGender = 'Tất cả';
                                    _selectedAgeGroup = 'Tất cả';
                                    _hometownFilter = 'Tất cả';
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Đặt lại', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedGender = tempGender;
                                    _selectedAgeGroup = tempAge;
                                    _hometownFilter = tempProvince;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Áp dụng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
