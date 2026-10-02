import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/call_model.dart';
import '../../services/webrtc_service.dart';
import '../../services/call_sound_service.dart';
import '../../services/chat_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserName;
  final CallType callType;
  final bool isCaller;
  final String? callerId;
  final String? callerName;
  final String? receiverId;
  final String? roomId;

  const CallScreen({
    super.key,
    required this.callId,
    required this.remoteUserName,
    required this.callType,
    this.isCaller = true,
    this.callerId,
    this.callerName,
    this.receiverId,
    this.roomId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRtcService _webrtcService = WebRtcService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  String _statusText = 'Đang chuẩn bị cuộc gọi...';
  bool _isConnected = false;
  bool _isCallEnded = false;
  int _callSeconds = 0;
  Timer? _callTimer;
  Timer? _pingTimer;
  int _pingMs = 35;
  bool _remoteIsScreenSharing = false;
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _isSpeakerOn = widget.callType == CallType.video;
    _initCall();
  }

  void _startTimers() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _callSeconds++;
      });
    });

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      final ping = await _webrtcService.getPingMs();
      if (mounted && ping != null && ping > 0) {
        setState(() {
          _pingMs = ping;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _initCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      _remoteRenderer.onResize = () {
        if (mounted) setState(() {});
      };

      _webrtcService.onConnectionConnected = () {
        CallSoundService().stop();
        if (!_isConnected && mounted) {
          setState(() {
            _isConnected = true;
            _statusText = 'Đã kết nối';
          });
          _startTimers();
        }
      };

      _webrtcService.onConnectionDisconnected = () {
        CallSoundService().stop();
        _closeCallScreen('Cuộc gọi bị mất kết nối');
      };

      final isVideo = widget.callType == CallType.video;
      await _webrtcService.initLocalStream(
        isVideo: isVideo,
        localRenderer: _localRenderer,
      );

      if (mounted) {
        setState(() {
          _statusText = widget.isCaller ? 'Đang đổ chuông...' : 'Đang kết nối...';
        });
      }

      if (widget.isCaller) {
        CallSoundService().playRingback();
        await _webrtcService.startCall(
          callerId: widget.callerId ?? '',
          callerName: widget.callerName ?? '',
          receiverId: widget.receiverId ?? '',
          receiverName: widget.remoteUserName,
          type: widget.callType,
          remoteRenderer: _remoteRenderer,
          callId: widget.callId,
          roomId: widget.roomId,
        );
      } else {
        await _webrtcService.answerCall(
          callId: widget.callId,
          remoteRenderer: _remoteRenderer,
        );
      }

      // Lắng nghe trạng thái cuộc gọi từ Firestore
      _callSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          _closeCallScreen();
          return;
        }

        final data = snapshot.data();
        if (data != null) {
          final isSharing = data['isScreenSharing'] as bool? ?? false;
          if (_remoteIsScreenSharing != isSharing && mounted) {
            setState(() {
              _remoteIsScreenSharing = isSharing;
            });
          }

          final statusStr = data['status'] as String?;
          if (statusStr == CallStatus.connected.name) {
            if (!_isConnected && mounted) {
              setState(() {
                _isConnected = true;
                _statusText = 'Đã kết nối';
              });
              _startTimers();
            }
          } else if (statusStr == CallStatus.ended.name || statusStr == CallStatus.rejected.name) {
            _closeCallScreen(statusStr == CallStatus.rejected.name ? 'Cuộc gọi đã bị từ chối' : 'Cuộc gọi đã kết thúc');
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Lỗi kết nối: $e';
        });
      }
    }
  }

  void _closeCallScreen([String? message]) {
    if (_isCallEnded) return;
    _isCallEnded = true;

    CallSoundService().stop();

    _callTimer?.cancel();
    _pingTimer?.cancel();
    _callSubscription?.cancel();

    if (widget.roomId != null && widget.isCaller) {
      ChatService().sendCallLogMessage(
        roomId: widget.roomId!,
        callerId: widget.callerId ?? '',
        callerName: widget.callerName ?? '',
        isVideo: widget.callType == CallType.video,
        isConnected: _isConnected,
        durationSeconds: _callSeconds,
      );
    }

    // Gỡ srcObject khỏi renderers trước khi đóng để tránh crash/treo luồng native WebRTC
    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    } catch (_) {}

    _webrtcService.endCall(widget.callId);

    if (mounted) {
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    CallSoundService().stop();
    _callTimer?.cancel();
    _pingTimer?.cancel();
    _callSubscription?.cancel();
    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
      _localRenderer.dispose();
      _remoteRenderer.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _endCall() {
    _closeCallScreen('Bạn đã kết thúc cuộc gọi');
  }

  void _toggleScreenShare() async {
    if (_webrtcService.isScreenSharing) {
      await _webrtcService.stopScreenSharing(
        callId: widget.callId,
        localRenderer: _localRenderer,
      );
      if (mounted) setState(() {});
    } else {
      bool shareAudio = true;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.screen_share, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Chia sẻ màn hình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ứng dụng sẽ truyền trực tiếp hình ảnh màn hình của bạn cho người tham gia cuộc gọi.'),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withAlpha(40)),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      value: shareAudio,
                      title: const Text('Phát âm thanh thiết bị', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Truyền cả tiếng nhạc, video YouTube hoặc game sang máy bên kia trong khi vẫn đàm thoại bằng micro.', style: TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setDialogState(() {
                          shareAudio = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Bắt đầu chia sẻ'),
                ),
              ],
            );
          },
        ),
      );

      if (confirm == true) {
        final success = await _webrtcService.startScreenSharing(
          callId: widget.callId,
          localRenderer: _localRenderer,
          shareDeviceAudio: shareAudio,
        );
        if (mounted) {
          setState(() {});
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể bắt đầu chia sẻ màn hình. Vui lòng cấp quyền ghi màn hình.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == CallType.video;
    final hasRemoteVideo = (isVideo || _remoteIsScreenSharing) && _remoteRenderer.srcObject != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video hoặc Giao diện Avatar khi chưa có video
            if (hasRemoteVideo)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: _remoteIsScreenSharing
                      ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
                      : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.blueAccent.withAlpha(200),
                      child: Text(
                        widget.remoteUserName.isNotEmpty ? widget.remoteUserName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.remoteUserName,
                      style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_isConnected) ...[
                      Text(
                        _formatDuration(_callSeconds),
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isConnected ? Colors.green.withAlpha(50) : Colors.orange.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isConnected ? Colors.green : Colors.orange),
                          ),
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: _isConnected ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_isConnected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.cyanAccent, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi, size: 14, color: Colors.cyanAccent),
                                const SizedBox(width: 4),
                                Text(
                                  'Ping: ${_pingMs}ms',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

            // Local Video (Picture-in-picture) khi gọi video hoặc đang chia sẻ màn hình
            if (isVideo || _webrtcService.isScreenSharing)
              Positioned(
                top: 20,
                right: 20,
                width: 110,
                height: 155,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: !_webrtcService.isScreenSharing,
                      objectFit: _webrtcService.isScreenSharing
                          ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
                          : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Thông báo đang chia sẻ màn hình
            if (_webrtcService.isScreenSharing)
              Positioned(
                top: 78,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.screen_share, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Bạn đang chia sẻ màn hình', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (_remoteIsScreenSharing)
              Positioned(
                top: 78,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_share, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('${widget.remoteUserName} đang chia sẻ màn hình', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            // Header thông tin cuộc gọi
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.remoteUserName,
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isConnected ? _formatDuration(_callSeconds) : (isVideo ? 'Cuộc gọi Video' : 'Cuộc gọi Thoại'),
                          style: TextStyle(
                            color: _isConnected ? Colors.greenAccent : Colors.white70,
                            fontSize: 13,
                            fontWeight: _isConnected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (_isConnected) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Ping: ${_pingMs}ms',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Thanh điều khiển phía dưới
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Mic
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                      tooltip: _isMuted ? 'Bật mic' : 'Tắt mic',
                      color: _isMuted ? Colors.black : Colors.white,
                      onPressed: () {
                        setState(() => _isMuted = !_isMuted);
                        _webrtcService.toggleAudio(_isMuted);
                      },
                    ),
                  ),

                  // Nút chia sẻ màn hình (Screen Sharing)
                  if (isVideo)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _webrtcService.isScreenSharing ? Colors.green : Colors.white24,
                      child: IconButton(
                        icon: Icon(_webrtcService.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share),
                        tooltip: _webrtcService.isScreenSharing ? 'Dừng chia sẻ' : 'Chia sẻ màn hình',
                        color: Colors.white,
                        onPressed: _toggleScreenShare,
                      ),
                    ),

                  // Nút kết thúc cuộc gọi
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.redAccent,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, size: 30, color: Colors.white),
                      tooltip: 'Kết thúc cuộc gọi',
                      onPressed: _endCall,
                    ),
                  ),

                  // Toggle Camera / Đổi Camera
                  if (isVideo)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isVideoOff ? Colors.white : Colors.white24,
                      child: IconButton(
                        icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                        tooltip: _isVideoOff ? 'Mở camera' : 'Tắt camera',
                        color: _isVideoOff ? Colors.black : Colors.white,
                        onPressed: () {
                          setState(() => _isVideoOff = !_isVideoOff);
                          _webrtcService.toggleVideo(_isVideoOff);
                        },
                      ),
                    ),
                  // Nút Loa ngoài (Speakerphone)
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _isSpeakerOn ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_off),
                      tooltip: _isSpeakerOn ? 'Tắt loa ngoài' : 'Bật loa ngoài',
                      color: _isSpeakerOn ? Colors.black : Colors.white,
                      onPressed: () {
                        setState(() => _isSpeakerOn = !_isSpeakerOn);
                        _webrtcService.toggleSpeaker(_isSpeakerOn);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
