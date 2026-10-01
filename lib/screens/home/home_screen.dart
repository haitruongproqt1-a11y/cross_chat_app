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
import 'chat_list_view.dart';
import 'contacts_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<QuerySnapshot>? _incomingCallSub;
  String? _activeIncomingCallId;

  final List<Widget> _views = const [
    ChatListView(),
    ContactsView(),
    NearbyFriendsScreen(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls();
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
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
      if (snapshot.docs.isNotEmpty) {
        final callDoc = snapshot.docs.first;
        final callId = callDoc.id;
        final data = callDoc.data();

        if (_activeIncomingCallId == callId) return; // Đang hiển thị cho cuộc gọi này rồi

        _activeIncomingCallId = callId;
        final callerName = data['callerName'] ?? 'Người dùng KINI';
        final callTypeStr = data['type'] as String?;
        final isVideo = callTypeStr == CallType.video.name;

        _showIncomingCallDialog(
          callId: callId,
          callerName: callerName,
          isVideo: isVideo,
        );
      }
    });
  }

  void _showIncomingCallDialog({
    required String callId,
    required String callerName,
    required bool isVideo,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
              _activeIncomingCallId = null;
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
              _activeIncomingCallId = null;
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    callId: callId,
                    remoteUserName: callerName,
                    callType: isVideo ? CallType.video : CallType.audio,
                    isCaller: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Trò chuyện',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Danh bạ',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Quanh đây',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  // Giao diện PC / Desktop chia 2 cột (Split-Pane)
  Widget _buildDesktopLayout() {
    final chatProvider = Provider.of<ChatProvider>(context);
    final activeRoom = chatProvider.activeRoom;

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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Trò chuyện'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Danh bạ'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('Quanh đây'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Cài đặt'),
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
