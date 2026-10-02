import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/wallpaper_model.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/chat_wallpaper_widget.dart';

class WallpaperPickerScreen extends StatefulWidget {
  final String roomId;
  final String currentWallpaperType; // 'none', 'preset', 'custom'
  final String currentWallpaperValue; // 'sweet_sky', URL, etc.
  final Function(String type, String value)? onWallpaperSaved;

  const WallpaperPickerScreen({
    super.key,
    required this.roomId,
    required this.currentWallpaperType,
    required this.currentWallpaperValue,
    this.onWallpaperSaved,
  });

  @override
  State<WallpaperPickerScreen> createState() => _WallpaperPickerScreenState();
}

class _WallpaperPickerScreenState extends State<WallpaperPickerScreen> {
  late String _selectedType; // 'preset' or 'custom' or 'none'
  late String _selectedValue;
  bool _isSaving = false;
  bool _isUploadingCustom = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentWallpaperType.isEmpty ? 'preset' : widget.currentWallpaperType;
    _selectedValue = widget.currentWallpaperValue.isEmpty ? 'default' : widget.currentWallpaperValue;
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    setState(() => _isUploadingCustom = true);
    try {
      final storage = StorageService();
      final url = await storage.uploadFile(
        path: picked.path,
        fileName: 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg',
        folder: 'wallpapers/${widget.roomId}',
      );

      if (url != null) {
        setState(() {
          _selectedType = 'custom';
          _selectedValue = url;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải ảnh lên, vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCustom = false);
      }
    }
  }

  Future<void> _saveWallpaper() async {
    setState(() => _isSaving = true);
    try {
      await ChatService().updateRoomTheme(
        roomId: widget.roomId,
        wallpaperType: _selectedType,
        wallpaperValue: _selectedValue,
      );

      if (widget.onWallpaperSaved != null) {
        widget.onWallpaperSaved!(_selectedType, _selectedValue);
      }

      if (mounted) {
        Navigator.pop(context, {'type': _selectedType, 'value': _selectedValue});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hình nền cuộc trò chuyện!'),
            backgroundColor: Color(0xFFFF94B4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu hình nền: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  WallpaperModel _getCurrentPreviewWallpaper() {
    if (_selectedType == 'custom') {
      return WallpaperThemes.getWallpaper('custom', customUrl: _selectedValue);
    }
    return WallpaperThemes.getWallpaper(_selectedValue);
  }

  @override
  Widget build(BuildContext context) {
    final previewWallpaper = _getCurrentPreviewWallpaper();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withAlpha(180) ?? Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        leadingWidth: 70,
        centerTitle: true,
        title: const Text(
          'Đặt hình nền',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: _isSaving
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF94B4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _saveWallpaper,
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Khu vực xem trước trực tiếp hình nền (Live Preview)
          Container(
            height: 190,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ChatWallpaperWidget(
              wallpaper: previewWallpaper,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sent message preview
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0084FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Đặt hình nền cho cuộc trò chuyện của chúng ta nào!',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Received message preview
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Text(
                          'Chắc chắn rồi, hãy chọn một ảnh mà cả hai chúng ta đều thích',
                          style: TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lời dẫn giải thích
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'Hình nền sẽ chỉ được áp dụng cho cuộc trò chuyện này và mọi người sẽ thấy hình nền đó',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(160) ?? Colors.grey,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lưới chọn hình nền
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemCount: WallpaperThemes.allWallpapers.length + 1, // +1 cho tùy chọn thư viện
              itemBuilder: (context, index) {
                // Thẻ đầu tiên: Chọn từ thư viện máy
                if (index == 0) {
                  final isCustomSelected = _selectedType == 'custom';
                  return InkWell(
                    onTap: _pickCustomImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCustomSelected ? const Color(0xFFFF94B4) : Colors.grey.withAlpha(50),
                                width: isCustomSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: _isUploadingCustom
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF94B4).withAlpha(30),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_photo_alternate, color: Color(0xFFFF94B4), size: 26),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Từ thư viện',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const Text(
                                        'Tải ảnh lên',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ảnh của tôi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                // Các mẫu hình nền có sẵn
                final wp = WallpaperThemes.allWallpapers[index - 1];
                final isSelected = _selectedType == 'preset' && _selectedValue == wp.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = 'preset';
                      _selectedValue = wp.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF94B4) : Colors.transparent,
                              width: isSelected ? 2.8 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ChatWallpaperWidget(
                              wallpaper: wp,
                              child: isSelected
                                  ? Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        margin: const EdgeInsets.all(6),
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF94B4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        wp.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFFD81B60) : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
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
