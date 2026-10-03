import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';
import '../wall/user_wall_screen.dart';

class NearbyFriendsScreen extends StatefulWidget {
  const NearbyFriendsScreen({super.key});

  @override
  State<NearbyFriendsScreen> createState() => _NearbyFriendsScreenState();
}

class _NearbyFriendsScreenState extends State<NearbyFriendsScreen> {
  final ChatService _chatService = ChatService();
  final LocationService _locationService = LocationService();

  // Tab: 0 = Khám phá, 1 = Tôi
  int _currentTab = 0;

  // Search & Filters cho Khám phá
  final TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'Tất cả';
  double _selectedRadiusKm = 50.0;
  String _selectedProvince = 'Tất cả';
  String _selectedAgeRange = '18–100 tuổi';
  String _selectedMaritalStatus = 'Tất cả';
  bool _sortByNearToFar = true;
  bool _showLocationBanner = true;

  // Controllers cho Tab Tôi
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  String _myGender = 'Chưa xác định';
  String _myMaritalStatus = 'Độc thân';
  String _myProvince = 'Quảng Trị';

  bool _isLocating = false;
  bool _isSavingProfile = false;
  bool _initializedProfile = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedProfile) {
      final user = Provider.of<AuthProvider>(context).currentUser;
      if (user != null) {
        _myGender = user.gender.isNotEmpty ? user.gender : 'Nam';
        _myMaritalStatus = user.maritalStatus.isNotEmpty ? user.maritalStatus : 'Đã kết hôn';
        _myProvince = user.hometown.isNotEmpty ? user.hometown : 'Quảng Trị';
        _birthYearController.text = user.birthYear != null ? user.birthYear.toString() : '1994';
        _bioController.text = user.bio;
        _jobController.text = user.job;
        _initializedProfile = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _birthYearController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  // Cập nhật vị trí GPS
  void _updateMyLocation() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isLocating = true);
    final pos = await _locationService.getCurrentLocation();
    setState(() => _isLocating = false);

    if (pos != null) {
      await _chatService.updateUserLocation(user.uid, pos.latitude, pos.longitude);
      await auth.updateProfile(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vị trí GPS KINI đã sẵn sàng và được cập nhật thành công!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy vị trí. Vui lòng bật Dịch vụ vị trí trên máy.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Lưu hồ sơ Tab Tôi
  void _saveMyProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSavingProfile = true);
    final int? bYear = int.tryParse(_birthYearController.text.trim());

    await auth.updateProfile(
      gender: _myGender,
      maritalStatus: _myMaritalStatus,
      hometown: _myProvince,
      birthYear: bYear,
      bio: _bioController.text.trim(),
      job: _jobController.text.trim(),
    );

    setState(() => _isSavingProfile = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông tin hồ sơ KINI thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedGender = 'Tất cả';
      _selectedRadiusKm = 50.0;
      _selectedProvince = 'Tất cả';
      _selectedAgeRange = '18–100 tuổi';
      _selectedMaritalStatus = 'Tất cả';
      _sortByNearToFar = true;
      _searchController.clear();
    });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Thanh chuyển Tab pill chuẩn: [Khám phá] | [Tôi]
            _buildTopTabSegment(),
            const SizedBox(height: 12),

            Expanded(
              child: _currentTab == 0
                  ? _buildKhamPhaTab(currentUser, theme)
                  : _buildToiTab(currentUser, theme),
            ),
          ],
        ),
      ),
    );
  }

  // Segment Tab Pill [Khám phá] | [Tôi]
  Widget _buildTopTabSegment() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 0),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _currentTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Khám phá',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _currentTab == 0 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 1),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: _currentTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _currentTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tôi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _currentTab == 1 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: KHÁM PHÁ (Image 1) =================
  Widget _buildKhamPhaTab(UserModel currentUser, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Location Status Bar (Stitch UI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.navigation, color: Color(0xFF0284C7), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProvince == 'Tất cả' ? (currentUser.hometown.isNotEmpty ? currentUser.hometown : 'Việt Nam') : _selectedProvince,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Định vị chính xác • Bán kính ${_selectedRadiusKm.toInt()}km',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                          SizedBox(width: 4),
                          Text(
                            'Online',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Concentric Radar Graphic (Stitch UI)
              _buildRadarGraphic(currentUser),
              const SizedBox(height: 16),

              // Tiêu đề & Subtitle
              const Text(
                'Gặp người phù hợp ngay quanh đây',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '50 km và 100 km luôn FREE cho mọi tài khoản KINI.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              // Ô tìm kiếm theo tên, khu vực
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, khu vực',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Hàng Filter Chips 1: Giới tính, Bán kính, Tỉnh thành, Tuổi
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: _selectedGender == 'Tất cả' ? 'Giới tính' : _selectedGender,
                      onTap: _showGenderPicker,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: '${_selectedRadiusKm.toInt()} km',
                      onTap: _showRadiusPicker,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: _selectedProvince == 'Tất cả' ? 'Tỉnh thành' : _selectedProvince,
                      onTap: _showProvincePicker,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: _selectedAgeRange,
                      onTap: _showAgePicker,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Hàng Filter Chips 2: Tình trạng, Gần đến xa
              Row(
                children: [
                  _buildFilterChip(
                    label: _selectedMaritalStatus == 'Tất cả' ? 'Tình trạng' : _selectedMaritalStatus,
                    onTap: _showMaritalStatusPicker,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _sortByNearToFar ? 'Gần đến xa' : 'Xa đến gần',
                    onTap: () => setState(() => _sortByNearToFar = !_sortByNearToFar),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Hàng Xóa bộ lọc & Nút Tìm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'Xóa bộ lọc',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                    ),
                    child: const Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thông báo nếu tài khoản chưa bật chia sẻ vị trí
              if (!currentUser.shareLocation)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.visibility_off_outlined, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bạn đang tắt chia sẻ vị trí (Ẩn danh). Người khác không thể tìm thấy bạn cho tới khi bạn bật tại tab "Tôi".',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Danh sách người dùng thỏa mãn điều kiện
              StreamBuilder<List<UserModel>>(
                stream: _chatService.getAllUsers(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                  }

                  final allUsers = snapshot.data ?? [];

                  // LỌC NGHIÊM NGẶT: Chỉ người dùng có shareLocation == true và có tọa độ GPS mới được hiển thị!
                  final filteredUsers = allUsers.where((u) {
                    // QUY TẮC CỦA NGƯỜI DÙNG: "người nào muốn chia sẽ mới tìm được, còn người nào không chia sẽ thì không thể tìm được"
                    if (!u.shareLocation) return false;
                    if (u.latitude == null || u.longitude == null) return false;

                    // Lọc tìm kiếm theo tên hoặc khu vực
                    final q = _searchController.text.trim().toLowerCase();
                    if (q.isNotEmpty) {
                      final matchName = u.displayName.toLowerCase().contains(q);
                      final matchTown = u.hometown.toLowerCase().contains(q);
                      final matchUsername = u.username.toLowerCase().contains(q);
                      if (!matchName && !matchTown && !matchUsername) return false;
                    }

                    // Lọc Giới tính
                    if (_selectedGender != 'Tất cả' && u.gender != _selectedGender) {
                      return false;
                    }

                    // Lọc Tỉnh thành
                    if (_selectedProvince != 'Tất cả' && !u.hometown.toLowerCase().contains(_selectedProvince.toLowerCase())) {
                      return false;
                    }

                    // Lọc Tình trạng hôn nhân
                    if (_selectedMaritalStatus != 'Tất cả' && u.maritalStatus != _selectedMaritalStatus) {
                      return false;
                    }

                    // Lọc Tuổi
                    if (_selectedAgeRange != '18–100 tuổi' && u.birthYear != null) {
                      final age = DateTime.now().year - u.birthYear!;
                      if (_selectedAgeRange == '18–25' && (age < 18 || age > 25)) return false;
                      if (_selectedAgeRange == '26–35' && (age < 26 || age > 35)) return false;
                      if (_selectedAgeRange == '36–50' && (age < 36 || age > 50)) return false;
                      if (_selectedAgeRange == '50+' && age < 50) return false;
                    }

                    // Lọc Bán kính GPS (nếu người dùng hiện tại có GPS)
                    if (currentUser.latitude != null && currentUser.longitude != null) {
                      final dist = ChatService.calculateDistanceKm(
                        currentUser.latitude!,
                        currentUser.longitude!,
                        u.latitude!,
                        u.longitude!,
                      );
                      if (dist > _selectedRadiusKm) return false;
                    }

                    return true;
                  }).toList();

                  // Sắp xếp theo khoảng cách
                  if (currentUser.latitude != null && currentUser.longitude != null) {
                    filteredUsers.sort((a, b) {
                      final distA = ChatService.calculateDistanceKm(currentUser.latitude!, currentUser.longitude!, a.latitude!, a.longitude!);
                      final distB = ChatService.calculateDistanceKm(currentUser.latitude!, currentUser.longitude!, b.latitude!, b.longitude!);
                      return _sortByNearToFar ? distA.compareTo(distB) : distB.compareTo(distA);
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bộ đếm kết quả như Image 1: "2 người trong phạm vi 50 km"
                      Text(
                        '${filteredUsers.length} người trong phạm vi ${_selectedRadiusKm.toInt()} km',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (filteredUsers.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.person_search_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa tìm thấy người phù hợp quanh đây',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Thử mở rộng bán kính tìm kiếm hoặc thay đổi bộ lọc.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final u = filteredUsers[index];
                            double dist = 0.0;
                            if (currentUser.latitude != null && currentUser.longitude != null) {
                              dist = ChatService.calculateDistanceKm(
                                currentUser.latitude!,
                                currentUser.longitude!,
                                u.latitude!,
                                u.longitude!,
                              );
                            }

                            return _buildUserCard(u, dist);
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Banner Dịch vụ vị trí ở đáy màn hình như Image 1
        if (_showLocationBanner) _buildLocationNoticeBanner(),
      ],
    );
  }

  // Thẻ User chuẩn Image 1
  Widget _buildUserCard(UserModel user, double distanceKm) {
    final initials = user.displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final provinceStr = user.hometown.isNotEmpty ? user.hometown.toUpperCase() : 'VIỆT NAM';
    final birthStr = user.birthYear != null ? user.birthYear.toString() : '199x';
    final genderStr = user.gender.isNotEmpty && user.gender != 'Chưa xác định' ? user.gender : 'Bạn mới';

    return InkWell(
      onTap: () => _showUserDetailDialog(user, distanceKm),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar hình tròn có chữ cái viết tắt hoặc ảnh
            user.photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      user.photoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
                    ),
                  )
                : _buildInitialsAvatar(initials),
            const SizedBox(width: 14),

            // Thông tin ở giữa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$provinceStr · Thành viên KINI',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$genderStr · $birthStr',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),

            // Khoảng cách bên phải (0.1 km, 45.1 km) & Mũi tên >
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFF6366F1), // Tím nhạt nổi bật như trong hình chụp Hải Trường (HT)
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : 'K',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= TAB 2: TÔI (Image 2) =================
  Widget _buildToiTab(UserModel currentUser, ThemeData theme) {
    final hasGps = currentUser.latitude != null && currentUser.longitude != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Header Card Profile của Tôi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      name: currentUser.displayName,
                      photoUrl: currentUser.photoUrl,
                      radius: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasGps ? 'Vị trí KINI đã sẵn sàng' : 'Chưa bật định vị GPS',
                            style: TextStyle(
                              fontSize: 13,
                              color: hasGps ? const Color(0xFF10B981) : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icon định vị GPS
                    IconButton(
                      icon: _isLocating
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, color: Color(0xFF0284C7), size: 26),
                      tooltip: 'Cập nhật tọa độ GPS ngay',
                      onPressed: _isLocating ? null : _updateMyLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ các trường thông tin hồ sơ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildProfilePickItem('Giới tính', _myGender, () {
                      _showPickDialog('Chọn giới tính', ['Nam', 'Nữ', 'Khác'], (v) {
                        setState(() => _myGender = v);
                      });
                    }),
                    const Divider(height: 1),
                    _buildProfilePickItem('Tình trạng', _myMaritalStatus, () {
                      _showPickDialog('Chọn tình trạng', AppConstants.maritalStatusList, (v) {
                        setState(() => _myMaritalStatus = v);
                      });
                    }),
                    const Divider(height: 1),
                    _buildProfilePickItem('Tỉnh thành', _myProvince, () {
                      _showPickDialog('Chọn tỉnh thành', AppConstants.vietnamProvinces.where((p) => p != 'Tất cả').toList(), (v) {
                        setState(() => _myProvince = v);
                      });
                    }),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Năm sinh
                    _buildProfileInputLabel('Năm sinh'),
                    TextField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: _profileFieldDecoration(hintText: '1994'),
                    ),
                    const SizedBox(height: 14),

                    // Giới thiệu
                    _buildProfileInputLabel('Giới thiệu'),
                    TextField(
                      controller: _bioController,
                      maxLines: 2,
                      decoration: _profileFieldDecoration(hintText: 'Một vài điều về bạn'),
                    ),
                    const SizedBox(height: 14),

                    // Công việc
                    _buildProfileInputLabel('Công việc'),
                    TextField(
                      controller: _jobController,
                      decoration: _profileFieldDecoration(hintText: 'Ví dụ: Thiết kế'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút Lưu Hồ Sơ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSavingProfile ? null : _saveMyProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSavingProfile
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Lưu Hồ Sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // Quyền riêng tư chia sẻ vị trí
              const Text(
                'Quyền riêng tư',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.share_location, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cho phép tìm quanh đây',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Khi bật, người quanh đây có thể thấy bạn. Khi tắt, bạn hoàn toàn ẩn danh.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: currentUser.shareLocation,
                      activeThumbColor: const Color(0xFF0284C7),
                      onChanged: (val) async {
                        await Provider.of<AuthProvider>(context, listen: false).updateProfile(shareLocation: val);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Đã bật chia sẻ vị trí quanh đây!' : 'Đã tắt chia sẻ vị trí (Bạn đang ẩn danh).'),
                              backgroundColor: val ? const Color(0xFF10B981) : Colors.blueGrey,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Banner thông báo vị trí ở đáy
        if (_showLocationBanner) _buildLocationNoticeBanner(),
      ],
    );
  }

  // Banner thông báo vị trí ở đáy như Image 1 & 2
  Widget _buildLocationNoticeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Hãy bật Dịch vụ vị trí trên điện thoại rồi thử lại.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showLocationBanner = false),
            child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePickItem(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ),
    );
  }

  InputDecoration _profileFieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }

  // Dialogs chọn lọc
  void _showGenderPicker() {
    _showPickDialog('Chọn giới tính', ['Tất cả', 'Nam', 'Nữ', 'Khác'], (v) {
      setState(() => _selectedGender = v);
    });
  }

  void _showRadiusPicker() {
    _showPickDialog('Chọn phạm vi khoảng cách', ['10 km', '20 km', '50 km', '100 km', '200 km', '500 km'], (v) {
      final numVal = double.tryParse(v.replaceAll(' km', '')) ?? 50.0;
      setState(() => _selectedRadiusKm = numVal);
    });
  }

  void _showProvincePicker() {
    _showPickDialog('Chọn tỉnh thành', AppConstants.vietnamProvinces, (v) {
      setState(() => _selectedProvince = v);
    });
  }

  void _showAgePicker() {
    _showPickDialog('Chọn độ tuổi', ['18–100 tuổi', '18–25', '26–35', '36–50', '50+'], (v) {
      setState(() => _selectedAgeRange = v);
    });
  }

  void _showMaritalStatusPicker() {
    _showPickDialog('Chọn tình trạng', ['Tất cả', ...AppConstants.maritalStatusList], (v) {
      setState(() => _selectedMaritalStatus = v);
    });
  }

  void _showPickDialog(String title, List<String> options, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final opt = options[i];
                  return ListTile(
                    title: Text(opt),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(opt);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailDialog(UserModel user, double distanceKm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarWidget(name: user.displayName, photoUrl: user.photoUrl, radius: 36),
              const SizedBox(height: 12),
              Text(user.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${user.gender} · ${user.birthYear ?? "Chưa rõ năm sinh"} · ${user.hometown.isNotEmpty ? user.hometown : "Việt Nam"}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Cách bạn khoảng ${distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('"${user.bio}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF334155))),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_pin),
                      label: const Text('Xem trang'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserWallScreen(targetUser: user)));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Nhắn tin'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openChatWithUser(user);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarGraphic(UserModel currentUser) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        ),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0284C7).withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Rings
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7DD3FC).withAlpha(120), width: 1.2),
            ),
          ),
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withAlpha(140), width: 1.2),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0284C7).withAlpha(160), width: 1.2),
              color: const Color(0xFFE0F2FE).withAlpha(100),
            ),
          ),

          // User Blip 1 (Top Left)
          Positioned(
            top: 28,
            left: 55,
            child: _buildRadarBlip('0.8 km', const Color(0xFF10B981)),
          ),

          // User Blip 2 (Top Right)
          Positioned(
            top: 36,
            right: 50,
            child: _buildRadarBlip('1.4 km', const Color(0xFF0284C7)),
          ),

          // User Blip 3 (Bottom Left)
          Positioned(
            bottom: 38,
            left: 70,
            child: _buildRadarBlip('2.5 km', const Color(0xFF8B5CF6)),
          ),

          // User Blip 4 (Bottom Right)
          Positioned(
            bottom: 32,
            right: 65,
            child: _buildRadarBlip('3.1 km', const Color(0xFFF59E0B)),
          ),

          // Center Blip (Me)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0369A1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF0284C7).withAlpha(80), blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(Icons.navigation, color: Colors.white, size: 18),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge at Bottom
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE).withAlpha(240),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, size: 12, color: Color(0xFF0284C7)),
                  SizedBox(width: 5),
                  Text(
                    'Đang tự động quét lân cận...',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarBlip(String distance, Color dotColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: dotColor.withAlpha(80), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            distance,
            style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
