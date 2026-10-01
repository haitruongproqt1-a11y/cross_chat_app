import 'package:flutter/foundation.dart';
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

  Future<void> initLocalStream({required bool isVideo, required RTCVideoRenderer localRenderer}) async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 25},
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

      // Kích hoạt loa ngoài để đàm thoại 2 chiều to rõ
      try {
        await Helper.setSpeakerphoneOn(true);
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
            await Helper.setSpeakerphoneOn(true);
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

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      onConnectionConnected?.call();
      try {
        Helper.setSpeakerphoneOn(true);
      } catch (_) {}
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('WebRTC ICE State (Caller): $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(true);
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

    // Create SDP Offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    final callSession = CallSessionModel(
      callId: realCallId,
      callerId: callerId,
      callerName: callerName,
      receiverId: receiverId,
      receiverName: receiverName,
      type: type,
      status: CallStatus.ringing,
      createdAt: DateTime.now(),
      sdpOffer: offer.toMap(),
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
          await Helper.setSpeakerphoneOn(true);
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

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      remoteRenderer.srcObject = _remoteStream;
      onConnectionConnected?.call();
      try {
        Helper.setSpeakerphoneOn(true);
      } catch (_) {}
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('Receiver ICE State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onConnectionConnected?.call();
        try {
          Helper.setSpeakerphoneOn(true);
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

    // 2. Tạo và Set SDP Answer
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await callDoc.update({
      'sdpAnswer': answer.toMap(),
      'status': CallStatus.connected.name,
    });

    try {
      await Helper.setSpeakerphoneOn(true);
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
  }) async {
    try {
      final mediaConstraints = <String, dynamic>{
        'video': true,
        'audio': false,
      };

      _screenStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      final screenTrack = _screenStream?.getVideoTracks().firstOrNull;

      if (screenTrack != null && _peerConnection != null) {
        final senders = await _peerConnection!.getSenders();
        for (var sender in senders) {
          if (sender.track?.kind == 'video') {
            await sender.replaceTrack(screenTrack);
          }
        }
        localRenderer.srcObject = _screenStream;
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
      _screenStream?.getTracks().forEach((track) => track.stop());
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

    _screenStream?.getTracks().forEach((track) => track.stop());
    _screenStream?.dispose();
    _screenStream = null;
    _isScreenSharing = false;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    await _peerConnection?.close();
    _peerConnection = null;
  }
}
