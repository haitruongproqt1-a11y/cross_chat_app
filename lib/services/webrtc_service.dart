import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_model.dart';

class WebRtcService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  VoidCallback? onConnectionConnected;
  VoidCallback? onConnectionDisconnected;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      // 1. Google Public STUN Servers (100% Free P2P Direct)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},

      // 2. Twilio & Cloudflare STUN Servers
      {'urls': 'stun:global.stun.twilio.com:3478'},
      {'urls': 'stun:stun.cloudflare.com:3478'},

      // 3. OpenRelay Free TURN Servers (Xuyên qua mọi NAT, Firewall, 4G/5G, Giả lập)
      {
        'urls': [
          'stun:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turn:openrelay.metered.ca:443?transport=udp',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  String _optimizeSdp(String sdp) {
    final lines = sdp.split('\r\n');
    final modifiedLines = <String>[];
    String? opusPayloadType;

    for (var line in lines) {
      if (line.startsWith('a=rtpmap:') && line.toLowerCase().contains('opus/48000')) {
        final match = RegExp(r'a=rtpmap:(\d+)\s+opus/48000', caseSensitive: false).firstMatch(line);
        if (match != null) {
          opusPayloadType = match.group(1);
        }
      }
    }

    for (var line in lines) {
      var currentLine = line;
      if (opusPayloadType != null && currentLine.startsWith('a=fmtp:$opusPayloadType')) {
        if (!currentLine.contains('minptime=')) {
          currentLine = '$currentLine;minptime=10;ptime=20;maxaveragebitrate=64000;stereo=0;sprop-stereo=0;useinbandfec=1;usedtx=1';
        }
      }
      modifiedLines.add(currentLine);
      if (currentLine.startsWith('m=video')) {
        modifiedLines.add('b=AS:2000'); // 2 Mbps max video bitrate to eliminate bufferbloat and lag
      }
    }
    return modifiedLines.join('\r\n');
  }

  Future<void> initLocalStream({required bool isVideo, required RTCVideoRenderer localRenderer}) async {
    final audioConstraints = <String, dynamic>{
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'googEchoCancellation': true,
      'googNoiseSuppression': true,
      'googAutoGainControl': true,
      'googHighpassFilter': true,
      'googTypingNoiseDetection': true,
    };

    final mediaConstraints = <String, dynamic>{
      'audio': audioConstraints,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640, 'max': 1280},
              'height': {'ideal': 480, 'max': 720},
              'frameRate': {'ideal': 30, 'max': 30},
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      // Bật và kích hoạt mic rõ ràng
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
        try {
          Helper.setMicrophoneMute(false, track);
        } catch (_) {}
      });

      localRenderer.srcObject = _localStream;

      // Loa ngoài chỉ bật khi là cuộc gọi video. Cuộc gọi thoại mặc định dùng loa trong để chống rú rít và vọng âm
      try {
        await Helper.setSpeakerphoneOn(isVideo);
      } catch (_) {}
    } catch (e) {
      debugPrint('Lỗi mở Camera/Mic: $e');
      if (isVideo) {
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
          _localStream?.getAudioTracks().forEach((track) {
            track.enabled = true;
            try {
              Helper.setMicrophoneMute(false, track);
            } catch (_) {}
          });
          localRenderer.srcObject = _localStream;
          try {
            await Helper.setSpeakerphoneOn(false);
          } catch (_) {}
        } catch (_) {}
      }
    }
  }

  Future<String> startCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverName,
    required CallType type,
    required RTCVideoRenderer remoteRenderer,
    String? callId,
    String? roomId,
  }) async {
    final callDoc = (callId != null && callId.isNotEmpty)
        ? _firestore.collection('calls').doc(callId)
        : _firestore.collection('calls').doc();
    final realCallId = callDoc.id;

    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        callDoc.collection('callerCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    final isVideoCall = type == CallType.video;

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      onConnectionConnected?.call();
      try {
        Helper.setSpeakerphoneOn(isVideoCall);
      } catch (_) {}
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(isVideoCall);
        } catch (_) {}
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('WebRTC ICE State (Caller): $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(isVideoCall);
        } catch (_) {}
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onConnectionDisconnected?.call();
      }
    };

    // Add local tracks
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Create SDP Offer with Ultra-Low Latency & Anti-Lag optimizations
    final offer = await _peerConnection!.createOffer();
    final optimizedSdp = _optimizeSdp(offer.sdp ?? '');
    final optimizedOffer = RTCSessionDescription(optimizedSdp, offer.type);
    await _peerConnection!.setLocalDescription(optimizedOffer);

    final callSession = CallSessionModel(
      roomId: roomId,
      callId: realCallId,
      callerId: callerId,
      callerName: callerName,
      receiverId: receiverId,
      receiverName: receiverName,
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      sdpOffer: optimizedOffer.toMap(),
    );

    await callDoc.set(callSession.toMap());

    // Hàng đợi lưu trữ Candidate để tránh Race condition trước khi setRemoteDescription
    bool isRemoteDescSet = false;
    final List<RTCIceCandidate> candidateQueue = [];

    // Lắng nghe Answer từ máy nhận
    callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data != null && data['sdpAnswer'] != null && !isRemoteDescSet) {
        final answer = RTCSessionDescription(
          data['sdpAnswer']['sdp'],
          data['sdpAnswer']['type'],
        );
        await _peerConnection?.setRemoteDescription(answer);
        isRemoteDescSet = true;

        // Xả toàn bộ hàng đợi candidate
        for (var c in candidateQueue) {
          try {
            await _peerConnection?.addCandidate(c);
          } catch (e) {
            debugPrint('Error draining candidate: $e');
          }
        }
        candidateQueue.clear();

        try {
          await Helper.setSpeakerphoneOn(isVideoCall);
        } catch (_) {}
      }
    });

    // Lắng nghe ICE candidates từ máy nhận
    callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['candidate'] != null) {
            final mLine = data['sdpMLineIndex'] ?? data['sdpMlineIndex'] ?? 0;
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              mLine is int ? mLine : int.tryParse(mLine.toString()) ?? 0,
            );

            if (isRemoteDescSet && _peerConnection != null) {
              try {
                _peerConnection?.addCandidate(candidate);
              } catch (_) {}
            } else {
              candidateQueue.add(candidate);
            }
          }
        }
      }
    });

    return realCallId;
  }

  Future<void> answerCall({
    required String callId,
    required RTCVideoRenderer remoteRenderer,
  }) async {
    final callDoc = _firestore.collection('calls').doc(callId);
    final callData = (await callDoc.get()).data();
    if (callData == null) return;

    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        callDoc.collection('receiverCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    final isVideoCall = callData['type'] == CallType.video.name;

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      onConnectionConnected?.call();
      try {
        Helper.setSpeakerphoneOn(isVideoCall);
      } catch (_) {}
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(isVideoCall);
        } catch (_) {}
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('Receiver ICE State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(isVideoCall);
        } catch (_) {}
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onConnectionDisconnected?.call();
      }
    };

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // 1. Set Remote Offer trước
    final offerData = callData['sdpOffer'];
    if (offerData != null) {
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], offerData['type']),
      );
    }

    // 2. Tạo và Set SDP Answer với tối ưu độ trễ thấp
    final answer = await _peerConnection!.createAnswer();
    final optimizedSdp = _optimizeSdp(answer.sdp ?? '');
    final optimizedAnswer = RTCSessionDescription(optimizedSdp, answer.type);
    await _peerConnection!.setLocalDescription(optimizedAnswer);

    await callDoc.update({
      'sdpAnswer': optimizedAnswer.toMap(),
      'status': CallStatus.connected.name,
    });

    try {
      await Helper.setSpeakerphoneOn(isVideoCall);
    } catch (_) {}

    // 3. Lắng nghe caller candidates
    callDoc.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['candidate'] != null) {
            final mLine = data['sdpMLineIndex'] ?? data['sdpMlineIndex'] ?? 0;
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              mLine is int ? mLine : int.tryParse(mLine.toString()) ?? 0,
            );
            try {
              _peerConnection?.addCandidate(candidate);
            } catch (e) {
              debugPrint('Lỗi add candidate: $e');
            }
          }
        }
      }
    });
  }

  void toggleAudio(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleVideo(bool isVideoOff) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isVideoOff;
    });
  }

  void toggleSpeaker(bool isSpeakerOn) {
    try {
      Helper.setSpeakerphoneOn(isSpeakerOn);
    } catch (_) {}
  }

  void switchCamera() {
    _localStream?.getVideoTracks().forEach((track) {
      Helper.switchCamera(track);
    });
  }

  Future<int?> getPingMs() async {
    try {
      if (_peerConnection == null) return null;
      final stats = await _peerConnection!.getStats();
      for (var report in stats) {
        if (report.type == 'candidate-pair') {
          final rtt = report.values['currentRoundTripTime'] ?? report.values['roundTripTime'];
          if (rtt != null) {
            final val = double.tryParse(rtt.toString());
            if (val != null && val > 0) {
              return (val * 1000).toInt();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  MediaStream? _screenStream;
  bool _isScreenSharing = false;
  bool get isScreenSharing => _isScreenSharing;

  Future<bool> startScreenSharing({
    required String callId,
    required RTCVideoRenderer localRenderer,
    bool shareDeviceAudio = false,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          const channel = MethodChannel('com.example.cross_chat_app/screen_share');
          await channel.invokeMethod('startService');
        } catch (e) {
          debugPrint('Error starting ScreenCaptureService: $e');
        }
      }

      final mediaConstraints = <String, dynamic>{
        'video': {
          'mandatory': {
            'minWidth': 720,
            'minHeight': 1280,
            'maxWidth': 1080,
            'maxHeight': 1920,
            'maxFrameRate': 30,
          },
          'optional': [
            {'googCpuOveruseDetection': true},
          ],
        },
        'audio': shareDeviceAudio,
      };

      _screenStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      final screenTrack = _screenStream?.getVideoTracks().firstOrNull;

      if (screenTrack != null && _peerConnection != null) {
        final senders = await _peerConnection!.getSenders();
        bool videoSenderFound = false;
        for (var sender in senders) {
          if (sender.track?.kind == 'video') {
            await sender.replaceTrack(screenTrack);
            videoSenderFound = true;
          }
        }
        if (!videoSenderFound) {
          await _peerConnection!.addTrack(screenTrack, _screenStream!);
        }
        localRenderer.srcObject = _screenStream;
      }

      // Đảm bảo micro từ localStream vẫn bật để 2 bên tiếp tục đàm thoại
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
        try {
          Helper.setMicrophoneMute(false, track);
        } catch (_) {}
      });

      // Nếu chia sẻ âm thanh thiết bị (nhạc / video), gửi kèm track âm thanh đó
      final screenAudioTrack = _screenStream?.getAudioTracks().firstOrNull;
      if (screenAudioTrack != null && _peerConnection != null) {
        await _peerConnection!.addTrack(screenAudioTrack, _screenStream!);
      }

      _isScreenSharing = true;
      await _firestore.collection('calls').doc(callId).update({
        'isScreenSharing': true,
      });

      screenTrack?.onEnded = () {
        stopScreenSharing(callId: callId, localRenderer: localRenderer);
      };

      return true;
    } catch (e) {
      debugPrint('Lỗi chia sẻ màn hình: $e');
      return false;
    }
  }

  Future<void> stopScreenSharing({
    required String callId,
    required RTCVideoRenderer localRenderer,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          const channel = MethodChannel('com.example.cross_chat_app/screen_share');
          await channel.invokeMethod('stopService');
        } catch (e) {
          debugPrint('Error stopping ScreenCaptureService: $e');
        }
      }

      _screenStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      _screenStream?.dispose();
      _screenStream = null;

      final cameraTrack = _localStream?.getVideoTracks().firstOrNull;
      if (cameraTrack != null && _peerConnection != null) {
        final senders = await _peerConnection!.getSenders();
        for (var sender in senders) {
          if (sender.track?.kind == 'video') {
            await sender.replaceTrack(cameraTrack);
          }
        }
        localRenderer.srcObject = _localStream;
      }

      _isScreenSharing = false;
      await _firestore.collection('calls').doc(callId).update({
        'isScreenSharing': false,
      });
    } catch (e) {
      debugPrint('Lỗi dừng chia sẻ màn hình: $e');
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': CallStatus.ended.name,
      });
    } catch (_) {}

    // Dừng service chia sẻ màn hình nếu còn đang chạy
    if (defaultTargetPlatform == TargetPlatform.android && _isScreenSharing) {
      try {
        const channel = MethodChannel('com.example.cross_chat_app/screen_share');
        channel.invokeMethod('stopService');
      } catch (_) {}
    }

    // 1. Vô hiệu hóa toàn bộ callback để không bị đơ hoặc gọi chéo trong lúc hủy
    try {
      _peerConnection?.onIceCandidate = null;
      _peerConnection?.onTrack = null;
      _peerConnection?.onAddStream = null;
      _peerConnection?.onIceConnectionState = null;
    } catch (_) {}

    // 2. Dừng stream chia sẻ màn hình
    try {
      _screenStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      _screenStream?.dispose();
    } catch (_) {}
    _screenStream = null;
    _isScreenSharing = false;

    // 3. Dừng stream local
    try {
      _localStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    // 4. Giải phóng remote stream
    try {
      _remoteStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
      _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;

    // 5. Đóng RTCPeerConnection an toàn
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;
  }
}
