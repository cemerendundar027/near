import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'hive_adapters.dart';

/// Mesaj kalıcılığını yöneten servis
class MessageStore extends ChangeNotifier {
  static final MessageStore instance = MessageStore._internal();
  MessageStore._internal();

  Box<Message>? _messagesBox;
  
  // Bellekte tuttuğumuz mesaj cache'i (chatId -> List<Message>)
  final Map<String, List<Message>> _messageCache = {};

  /// Hive kutusuna erişim
  Box<Message> get _box {
    _messagesBox ??= Hive.box<Message>(HiveBoxes.messages);
    return _messagesBox!;
  }

  /// Belirli bir sohbet için mesajları yükle
  List<Message> getMessages(String chatId) {
    // Önce cache'e bak
    if (_messageCache.containsKey(chatId)) {
      return _messageCache[chatId]!;
    }
    
    // Hive'dan yükle
    final messages = _box.values
        .where((m) => m.chatId == chatId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    _messageCache[chatId] = messages;
    return messages;
  }

  /// Mesaj ekle
  Future<void> addMessage(Message message) async {
    // Hive'a kaydet
    await _box.put(message.id, message);
    
    // Cache'i güncelle
    _messageCache.putIfAbsent(message.chatId, () => []);
    _messageCache[message.chatId]!.add(message);
    _messageCache[message.chatId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    notifyListeners();
  }

  /// Mesaj güncelle (örn. status değişikliği)
  Future<void> updateMessage(Message message) async {
    await _box.put(message.id, message);
    
    // Cache'i güncelle
    if (_messageCache.containsKey(message.chatId)) {
      final index = _messageCache[message.chatId]!.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messageCache[message.chatId]![index] = message;
      }
    }
    
    notifyListeners();
  }

  /// Mesaj sil
  Future<void> deleteMessage(String messageId, String chatId) async {
    await _box.delete(messageId);
    
    // Cache'den sil
    _messageCache[chatId]?.removeWhere((m) => m.id == messageId);
    
    notifyListeners();
  }

  /// Sohbetteki tüm mesajları sil
  Future<void> clearChat(String chatId) async {
    final messagesToDelete = _box.values
        .where((m) => m.chatId == chatId)
        .map((m) => m.id)
        .toList();
    
    for (final id in messagesToDelete) {
      await _box.delete(id);
    }
    
    _messageCache.remove(chatId);
    notifyListeners();
  }

  /// Son mesajı getir (ChatPreview için)
  Message? getLastMessage(String chatId) {
    final messages = getMessages(chatId);
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Okunmamış mesaj sayısı
  int getUnreadCount(String chatId) {
    final messages = getMessages(chatId);
    return messages.where((m) => !m.isMe && m.status != MessageStatus.read).length;
  }

  /// Tüm okunmamış mesaj sayısı
  int get totalUnreadCount {
    int count = 0;
    for (final messages in _messageCache.values) {
      count += messages.where((m) => !m.isMe && m.status != MessageStatus.read).length;
    }
    return count;
  }

  /// Tüm mesajları temizle
  Future<void> clearAll() async {
    await _box.clear();
    _messageCache.clear();
    notifyListeners();
  }

  /// Demo mesajları yükle (test amaçlı)
  Future<void> loadDemoMessages(String chatId, List<Message> messages) async {
    for (final message in messages) {
      await _box.put(message.id, message);
    }
    _messageCache[chatId] = List.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }
}
