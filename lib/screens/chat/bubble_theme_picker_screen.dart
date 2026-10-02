import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bubble_theme_model.dart';
import '../../services/chat_service.dart';
import '../../providers/auth_provider.dart';

class BubbleThemePickerScreen extends StatefulWidget {
  final String roomId;
  final String currentThemeId;
  final String? userId;
  final Function(String newThemeId)? onThemeSaved;

  const BubbleThemePickerScreen({
    super.key,
    required this.roomId,
    required this.currentThemeId,
    this.userId,
    this.onThemeSaved,
  });

  @override
  State<BubbleThemePickerScreen> createState() => _BubbleThemePickerScreenState();
}

class _BubbleThemePickerScreenState extends State<BubbleThemePickerScreen> {
  late String _selectedThemeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.currentThemeId;
  }

  Future<void> _saveTheme() async {
    setState(() => _isSaving = true);
    try {
      // Lưu vào hồ sơ cá nhân người dùng để áp dụng cho mọi tin nhắn người dùng gửi
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        await ChatService().updateUserBubbleTheme(
          userId: widget.userId!,
          bubbleThemeId: _selectedThemeId,
        );
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).updateBubbleThemeId(_selectedThemeId);
        }
      }
      // Lưu vào phòng chat để tương thích
      if (widget.roomId.isNotEmpty) {
        await ChatService().updateRoomTheme(
          roomId: widget.roomId,
          bubbleThemeId: _selectedThemeId,
        );
      }
      if (widget.onThemeSaved != null) {
        widget.onThemeSaved!(_selectedThemeId);
      }
      if (mounted) {
        Navigator.pop(context, _selectedThemeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật kiểu bong bóng trò chuyện của bạn!'),
            backgroundColor: Color(0xFFFE0979),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu kiểu bong bóng: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = BubbleThemes.getTheme(_selectedThemeId);
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
          'Chọn kiểu bong bóng',
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
                    onPressed: _saveTheme,
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Khu vực xem trước trực tiếp (Live Preview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor.withAlpha(120),
              border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bong bóng người gửi (Me - Kiểu bạn chọn sẽ xuất hiện tại đây)
                Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: activeTheme.sentBgColor,
                          gradient: activeTheme.sentBgGradientEnd != null
                              ? LinearGradient(
                                  colors: [activeTheme.sentBgColor, activeTheme.sentBgGradientEnd!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(activeTheme.borderRadius),
                          border: Border.all(
                            color: activeTheme.sentBorderColor,
                            width: activeTheme.sentBorderWidth,
                          ),
                          boxShadow: activeTheme.boxShadow,
                        ),
                        child: Text(
                          'Nay bạn có thể thay đổi kiểu bong bóng và cuộc trò chuyện sẽ có giao diện mới. Quá ngầu!',
                          style: TextStyle(
                            color: activeTheme.sentTextColor,
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      // Sticker góc trên phải (như thỏ mây, capybara)
                      if (activeTheme.stickerTopRight != null)
                        Positioned(
                          top: -14,
                          right: 8,
                          child: Text(
                            activeTheme.stickerTopRight!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      // Sticker góc trên trái (như đám mây)
                      if (activeTheme.stickerTopLeft != null)
                        Positioned(
                          top: -10,
                          left: 4,
                          child: Text(
                            activeTheme.stickerTopLeft!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Bong bóng người nhận (Other) với hình trang trí thỏ/capybara
                Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: activeTheme.receivedBgColor,
                          gradient: activeTheme.receivedBgGradientEnd != null
                              ? LinearGradient(
                                  colors: [activeTheme.receivedBgColor, activeTheme.receivedBgGradientEnd!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(activeTheme.borderRadius),
                          border: Border.all(
                            color: activeTheme.receivedBorderColor,
                            width: activeTheme.receivedBorderWidth,
                          ),
                          boxShadow: activeTheme.boxShadow,
                        ),
                        child: Text(
                          'Dạ vâng, nhìn cưng xỉu luôn á anh! Tha hồ đổi kiểu. 😍',
                          style: TextStyle(
                            color: activeTheme.receivedTextColor,
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      // Sticker góc trên phải (như thỏ mây, capybara)
                      if (activeTheme.stickerTopRight != null)
                        Positioned(
                          top: -14,
                          right: 8,
                          child: Text(
                            activeTheme.stickerTopRight!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      // Sticker góc trên trái (như đám mây)
                      if (activeTheme.stickerTopLeft != null)
                        Positioned(
                          top: -10,
                          left: 4,
                          child: Text(
                            activeTheme.stickerTopLeft!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tiêu đề danh sách gợi ý
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Gợi ý',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE0979).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${BubbleThemes.allThemes.length} mẫu',
                    style: const TextStyle(
                      color: Color(0xFFFE0979),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lưới danh sách các kiểu bong bóng
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemCount: BubbleThemes.allThemes.length,
              itemBuilder: (context, index) {
                final item = BubbleThemes.allThemes[index];
                final isSelected = item.id == _selectedThemeId;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedThemeId = item.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF94B4).withAlpha(25)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF94B4)
                            : Colors.grey.withAlpha(40),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Color(0x33FF94B4),
                                offset: Offset(0, 3),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mô phỏng bong bóng nhỏ
                        Expanded(
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 82,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: item.receivedBgColor,
                                    gradient: item.receivedBgGradientEnd != null
                                        ? LinearGradient(
                                            colors: [item.receivedBgColor, item.receivedBgGradientEnd!],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(item.borderRadius > 12 ? 10 : 4),
                                    border: Border.all(
                                      color: item.receivedBorderColor,
                                      width: item.receivedBorderWidth,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.icon,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                if (item.stickerTopRight != null)
                                  Positioned(
                                    top: -9,
                                    right: -4,
                                    child: Text(
                                      item.stickerTopRight!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Tên mẫu bong bóng
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFD81B60)
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
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
