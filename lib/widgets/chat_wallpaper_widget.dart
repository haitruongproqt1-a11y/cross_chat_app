import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wallpaper_model.dart';

class ChatWallpaperWidget extends StatelessWidget {
  final WallpaperModel wallpaper;
  final Widget child;

  const ChatWallpaperWidget({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (wallpaper.id == 'default' && (wallpaper.networkUrl == null || wallpaper.networkUrl!.isEmpty)) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    }

    if (wallpaper.networkUrl != null && wallpaper.networkUrl!.isNotEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: wallpaper.networkUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black12),
              errorWidget: (_, __, ___) => Container(color: Colors.black26),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(20),
            ),
          ),
          child,
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: wallpaper.gradientColors,
                begin: wallpaper.begin,
                end: wallpaper.end,
              ),
            ),
            child: CustomPaint(
              painter: _PatternPainter(patternType: wallpaper.patternType),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final String patternType;

  _PatternPainter({required this.patternType});

  @override
  void paint(Canvas canvas, Size size) {
    switch (patternType) {
      case 'hearts':
        _drawHearts(canvas, size);
        break;
      case 'jazz':
        _drawJazz(canvas, size);
        break;
      case 'chair':
        _drawChair(canvas, size);
        break;
      case 'ocean':
        _drawOcean(canvas, size);
        break;
      case 'lavender':
        _drawLavender(canvas, size);
        break;
      case 'flower_cloud':
        _drawFlowerCloud(canvas, size);
        break;
      case 'cable_car':
        _drawCableCar(canvas, size);
        break;
      case 'puppy':
        _drawPuppy(canvas, size);
        break;
      case 'checker':
        _drawChecker(canvas, size);
        break;
      case 'stars':
        _drawStars(canvas, size);
        break;
    }
  }

  void _drawHearts(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.fill;

    // Vẽ một số hình trái tim và đốm sáng mờ ảo
    final random = math.Random(42);
    for (int i = 0; i < 16; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 10.0 + random.nextDouble() * 24.0;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawJazz(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.shade900.withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Vẽ họa tiết nốt nhạc trừu tượng
    for (double y = 40; y < size.height; y += 80) {
      for (double x = 30; x < size.width; x += 90) {
        canvas.drawCircle(Offset(x, y), 5, paint..style = PaintingStyle.fill);
        canvas.drawLine(Offset(x + 5, y), Offset(x + 5, y - 18), paint..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(x + 5, y - 18), Offset(x + 14, y - 14), paint);
      }
    }
  }

  void _drawChair(Canvas canvas, Size size) {
    // Vẽ bóng đổ và phối cảnh 3D không gian tối giản
    final shadowPaint = Paint()
      ..color = Colors.blueGrey.withAlpha(40)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.65),
        width: 140,
        height: 45,
      ),
      shadowPaint,
    );
  }

  void _drawOcean(Canvas canvas, Size size) {
    final boatPaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = const Color(0xFF003D66).withAlpha(80)
      ..style = PaintingStyle.fill;

    // Vẽ vài chiếc thuyền trắng nhỏ trên mặt biển xanh
    final boats = [
      Offset(size.width * 0.3, size.height * 0.25),
      Offset(size.width * 0.65, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.82),
    ];

    for (final b in boats) {
      canvas.drawOval(Rect.fromCenter(center: Offset(b.dx + 4, b.dy + 8), width: 32, height: 12), shadowPaint);
      canvas.drawOval(Rect.fromCenter(center: b, width: 30, height: 10), boatPaint);
    }
  }

  void _drawLavender(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.fill;

    final random = math.Random(108);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 1.5 + random.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  void _drawFlowerCloud(Canvas canvas, Size size) {
    final petalPaint = Paint()
      ..color = Colors.pink.shade200.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (double y = 60; y < size.height; y += 120) {
      for (double x = 40; x < size.width; x += 100) {
        canvas.drawCircle(Offset(x, y), 12, petalPaint);
        canvas.drawCircle(Offset(x, y), 4, petalPaint..style = PaintingStyle.fill);
        petalPaint.style = PaintingStyle.stroke;
      }
    }
  }

  void _drawCableCar(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueGrey.withAlpha(60)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.2),
      linePaint,
    );
  }

  void _drawPuppy(Canvas canvas, Size size) {
    final pawPaint = Paint()
      ..color = const Color(0xFF8D6E63).withAlpha(45)
      ..style = PaintingStyle.fill;

    for (double y = 80; y < size.height; y += 140) {
      for (double x = 50; x < size.width; x += 110) {
        canvas.drawCircle(Offset(x, y), 8, pawPaint);
        canvas.drawCircle(Offset(x - 8, y - 8), 3.5, pawPaint);
        canvas.drawCircle(Offset(x, y - 11), 3.5, pawPaint);
        canvas.drawCircle(Offset(x + 8, y - 8), 3.5, pawPaint);
      }
    }
  }

  void _drawChecker(Canvas canvas, Size size) {
    final checkPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.fill;

    const squareSize = 28.0;
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        if (((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), checkPaint);
        }
      }
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = const Color(0xFF64FFDA).withAlpha(120)
      ..style = PaintingStyle.fill;

    final random = math.Random(77);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 1.0 + random.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.patternType != patternType;
}
