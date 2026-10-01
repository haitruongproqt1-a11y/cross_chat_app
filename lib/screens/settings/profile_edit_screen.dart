import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/avatar_widget.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  late TextEditingController _hometownController;
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  String _gender = 'Nam';
  int? _birthYear;

  static const List<String> popularProvinces = [
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ', 'Huế',
    'Quảng Trị', 'Quảng Bình', 'Nghệ An', 'Hà Tĩnh', 'Thanh Hóa',
    'Bình Dương', 'Đồng Nai', 'Bà Rịa - Vũng Tàu', 'Khánh Hòa', 'Lâm Đồng'
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _statusController = TextEditingController(text: user?.statusMessage ?? '');
    _hometownController = TextEditingController(text: user?.hometown ?? '');
    _gender = (user?.gender != null && user!.gender.isNotEmpty) ? user.gender : 'Nam';
    _birthYear = user?.birthYear ?? 2000;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await auth.updateProfile(
      displayName: _nameController.text.trim(),
      statusMessage: _statusController.text.trim(),
      gender: _gender,
      birthYear: _birthYear,
      hometown: _hometownController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
    );
    Navigator.pop(context);
  }

  void _changeAvatar() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final image = await _storageService.pickImage();
    if (image != null) {
      setState(() => _isLoading = true);
      final bytes = await image.readAsBytes();
      final url = await _storageService.uploadFile(
        path: image.path,
        fileName: 'avatar.jpg',
        folder: 'avatars/${auth.currentUser?.uid}',
        fileBytes: bytes,
      );

      if (url != null) {
        await auth.updateProfile(photoUrl: url);
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Hồ Sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu thay đổi',
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  AvatarWidget(
                    photoUrl: user?.photoUrl,
                    name: user?.displayName ?? 'Người dùng',
                    radius: 50,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        tooltip: 'Đổi ảnh đại diện',
                        onPressed: _changeAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tên hiển thị
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị / Biệt danh',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tiểu sử
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: 'Tiểu sử / Lời giới thiệu',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Giới tính
            const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: ['Nam', 'Nữ', 'Khác'].map((g) {
                final isSelected = _gender == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _gender = g);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Năm sinh & Tuổi
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _birthYear,
                    decoration: const InputDecoration(
                      labelText: 'Năm sinh',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(75, (i) => currentYear - 10 - i).map((year) {
                      final age = currentYear - year;
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year ($age tuổi)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _birthYear = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quê quán / Tỉnh thành
            TextField(
              controller: _hometownController,
              decoration: InputDecoration(
                labelText: 'Quê quán / Tỉnh thành',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: const OutlineInputBorder(),
                hintText: 'Nhập hoặc chọn tỉnh/thành bên dưới',
                suffixIcon: _hometownController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _hometownController.clear()),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: popularProvinces.map((prov) {
                return ActionChip(
                  label: Text(prov, style: const TextStyle(fontSize: 12)),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _hometownController.text = prov;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Thông tin tài khoản
            Card(
              elevation: 0,
              color: Colors.grey.withAlpha(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                      title: const Text('Email đăng ký', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(user?.email ?? 'Chưa rõ'),
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.badge_outlined, color: Colors.green),
                      title: const Text('Mã ID cá nhân', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(user?.uid ?? ''),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
