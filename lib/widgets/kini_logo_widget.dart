import 'package:flutter/material.dart';

class KiniLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const KiniLogoWidget({
    super.key,
    this.size = 76,
    this.showText = true,
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
            color: const Color(0xFF0284C7), // Primary KINI Blue
            borderRadius: BorderRadius.circular(size * 0.32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.58,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'sans-serif',
                ),
              ),
              Positioned(
                right: size * 0.20,
                bottom: size * 0.22,
                child: Container(
                  width: size * 0.20,
                  height: size * 0.20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF), // Cyan/Mint dot
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          const Text(
            'KINI',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ],
    );
  }
}
