import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'chat_service.dart';

class ChatStore extends ChangeNotifier {
  ChatStore._();
  static final instance = ChatStore._();

  SharedPreferences? _prefs;
  bool _initialized = false;
  final _chatService = ChatService.instance;

  // Chat listesi cache (Supabase'den güncellenir)
  List<ChatPreview> _chats = [];

  final Map<String, int> _unread = {};
  final Map<String, bool> _typing = {};
  String? _activeChatId;

  // Presence artık Supabase'den alınıyor
  final Map<String, Presence> _presenceByUserId = {};

  final Set<String> _mutedUserIds = {};
  final Set<String> _blockedUserIds = {};

  // ✅ Backend hazırlığı: pinned chats (UI'dan başlar, backend gelince sync)
  final Set<String> _pinnedChatIds = {};

  // ✅ Backend hazırlığı: archived chats
  final Set<String> _archivedChatIds = {};

  // ✅ Draft messages - taslak mesajlar
  final Map<String, String> _draftMessages = {};

  // ✅ Quick replies - hazır yanıtlar
  List<String> _quickReplies = [
    'Tamam 👍',
    'Teşekkürler! 🙏',
    'Şimdi uygun değilim',
    'Hemen dönüyorum',
    'Tamam, anlaştık ✅',
    'Birazdan yazarım',
    'OK',
    '❤️',
    '😂',
    '👏',
  ];

  /// SharedPreferences'ı yükle ve ChatService'i başlat
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadFromStorage();
    
    // ChatService'i başlat ve Supabase'den chatleri yükle
    await _chatService.init();
    
    // ChatService değişikliklerini dinle
    _chatService.addListener(_onChatServiceUpdate);
    
