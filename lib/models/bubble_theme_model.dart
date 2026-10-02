import 'package:flutter/material.dart';

class BubbleThemeModel {
  final String id;
  final String name;
  final String icon; // Biểu tượng con vật / nhân vật
  final String? subtitle;

  // Cấu hình bong bóng người gửi (Me)
  final Color sentBgColor;
  final Color? sentBgGradientEnd;
  final Color sentTextColor;
  final Color sentBorderColor;
  final double sentBorderWidth;

  // Cấu hình bong bóng người nhận (Other)
  final Color receivedBgColor;
  final Color? receivedBgGradientEnd;
  final Color receivedTextColor;
  final Color receivedBorderColor;
  final double receivedBorderWidth;

  // Bo góc và đổ bóng
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  // Nhãn / Sticker trang trí (như chú thỏ, capybara, bong bóng)
  final String? stickerTopLeft;
  final String? stickerTopRight;
  final String? stickerBottomRight;
  final Color? badgeColor;

  const BubbleThemeModel({
    required this.id,
    required this.name,
    required this.icon,
    this.subtitle,
    required this.sentBgColor,
    this.sentBgGradientEnd,
    required this.sentTextColor,
    required this.sentBorderColor,
    this.sentBorderWidth = 1.0,
    required this.receivedBgColor,
    this.receivedBgGradientEnd,
    required this.receivedTextColor,
    required this.receivedBorderColor,
    this.receivedBorderWidth = 1.0,
    this.borderRadius = 16.0,
    this.boxShadow,
    this.stickerTopLeft,
    this.stickerTopRight,
    this.stickerBottomRight,
    this.badgeColor,
  });
}

class BubbleThemes {
  static const List<BubbleThemeModel> allThemes = [
    // 1. Mặc định
    BubbleThemeModel(
      id: 'default',
      name: 'Mặc định',
      icon: '💬',
      subtitle: 'Xanh KINI & Xám thanh lịch',
      sentBgColor: Color(0xFF0084FF),
      sentTextColor: Colors.white,
      sentBorderColor: Colors.transparent,
      receivedBgColor: Color(0xFFF0F2F5),
      receivedTextColor: Color(0xFF050505),
      receivedBorderColor: Colors.transparent,
      borderRadius: 18.0,
    ),

    // 2. Thỏ mây (Chuẩn mẫu ảnh 1 & 2)
    BubbleThemeModel(
      id: 'bunny_clouds',
      name: 'Thỏ mây ngọt ngào',
      icon: '🐰',
      subtitle: 'Thỏ ngọc & đám mây vàng kem',
      sentBgColor: Color(0xFFE5A952),
      sentBgGradientEnd: Color(0xFFC7852E),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFA86B1E),
      sentBorderWidth: 1.5,
      receivedBgColor: Color(0xFFFFFDF8),
      receivedTextColor: Color(0xFF33271A),
      receivedBorderColor: Color(0xFFE8D3B2),
      receivedBorderWidth: 1.8,
      borderRadius: 16.0,
      stickerTopLeft: '☁️',
      stickerTopRight: '🐰🥕',
      badgeColor: Color(0xFFFFECC8),
      boxShadow: [
        BoxShadow(
          color: Color(0x26C7852E),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ),

    // 3. Capybara (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'capybara',
      name: 'Capybara',
      icon: '🦫',
      subtitle: 'Capybara đội cam thư giãn',
      sentBgColor: Color(0xFFB8783A),
      sentBgGradientEnd: Color(0xFF8E541E),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF703F12),
      receivedBgColor: Color(0xFFFDF8EE),
      receivedTextColor: Color(0xFF3E2B18),
      receivedBorderColor: Color(0xFFCFA06E),
      receivedBorderWidth: 1.8,
      borderRadius: 16.0,
      stickerTopRight: '🦫🍊',
      badgeColor: Color(0xFFE4B783),
      boxShadow: [
        BoxShadow(
          color: Color(0x1A8E541E),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    ),

    // 4. Rái cá vui nhộn (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'otter_bubbles',
      name: 'Rái cá vui nhộn',
      icon: '🦦',
      subtitle: 'Bong bóng xanh nước & rái cá',
      sentBgColor: Color(0xFF1396C9),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF0D7198),
      receivedBgColor: Color(0xFFE3F8FF),
      receivedTextColor: Color(0xFF104A62),
      receivedBorderColor: Color(0xFF72D2F4),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '🫧',
      stickerTopRight: '🦦🫧',
      badgeColor: Color(0xFFB1E7FB),
    ),

