import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  ChatRoomModel? _activeRoom;
  ThemeMode _themeMode = ThemeMode.system;

  ChatRoomModel? get activeRoom => _activeRoom;
  ThemeMode get themeMode => _themeMode;

  void setActiveRoom(ChatRoomModel? room) {
    _activeRoom = room;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Stream<List<ChatRoomModel>> getRooms(String uid) {
    return _chatService.getChatRooms(uid);
  }

  Stream<List<UserModel>> getContacts(String uid) {
    return _chatService.getAllUsers(uid);
  }
}
