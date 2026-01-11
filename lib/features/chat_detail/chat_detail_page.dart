import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme.dart';
import '../../shared/chat_store.dart';
import '../../shared/chat_service.dart';
import '../../shared/audio_service.dart';
import '../../shared/message_store.dart';
import '../../shared/models.dart';
import '../../shared/widgets/emoji_picker.dart';
import '../../shared/widgets/typing_indicator.dart' hide MessageStatus;
import '../../shared/widgets/voice_message.dart';
import '../../shared/widgets/chat_wallpaper.dart';
import '../../shared/widgets/link_preview.dart';
import '../../shared/widgets/gif_picker.dart';
import '../chats/forward_message_page.dart';
import '../chats/media_gallery_page.dart';
import '../chats/message_search_page.dart';
import '../chats/chat_extras_pages.dart';
import '../chats/group_info_page.dart';
import 'message_info_sheet.dart';
import '../../shared/message_effects.dart';
import '../../shared/settings_service.dart';

class ChatDetailPage extends StatefulWidget {
  static const route = '/chat';

  /// Deep link parameters
  final String? deepLinkChatId;
  final String? deepLinkMessageId;

  const ChatDetailPage({
    super.key,
    this.deepLinkChatId,
    this.deepLinkMessageId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final store = ChatStore.instance;
  final messageStore = MessageStore.instance;
  final chatService = ChatService.instance;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  late ChatPreview _chat;
  Map<String, dynamic>? _supabaseChat; // Supabase'den gelen chat bilgisi

  // Supabase realtime channel
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _messageStatusChannel;
  RealtimeChannel? _reactionsChannel;
  StreamSubscription? _presenceSubscription; // Stream subscription for presence
  List<Map<String, dynamic>> _supabaseMessages = [];
  List<Message>? _cachedMessages; // Cache for processed messages
  bool _useSupabase = false;

  // Gizlilik kontrol durumları (Phase 6'da calls için kullanılacak)
  // ignore: unused_field
  bool _canSeeLastSeen = true;
  bool _canSeeReadReceipts = true;
  bool _canSeeProfilePhoto = true;

  // Gerçek zamanlı online durumu
  // Gerçek zamanlı online durumu - Artık ChatStore'dan takip ediliyor

  // Supabase'den chat adı
  String get _chatName {
    if (_supabaseChat != null) {
      return chatService.getChatName(_supabaseChat!);
    }
    return _chat.name;
  }

  // Online durumu kontrolü için _canSeeLastSeen ve store.presenceOf kullanılıyor
  // Widget ağacında doğrudan erişildiği için getter burada tanımlanmıyor

  // Mesaj durumu cache'i (messageId -> status)
  final Map<String, MessageStatus> _messageStatusCache = {};

  List<Message> get _messages {
    if (_useSupabase) {
      if (_cachedMessages != null) return _cachedMessages!;

      if (_supabaseMessages.isNotEmpty) {
        debugPrint(
          'ChatDetailPage: Mapping ${_supabaseMessages.length} supabase messages...',
        );
        final currentUserId = chatService.currentUserId;
        // Mesajları created_at'e göre sırala (eski -> yeni)
        final sortedMessages =
            List<Map<String, dynamic>>.from(_supabaseMessages)..sort((a, b) {
              final aTime =
                  DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
              final bTime =
                  DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
              return aTime.compareTo(bTime);
            });

        try {
          _cachedMessages = sortedMessages.map((m) {
            final senderId = m['sender_id'] ?? '';
            final messageId = m['id'] ?? '';
            final isMe = senderId == currentUserId;

            MessageStatus status = MessageStatus.sent;
            if (isMe) {
              status = _messageStatusCache[messageId] ?? MessageStatus.sent;
            }

            final typeStr = m['type'] as String?;
            final type = Message.parseType(typeStr);

            Map<String, dynamic>? metadata;
            if (m['metadata'] is Map) {
              metadata = Map<String, dynamic>.from(m['metadata'] as Map);
            }

            return Message(
              id: messageId,
              chatId: m['chat_id'] ?? _chat.id,
              senderId: isMe ? 'me' : senderId,
              text: m['content'] ?? '',
              createdAt:
                  DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
              status: status,
              type: type,
              mediaUrl: m['media_url'] as String?,
              metadata: metadata,
              isStarred: (m['starred_messages'] as List?)?.isNotEmpty ?? false,
            );
          }).toList();

          debugPrint(
            'ChatDetailPage: Successfully mapped ${_cachedMessages!.length} messages',
          );
          return _cachedMessages!;
        } catch (mapError) {
          debugPrint('ChatDetailPage: ERROR during message mapping: $mapError');
          // Hata durumunda boş değil, yarıda kesilmiş listeyi veya logu döndür
          return [];
        }
      }
      debugPrint('ChatDetailPage: _supabaseMessages is empty');
      return [];
    }
    return messageStore.getMessages(_chat.id);
  }

  Message? _replyTo;
  final Set<String> _starredMessageIds = {};
  bool _showEmojiPicker = false;
  bool _isRecordingVoice = false;

  /// Selected wallpaper ID (null = default)
  String? _wallpaperId;
  bool _wallpaperLoaded = false;

  /// Link preview state
  LinkPreviewData? _inputLinkPreview;
  bool _isLoadingLinkPreview = false;
  String? _lastDetectedUrl;

  /// Typing indicator
  RealtimeChannel? _typingChannel;
  bool _isOtherUserTyping = false;
  DateTime? _lastTypingSent;

  /// @Mention sistemi (3.6)
  bool _showMentionSuggestions = false;
  List<Map<String, dynamic>> _mentionSuggestions = [];
  List<Map<String, dynamic>> _chatMembers = [];
  int _mentionStartIndex = -1;
  bool get _isGroupChat => _supabaseChat?['is_group'] == true;

  /// Mesaj Efektleri (Premium)
  MessageEffect _selectedEffect = MessageEffect.none;
  bool _showEffectOverlay = false;
  MessageEffect _playingEffect = MessageEffect.none;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _initSupabaseChat();
    _loadSavedMessageEffect();
  }

  /// Kayıtlı mesaj efektini yükle
  void _loadSavedMessageEffect() {
    final savedEffect = SettingsService.instance.defaultMessageEffect;
    _selectedEffect = MessageEffect.fromString(savedEffect);
  }

  /// Kayıtlı duvar kağıdını yükle
  Future<void> _loadSavedWallpaper() async {
    if (_wallpaperLoaded) return;
    _wallpaperLoaded = true;

    final saved = await WallpaperService.instance.getWallpaper(_chat.id);
    if (saved != null && mounted) {
      setState(() => _wallpaperId = saved);
    }
  }

  /// Supabase chat'i başlat
  Future<void> _initSupabaseChat() async {
    // Supabase'de bu chat var mı kontrol et
    final currentUserId = chatService.currentUserId;
    if (currentUserId == null) {
      debugPrint('ChatService: User not logged in, using mock data');
      return;
    }

    // Chat ID'yi sonra alacağız (didChangeDependencies'de)
    // Bu metod didChangeDependencies sonrası tekrar çağrılacak
  }

  /// Yıldızlı mesaj ID'lerini yükle
  Future<void> _loadStarredMessageIds() async {
    final starred = await ChatService.instance.getStarredMessages();
    if (mounted) {
      setState(() {
        _starredMessageIds.clear();
        for (final s in starred) {
          final message = s['message'] as Map<String, dynamic>?;
          if (message != null && message['id'] != null) {
            // Sadece bu chat'e ait olanları ekle
            final chat = message['chat'] as Map<String, dynamic>?;
            if (chat != null && chat['id'] == _chat.id) {
              _starredMessageIds.add(message['id'] as String);
            }
          }
        }
      });
    }
  }

  bool _supabaseInitialized = false;

  /// Supabase mesajlarını yükle ve dinle
  Future<void> _loadSupabaseMessages() async {
    if (chatService.currentUserId == null || _supabaseInitialized) return;

    try {
      _supabaseInitialized = true;
      // Supabase chat bilgisini al (isim, online durumu vs.)
      _supabaseChat = chatService.chats.firstWhere(
        (c) => c['id'] == _chat.id,
        orElse: () => <String, dynamic>{},
      );
      if (_supabaseChat?.isEmpty ?? true) _supabaseChat = null;

      // Mesajları yükle
      await chatService.loadMessages(_chat.id);
      _supabaseMessages = chatService.getMessages(_chat.id);
      _cachedMessages = null; // Önbelleği temizle
      _useSupabase = true;

      // Grup sohbetiyse üyeleri yükle
      if (_supabaseChat?['is_group'] == true) {
        _loadChatMembersIfNeeded();
      }

      // Yıldızlı mesajları yükle
      _loadStarredMessageIds();

      // Realtime subscription - yeni mesajları dinle
      _messagesChannel = chatService.subscribeToMessages(_chat.id, (
        newMessage,
      ) {
        debugPrint('ChatDetailPage: New message received');
        final messageId = newMessage['id'] as String?;
        final senderId = newMessage['sender_id'] as String?;

        // Gelen mesajı hemen read olarak işaretle (chat açık olduğu için)
        if (messageId != null && senderId != chatService.currentUserId) {
          chatService.markMessageAsRead(messageId);
        }

        setState(() {
          _cachedMessages = null; // Önbelleği geçersiz kıl
          _supabaseMessages = chatService.getMessages(_chat.id);
        });
        _scrollToBottom();
      });

      // Typing indicator subscription
      _typingChannel = chatService.subscribeToTyping(_chat.id, (userId) {
        if (mounted) {
          setState(() => _isOtherUserTyping = true);
          // 3 saniye sonra kapat
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _isOtherUserTyping = false);
          });
        }
      });