    _initialized = true;
    notifyListeners();
  }

  void _onChatServiceUpdate() {
    // ChatService güncellendiğinde cache'i güncelle
    _chats = _convertSupabaseChats();
    
    // UI'ı güncelle (build sonrasında)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _loadFromStorage() {
    if (_prefs == null) return;

    // Pinned chats
    final pinnedList = _prefs!.getStringList('pinnedChatIds') ?? [];
    _pinnedChatIds.addAll(pinnedList);

    // Archived chats
    final archivedList = _prefs!.getStringList('archivedChatIds') ?? [];
    _archivedChatIds.addAll(archivedList);

    // Muted users
    final mutedList = _prefs!.getStringList('mutedUserIds') ?? [];
    _mutedUserIds.addAll(mutedList);

    // Blocked users
    final blockedList = _prefs!.getStringList('blockedUserIds') ?? [];
    _blockedUserIds.addAll(blockedList);

    // Quick replies
    final quickList = _prefs!.getStringList('quickReplies');
    if (quickList != null && quickList.isNotEmpty) {
      _quickReplies = quickList;
    }

    // Draft messages
    final draftKeys = _prefs!.getKeys().where((k) => k.startsWith('draft_'));
    for (final key in draftKeys) {
      final chatId = key.replaceFirst('draft_', '');
      final draft = _prefs!.getString(key);
      if (draft != null && draft.isNotEmpty) {
        _draftMessages[chatId] = draft;
      }
    }
  }

  Future<void> _saveStringList(String key, Iterable<String> values) async {
    await _prefs?.setStringList(key, values.toList());
  }

  /// Supabase'den gelen chatleri ChatPreview'a dönüştür
  List<ChatPreview> _convertSupabaseChats() {
    return _chatService.chats.map((chat) {
      final otherUser = _chatService.getOtherUser(chat);
      final name = _chatService.getChatName(chat);
      final isOnline = _chatService.isOtherUserOnline(chat);
      final lastMessage = chat['last_message'] ?? '';
      final time = _chatService.formatLastMessageTime(chat);
      final isGroup = chat['is_group'] == true;
      final avatarUrl = _chatService.getChatAvatar(chat);
      
      return ChatPreview(
        id: chat['id'] as String,
        userId: otherUser?['id'] ?? '',
        name: name,
        lastMessage: lastMessage,
        time: time,
        online: isOnline,
        isGroup: isGroup,
        avatarUrl: avatarUrl,
      );
    }).toList();
  }

  List<ChatPreview> get chats {
    // Supabase'den gelen chatler
    final list = _convertSupabaseChats();
    
    // pinned -> üstte
    list.sort((a, b) {
      final ap = _pinnedChatIds.contains(a.id);
      final bp = _pinnedChatIds.contains(b.id);
      if (ap == bp) return 0;
      return ap ? -1 : 1;
    });
    return List.unmodifiable(list);
  }
  
  /// Sadece grup sohbetleri
  List<ChatPreview> get groupChats {
    return chats.where((c) => c.isGroup).toList();
  }
  
  /// Sadece birebir sohbetler
  List<ChatPreview> get directChats {
    return chats.where((c) => !c.isGroup).toList();
  }

  // ✅ Settings listeleri için
  List<String> get mutedUserIds =>
      List.unmodifiable(_mutedUserIds.toList()..sort());
  List<String> get blockedUserIds =>
      List.unmodifiable(_blockedUserIds.toList()..sort());

  // Kullanıcı adı çözümleme - Supabase'den
  String nameOfUser(String userId) {
    // Chat listesinde ara
    final chatList = chats;
    final idx = chatList.indexWhere((c) => c.userId == userId);
    if (idx != -1) return chatList[idx].name;
    
    // ChatService'den kullanıcı bilgisi kontrol et
    for (final chat in _chatService.chats) {
      final otherUser = _chatService.getOtherUser(chat);
      if (otherUser?['id'] == userId) {
        return otherUser?['full_name'] ?? otherUser?['username'] ?? 'Kullanıcı';
      }
    }
    
    return 'Kullanıcı';
  }

  int unreadCount(String chatId) => _unread[chatId] ?? 0;
  bool isTyping(String chatId) => _typing[chatId] ?? false;

  bool isMuted(String userId) => _mutedUserIds.contains(userId);
  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  bool isPinned(String chatId) => _pinnedChatIds.contains(chatId);

  bool isArchived(String chatId) => _archivedChatIds.contains(chatId);

  // Draft messages methods
  String? getDraft(String chatId) => _draftMessages[chatId];
  
  void saveDraft(String chatId, String text) {
    if (text.isEmpty) {
      _draftMessages.remove(chatId);
      _prefs?.remove('draft_$chatId');
    } else {
      _draftMessages[chatId] = text;
      _prefs?.setString('draft_$chatId', text);
    }
    _safeNotify();
  }
  
  void clearDraft(String chatId) {
    _draftMessages.remove(chatId);
    _prefs?.remove('draft_$chatId');
    _safeNotify();
  }

  // Quick replies getters/setters
  List<String> get quickReplies => List.unmodifiable(_quickReplies);
  
  void addQuickReply(String text) {
    if (!_quickReplies.contains(text)) {
      _quickReplies.insert(0, text);
      if (_quickReplies.length > 20) _quickReplies.removeLast();
      _saveStringList('quickReplies', _quickReplies);
      _safeNotify();
    }
  }
  
  void removeQuickReply(String text) {
    _quickReplies.remove(text);
    _saveStringList('quickReplies', _quickReplies);
    _safeNotify();
  }

  void togglePin(String chatId) {
    if (_pinnedChatIds.contains(chatId)) {
      _pinnedChatIds.remove(chatId);
    } else {
      _pinnedChatIds.add(chatId);
    }
    _saveStringList('pinnedChatIds', _pinnedChatIds);
    _safeNotify();
  }

  void toggleArchive(String chatId) {
    if (_archivedChatIds.contains(chatId)) {
      _archivedChatIds.remove(chatId);
    } else {
      _archivedChatIds.add(chatId);
    }
    _saveStringList('archivedChatIds', _archivedChatIds);
    _safeNotify();
  }

  Presence presenceOf(String userId) {
    return _presenceByUserId[userId] ??
        Presence(
          online: false,
          lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
  }

  void setPresence(String userId, Presence p) {
    _presenceByUserId[userId] = p;
    _safeNotify();
  }

  void toggleMute(String userId) {
    if (_mutedUserIds.contains(userId)) {
      _mutedUserIds.remove(userId);
    } else {
      _mutedUserIds.add(userId);
    }
    _saveStringList('mutedUserIds', _mutedUserIds);
    _safeNotify();
  }

  void toggleBlock(String userId) {
    if (_blockedUserIds.contains(userId)) {
      _blockedUserIds.remove(userId);
    } else {
      _blockedUserIds.add(userId);
    }
    _saveStringList('blockedUserIds', _blockedUserIds);
    _safeNotify();
  }

  void unblock(String userId) {
    _blockedUserIds.remove(userId);
    _saveStringList('blockedUserIds', _blockedUserIds);
    _safeNotify();
  }

  void unmute(String userId) {
    _mutedUserIds.remove(userId);
    _saveStringList('mutedUserIds', _mutedUserIds);
    _safeNotify();
  }

  void removeChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);
    _unread.remove(chatId);
    _typing.remove(chatId);
    _pinnedChatIds.remove(chatId);
    _archivedChatIds.remove(chatId);
    _draftMessages.remove(chatId);
    _prefs?.remove('draft_$chatId');
    _saveStringList('pinnedChatIds', _pinnedChatIds);
    _saveStringList('archivedChatIds', _archivedChatIds);
    _safeNotify();
  }

  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (isBuilding) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!hasListeners) return;
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    if (chatId != null) {
      _unread[chatId] = 0;
      _typing[chatId] = false;
    }
    _safeNotify();
  }

  void clearUnread(String chatId) {
    _unread[chatId] = 0;
    _safeNotify();
  }

  void _incUnread(String chatId) {
    _unread[chatId] = (_unread[chatId] ?? 0) + 1;
    _safeNotify();
  }

  void setTyping(String chatId, bool value) {
    _typing[chatId] = value;
    _safeNotify();
  }

  void upsertChat(ChatPreview updated, {bool moveToTop = true}) {
    final idx = _chats.indexWhere((c) => c.id == updated.id);
    if (idx == -1) {
      _chats.insert(0, updated);
      _safeNotify();
      return;
    }

    _chats[idx] = updated;
    if (moveToTop) {
      final c = _chats.removeAt(idx);
      _chats.insert(0, c);
    }
    _safeNotify();
  }

  String nowHHmm() {
    final t = DateTime.now();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void simulateIncoming({
    required String chatId,
    required String replyText,
    Duration typingDelay = const Duration(milliseconds: 600),
    Duration replyDelay = const Duration(milliseconds: 1200),
  }) {
    _typing[chatId] = true;
    _safeNotify();

    Timer(typingDelay, () {
      Timer(replyDelay, () {
        _typing[chatId] = false;

        final idx = _chats.indexWhere((c) => c.id == chatId);
        if (idx == -1) {
          _safeNotify();
          return;
        }

        final c = _chats[idx];
        final updated = ChatPreview(
          id: c.id,
          userId: c.userId,
          name: c.name,
          lastMessage: replyText,
          time: nowHHmm(),
          online: c.online,
          isGroup: c.isGroup,
          avatarUrl: c.avatarUrl,
        );

        upsertChat(updated, moveToTop: true);

        if (_activeChatId != chatId) {
          _incUnread(chatId);
        } else {
          _safeNotify();
        }

        _presenceByUserId[c.userId] = Presence(
          online: c.online,
          lastSeenAt: DateTime.now(),
        );
        _safeNotify();
      });
    });
  }
}
