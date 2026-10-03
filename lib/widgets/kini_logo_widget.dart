import 'package:flutter/material.dart';

class KiniLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showGlow;

  const KiniLogoWidget({
    super.key,
    this.size = 72,
    this.showText = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withAlpha(120),
                      blurRadius: size * 0.35,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7928CA).withAlpha(80),
                      blurRadius: size * 0.5,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/kini_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback nếu chưa load được ảnh
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F2FE), Color(0xFF7928CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(size * 0.28),
                  ),
                  child: Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE0FDFF), Color(0xFF00F2FE), Color(0xFFDBB8FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              'KiniChat',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'KẾT NỐI THẾ HỆ MỚI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: const Color(0xFF00F2FE).withAlpha(200),
            ),
          ),
        ],
      ],
    );
  }
}