      // Chat'i okundu olarak işaretle (tüm mesajları read yap)
      _markAllMessagesAsRead();

      // Gizlilik ayarlarını kontrol et (birebir sohbet için)
      if (!_isGroupChat) {
        await _checkPrivacySettings(); // await eklendi - race condition fix
        // Online durumu takibini başlat
        _initPresence();
      }

      // Kendi mesajlarımın durumlarını yükle (gizlilik ayarları yüklendikten sonra)
      await _loadMyMessageStatuses();

      // Mesaj tepkilerini dinle
      _subscribeToReactions();

      if (mounted) {
        setState(() {
          _cachedMessages = null;
          _supabaseMessages = chatService.getMessages(_chat.id);
        });
        _scrollToBottom(jump: true);
      }

      debugPrint(
        'ChatDetailPage: Loaded ${_supabaseMessages.length} messages from Supabase',
      );
    } catch (e) {
      debugPrint('ChatDetailPage: Error loading Supabase messages: $e');
      // Mock data'ya devam et
      _useSupabase = false;
    }
  }

  /// Tüm mesajları okundu olarak işaretle (chat açıldığında)
  void _markAllMessagesAsRead() {
    // Chat açıldığında tüm mesajları read olarak işaretle
    chatService.markChatAsRead(_chat.id);
    // Unread count'u da sıfırla
    chatService.clearUnreadCount(_chat.id);
  }

  /// Gizlilik ayarlarını kontrol et (last seen, profile photo ve read receipts)
  Future<void> _checkPrivacySettings() async {
    if (_isGroupChat || _supabaseChat == null) return;

    final otherUser = chatService.getOtherUser(_supabaseChat!);
    if (otherUser == null) return;

    final otherUserId = otherUser['id'] as String?;
    if (otherUserId == null) return;

    try {
      // Last seen gizlilik kontrolü
      final canSeeLastSeen = await chatService.canSeeLastSeen(otherUserId);
      // Profile photo gizlilik kontrolü
      final canSeeProfilePhoto = await chatService.canSeeProfilePhoto(otherUserId);
      // Read receipts gizlilik kontrolü
      final canSeeReadReceipts = await chatService.canSeeReadReceipts(
        otherUserId,
      );

      if (mounted) {
        setState(() {
          _canSeeLastSeen = canSeeLastSeen;
          _canSeeProfilePhoto = canSeeProfilePhoto;
          _canSeeReadReceipts = canSeeReadReceipts;
        });
      }

      debugPrint(
        'Privacy: canSeeLastSeen=$canSeeLastSeen, canSeeProfilePhoto=$canSeeProfilePhoto, canSeeReadReceipts=$canSeeReadReceipts',
      );
    } catch (e) {
      debugPrint('Error checking privacy settings: $e');
    }
  }

  /// Kendi gönderdiğim mesajların durumlarını yükle
  Future<void> _loadMyMessageStatuses() async {
    final currentUserId = chatService.currentUserId;
    if (currentUserId == null) return;

    // Grup için üye sayısını al (gönderen hariç)
    final memberCount = _isGroupChat ? (_chatMembers.length - 1) : 1;

    for (final msg in _supabaseMessages) {
      final senderId = msg['sender_id'] as String?;
      final messageId = msg['id'] as String?;

      // Sadece kendi mesajlarım için durum kontrolü
      if (senderId == currentUserId && messageId != null) {
        // Gizlilik kontrolü - okundu bilgisi kapalıysa sadece sent göster
        if (!_isGroupChat && !_canSeeReadReceipts) {
          _messageStatusCache[messageId] = MessageStatus.sent;
          continue;
        }

        final statusData = await chatService.getMessageReadStatus(messageId);

        // Grup vs bireysel sohbet için farklı mantık
        MessageStatus status = MessageStatus.sent; // tek tik

        if (_isGroupChat) {
          // Grup: Tüm üyeler okudu mu kontrol et
          final readCount = statusData['read_count'] as int? ?? 0;
          if (readCount >= memberCount && memberCount > 0) {
            status = MessageStatus.read; // herkes okudu
          } else if (readCount > 0) {
            status = MessageStatus.delivered; // bazıları okudu
          }
        } else {
          // Bireysel: Herhangi bir okuma varsa okundu
          if (statusData['read'] == true) {
            status = MessageStatus.read;
          }
        }

        _messageStatusCache[messageId] = status;
      }
    }

    // Mesaj durumu değişikliklerini dinle (realtime)
    _subscribeToMessageStatusChanges();

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Mesaj durumu değişikliklerini realtime dinle
  void _subscribeToMessageStatusChanges() {
    final currentUserId = chatService.currentUserId;
    if (currentUserId == null) return;

    _messageStatusChannel = Supabase.instance.client
        .channel('message_status_${_chat.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_status',
          callback: (payload) {
            final messageId = payload.newRecord['message_id'] as String?;
            final readAt = payload.newRecord['read_at'];
            final deliveredAt = payload.newRecord['delivered_at'];

            if (messageId != null) {
              // Bu mesajın bu chat'teki kendi mesajlarımdan biri olup olmadığını kontrol et
              final isMyMessageInThisChat = _supabaseMessages.any(
                (m) => m['id'] == messageId && m['sender_id'] == currentUserId,
              );

              if (isMyMessageInThisChat) {
                MessageStatus newStatus = MessageStatus.sent;
                if (readAt != null) {
                  newStatus = MessageStatus.read;
                } else if (deliveredAt != null) {
                  newStatus = MessageStatus.delivered;
                }

                if (mounted) {
                  setState(() {
                    _cachedMessages =
                        null; // Cache'i temizle ki yeni status ile Message objeleri tekrar oluşturulsun
                    _messageStatusCache[messageId] = newStatus;
                  });
                }
              }
            }
          },
        )
        .subscribe();

    debugPrint(
      'ChatDetailPage: Subscribed to message status changes for ${_chat.id}',
    );
  }

  /// Mesaj tepkilerini realtime dinle
  void _subscribeToReactions() {
    if (chatService.currentUserId == null) return;

    _reactionsChannel = Supabase.instance.client
        .channel('reactions_${_chat.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (payload) async {
            debugPrint(
              'ChatDetailPage: Reaction changed: ${payload.eventType}',
            );
            // Tepki değiştiğinde mesajları yeniden yükle (en güvenlisi)
            // İleride mesaj listesini yerel olarak güncelleyen daha optimize bir yöntem eklenebilir
            if (mounted) {
              await chatService.loadMessages(_chat.id);
              setState(() {
                _cachedMessages = null; // Invalidate cache
                _supabaseMessages = chatService.getMessages(_chat.id);
              });
            }
          },
        )
        .subscribe();

    debugPrint('ChatDetailPage: Subscribed to reactions');
  }

  /// URL detection and preview loading
  void _onTextChanged() {
    final text = _controller.text;
    final url = LinkDetector.extractFirstUrl(text);

    if (url != null && url != _lastDetectedUrl) {
      _lastDetectedUrl = url;
      _loadLinkPreview(url);
    } else if (url == null && _inputLinkPreview != null) {
      setState(() {
        _inputLinkPreview = null;
        _lastDetectedUrl = null;
      });
    }

    // Typing indicator gönder (her 2 saniyede bir)
    if (text.isNotEmpty && _useSupabase) {
      final now = DateTime.now();
      if (_lastTypingSent == null ||
          now.difference(_lastTypingSent!).inSeconds >= 2) {
        _lastTypingSent = now;
        chatService.sendTypingIndicator(_chat.id);
      }
    }

    // @Mention algılama (sadece grup sohbetlerinde)
    if (_isGroupChat) {
      _detectMention(text);
    }
  }

  /// @Mention algılama
  void _detectMention(String text) {
    final cursorPosition = _controller.selection.baseOffset;
    if (cursorPosition < 0) return;

    // Cursor'dan geriye doğru @ karakterini ara
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break; // Boşluk veya yeni satır bulunca dur
      }
    }

    if (atIndex >= 0) {
      // @ ile cursor arası query
      final query = text.substring(atIndex + 1, cursorPosition);

      // @ yeni mi yazıldı yoksa devam mı ediyor
      if (_mentionStartIndex != atIndex) {
        _mentionStartIndex = atIndex;
        _loadChatMembersIfNeeded();
      }

      // Filtreleme
      _filterMentionSuggestions(query);
    } else {
      // @ bulunamadı, önerileri kapat
      if (_showMentionSuggestions) {
        setState(() {
          _showMentionSuggestions = false;
          _mentionStartIndex = -1;
        });
      }
    }
  }

  /// Grup üyelerini yükle (lazy loading)
  Future<void> _loadChatMembersIfNeeded() async {
    if (_chatMembers.isNotEmpty) return;

    final members = await chatService.getGroupMembers(_chat.id);
    debugPrint('ChatDetailPage: Loaded ${members.length} group members');
    if (mounted) {
      setState(() {
        _chatMembers = members;
      });
    }
  }

  /// Mesaj sender ID'sine göre isim bul
  String? _getSenderNameForMessage(String senderId) {
    // Önce _chatMembers'dan bak
    for (final member in _chatMembers) {
      final userId = member['user_id'] as String?;
      if (userId == senderId) {
        final profile = member['profiles'] as Map<String, dynamic>?;
        return profile?['full_name'] ?? profile?['username'] ?? 'Kullanıcı';
      }
    }

    // Supabase mesajlarından sender bilgisi al
    for (final msg in _supabaseMessages) {
      if (msg['sender_id'] == senderId) {
        final sender = msg['sender'] as Map<String, dynamic>?;
        if (sender != null) {
          return sender['full_name'] ?? sender['username'] ?? 'Kullanıcı';
        }
      }
    }

    return null;
  }

  /// Mesaj ID'sine göre reactions bul
  List<Map<String, dynamic>>? _getReactionsForMessage(String messageId) {
    for (final msg in _supabaseMessages) {
      if (msg['id'] == messageId) {
        final reactions = msg['message_reactions'];
        if (reactions != null && reactions is List && reactions.isNotEmpty) {
          return List<Map<String, dynamic>>.from(reactions);
        }
      }
    }
    return null;
  }

  /// Mention önerilerini filtrele
  void _filterMentionSuggestions(String query) {
    final currentUserId = chatService.currentUserId;
    final lowerQuery = query.toLowerCase();

    final filtered = _chatMembers.where((member) {
      final userId = member['user_id'] as String?;
      if (userId == currentUserId) return false; // Kendini hariç tut

      final profile = member['profiles'] as Map<String, dynamic>?;
      final username = (profile?['username'] ?? '').toString().toLowerCase();
      final fullName = (profile?['full_name'] ?? '').toString().toLowerCase();

      if (query.isEmpty) return true;
      return username.contains(lowerQuery) || fullName.contains(lowerQuery);
    }).toList();

    setState(() {
      _mentionSuggestions = filtered;
      _showMentionSuggestions = filtered.isNotEmpty;
    });
  }

  /// Mention seçildiğinde
  void _onMentionSelected(Map<String, dynamic> member) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? '';

    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;

    // @query kısmını @username ile değiştir
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterCursor = cursorPosition < text.length
        ? text.substring(cursorPosition)
        : '';

    final newText = '$beforeMention@$username $afterCursor';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: beforeMention.length + (username as String).length + 2,
      ),
    );

    setState(() {
      _showMentionSuggestions = false;
      _mentionStartIndex = -1;
    });
  }

  void _loadLinkPreview(String url) {
    setState(() {
      _isLoadingLinkPreview = true;
    });

    // Simulated preview loading (in real app, fetch from server)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_lastDetectedUrl != url) return; // URL changed

      setState(() {
        _isLoadingLinkPreview = false;
        _inputLinkPreview = LinkPreviewData(
          url: url,
          title: 'Link Önizlemesi',
          description: 'Bu link için önizleme bilgisi',
          siteName: Uri.tryParse(url)?.host.replaceFirst('www.', ''),
        );
      });
    });
  }

  void _clearLinkPreview() {
    setState(() {
      _inputLinkPreview = null;
      _lastDetectedUrl = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Priority: Deep link chatId > Route arguments > Default
    if (widget.deepLinkChatId != null) {
      final chatFromDeepLink = store.chats.firstWhere(
        (c) => c.id == widget.deepLinkChatId,
        orElse: () => ChatPreview(
          id: widget.deepLinkChatId!,
          userId: 'u_${widget.deepLinkChatId}',
          name: 'Kullanıcı',
          lastMessage: '',
          time: '',
          online: false,
        ),
      );
      _chat = chatFromDeepLink;
    } else {
      final arg = ModalRoute.of(context)?.settings.arguments;
      _chat = (arg is ChatPreview)
          ? arg
          : const ChatPreview(
              id: 'c2',
              userId: 'u2',
              name: 'Ayşe',
              lastMessage: '',
              time: '',
              online: false,
            );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      store.setActiveChat(_chat.id);

      // Scroll to specific message if deepLinkMessageId provided
      if (widget.deepLinkMessageId != null) {
        _scrollToMessage(widget.deepLinkMessageId!);
      }
    });

    // Supabase mesajlarını yükle
    _loadSupabaseMessages();

    // Kayıtlı duvar kağıdını yükle
    _loadSavedWallpaper();
  }

  @override
  void dispose() {
    store.setActiveChat(null);
    _messagesChannel?.unsubscribe();
    _messageStatusChannel?.unsubscribe();
    _reactionsChannel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _presenceSubscription?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initPresence() {
    if (_isGroupChat) return;

    // Supabase chat henüz yüklenmediyse bile _chat.userId ile dene
    String? otherUserId;

    if (_supabaseChat != null) {
      final otherUser = chatService.getOtherUser(_supabaseChat!);
      otherUserId = otherUser?['id'] as String?;
    } else {
      // ChatPreview'dan id al (eğer supabase chat henüz yoksa)
      // ChatPreview'da userId diğer kullanıcının ID'si oluyor (otherUserId)
      otherUserId = _chat.otherUserId;
    }

    if (otherUserId == null) return;

    debugPrint('ChatDetailPage: Subscribing to presence for $otherUserId');

    // Start subscription
    _presenceSubscription?.cancel();
    _presenceSubscription = chatService.subscribeToPresence(otherUserId);
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Scroll to a specific message by ID (for deep linking)
  void _scrollToMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      // Approximate scroll position (each message ~70px)
      final targetPosition = index * 70.0;
      _scrollController.animateTo(
        targetPosition.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      // Highlight the message briefly
      _toast('Mesaja kaydırıldı');
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _toast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: Duration(milliseconds: isError ? 2000 : 900),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  void _simulateIncomingMessage({required String text}) {
    store.simulateIncoming(chatId: _chat.id, replyText: text);

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      final incomingMsg = Message(
        id: _newId(),
        chatId: _chat.id,
        senderId: _chat.userId,
        text: text,
        createdAt: DateTime.now(),
        status: MessageStatus.delivered,
      );
      messageStore.addMessage(incomingMsg);
      setState(() {});
      _scrollToBottom();
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final time = store.nowHHmm();
    final now = DateTime.now();

    final replyPrefix = _replyTo != null ? '↩ ${_replyTo!.text}\n' : '';
    final composed = replyPrefix.isEmpty ? text : '$replyPrefix$text';

    // Supabase kullanılıyorsa
    if (_useSupabase && chatService.currentUserId != null) {
      _sendSupabaseMessage(composed);
      return;
    }

    // Mock data için eski davranış
    final sendingMsg = Message(
      id: _newId(),
      chatId: _chat.id,
      senderId: 'me',
      text: composed,
      createdAt: now,
      status: MessageStatus.sending,
    );

    // Mesajı Hive'a kaydet
    messageStore.addMessage(sendingMsg);

    setState(() {
      _replyTo = null;
      // Clear link preview after sending
      _inputLinkPreview = null;
      _lastDetectedUrl = null;
    });
    _scrollToBottom();

    store.upsertChat(
      ChatPreview(
        id: _chat.id,
        userId: _chat.userId,
        name: _chat.name,
        lastMessage: text,
        time: time,
        online: store.presenceOf(_chat.userId).online,
      ),
      moveToTop: true,
    );

    _controller.clear();
    FocusScope.of(context).unfocus();

    // Mesaj durumunu "sent" olarak güncelle
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final sentMsg = Message(
        id: sendingMsg.id,
        chatId: sendingMsg.chatId,
        senderId: sendingMsg.senderId,
        text: sendingMsg.text,
        createdAt: sendingMsg.createdAt,
        status: MessageStatus.sent,
      );
      messageStore.updateMessage(sentMsg);
      setState(() {});
    });

    _simulateIncomingMessage(text: 'Tamam 👍');
  }

  /// Supabase'e mesaj gönder
  Future<void> _sendSupabaseMessage(String content) async {
    _controller.clear();
    FocusScope.of(context).unfocus();

    // Efekti kaydet ve sıfırla
    final effect = _selectedEffect;

    // Mention'ları parse et (grup sohbetlerinde)
    List<Map<String, dynamic>>? mentions;
    if (_isGroupChat && _chatMembers.isNotEmpty) {
      mentions = ChatService.parseMentions(content, _chatMembers);
    }

    setState(() {
      _replyTo = null;
      _inputLinkPreview = null;
      _lastDetectedUrl = null;
      _showMentionSuggestions = false;
      _mentionStartIndex = -1;
      // NOT: _selectedEffect sıfırlanmıyor - kullanıcı değiştirene kadar kalıcı
    });

    final success = await chatService.sendMessageWithMentionsAndEffect(
      chatId: _chat.id,
      content: content,
      mentions: mentions,
      replyToId: _replyTo?.id,
      effect: effect != MessageEffect.none ? effect.value : null,
    );

    if (success) {
      debugPrint(
        'ChatDetailPage: Message sent to Supabase${effect != MessageEffect.none ? ' with ${effect.label} effect' : ''}',
      );

      // Anlık güncelleme için cache temizle ve veriyi al
      if (mounted) {
        setState(() {
          _cachedMessages = null;
          _supabaseMessages = chatService.getMessages(_chat.id);
        });
      }

      // Efekt varsa overlay göster
      if (effect != MessageEffect.none) {
        _playMessageEffect(effect);
      }
    } else {
      _toast('Mesaj gönderilemedi');
    }
  }

  /// Mesaj efekti oynat
  void _playMessageEffect(MessageEffect effect) {
    setState(() {
      _showEffectOverlay = true;
      _playingEffect = effect;
    });
  }

  /// Efekt seçici göster
  void _showEffectPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MessageEffectPickerSheet(
        currentEffect: _selectedEffect,
        onEffectSelected: (effect) {
          setState(() => _selectedEffect = effect);
          // Seçilen efekti kalıcı olarak kaydet
          SettingsService.instance.setDefaultMessageEffect(effect.value);
        },
      ),
    );
  }

  void _startCall({required bool video}) {
    context.push('/call/${_chat.id}?video=$video');
  }

  void _openForwardPage(Message m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ForwardMessagePage(messageText: m.text, messageId: m.id),
      ),
    );
  }

  void _openMediaGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MediaGalleryPage(chatId: _chat.id, chatName: _chat.name),
      ),
    );
  }

  void _openStarredMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StarredMessagesPage()),
    );
  }

  void _showReportDialog(BuildContext ctx) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text(
          'Şikayet Et',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_chat.name} kullanıcısını şikayet etmek üzeresiniz.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Şikayet nedeniniz...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(ctx);
              _toast('Şikayet gönderildi. İncelemeye alınacak.');
            },
            child: const Text('Şikayet Et'),
          ),
        ],
      ),
    );
  }

  void _openWallpaperPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatWallpaperPicker(
          chatId: _chat.id,
          currentWallpaper: _wallpaperId,
          onWallpaperChanged: (wallpaper) async {
            // Duvar kağıdını kaydet
            await WallpaperService.instance.saveWallpaper(_chat.id, wallpaper);

            setState(() {
              _wallpaperId = wallpaper;
            });
            _toast('Duvar kağıdı uygulandı');
          },
        ),
      ),
    );
  }

  // === Attachment methods (Faz 4: Medya Paylaşımı) ===
  final _picker = ImagePicker();
  bool _isUploadingMedia = false;

  /// Kameradan fotoğraf çek ve gönder (4.1)
  Future<void> _pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Sıkıştırma (4.5)
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        await _sendPhotoToSupabase(image);
      }
    } catch (e) {
      _toast('Kamera açılamadı');
      debugPrint('Camera error: $e');
    }
  }

  /// Galeriden fotoğraf seç ve gönder (4.1)
  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 70, // Sıkıştırma (4.5)
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        for (final image in images) {
          await _sendPhotoToSupabase(image);
        }
      }
    } catch (e) {
      _toast('Galeri açılamadı');
      debugPrint('Gallery error: $e');
    }
  }

  /// Video seç ve gönder (4.2)
  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        await _sendVideoToSupabase(video);
      }
    } catch (e) {
      _toast('Video seçilemedi');
      debugPrint('Video pick error: $e');
    }
  }

  // NOT: _recordVideo metodu kaldırıldı, video çekimi _pickVideo ile ImageSource.camera ile yapılabilir

  /// Fotoğrafı Supabase'e gönder (4.1)
  Future<void> _sendPhotoToSupabase(XFile image) async {
    if (_isUploadingMedia) return;

    setState(() => _isUploadingMedia = true);
    _toast('Fotoğraf gönderiliyor...');

    try {
      final bytes = await image.readAsBytes();
      final fileName = image.name.isNotEmpty
          ? image.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final success = await chatService.sendPhoto(
        chatId: _chat.id,
        fileBytes: bytes,
        fileName: fileName,
      );

      if (success) {
        debugPrint('ChatDetailPage: Photo sent successfully');
      } else {
        _toast('Fotoğraf gönderilemedi');
      }
    } catch (e) {
      _toast('Fotoğraf yüklenirken hata oluştu');
      debugPrint('Photo upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  /// Videoyu Supabase'e gönder (4.2)
  Future<void> _sendVideoToSupabase(XFile video) async {
    if (_isUploadingMedia) return;

    setState(() => _isUploadingMedia = true);
    _toast('Video gönderiliyor...');

    try {
      final bytes = await video.readAsBytes();
      final fileName = video.name.isNotEmpty
          ? video.name
          : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Video boyut kontrolü (max 50MB)
      if (bytes.length > 50 * 1024 * 1024) {
        _toast('Video çok büyük (max 50MB)');
        return;
      }

      final success = await chatService.sendVideo(
        chatId: _chat.id,
        videoBytes: bytes,
        fileName: fileName,
      );

      if (success) {
        debugPrint('ChatDetailPage: Video sent successfully');
      } else {
        _toast('Video gönderilemedi');
      }
    } catch (e) {
      _toast('Video yüklenirken hata oluştu');
      debugPrint('Video upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  /// Dosya seç ve gönder (4.4 - Gerçek implementasyon)
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes == null) {
          _toast('Dosya okunamadı');
          return;
        }

        // Boyut kontrolü (max 25MB)
        if (file.size > 25 * 1024 * 1024) {
          _toast('Dosya çok büyük (max 25MB)');
          return;
        }

        await _sendFileToSupabase(file);
      }
    } catch (e) {
      _toast('Dosya seçilemedi');
      debugPrint('File picker error: $e');
    }
  }

  /// Dosyayı Supabase'e gönder (4.4)
  Future<void> _sendFileToSupabase(PlatformFile file) async {
    if (_isUploadingMedia || file.bytes == null) return;

    setState(() => _isUploadingMedia = true);
    _toast('Dosya gönderiliyor...');

    try {
      final success = await chatService.sendFile(
        chatId: _chat.id,
        fileBytes: file.bytes!,
        fileName: file.name,
        fileSize: file.size,
      );

      if (success) {
        debugPrint('ChatDetailPage: File sent: ${file.name}');
      } else {
        _toast('Dosya gönderilemedi');
      }
    } catch (e) {
      _toast('Dosya yüklenirken hata oluştu');
      debugPrint('File upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  /// GIF seç ve gönder
  void _openGifPicker() async {
    final gif = await GifPicker.show(context);
    if (gif != null && mounted) {
      if (_useSupabase) {
        final success = await chatService.sendGif(
          chatId: _chat.id,
          gifUrl: gif.url,
        );
        if (!success) _toast('GIF gönderilemedi');
      } else {
        _sendMediaMessage('🎬 GIF gönderildi');
      }
    }
  }

  /// Konum paylaş (4.9 - Gerçek implementasyon)
  Future<void> _shareLocation() async {
    _toast('Konum alınıyor...');

    try {
      // İzin kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _toast('Konum izni reddedildi', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _toast(
          'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.',
          isError: true,
        );
        return;
      }

      // Konum servisinin açık olduğunu kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Konum servisleri kapalı', isError: true);
        return;
      }

      // Konumu al
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Adresi çözümle
      String address = 'Konum';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = [
            place.street,
            place.subLocality,
            place.locality,
            place.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (_) {
        // Adres çözümlenemezse koordinatları göster
        address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      // Konumu gönder
      if (_useSupabase) {
        final success = await chatService.sendLocation(
          chatId: _chat.id,
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        );
        if (!success) {
          _toast('Konum gönderilemedi', isError: true);
        }
      } else {
        _sendMediaMessage('📍 Konum: $address');
      }
    } catch (e) {
      _toast('Konum alınamadı', isError: true);
      debugPrint('Location error: $e');
    }
  }

  /// Kişi paylaş (4.10 - Gerçek implementasyon)
  Future<void> _shareContact() async {
    try {
      // Rehber izni iste
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        _toast('Rehber izni reddedildi', isError: true);
        return;
      }

      // Rehberden kişi seç
      final contact = await FlutterContacts.openExternalPick();

      if (contact == null) return;

      // Telefon numarasını al
      final fullContact = await FlutterContacts.getContact(contact.id);
      final phone = fullContact?.phones.isNotEmpty == true
          ? fullContact!.phones.first.number
          : '';

      // Kişiyi gönder
      if (_useSupabase) {
        final success = await chatService.sendContact(
          chatId: _chat.id,
          contactName: contact.displayName,
          contactPhone: phone,
        );
        if (!success) {
          _toast('Kişi gönderilemedi', isError: true);
        }
      } else {
        _sendMediaMessage('👤 Kişi paylaşıldı: ${contact.displayName}');
      }
    } catch (e) {
      _toast('Kişi seçilemedi', isError: true);
      debugPrint('Contact picker error: $e');
    }
  }

  // NOT: _shareContactModal metodu kaldırıldı, flutter_contacts kullanılıyor

  void _sendMediaMessage(String text) {
    final msg = Message(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      chatId: _chat.id,
      senderId: 'me',
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    setState(() => _messages.insert(0, msg));

    // Durumu güncelle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = Message(
              id: msg.id,
              chatId: msg.chatId,
              senderId: msg.senderId,
              text: msg.text,
              createdAt: msg.createdAt,
              status: MessageStatus.sent,
            );
          }
        });
      }
    });
  }

  void _openMessageSearch() async {
    final result = await Navigator.push<Message>(
      context,
      MaterialPageRoute(
        builder: (context) => MessageSearchPage(
          chatId: _chat.id,
          chatName: _chat.name,
          messages: _messages,
        ),
      ),
    );

    if (result != null && mounted) {
      // Mesaja scroll et
      final index = _messages.indexWhere((m) => m.id == result.id);
      if (index != -1) {
        _scrollController.animateTo(
          index * 80.0, // Yaklaşık mesaj yüksekliği
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _toast('Mesaj bulundu');
      }
    }
  }

  void _showMessageInfo(Message m) {
    MessageInfoSheet.show(context, message: m, chatName: _chat.name);
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;

    // Selection geçerli değilse (cursor yok), sona ekle
    if (!selection.isValid || selection.start < 0) {
      _controller.text = text + emoji;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      return;
    }

    final newText = text.replaceRange(selection.start, selection.end, emoji);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  final _audioService = AudioService.instance;

  /// Sesli mesaj kaydını başlat (4.3 - Gerçek implementasyon)
  Future<void> _startVoiceRecording() async {
    final started = await _audioService.startRecording();
    if (started) {
      setState(() => _isRecordingVoice = true);
    } else {
      _toast('Mikrofon izni gerekli');
    }
  }

  /// Kaydı iptal et
  Future<void> _cancelVoiceRecording() async {
    await _audioService.cancelRecording();
    setState(() => _isRecordingVoice = false);
  }

  /// Sesli mesaj gönder (4.3 - Gerçek implementasyon)
  Future<void> _sendVoiceMessage(Duration duration) async {
    setState(() => _isRecordingVoice = false);

    // Kaydı durdur ve dosyayı al
    final audioFile = await _audioService.stopRecording();

    if (audioFile == null) {
      _toast('Ses kaydı alınamadı');
      return;
    }

    if (_useSupabase) {
      setState(() => _isUploadingMedia = true);
      _toast('Sesli mesaj gönderiliyor...');

      try {
        final bytes = await audioFile.readAsBytes();

        final success = await chatService.sendVoiceMessage(
          chatId: _chat.id,
          audioBytes: bytes,
          durationSeconds: duration.inSeconds,
        );

        if (success) {
          debugPrint(
            'ChatDetailPage: Voice message sent (${duration.inSeconds}s)',
          );
        } else {
          _toast('Sesli mesaj gönderilemedi');
        }
      } catch (e) {
        _toast('Sesli mesaj yüklenirken hata oluştu');
        debugPrint('Voice message error: $e');
      } finally {
        // Geçici dosyayı sil
        try {
          await audioFile.delete();
        } catch (_) {}
        if (mounted) setState(() => _isUploadingMedia = false);
      }
    } else {
      _toast('Sesli mesaj gönderildi (${duration.inSeconds}s)');
    }
  }

  /// Mesaja tepki ekle
  Future<void> _addReaction(Message m, String emoji) async {
    try {
      final success = await chatService.addReaction(
        messageId: m.id,
        emoji: emoji,
      );

      if (success) {
        HapticFeedback.lightImpact();
        // Anlık güncelleme için mesajları reload et
        await chatService.loadMessages(_chat.id);
        if (mounted) {
          setState(() {
            _cachedMessages = null;
            _supabaseMessages = chatService.getMessages(_chat.id);
          });
        }
      } else {
        _toast('Reaksiyon eklenemedi (Tablo hatası olabilir)', isError: true);
      }
    } catch (e) {
      debugPrint('ChatDetailPage: Error adding reaction: $e');
      _toast('Hata: $e', isError: true);
    }
  }

  Future<void> _onMessageLongPress(Message m) async {
    final action = await showModalBottomSheet<_MsgAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cs = Theme.of(context).colorScheme;
        final isMe = m.isMe;
        final starred = _starredMessageIds.contains(m.id);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Message preview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurface),
                  ),
                ),
                // Quick reactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((
                        emoji,
                      ) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addReaction(m, emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.reply_rounded,
                      label: 'Yanıtla',
                      onTap: () => Navigator.pop(context, _MsgAction.reply),
                    ),
                    _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Kopyala',
                      onTap: () => Navigator.pop(context, _MsgAction.copy),
                    ),
                    _ActionButton(
                      icon: starred
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: starred ? 'Kaldır' : 'Yıldızla',
                      onTap: () => Navigator.pop(context, _MsgAction.star),
                    ),
                    _ActionButton(
                      icon: Icons.forward_rounded,
                      label: 'İlet',
                      onTap: () => Navigator.pop(context, _MsgAction.forward),
                    ),
                    if (isMe)
                      _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Düzenle',
                        onTap: () => Navigator.pop(context, _MsgAction.edit),
                      ),
                    if (isMe)
                      _ActionButton(
                        icon: Icons.info_outline_rounded,
                        label: 'Bilgi',
                        onTap: () => Navigator.pop(context, _MsgAction.info),
                      ),
                    if (isMe)
                      _ActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Sil',
                        onTap: () => Navigator.pop(context, _MsgAction.delete),
                        isDestructive: true,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;

    switch (action) {
      case _MsgAction.copy:
        await Clipboard.setData(ClipboardData(text: m.text));
        if (!mounted) return;
        _toast('Kopyalandı');
        break;
      case _MsgAction.reply:
        setState(() => _replyTo = m);
        break;
      case _MsgAction.forward:
        if (!mounted) return;
        Navigator.pop(context);
        _openForwardPage(m);
        break;
      case _MsgAction.star:
        final wasStarred = _starredMessageIds.contains(m.id);
        // Önce UI'ı güncelle (optimistic update)
        setState(() {
          if (wasStarred) {
            _starredMessageIds.remove(m.id);
          } else {
            _starredMessageIds.add(m.id);
          }
        });
        // Database'i güncelle
        final success = await ChatService.instance.toggleStarMessage(m.id);
        if (!success && mounted) {
          // Başarısız olursa geri al
          setState(() {
            if (wasStarred) {
              _starredMessageIds.add(m.id);
            } else {
              _starredMessageIds.remove(m.id);
            }
          });
          _toast('İşlem başarısız');
        } else {
          _toast(wasStarred ? 'Yıldız kaldırıldı' : 'Yıldızlandı');
        }
        break;
      case _MsgAction.info:
        _showMessageInfo(m);
        break;
      case _MsgAction.edit:
        _showEditMessageDialog(m);
        break;
      case _MsgAction.delete:
        _showDeleteConfirmation(m);
        break;
    }
  }

  /// Mesaj düzenleme dialogu
  void _showEditMessageDialog(Message m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editController = TextEditingController(text: m.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          'Mesajı Düzenle',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Mesaj...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != m.text) {
                Navigator.pop(context);

                if (_useSupabase) {
                  final success = await chatService.editMessage(m.id, newText);
                  if (success) {
                    await chatService.loadMessages(_chat.id);
                    setState(() {
                      _supabaseMessages = chatService.getMessages(_chat.id);
                    });
                    _toast('Mesaj düzenlendi');
                  } else {
                    _toast('Düzenleme başarısız');
                  }
                } else {
                  // Mock data için local güncelleme
                  final index = _messages.indexWhere((x) => x.id == m.id);
                  if (index != -1) {
                    setState(() {
                      _messages[index] = m.copyWith(text: newText);
                    });
                  }
                  _toast('Mesaj düzenlendi');
                }
              }
            },
            child: Text('Kaydet', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Mesaj silme onayı
  void _showDeleteConfirmation(Message m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          'Mesajı Sil',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Bu mesajı silmek istediğinize emin misiniz?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (_useSupabase) {
                final success = await chatService.deleteMessage(m.id);
                if (success) {
                  await chatService.loadMessages(_chat.id);
                  setState(() {
                    _supabaseMessages = chatService.getMessages(_chat.id);
                  });
                  _toast('Mesaj silindi');
                } else {
                  _toast('Silme başarısız');
                }
              } else {
                // Mock data için local silme
                setState(() => _messages.removeWhere((x) => x.id == m.id));
                _toast('Silindi');
              }
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    // Grup için GroupInfoPage'e git
    if (_isGroupChat) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupInfoPage(groupId: _chat.id)),
      ).then((_) {
        // GroupInfoPage'den döndükten sonra wallpaper'ı yeniden yükle
        _wallpaperLoaded = false;
        _loadSavedWallpaper();
      });
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final presence = store.presenceOf(_chat.userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Profile
            CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
              child: Icon(
                Icons.person,
                size: 50,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _chat.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              presence.online
                  ? 'Çevrimiçi'
                  : chatService.formatLastSeen(presence.lastSeenAt),
              style: TextStyle(
                color: presence.online
                    ? NearTheme.primary
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProfileAction(
                  icon: Icons.call_rounded,
                  label: 'Sesli',
                  onTap: () {
                    Navigator.pop(ctx);
                    _startCall(video: false);
                  },
                ),
                const SizedBox(width: 32),
                _ProfileAction(
                  icon: Icons.videocam_rounded,
                  label: 'Görüntülü',
                  onTap: () {
                    Navigator.pop(ctx);
                    _startCall(video: true);
                  },
                ),
                const SizedBox(width: 32),
                _ProfileAction(
                  icon: Icons.search_rounded,
                  label: 'Ara',
                  onTap: () {
                    Navigator.pop(ctx);
                    _openMessageSearch();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Options
            Expanded(
              child: ListView(
                children: [
                  _InfoTile(
                    icon: Icons.image_rounded,
                    label: 'Medya, Bağlantılar, Belgeler',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openMediaGallery();
                    },
                  ),
                  _InfoTile(
                    icon: Icons.star_rounded,
                    label: 'Yıldızlı Mesajlar',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openStarredMessages();
                    },
                  ),
                  _InfoTile(
                    icon: Icons.notifications_rounded,
                    label: 'Bildirimleri Sessize Al',
                    onTap: () {
                      store.toggleMute(_chat.userId);
                      Navigator.pop(ctx);
                      _toast(
                        store.isMuted(_chat.userId)
                            ? 'Sessize alındı'
                            : 'Sessiz kaldırıldı',
                      );
                    },
                  ),
                  _InfoTile(
                    icon: Icons.wallpaper_rounded,
                    label: 'Duvar Kağıdı',
                    onTap: () {
                      Navigator.pop(ctx);
                      _openWallpaperPicker();
                    },
                  ),
                  const Divider(height: 32),
                  _InfoTile(
                    icon: Icons.block_rounded,
                    label: 'Engelle',
                    color: Colors.red,
                    onTap: () {
                      store.toggleBlock(_chat.userId);
                      Navigator.pop(ctx);
                      if (store.isBlocked(_chat.userId)) Navigator.pop(context);
                    },
                  ),
                  _InfoTile(
                    icon: Icons.thumb_down_rounded,
                    label: 'Şikayet Et',
                    color: Colors.red,
                    onTap: () => _showReportDialog(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([store, chatService]),
      builder: (context, _) {
        final presence = store.presenceOf(_chat.userId);
        final typing = store.isTyping(_chat.id) || _isOtherUserTyping;

        // Grup için online durumu gösterme
        final isOnline = _isGroupChat ? false : (presence.online && _canSeeLastSeen);

        // Grup için üye sayısı, bireysel sohbet için online durumu
        String subtitle;
        if (_isGroupChat) {
          final memberCount = _chatMembers.length;
          subtitle = typing
              ? 'birisi yazıyor...'
              : (memberCount > 0 ? '$memberCount üye' : 'Yükleniyor...');
        } else {
          // Son görülme gizlilik kontrolü
          if (!_canSeeLastSeen) {
            subtitle = typing ? 'yazıyor...' : '';
          } else {
            subtitle = typing
                ? 'yazıyor...'
                : (presence.online
                      ? 'Çevrimiçi'
                      : chatService.formatLastSeen(presence.lastSeenAt));
          }

          if (subtitle.isEmpty) subtitle = ''; // Boş ise boş
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
            leadingWidth: 30,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: NearTheme.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: InkWell(
              onTap: _showChatInfo,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _isGroupChat
                            ? NearTheme.primary.withAlpha(30)
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                        // Profil fotoğrafı gizlilik kontrolü
                        backgroundImage: (_canSeeProfilePhoto && _supabaseChat?['avatar_url'] != null)
                            ? NetworkImage(_supabaseChat!['avatar_url'])
                            : null,
                        child: (!_canSeeProfilePhoto || _supabaseChat?['avatar_url'] == null)
                            ? Icon(
                                _isGroupChat ? Icons.group : Icons.person,
                                size: 22,
                                color: _isGroupChat
                                    ? NearTheme.primary
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600),
                              )
                            : null,
                      ),
                      // Sadece bireysel sohbetlerde online durumu göster
                      if (isOnline && !_isGroupChat)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chatName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (typing)
                          Row(
                            children: [
                              const TypingIndicator(dotSize: 6),
                              const SizedBox(width: 6),
                              Text(
                                'yazıyor',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: NearTheme.primary,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isOnline
                                  ? const Color(0xFF25D366)
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _openMessageSearch,
                icon: Icon(Icons.search_rounded, color: NearTheme.primary),
              ),
              IconButton(
                onPressed: () => _startCall(video: true),
                icon: Icon(Icons.videocam_rounded, color: NearTheme.primary),
              ),
              IconButton(
                onPressed: () => _startCall(video: false),
                icon: Icon(Icons.call_rounded, color: NearTheme.primary),
              ),
              IconButton(
                onPressed: _showChatInfo,
                icon: Icon(Icons.more_vert, color: NearTheme.primary),
              ),
            ],
          ),

          body: Stack(
            children: [
              ChatWallpaper(
                wallpaperId: _wallpaperId,
                child: Column(
                  children: [
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        itemCount: _messages.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) return _DayChip(text: 'Bugün');
                          final m = _messages[i - 1];

                          // Grup sohbetinde sender name bul
                          String? senderName;
                          if (_isGroupChat && !m.isMe) {
                            senderName = _getSenderNameForMessage(m.senderId);
                          }

                          // Reactions bul
                          final reactions = _getReactionsForMessage(m.id);

                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _SwipeableMessageBubble(
                              message: m,
                              starred:
                                  m.isStarred ||
                                  _starredMessageIds.contains(m.id),
                              onLongPress: () => _onMessageLongPress(m),
                              onReply: () => setState(() => _replyTo = m),
                              onReact: (emoji) => _addReaction(m, emoji),
                              isGroupChat: _isGroupChat,
                              senderName: senderName,
                              reactions: reactions,
                            ),
                          );
                        },
                      ),
                    ),

                    // Reply bar
                    if (_replyTo != null)
                      Container(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: NearTheme.primary,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _replyTo!.isMe ? 'Sen' : _chat.name,
                                      style: TextStyle(
                                        color: NearTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _replyTo!.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                onPressed: () =>
                                    setState(() => _replyTo = null),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Voice recorder overlay
                    if (_isRecordingVoice)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SafeArea(
                          top: false,
                          child: VoiceMessageRecorder(
                            onCancel: _cancelVoiceRecording,
                            onRecordingComplete: _sendVoiceMessage,
                          ),
                        ),
                      ),

                    // @Mention önerileri (input bar üstünde)
                    if (_showMentionSuggestions &&
                        _mentionSuggestions.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _mentionSuggestions.length,
                          itemBuilder: (context, index) {
                            final member = _mentionSuggestions[index];
                            final profile =
                                member['profiles'] as Map<String, dynamic>?;
                            final username = profile?['username'] ?? '';
                            final fullName = profile?['full_name'] ?? '';
                            final avatarUrl = profile?['avatar_url'];

                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: NearTheme.primary,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                fullName.isNotEmpty ? fullName : username,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '@$username',
                                style: TextStyle(
                                  color: NearTheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => _onMentionSelected(member),
                            );
                          },
                        ),
                      ),

                    // Link preview (above input bar)
                    if (!_isRecordingVoice &&
                        (_inputLinkPreview != null || _isLoadingLinkPreview))
                      Container(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: InputLinkPreview(
                          previewData: _inputLinkPreview,
                          isLoading: _isLoadingLinkPreview,
                          onRemove: _clearLinkPreview,
                        ),
                      ),

                    // Input bar (hidden when recording)
                    if (!_isRecordingVoice)
                      Container(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              // Input field
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _showEmojiPicker
                                              ? Icons.keyboard
                                              : Icons.emoji_emotions_outlined,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        onPressed: _toggleEmojiPicker,
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _send(),
                                          onTap: () {
                                            if (_showEmojiPicker) {
                                              setState(
                                                () => _showEmojiPicker = false,
                                              );
                                            }
                                          },
                                          style: TextStyle(color: cs.onSurface),
                                          decoration: InputDecoration(
                                            hintText: 'Mesaj',
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.attach_file_rounded,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        onPressed: () =>
                                            _showAttachmentOptions(),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.camera_alt_rounded,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                        onPressed: _pickFromCamera,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // ✨ Effect Button (Premium)
                              EffectButton(
                                currentEffect: _selectedEffect,
                                onTap: _showEffectPicker,
                              ),
                              const SizedBox(width: 4),
                              // Send/Voice button
                              GestureDetector(
                                onTap: _controller.text.isEmpty
                                    ? _startVoiceRecording
                                    : _send,
                                onLongPress: _controller.text.isEmpty
                                    ? _startVoiceRecording
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedEffect != MessageEffect.none
                                        ? _selectedEffect.colors.first
                                        : NearTheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        _selectedEffect != MessageEffect.none
                                        ? [
                                            BoxShadow(
                                              color: _selectedEffect
                                                  .colors
                                                  .first
                                                  .withAlpha(100),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _controller.text.isEmpty
                                        ? Icons.mic_rounded
                                        : (_selectedEffect != MessageEffect.none
                                              ? _selectedEffect.icon
                                              : Icons.send_rounded),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Emoji picker
                    if (_showEmojiPicker)
                      EmojiPickerWidget(
                        height: 280,
                        onEmojiSelected: _onEmojiSelected,
                        onBackspace: () {
                          if (_controller.text.isNotEmpty) {
                            _controller.text = _controller.text.substring(
                              0,
                              _controller.text.length - 1,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ), // Close ChatWallpaper
              // ✨ Message Effect Overlay (Premium)
              if (_showEffectOverlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: MessageEffectOverlay(
                      effect: _playingEffect,
                      onComplete: () {
                        if (mounted) {
                          setState(() {
                            _showEffectOverlay = false;
                            _playingEffect = MessageEffect.none;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ], // Close Stack
          ), // Close body Stack
        );
      },
    );
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.insert_drive_file,
                    label: 'Belge',
                    color: const Color(0xFF5E5CE6),
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: const Color(0xFFFF2D55),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.photo,
                    label: 'Galeri',
                    color: const Color(0xFF9F5FF2),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: const Color(0xFFFF3B30),
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.gif_box,
                    label: 'GIF',
                    color: const Color(0xFFFF9500),
                    onTap: () {
                      Navigator.pop(context);
                      _openGifPicker();
                    },
                  ),
                  _AttachOption(
                    icon: Icons.location_on,
                    label: 'Konum',
                    color: const Color(0xFF34C759),
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.person,
                    label: 'Kişi',
                    color: const Color(0xFF007AFF),
                    onTap: () {
                      Navigator.pop(context);
                      _shareContact();
                    },
                  ),
                  const SizedBox(width: 80), // Boşluk
                  const SizedBox(width: 80), // Boşluk
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MsgAction { copy, reply, forward, star, info, edit, delete }

// Action Button for message options
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// Profile Action Button
class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: NearTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NearTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: NearTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Info Tile
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? Colors.white70 : Colors.black87);

    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}

// Day Chip
class _DayChip extends StatelessWidget {
  final String text;
  const _DayChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// Swipeable Message Bubble Wrapper
class _SwipeableMessageBubble extends StatefulWidget {
  final Message message;
  final bool starred;
  final VoidCallback onLongPress;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final bool isGroupChat;
  final String? senderName;
  final List<Map<String, dynamic>>? reactions;

  const _SwipeableMessageBubble({
    required this.message,
    required this.starred,
    required this.onLongPress,
    required this.onReply,
    required this.onReact,
    this.isGroupChat = false,
    this.senderName,
    this.reactions,
  });

  @override
  State<_SwipeableMessageBubble> createState() =>
      _SwipeableMessageBubbleState();
}

class _SwipeableMessageBubbleState extends State<_SwipeableMessageBubble>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  static const double _swipeThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(_heartAnimationController);

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimationController);

    _heartAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeartAnimation = false);
        _heartAnimationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() => _showHeartAnimation = true);
    _heartAnimationController.forward();
    widget.onReact('❤️');
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Sadece sağa kaydırma (reply için)
    final isMe = widget.message.isMe;

    if (isMe) {
      // Benim mesajım: sola kaydır
      if (details.delta.dx < 0) {
        setState(() {
          _dragExtent = (_dragExtent + details.delta.dx).clamp(
            -_swipeThreshold * 1.5,
            0,
          );
        });
      }
    } else {
      // Karşı tarafın mesajı: sağa kaydır
      if (details.delta.dx > 0) {
        setState(() {
          _dragExtent = (_dragExtent + details.delta.dx).clamp(
            0,
            _swipeThreshold * 1.5,
          );
        });
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final threshold = widget.message.isMe ? -_swipeThreshold : _swipeThreshold;

    if ((widget.message.isMe && _dragExtent <= threshold) ||
        (!widget.message.isMe && _dragExtent >= threshold)) {
      HapticFeedback.mediumImpact();
      widget.onReply();
    }

    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final progress = (_dragExtent.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Reply indicator
        Positioned.fill(
          child: Align(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(
                left: isMe ? 16 : 0,
                right: isMe ? 0 : 16,
              ),
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + (progress * 0.5),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NearTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply,
                      color: NearTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Message bubble with gesture
        GestureDetector(
          onDoubleTap: _onDoubleTap,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Stack(
              children: [
                _MessageBubble(
                  message: widget.message,
                  starred: widget.starred,
                  onLongPress: widget.onLongPress,
                  isGroupChat: widget.isGroupChat,
                  senderName: widget.senderName,
                  reactions: widget.reactions,
                ),

                // Heart animation overlay
                if (_showHeartAnimation)
                  Positioned.fill(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _heartAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _heartOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _heartScaleAnimation.value,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 80,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Message Bubble
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool starred;
  final VoidCallback onLongPress;
  final bool isGroupChat;
  final String? senderName;
  final List<Map<String, dynamic>>? reactions;

  const _MessageBubble({
    required this.message,
    required this.starred,
    required this.onLongPress,
    this.isGroupChat = false,
    this.senderName,
    this.reactions,
  });

  String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  IconData _statusIcon(MessageStatus s) {
    switch (s) {
      case MessageStatus.sending:
        return Icons.access_time_rounded;
      case MessageStatus.sent:
        return Icons.check_rounded;
      case MessageStatus.delivered:
        return Icons.done_all_rounded;
      case MessageStatus.read:
        return Icons.done_all_rounded;
    }
  }

  Color _statusColor(MessageStatus s) {
    return s == MessageStatus.read ? const Color(0xFF53BDEB) : Colors.white60;
  }

  // Sender name için renk (WhatsApp tarzı)
  Color _getSenderColor(String name) {
    final colors = [
      const Color(0xFF7B3FF2), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = message.isMe;

    // WhatsApp style colors with NearTheme accent
    final myBubbleColor = NearTheme.primary;
    final theirBubbleColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final myTextColor = Colors.white;
    final theirTextColor = isDark ? Colors.white : Colors.black87;

    // Medya tipine göre padding ayarla
    final isMediaMessage =
        message.type == MessageType.image ||
        message.type == MessageType.video ||
        message.type == MessageType.gif;
    final bubblePadding = isMediaMessage
        ? const EdgeInsets.all(4.0)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    // Grup sohbetinde gönderen ismini göster
    final showSenderName =
        isGroupChat && !isMe && senderName != null && senderName!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          padding: bubblePadding,
          decoration: BoxDecoration(
            color: isMe ? myBubbleColor : theirBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Grup sohbetinde gönderen ismi
              if (showSenderName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getSenderColor(senderName!),
                    ),
                  ),
                ),

              // Starred indicator
              if (starred)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: isMe ? Colors.white70 : Colors.amber,
                  ),
                ),

              // Medya içeriği (tip bazlı)
              _buildMediaContent(
                context,
                isDark,
                isMe,
                myTextColor,
                theirTextColor,
              ),

              // Caption (medya mesajları için)
              if (isMediaMessage && message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? myTextColor : theirTextColor,
                      fontSize: 15,
                    ),
                  ),
                ),

              // Time & status
              Padding(
                padding: isMediaMessage
                    ? const EdgeInsets.all(8)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe
                            ? Colors.white60
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    if (starred) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: isMe
                            ? Colors.white60
                            : Colors.amber.withValues(alpha: 0.7),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _statusIcon(message.status),
                        size: 14,
                        color: _statusColor(message.status),
                      ),
                    ],
                  ],
                ),
              ),

              // Reactions badge
              if (reactions != null && reactions!.isNotEmpty)
                _buildReactionsBadge(isDark),
            ],
          ),
        ),
      ),
    );
  }

  /// Reactions badge widget'ı
  Widget _buildReactionsBadge(bool isDark) {
    // Emoji'leri grupla
    final emojiCounts = <String, int>{};
    for (final r in reactions!) {
      final emoji = r['emoji'] as String? ?? '❤️';
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojiCounts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Medya tipine göre içerik oluştur
  Widget _buildMediaContent(
    BuildContext context,
    bool isDark,
    bool isMe,
    Color myTextColor,
    Color theirTextColor,
  ) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildVideoContent(context);
      case MessageType.voice:
        return _buildVoiceContent(context, isMe);
      case MessageType.file:
        return _buildFileContent(
          context,
          isDark,
          isMe,
          myTextColor,
          theirTextColor,
        );
      case MessageType.gif:
        return _buildGifContent(context);
      case MessageType.location:
        return _buildLocationContent(
          context,
          isDark,
          isMe,
          myTextColor,
          theirTextColor,
        );
      case MessageType.contact:
        return _buildContactContent(
          context,
          isDark,
          isMe,
          myTextColor,
          theirTextColor,
        );
      case MessageType.text:
        return _buildTextContent(
          context,
          isDark,
          isMe,
          myTextColor,
          theirTextColor,
        );
    }
  }

  /// Text mesaj içeriği
  Widget _buildTextContent(
    BuildContext context,
    bool isDark,
    bool isMe,
    Color myTextColor,
    Color theirTextColor,
  ) {
    final url = LinkDetector.extractFirstUrl(message.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Link preview
        if (url != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinkPreviewCard(
              url: url,
              title: 'Link Önizlemesi',
              siteName: Uri.tryParse(url)?.host.replaceFirst('www.', ''),
              isCompact: true,
              onTap: () => _openUrl(url),
            ),
          ),
        // Text
        LinkifiedText(
          text: message.text,
          style: TextStyle(
            color: isMe ? myTextColor : theirTextColor,
            fontSize: 16,
          ),
          linkStyle: TextStyle(
            color: isMe ? Colors.white : NearTheme.primary,
            fontSize: 16,
            decoration: TextDecoration.underline,
          ),
          onLinkTap: (link) => _openUrl(link),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Fotoğraf içeriği
  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Icon(Icons.broken_image)),
      );
    }

    debugPrint('Loading image: ${message.mediaUrl}');

    return GestureDetector(
      onTap: () => _openFullScreenImage(context, message.mediaUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.mediaUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load error: $error');
            debugPrint('Image URL: ${message.mediaUrl}');
            return Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf yüklenemedi',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                  color: NearTheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Tam ekran fotoğraf görüntüleyici
  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            imageUrl: imageUrl,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Video içeriği
  Widget _buildVideoContent(BuildContext context) {
    final thumbnailUrl = message.metadata?['thumbnail_url'] as String?;

    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
          _openVideoPlayer(context, message.mediaUrl!);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.black54,
                  child: const Center(
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.black54,
                child: const Center(
                  child: Icon(Icons.videocam, color: Colors.white38, size: 48),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Süre göstergesi
            if (message.metadata?['duration_ms'] != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(
                      Duration(
                        milliseconds: message.metadata!['duration_ms'] as int,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tam ekran video oynatıcı aç
  void _openVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  /// Sesli mesaj içeriği
  Widget _buildVoiceContent(BuildContext context, bool isMe) {
    final durationSeconds = message.duration ?? 0;

    return VoiceMessagePlayer(
      duration: Duration(seconds: durationSeconds),
      audioUrl: message.mediaUrl,
      isFromMe: isMe,
    );
  }

  /// Dosya içeriği
  Widget _buildFileContent(
    BuildContext context,
    bool isDark,
    bool isMe,
    Color myTextColor,
    Color theirTextColor,
  ) {
    final fileName = message.fileName ?? 'Dosya';
    final fileSize = message.fileSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withAlpha(50)
                : NearTheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(fileName),
            color: isMe ? Colors.white : NearTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: TextStyle(
                  color: isMe ? myTextColor : theirTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (fileSize != null)
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white60
                        : (isDark ? Colors.white54 : Colors.black45),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// GIF içeriği
  Widget _buildGifContent(BuildContext context) {
    if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('GIF')));
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(context, message.mediaUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.mediaUrl!,
          fit: BoxFit.cover,
          headers: const {'Accept': 'image/gif, image/*'},
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stack) {
            debugPrint('GIF load error: $error for URL: ${message.mediaUrl}');
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gif_box, size: 40, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text(
                    'GIF yüklenemedi',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Konum içeriği
  Widget _buildLocationContent(
    BuildContext context,
    bool isDark,
    bool isMe,
    Color myTextColor,
    Color theirTextColor,
  ) {
    final address = message.text.isNotEmpty ? message.text : 'Konum';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withAlpha(50)
                : Colors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: isMe ? Colors.white : Colors.green,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Konum',
                style: TextStyle(
                  color: isMe ? myTextColor : theirTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  color: isMe
                      ? Colors.white70
                      : (isDark ? Colors.white60 : Colors.black54),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Kişi kartı içeriği
  Widget _buildContactContent(
    BuildContext context,
    bool isDark,
    bool isMe,
    Color myTextColor,
    Color theirTextColor,
  ) {
    final contactName = message.metadata?['name'] ?? message.text;
    final contactPhone = message.metadata?['phone'] ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isMe
              ? Colors.white.withAlpha(50)
              : NearTheme.primary,
          child: Text(
            contactName.isNotEmpty ? contactName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contactName,
                style: TextStyle(
                  color: isMe ? myTextColor : theirTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (contactPhone.isNotEmpty)
                Text(
                  contactPhone,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white70
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Attachment option button
class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mesaj arama sheet'i
class _MessageSearchSheet extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool useSupabase;
  final Function(Map<String, dynamic>) onMessageTap;

  const _MessageSearchSheet({
    required this.chatId,
    required this.chatName,
    required this.useSupabase,
    required this.onMessageTap,
  });

  @override
  State<_MessageSearchSheet> createState() => _MessageSearchSheetState();
}

class _MessageSearchSheetState extends State<_MessageSearchSheet> {
  final _searchController = TextEditingController();
  final _chatService = ChatService.instance;
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _query = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = query;
    });

    final results = await _chatService.searchMessagesInChat(
      widget.chatId,
      query,
    );

    if (mounted && _query == query) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    '${widget.chatName} içinde ara',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _search,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Mesaj ara...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _isSearching
                ? Center(
                    child: CircularProgressIndicator(color: NearTheme.primary),
                  )
                : _results.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'Aramak için yazın' : 'Sonuç bulunamadı',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final message = _results[index];
                      final sender = message['sender'] as Map<String, dynamic>?;
                      final senderName =
                          sender?['full_name'] ??
                          sender?['username'] ??
                          'Bilinmeyen';
                      final content = message['content'] ?? '';
                      final createdAt = DateTime.tryParse(
                        message['created_at'] ?? '',
                      );
                      final timeStr = createdAt != null
                          ? '${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                          : '';

                      return ListTile(
                        onTap: () => widget.onMessageTap(message),
                        leading: CircleAvatar(
                          backgroundColor: NearTheme.primary,
                          child: Text(
                            senderName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        trailing: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tam ekran fotoğraf görüntüleyici widget
class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final Animation<double> animation;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.animation,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tıklanabilir arka plan - kapatmak için
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Fotoğraf - pinch to zoom
          Center(
            child: Hero(
              tag: widget.imageUrl,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                onInteractionEnd: (details) {
                  // Çok küçükse sıfırla
                  if (_transformationController.value.getMaxScaleOnAxis() <
                      1.0) {
                    _resetZoom();
                  }
                },
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: 100,
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Fotoğraf yüklenemedi',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Üst bar - kapatma butonu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Yakınlaştırmayı sıfırla',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Alt bilgi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yakınlaştırmak için parmakla sıkıştırın',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tam ekran video oynatıcı widget
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: _hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Video yüklenemedi',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.videoUrl,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Controls overlay
            if (_showControls && _isInitialized) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),

              // Center play/pause button
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (context, value, child) {
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    trackHeight: 3,
                                    activeTrackColor: NearTheme.primary,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: NearTheme.primary,
                                  ),
                                  child: Slider(
                                    value: value.position.inMilliseconds
                                        .toDouble(),
                                    min: 0,
                                    max: value.duration.inMilliseconds
                                        .toDouble(),
                                    onChanged: (newValue) {
                                      _controller.seekTo(
                                        Duration(
                                          milliseconds: newValue.toInt(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(value.position),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(value.duration),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Close button when controls are hidden
            if (!_showControls || _hasError)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
