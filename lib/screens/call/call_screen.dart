import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/call_model.dart';
import '../../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserName;
  final CallType callType;
  final bool isCaller;
  final String? callerId;
  final String? callerName;
  final String? receiverId;

  const CallScreen({
    super.key,
    required this.callId,
    required this.remoteUserName,
    required this.callType,
    this.isCaller = true,
    this.callerId,
    this.callerName,
    this.receiverId,
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
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      _remoteRenderer.onResize = () {
        if (mounted) setState(() {});
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
        await _webrtcService.startCall(
          callerId: widget.callerId ?? '',
          callerName: widget.callerName ?? '',
          receiverId: widget.receiverId ?? '',
          receiverName: widget.remoteUserName,
          type: widget.callType,
          remoteRenderer: _remoteRenderer,
          callId: widget.callId,
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
          if (mounted) Navigator.pop(context);
          return;
        }

        final data = snapshot.data();
        if (data != null) {
          final statusStr = data['status'] as String?;
          if (statusStr == CallStatus.connected.name) {
            if (mounted) {
              setState(() {
                _isConnected = true;
                _statusText = 'Đã kết nối';
              });
            }
          } else if (statusStr == CallStatus.ended.name || statusStr == CallStatus.rejected.name) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(statusStr == CallStatus.rejected.name ? 'Cuộc gọi đã bị từ chối' : 'Cuộc gọi đã kết thúc')),
              );
              Navigator.pop(context);
            }
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

  @override
  void dispose() {
    _callSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _endCall() async {
    await _webrtcService.endCall(widget.callId);
    if (mounted) Navigator.pop(context);
  }

  void _toggleScreenShare() async {
    if (_webrtcService.isScreenSharing) {
      await _webrtcService.stopScreenSharing(
        callId: widget.callId,
        localRenderer: _localRenderer,
      );
      if (mounted) setState(() {});
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Chia sẻ màn hình'),
          content: const Text('Ứng dụng sẽ truyền trực tiếp màn hình của bạn cho người tham gia cuộc gọi.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bắt đầu chia sẻ'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _webrtcService.startScreenSharing(
          callId: widget.callId,
          localRenderer: _localRenderer,
        );
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == CallType.video;
    final hasRemoteVideo = isVideo && _remoteRenderer.srcObject != null && _remoteRenderer.renderVideo;

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
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  ],
                ),
              ),

            // Local Video (Picture-in-picture) khi gọi video
            if (isVideo)
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
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Header thông tin cuộc gọi
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.remoteUserName,
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isVideo ? 'Cuộc gọi Video' : 'Cuộc gọi Thoại',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
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
