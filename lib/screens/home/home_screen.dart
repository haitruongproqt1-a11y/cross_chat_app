import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/call_model.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/chat_detail_screen.dart';
import '../call/call_screen.dart';
import '../nearby/nearby_friends_screen.dart';
import '../wall/user_wall_screen.dart';
import '../../services/call_sound_service.dart';
import '../../services/notification_service.dart';
import '../../services/ota_update_service.dart';
import '../../services/localization_service.dart';
import 'chat_list_view.dart';
import 'contacts_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<QuerySnapshot>? _incomingCallSub;
  StreamSubscription<QuerySnapshot>? _incomingMessageSub;
  String? _activeIncomingCallId;
  final int _initTimestamp = DateTime.now().millisecondsSinceEpoch;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final List<Widget> _views = const [
    ChatListView(),
    ContactsView(),
    NearbyFriendsScreen(),
    UserWallScreen(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls();
      _listenForIncomingMessages();
      // Tự động kiểm tra bản cập nhật nền khi khởi động
      OtaUpdateService().checkUpdate(context, showNoUpdateDialog: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomingCallSub?.cancel();
    _incomingMessageSub?.cancel();
    super.dispose();
  }

  void _listenForIncomingMessages() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    _incomingMessageSub = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final senderId = data['lastMessageSenderId'] as String?;
          if (senderId == null || senderId == user.uid) continue;

          int? msgTimeMs;
          final rawTime = data['lastMessageTime'];
          if (rawTime is int) {
            msgTimeMs = rawTime;
          } else if (rawTime is Timestamp) {
            msgTimeMs = rawTime.millisecondsSinceEpoch;
          }

          if (msgTimeMs == null || msgTimeMs < _initTimestamp) continue;

          final roomId = change.doc.id;
          if (ChatDetailScreen.activeRoomId == roomId) continue;

          // CHỈ hiện thông báo khi người dùng KHÔNG ở trong ứng dụng (app chạy nền / ẩn)
          if (_lifecycleState == AppLifecycleState.resumed) continue;

          final senderName = (data['lastMessageSenderName'] as String?)?.isNotEmpty == true
              ? data['lastMessageSenderName'] as String
              : (data['name'] as String? ?? 'Tin nhắn mới');
          final messageText = data['lastMessage'] as String? ?? 'Bạn có tin nhắn mới';

          CallSoundService().playMessageChime();
          NotificationService().showLocalNotification(
            id: roomId.hashCode,
            title: senderName,
            body: messageText,
            payload: roomId,
          );
        }
      }
    });
  }

  void _listenForIncomingCalls() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    _incomingCallSub = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: user.uid)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        CallSoundService().stop();
        if (_activeIncomingCallId != null && _incomingCallCtx != null) {
          if (mounted && Navigator.canPop(_incomingCallCtx!)) {
            Navigator.pop(_incomingCallCtx!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Người gọi đã kết thúc cuộc gọi')),
            );
          }
          _activeIncomingCallId = null;
          _incomingCallCtx = null;
        }
        return;
      }

      final callDoc = snapshot.docs.first;
      final callId = callDoc.id;
      final data = callDoc.data();

      if (_activeIncomingCallId == callId) return; // Đang hiển thị cho cuộc gọi này rồi

      _activeIncomingCallId = callId;
      final callerName = data['callerName'] ?? 'Người dùng KINI';
      final callTypeStr = data['type'] as String?;
      final isVideo = callTypeStr == CallType.video.name;
      final roomId = data['roomId'] as String?;

      CallSoundService().playRingtone();

      // Chỉ hiển thị notification banner khi app ở chế độ nền
      if (_lifecycleState != AppLifecycleState.resumed) {
        NotificationService().showLocalNotification(
          id: callId.hashCode,
          title: isVideo ? '📞 Cuộc gọi video đến' : '📞 Cuộc gọi thoại đến',
          body: '$callerName đang gọi cho bạn...',
          payload: roomId,
        );
      }

      _showIncomingCallDialog(
        callId: callId,
        callerName: callerName,
        isVideo: isVideo,
        roomId: roomId,
      );
    });
  }

  BuildContext? _incomingCallCtx;

  void _showIncomingCallDialog({
    required String callId,
    required String callerName,
    required bool isVideo,
    String? roomId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _incomingCallCtx = ctx;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isVideo ? Icons.videocam : Icons.phone_in_talk,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text('Cuộc Gọi Đến', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent.withAlpha(200),
              child: Text(
                callerName.isNotEmpty ? callerName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              callerName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isVideo ? 'Đang gọi video cho bạn...' : 'Đang gọi thoại cho bạn...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // Nút Từ chối
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.call_end),
            label: const Text('Từ chối'),
            onPressed: () async {
              CallSoundService().stop();
              _activeIncomingCallId = null;
              _incomingCallCtx = null;
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('calls').doc(callId).update({
                'status': CallStatus.rejected.name,
              });
            },
          ),
          // Nút Trả lời
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: Icon(isVideo ? Icons.videocam : Icons.call),
            label: const Text('Trả lời'),
            onPressed: () {
              CallSoundService().stop();
              _activeIncomingCallId = null;
              _incomingCallCtx = null;
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callId: callId,
                    remoteUserName: callerName,
                    callType: isVideo ? CallType.video : CallType.audio,
                    isCaller: false,
                    roomId: roomId,
                  ),
                ),
              );
            },
          ),
        ],
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      desktopBody: _buildDesktopLayout(),
    );
  }

  // Giao diện Mobile với thanh điều hướng đáy (BottomNavigationBar)
  Widget _buildMobileLayout() {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: loc.t('tab_messages'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.contacts_outlined),
            selectedIcon: const Icon(Icons.contacts),
            label: loc.t('tab_contacts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: loc.t('tab_nearby'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: loc.t('tab_wall'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: loc.t('tab_settings'),
          ),
        ],
      ),
    );
  }

  // Giao diện PC / Desktop chia 2 cột (Split-Pane)
  Widget _buildDesktopLayout() {
    final chatProvider = Provider.of<ChatProvider>(context);
    final activeRoom = chatProvider.activeRoom;
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      body: Row(
        children: [
          // Cột thanh điều hướng trái
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(Icons.forum_rounded, size: 36, color: Colors.blueAccent),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: Text(loc.t('tab_messages')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.contacts_outlined),
                selectedIcon: const Icon(Icons.contacts),
                label: Text(loc.t('tab_contacts')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: Text(loc.t('tab_nearby')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.dynamic_feed_outlined),
                selectedIcon: const Icon(Icons.dynamic_feed),
                label: Text(loc.t('tab_wall')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: Text(loc.t('tab_settings')),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Cột giữa: Danh sách (Tin nhắn / Danh bạ / Quanh đây / Cài đặt)
          SizedBox(
            width: 360,
            child: _views[_currentIndex],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Cột phải: Khung chat chi tiết hoặc màn hình chào mừng
          Expanded(
            child: activeRoom != null
                ? ChatDetailScreen(key: ValueKey(activeRoom.id), room: activeRoom)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withAlpha(20),
                          ),
                          child: Icon(
                            Icons.question_answer_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'KINI CHAT Máy Tính',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chọn một liên hệ hoặc nhóm bên trái để bắt đầu cuộc trò chuyện thời gian thực.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
