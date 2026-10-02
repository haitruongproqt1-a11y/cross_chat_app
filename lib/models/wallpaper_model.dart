import 'package:flutter/material.dart';

class WallpaperModel {
  final String id;
  final String name;
  final String? subtitle;
  final List<Color> gradientColors;
  final Alignment begin;
  final Alignment end;
  final String patternType; // 'none', 'hearts', 'jazz', 'ocean', 'lavender', 'flower_cloud', 'chair', 'checker', 'stars', 'cable_car', 'puppy'
  final String? networkUrl;
  final bool isCustom;

  const WallpaperModel({
    required this.id,
    required this.name,
    this.subtitle,
    required this.gradientColors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.patternType = 'none',
    this.networkUrl,
    this.isCustom = false,
  });
}

class WallpaperThemes {
  static const List<WallpaperModel> allWallpapers = [
    // 1. Mặc định (Theo theme)
    WallpaperModel(
      id: 'default',
      name: 'Mặc định',
      subtitle: 'Nền hệ thống tự nhiên',
      gradientColors: [Color(0xFFF7F8FA), Color(0xFFEDF1F7)],
      patternType: 'none',
    ),

    // 2. Bầu trời ngọt ngào (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'sweet_sky',
      name: 'Bầu trời ngọt ngào',
      subtitle: 'Hồng pastel và trái tim mơ mộng',
      gradientColors: [Color(0xFFFFC0D3), Color(0xFFFFE5EC), Color(0xFFD6C8FF)],
      patternType: 'hearts',
    ),

    // 3. Câu lạc bộ nhạc jazz (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'jazz_club',
      name: 'Câu lạc bộ nhạc jazz',
      subtitle: 'Họa tiết nốt nhạc & saxophone tím',
      gradientColors: [Color(0xFFE5D9F2), Color(0xFFD8B4E2), Color(0xFFCDC1FF)],
      patternType: 'jazz',
    ),

    // 4. Ghế lơ lửng (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'floating_chair',
      name: 'Ghế lơ lửng',
      subtitle: 'Không gian 3D nghệ thuật tối giản',
      gradientColors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      patternType: 'chair',
    ),

    // 5. Thuyền trôi dạt (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'azure_ocean',
      name: 'Thuyền trôi dạt',
      subtitle: 'Mặt biển xanh biếc thanh bình',
      gradientColors: [Color(0xFF0077B6), Color(0xFF0096C7), Color(0xFF48CAE4)],
      patternType: 'ocean',
    ),

    // 6. Màn sương oải hương (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'lavender_mist',
      name: 'Màn sương oải hương',
      subtitle: 'Gradient tím khói lấp lánh sao trời',
      gradientColors: [Color(0xFFB39DDB), Color(0xFF9575CD), Color(0xFF7E57C2)],
      patternType: 'lavender',
    ),

    // 7. Mây và hoa (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'cloud_flower',
      name: 'Mây và hoa',
      subtitle: 'Sắc cam hồng đào và cánh hoa nhỏ',
      gradientColors: [Color(0xFFFFD1DC), Color(0xFFFFE0B2), Color(0xFFFFCCBC)],
      patternType: 'flower_cloud',
    ),

    // 8. Cáp treo bầu trời (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'cable_car',
      name: 'Cáp treo bầu trời',
      subtitle: 'Bầu trời xanh trong vắt trên cao',
      gradientColors: [Color(0xFF81D4FA), Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
      patternType: 'cable_car',
    ),

    // 9. Corgi cưng dễ thương (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'corgi_puppy',
      name: 'Corgi cưng',
      subtitle: 'Chú cún cưng ngộ nghĩnh tone be',
      gradientColors: [Color(0xFFF5EBE0), Color(0xFFE3D5CA), Color(0xFFD5BDAF)],
      patternType: 'puppy',
    ),

    // 10. Caro xanh pastel (Chuẩn mẫu ảnh 3)
    WallpaperModel(
      id: 'mint_checker',
      name: 'Caro xanh pastel',
      subtitle: 'Họa tiết ô cờ mint thời thượng',
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      patternType: 'checker',
    ),

    // 11. Đêm cực quang sao băng (Aurora Night)
    WallpaperModel(
      id: 'aurora_night',
      name: 'Cực quang đêm huyền ảo',
      subtitle: 'Ánh sáng Bắc cực quang lung linh',
      gradientColors: [Color(0xFF0F172A), Color(0xFF0D9488), Color(0xFF064E3B)],
      patternType: 'stars',
    ),

    // 12. Sakura mùa xuân (Cherry Blossom)
    WallpaperModel(
      id: 'sakura_blossom',
      name: 'Mưa hoa anh đào',
      subtitle: 'Cánh hoa anh đào rơi lãng mạn',
      gradientColors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1), Color(0xFFFFD1DC)],
      patternType: 'hearts',
    ),
  ];

  static WallpaperModel getWallpaper(String? id, {String? customUrl}) {
    if (customUrl != null && customUrl.isNotEmpty) {
      return WallpaperModel(
        id: 'custom',
        name: 'Ảnh tùy chỉnh',
        subtitle: 'Ảnh tải lên từ thiết bị',
        gradientColors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
        networkUrl: customUrl,
        isCustom: true,
      );
    }
    if (id == null || id.isEmpty || id == 'none') return allWallpapers.first;
    return allWallpapers.firstWhere(
      (w) => w.id == id,
      orElse: () => allWallpapers.first,
    );
  }
}