    // 5. Olivia Rodrigo (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'olivia_rodrigo',
      name: 'Olivia Rodrigo',
      icon: '🌸',
      subtitle: 'Hoa anh đào & bướm hồng',
      sentBgColor: Color(0xFFE94B8A),
      sentBgGradientEnd: Color(0xFFC72866),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFAC1D56),
      receivedBgColor: Color(0xFFFFF0F5),
      receivedTextColor: Color(0xFF5A1E35),
      receivedBorderColor: Color(0xFFF3A0C4),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '🌸',
      stickerTopRight: '🦋🌸',
      badgeColor: Color(0xFFFFD1E1),
    ),

    // 6. Ếch vịt (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'duck_frog',
      name: 'Ếch vịt',
      icon: '🦆',
      subtitle: 'Vịt vàng tắm ao & ếch nhỏ',
      sentBgColor: Color(0xFFF5A623),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFCE8712),
      receivedBgColor: Color(0xFFFFFDE6),
      receivedTextColor: Color(0xFF4A3D06),
      receivedBorderColor: Color(0xFFE5D56A),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '🪷',
      stickerTopRight: '🦆🐸',
      badgeColor: Color(0xFFFFFAAA),
    ),

    // 7. Ếch xanh ngộ nghĩnh (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'green_frog',
      name: 'Ếch',
      icon: '🐸',
      subtitle: 'Mắt ếch to tròn lém lỉnh',
      sentBgColor: Color(0xFF2E7D32),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF1B5E20),
      receivedBgColor: Color(0xFFE8F5E9),
      receivedTextColor: Color(0xFF1B3B1D),
      receivedBorderColor: Color(0xFF81C784),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '👀',
      stickerTopRight: '🐸☘️',
      badgeColor: Color(0xFFA5D6A7),
    ),

    // 8. Pepe thả tim (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'pepe_love',
      name: 'Pepe thả tim',
      icon: '💖',
      subtitle: 'Chú ếch Pepe bắn tim ngọt ngào',
      sentBgColor: Color(0xFFE84393),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFC22770),
      receivedBgColor: Color(0xFFFFF0F6),
      receivedTextColor: Color(0xFF4D142F),
      receivedBorderColor: Color(0xFFFFADC6),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '💕',
      stickerTopRight: '🐸💖',
      badgeColor: Color(0xFFFFCCD9),
    ),

    // 9. Mèo chó (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'cat_dog',
      name: 'Mèo chó',
      icon: '🐱🐶',
      subtitle: 'Mèo con và cún cưng bên nhau',
      sentBgColor: Color(0xFFE0823D),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFB55F20),
      receivedBgColor: Color(0xFFFFF9EE),
      receivedTextColor: Color(0xFF47280E),
      receivedBorderColor: Color(0xFFF3C28D),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '🐾',
      stickerTopRight: '🐱🐶',
      badgeColor: Color(0xFFFFDFB6),
    ),

    // 10. Cá sấu thư thái (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'croco_chill',
      name: 'Cá sấu thư thái',
      icon: '🐊',
      subtitle: 'Cá sấu đội mũ nằm chill',
      sentBgColor: Color(0xFF3F51B5),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF283593),
      receivedBgColor: Color(0xFFE8EAF6),
      receivedTextColor: Color(0xFF1A237E),
      receivedBorderColor: Color(0xFF9FA8DA),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopRight: '🐊🧢',
      badgeColor: Color(0xFFC5CAE9),
    ),

    // 11. Mèo khoẻ cơ (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'buff_cat',
      name: 'Mèo khoẻ cơ',
      icon: '😼💪',
      subtitle: 'Mèo tập gym cơ bắp cuồn cuộn',
      sentBgColor: Color(0xFF212121),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF424242),
      receivedBgColor: Color(0xFFF5F5F5),
      receivedTextColor: Color(0xFF212121),
      receivedBorderColor: Color(0xFF9E9E9E),
      receivedBorderWidth: 1.8,
      borderRadius: 14.0,
      stickerTopRight: '💪😼',
      badgeColor: Color(0xFFE0E0E0),
    ),

    // 12. Diva lộng lẫy (Chuẩn mẫu ảnh 2)
    BubbleThemeModel(
      id: 'diva_glam',
      name: 'Diva lộng lẫy',
      icon: '💄',
      subtitle: 'Son đỏ quyến rũ & mi cong',
      sentBgColor: Color(0xFFD81B60),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF880E4F),
      receivedBgColor: Color(0xFFFCE4EC),
      receivedTextColor: Color(0xFF4A148C),
      receivedBorderColor: Color(0xFFF48FB1),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopRight: '💋✨',
      badgeColor: Color(0xFFF8BBD0),
    ),

    // 13. Cyberpunk Neon 2077 (Mẫu mới cực ngầu)
    BubbleThemeModel(
      id: 'cyber_neon',
      name: 'Cyberpunk Neon',
      icon: '⚡',
      subtitle: 'Ánh sáng neon tương lai huyền ảo',
      sentBgColor: Color(0xFF180A2E),
      sentBgGradientEnd: Color(0xFF2E0854),
      sentTextColor: Color(0xFF00F2FE),
      sentBorderColor: Color(0xFF00F2FE),
      sentBorderWidth: 1.8,
      receivedBgColor: Color(0xFF0F172A),
      receivedTextColor: Color(0xFFFF52AF),
      receivedBorderColor: Color(0xFFFF0979),
      receivedBorderWidth: 1.8,
      borderRadius: 16.0,
      stickerTopRight: '⚡🔮',
      boxShadow: [
        BoxShadow(
          color: Color(0x66FE0979),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    ),

    // 14. Dải Ngân Hà (Galaxy Nebula)
    BubbleThemeModel(
      id: 'galaxy_nebula',
      name: 'Dải Ngân Hà',
      icon: '🌌',
      subtitle: 'Sao băng lung linh & bầu trời đêm',
      sentBgColor: Color(0xFF2D1B69),
      sentBgGradientEnd: Color(0xFF110726),
      sentTextColor: Color(0xFFE0E7FF),
      sentBorderColor: Color(0xFF818CF8),
      receivedBgColor: Color(0xFF1E1B4B),
      receivedTextColor: Color(0xFFDDD6FE),
      receivedBorderColor: Color(0xFFA78BFA),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '✨',
      stickerTopRight: '🪐🌙',
      boxShadow: [
        BoxShadow(
          color: Color(0x446366F1),
          blurRadius: 8,
        ),
      ],
    ),

    // 15. Trà xanh Matcha dịu êm
    BubbleThemeModel(
      id: 'matcha_latte',
      name: 'Matcha Latte',
      icon: '🍵',
      subtitle: 'Sắc xanh matcha bọt kem êm dịu',
      sentBgColor: Color(0xFF4A6B32),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF354E22),
      receivedBgColor: Color(0xFFF1F6EC),
      receivedTextColor: Color(0xFF27381A),
      receivedBorderColor: Color(0xFFA6C590),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopRight: '🍵🌿',
      badgeColor: Color(0xFFD5E6C7),
    ),

    // 16. Gấu dâu Lotso ngọt ngào
    BubbleThemeModel(
      id: 'strawberry_bear',
      name: 'Gấu dâu Lotso',
      icon: '🍓',
      subtitle: 'Hương dâu tây ngọt lịm mùa hạ',
      sentBgColor: Color(0xFFC2185B),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF880E4F),
      receivedBgColor: Color(0xFFFFF0F3),
      receivedTextColor: Color(0xFF5E0B2D),
      receivedBorderColor: Color(0xFFFF94B4),
      receivedBorderWidth: 1.8,
      borderRadius: 16.0,
      stickerTopLeft: '🍓',
      stickerTopRight: '🧸🍓',
      badgeColor: Color(0xFFFFBCCD),
    ),

    // 17. Hoàng hôn mùa thu (Autumn Sunset)
    BubbleThemeModel(
      id: 'autumn_sunset',
      name: 'Hoàng hôn mùa thu',
      icon: '🍂',
      subtitle: 'Ánh tà dương vàng cam & lá phong',
      sentBgColor: Color(0xFFD9480F),
      sentBgGradientEnd: Color(0xFFC92A2A),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFA61E4D),
      receivedBgColor: Color(0xFFFFF4E6),
      receivedTextColor: Color(0xFF491C08),
      receivedBorderColor: Color(0xFFFFC078),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopRight: '🍁🍂',
      badgeColor: Color(0xFFFFD8A8),
    ),

    // 18. Mây kẹo bông (Cotton Candy)
    BubbleThemeModel(
      id: 'cotton_candy',
      name: 'Mây kẹo bông',
      icon: '🍬',
      subtitle: 'Gradient pastel tím hồng mơ mộng',
      sentBgColor: Color(0xFF9061F9),
      sentBgGradientEnd: Color(0xFFE74694),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFFC27803),
      sentBorderWidth: 0,
      receivedBgColor: Color(0xFFFDF2F8),
      receivedTextColor: Color(0xFF4C1D95),
      receivedBorderColor: Color(0xFFFBCFE8),
      receivedBorderWidth: 1.8,
      borderRadius: 18.0,
      stickerTopLeft: '🌈',
      stickerTopRight: '☁️🍭',
    ),

    // 19. Cực quang Aurora Băng giá
    BubbleThemeModel(
      id: 'ice_aurora',
      name: 'Băng tuyết Aurora',
      icon: '❄️',
      subtitle: 'Bông tuyết trắng & ánh sáng cực quang',
      sentBgColor: Color(0xFF007791),
      sentBgGradientEnd: Color(0xFF00A896),
      sentTextColor: Colors.white,
      sentBorderColor: Color(0xFF028090),
      receivedBgColor: Color(0xFFF0FDFE),
      receivedTextColor: Color(0xFF073B4C),
      receivedBorderColor: Color(0xFF99E2EC),
      receivedBorderWidth: 1.6,
      borderRadius: 16.0,
      stickerTopLeft: '✨',
      stickerTopRight: '❄️🏔️',
    ),

    // 20. Retro 8-Bit Pixel Arcade
    BubbleThemeModel(
      id: 'pixel_arcade',
      name: 'Pixel Arcade 8-Bit',
      icon: '👾',
      subtitle: 'Trò chơi điện tử cổ điển hoài niệm',
      sentBgColor: Color(0xFF374151),
      sentTextColor: Color(0xFFFDE047),
      sentBorderColor: Color(0xFFFACC15),
      sentBorderWidth: 2.0,
      receivedBgColor: Color(0xFFF9FAFB),
      receivedTextColor: Color(0xFF111827),
      receivedBorderColor: Color(0xFF4B5563),
      receivedBorderWidth: 2.0,
      borderRadius: 6.0,
      stickerTopRight: '👾🕹️',
    ),
  ];

  static BubbleThemeModel getTheme(String? id) {
    if (id == null || id.isEmpty) return allThemes.first;
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => allThemes.first,
    );
  }
}
