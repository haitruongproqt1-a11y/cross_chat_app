import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../services/wall_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/avatar_widget.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final StorageService _storageService = StorageService();
  final WallService _wallService = WallService();
  final ChatService _chatService = ChatService();

  final List<XFile> _selectedFiles = [];
  PostMediaType _mediaType = PostMediaType.none;
  PostPrivacy _privacy = PostPrivacy.public;
  final List<String> _blockedUserIds = [];

  bool _isPosting = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _mediaType = PostMediaType.image;
        _selectedFiles.addAll(images);
      });
    }
  }

  void _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _mediaType = PostMediaType.video;
        _selectedFiles.clear();
        _selectedFiles.add(video);
      });
    }
  }

  void _showBlockedUsersSelector(UserModel currentUser) async {
    final usersSnapshot = await _chatService.getAllUsers(currentUser.uid).first;
    if (!mounted) return;

    final tempBlocked = List<String>.from(_blockedUserIds);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn người bị chặn xem bài viết này',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (usersSnapshot.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có liên hệ nào trong danh bạ để chặn.'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: usersSnapshot.length,
                    itemBuilder: (ctx, i) {
                      final f = usersSnapshot[i];
                      final isBlocked = tempBlocked.contains(f.uid);
                      return CheckboxListTile(
                        value: isBlocked,
                        secondary: AvatarWidget(name: f.displayName, photoUrl: f.photoUrl, radius: 18),
                        title: Text(f.displayName),
                        subtitle: Text(f.statusMessage, maxLines: 1),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              tempBlocked.add(f.uid);
                            } else {
                              tempBlocked.remove(f.uid);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
                onPressed: () {
                  setState(() {
                    _blockedUserIds.clear();
                    _blockedUserIds.addAll(tempBlocked);
                  });
                  Navigator.pop(ctx);
                },
                child: Text('Xác nhận (${tempBlocked.length} người bị chặn)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung hoặc đính kèm ảnh/video')),
      );
      return;
    }

    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    setState(() {
      _isPosting = true;
      _uploadProgress = 0.1;
    });

    try {
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last;
        final folder = _mediaType == PostMediaType.video ? 'wall_videos' : 'wall_images';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

        final url = await _storageService.uploadFile(
          path: file.path,
          fileName: fileName,
          folder: '$folder/${currentUser.uid}',
          fileBytes: bytes,
        );

        if (url != null) {
          uploadedUrls.add(url);
        }

        setState(() {
          _uploadProgress = 0.1 + (0.8 * ((i + 1) / _selectedFiles.length));
        });
      }

      await _wallService.createPost(
        author: currentUser,
        content: text,
        mediaUrls: uploadedUrls,
        mediaType: uploadedUrls.isEmpty ? PostMediaType.none : _mediaType,
        privacy: _privacy,
        blockedUserIds: _blockedUserIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng bài viết lên tường nhà thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng bài: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Bài Viết', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _isPosting ? null : _submitPost,
              child: _isPosting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ĐĂNG'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header + Privacy Selector
            if (user != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarWidget(name: user.displayName, photoUrl: user.photoUrl, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            PopupMenuButton<PostPrivacy>(
                              initialValue: _privacy,
                              onSelected: (val) => setState(() => _privacy = val),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blueAccent.withAlpha(50)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _privacy == PostPrivacy.public
                                          ? Icons.public
                                          : _privacy == PostPrivacy.friends
                                              ? Icons.people
                                              : Icons.lock,
                                      size: 14,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _privacy == PostPrivacy.public
                                          ? 'Công khai'
                                          : _privacy == PostPrivacy.friends
                                              ? 'Bạn bè'
                                              : 'Chỉ mình tôi',
                                      style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.blueAccent),
                                  ],
                                ),
                              ),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: PostPrivacy.public,
                                  child: Row(children: [Icon(Icons.public, size: 18), SizedBox(width: 8), Text('Công khai')]),
                                ),
                                const PopupMenuItem(
                                  value: PostPrivacy.friends,
                                  child: Row(children: [Icon(Icons.people, size: 18), SizedBox(width: 8), Text('Chỉ bạn bè')]),
                                ),
                                const PopupMenuItem(
                                  value: PostPrivacy.private,
                                  child: Row(children: [Icon(Icons.lock, size: 18), SizedBox(width: 8), Text('Chỉ mình tôi')]),
                                ),
                              ],
                            ),

                            // Nút chặn người xem cụ thể
                            InkWell(
                              onTap: () => _showBlockedUsersSelector(user),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _blockedUserIds.isNotEmpty ? Colors.red.withAlpha(25) : Colors.grey.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _blockedUserIds.isNotEmpty ? Colors.redAccent : Colors.grey),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.block, size: 14, color: _blockedUserIds.isNotEmpty ? Colors.redAccent : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _blockedUserIds.isNotEmpty ? 'Chặn ${_blockedUserIds.length} người xem' : 'Chặn người xem',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _blockedUserIds.isNotEmpty ? Colors.redAccent : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Content textfield
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 4,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì? Chia sẻ khoảnh khắc, cảm xúc hôm nay...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 16),
              ),
            ),

            if (_isPosting) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 6),
              const Center(child: Text('Đang tải ảnh/video và lưu bài viết...', style: TextStyle(fontSize: 12, color: Colors.grey))),
            ],

            const SizedBox(height: 16),

            // Media Preview
            if (_selectedFiles.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.map((file) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.black12,
                          child: _mediaType == PostMediaType.video
                              ? const Center(child: Icon(Icons.videocam, size: 40, color: Colors.blueAccent))
                              : Image.file(File(file.path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFiles.remove(file);
                              if (_selectedFiles.isEmpty) _mediaType = PostMediaType.none;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),

            // Media attachment buttons
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo_library, color: Colors.green),
                  label: const Text('Thêm Ảnh', style: TextStyle(color: Colors.green)),
                  onPressed: _pickImages,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.video_library, color: Colors.redAccent),
                  label: const Text('Thêm Video', style: TextStyle(color: Colors.redAccent)),
                  onPressed: _pickVideo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
