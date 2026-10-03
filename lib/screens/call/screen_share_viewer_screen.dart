import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class ScreenShareViewerScreen extends StatefulWidget {
  final String remoteUserName;
  final String? remoteUserAvatar;
  final String? streamTitle;
  final String resolution;

  const ScreenShareViewerScreen({
    super.key,
    this.remoteUserName = 'Lan Anh',
    this.remoteUserAvatar,
    this.streamTitle = 'Figma Review UX • Wireflows v2',
    this.resolution = '1080p 60fps',
  });

  @override
  State<ScreenShareViewerScreen> createState() => _ScreenShareViewerScreenState();
}

class _ScreenShareViewerScreenState extends State<ScreenShareViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isSpeakerOn = true;
  bool _isFullscreen = false;
  final List<_FloatingReaction> _reactions = [];

  void _addReaction(String emoji) {
    setState(() {
      _reactions.add(_FloatingReaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        emoji: emoji,
        xOffset: Random().nextDouble() * 160 - 80,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: Stack(
        children: [
          // Background ambient cyber glow
          Positioned(
            top: -100,
            left: size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryCyan.withAlpha(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withAlpha(40),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Screen Stream Simulation Display
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56), // Space for top header
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(150),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(27),
                          child: Stack(
                            children: [
                              // Simulated shared screen UI
                              _buildSimulatedStreamContent(),

                              // Live watermark badge
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(180),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryCyan.withAlpha(100),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.tertiaryMagenta,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.resolution,
                                        style: const TextStyle(
                                          color: AppTheme.primaryCyan,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom dock
              ],
            ),
          ),

          // Floating Mini PiP Webcam (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            right: 20,
            child: Container(
              width: 86,
              height: 118,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryCyan.withAlpha(120), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryCyan, AppTheme.secondaryViolet],
                          ),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        color: Colors.black.withAlpha(180),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bạn',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                bottom: 8,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withAlpha(230),
                border: const Border(
                  bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Màn hình của ${widget.remoteUserName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.streamTitle ?? 'Chia sẻ màn hình 1:1 siêu tốc',
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: _isSpeakerOn ? AppTheme.primaryCyan : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                ],
              ),
            ),
          ),

          // Floating Reaction Emojis
          ..._reactions.map((r) => _buildAnimatedReaction(r)),

          // Reaction Quick Bar (Above Dock)
          Positioned(
            bottom: 86,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest.withAlpha(200),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _reactionBtn('❤️'),
                    const SizedBox(width: 10),
                    _reactionBtn('🔥'),
                    const SizedBox(width: 10),
                    _reactionBtn('👏'),
                    const SizedBox(width: 10),
                    _reactionBtn('🎉'),
                    const SizedBox(width: 10),
                    _reactionBtn('🚀'),
                  ],
                ),
              ),
            ),
          ),

          // Floating Bottom Glass Control Dock
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest.withAlpha(240),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(160),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic button
                    _dockBtn(
                      icon: _isMicOn ? Icons.mic : Icons.mic_off,
                      isActive: _isMicOn,
                      activeColor: AppTheme.primaryCyan,
                      onTap: () => setState(() => _isMicOn = !_isMicOn),
                    ),
                    const SizedBox(width: 14),
                    // Video button
                    _dockBtn(
                      icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                      isActive: _isCameraOn,
                      activeColor: AppTheme.secondaryViolet,
                      onTap: () => setState(() => _isCameraOn = !_isCameraOn),
                    ),
                    const SizedBox(width: 14),
                    // Fullscreen button
                    _dockBtn(
                      icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      isActive: false,
                      activeColor: Colors.white,
                      onTap: () => setState(() => _isFullscreen = !_isFullscreen),
                    ),
                    const SizedBox(width: 14),
                    // End call / share button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryMagenta,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.tertiaryMagenta.withAlpha(120),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionBtn(String emoji) {
    return GestureDetector(
      onTap: () => _addReaction(emoji),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  Widget _dockBtn({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(40) : AppTheme.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? activeColor.withAlpha(120) : const Color(0x22FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white70,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAnimatedReaction(_FloatingReaction reaction) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(reaction.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1400),
      onEnd: () {
        setState(() {
          _reactions.removeWhere((r) => r.id == reaction.id);
        });
      },
      builder: (context, value, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final startY = MediaQuery.of(context).size.height - 140;
        final curY = startY - (value * 280);
        final curX = (screenWidth / 2) + reaction.xOffset;
        final opacity = (1.0 - value).clamp(0.0, 1.0);
        final scale = 1.0 + (value * 0.8);

        return Positioned(
          left: curX,
          top: curY,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                reaction.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulatedStreamContent() {
    return Container(
      color: const Color(0xFF131722),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 38),
          // Top bar simulated
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KiniChat UX Review',
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mobile Prototype • Wireflows v2.4',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryViolet.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '4K 60FPS',
                  style: TextStyle(
                    color: AppTheme.violetLight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Wireframe presentation card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.amberAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.tune, color: AppTheme.onSurfaceVariant, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.devices_rounded,
                            size: 56,
                            color: AppTheme.primaryCyan.withAlpha(180),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Luồng chia sẻ màn hình 1:1 siêu nét',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Độ trễ siêu thấp P2P • E2EE Quantum Guard',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Audio waveform indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, color: AppTheme.primaryCyan, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chia sẻ âm thanh hệ thống (Hi-Fi)',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BẬT',
                    style: TextStyle(
                      color: AppTheme.primaryCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingReaction {
  final String id;
  final String emoji;
  final double xOffset;

  _FloatingReaction({
    required this.id,
    required this.emoji,
    required this.xOffset,
  });
}
