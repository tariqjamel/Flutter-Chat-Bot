import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => {
      'text': m.text,
      'userId': m.user.id,
      'userName': m.user.firstName,
      'createdAt': m.createdAt.toIso8601String(),
      'image': m.medias?.firstOrNull?.url,
    }).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    var msgs = (json['messages'] as List).map((data) {
      final user = ChatUser(id: data['userId'], firstName: data['userName']);
      return ChatMessage(
        user: user,
        createdAt: DateTime.parse(data['createdAt']),
        text: data['text'] ?? "",
        medias: data['image'] != null ? [
          ChatMedia(url: data['image'], fileName: "", type: MediaType.image)
        ] : null,
      );
    }).toList();
    return ChatSession(id: json['id'], title: json['title'], messages: msgs);
  }
}

class HistoryManager {
  static const String _sessionsKey = 'chat_sessions';

  static Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    List<ChatSession> sessions = await getAllSessions();
    int index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }
    final String encodedData = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encodedData);
  }

  static Future<List<ChatSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_sessionsKey);
    if (encodedData == null) return [];
    final List<dynamic> decodedData = jsonDecode(encodedData);
    return decodedData.map((data) => ChatSession.fromJson(data)).toList();
  }

  static Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<ChatSession> sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == id);
    final String encodedData = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encodedData);
  }

  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
