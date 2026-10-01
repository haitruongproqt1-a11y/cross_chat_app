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
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _statusController = TextEditingController(text: user?.statusMessage ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await auth.updateProfile(
      displayName: _nameController.text.trim(),
      statusMessage: _statusController.text.trim(),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  AvatarWidget(
                    photoUrl: user?.photoUrl,
                    name: user?.displayName ?? 'Người dùng',
                    radius: 54,
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
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị / Biệt danh',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: 'Tiểu sử / Trạng thái',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('Địa chỉ Email'),
              subtitle: Text(user?.email ?? 'Chưa rõ'),
            ),
          ],
        ),
      ),
    );
  }
}
