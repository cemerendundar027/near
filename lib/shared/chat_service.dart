import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'chat_store.dart';

/// Supabase Chat Service - Gerçek zamanlı mesajlaşma
class ChatService extends ChangeNotifier {
  ChatService._();
  static final instance = ChatService._();

  final _supabase = SupabaseService.instance;

  // Realtime subscriptions
  RealtimeChannel? _chatsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _globalMessagesChannel;
  RealtimeChannel? _messageStatusChannel;

  // Cached data
  List<Map<String, dynamic>> _chats = [];
  final Map<String, List<Map<String, dynamic>>> _messagesByChat = {};

  // Unread count cache - chatId -> count
  final Map<String, int> _unreadCounts = {};

  // Privacy cache
  bool? _readReceiptsEnabled;

  // Loading states
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;

  // Getters
  List<Map<String, dynamic>> get chats => _chats;
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;
  Map<String, int> get unreadCounts => Map.unmodifiable(_unreadCounts);

  /// Toplam okunmamış mesaj sayısı
  int get totalUnreadCount => _unreadCounts.values.fold(0, (a, b) => a + b);

  String? get currentUserId => _supabase.currentUser?.id;
  
  /// Supabase client'a erişim (gerekli durumlarda)
  SupabaseClient get supabase => _supabase.client;

  /// Read receipts cache'ini güncelle (privacy ayarı değiştiğinde çağrılır)
  void updateReadReceiptsCache(bool enabled) {
    _readReceiptsEnabled = enabled;
    debugPrint('ChatService: Read receipts cache updated: $enabled');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Servisi başlat ve realtime dinlemeye başla
  Future<void> init() async {
    if (currentUserId == null) {
      debugPrint('ChatService: User not logged in');
      return;
    }

    await loadChats();
    _subscribeToChats();
    _subscribeToGlobalMessages();
    _subscribeToMessageStatus();
    await setOnlineStatus(true); // Online ol
  }

  /// Servisi temizle
  @override
  void dispose() {
    setOnlineStatus(false); // Offline ol
    _chatsChannel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    _globalMessagesChannel?.unsubscribe();
    _messageStatusChannel?.unsubscribe();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Kullanıcının tüm sohbetlerini getir
  Future<void> loadChats() async {
    if (currentUserId == null) {
      debugPrint('ChatService: loadChats - No user logged in');
      return;
    }

    debugPrint('ChatService: loadChats - User: $currentUserId');
    _isLoadingChats = true;
    notifyListeners();

    try {
      // Kullanıcının katıldığı chat_participants'ları al (last_read_at dahil)
      final participations = await _supabase.client
          .from('chat_participants')
          .select('chat_id, last_read_at')
          .eq('user_id', currentUserId!);

      debugPrint('ChatService: Found ${participations.length} participations');

      if (participations.isEmpty) {
        _chats = [];
        _unreadCounts.clear();
        _isLoadingChats = false;
        notifyListeners();
        return;
      }

      // Participation bilgilerini map'e al
      final participationMap = <String, String?>{};
      final chatIds = <String>[];
      for (final p in participations) {
        final chatId = p['chat_id'] as String;
        chatIds.add(chatId);
        participationMap[chatId] = p['last_read_at'] as String?;
      }

      // Chat detaylarını ve son mesajı al
      final chatsData = await _supabase.client
          .from('chats')
          .select('''
            *,
            chat_participants!inner(
              user_id,
              profiles!inner(id, username, full_name, avatar_url, is_online, last_seen, mood_aura)
            )
          ''')
          .inFilter('id', chatIds)
          .order('last_message_at', ascending: false);

      // Her chat için son mesajı formatla ve unread count hesapla
      final List<Map<String, dynamic>> formattedChats = [];
      for (final chat in chatsData) {
        final chatId = chat['id'] as String;
        final lastReadAt = participationMap[chatId];

        // Son mesajı al
        final lastMessageResult = await _supabase.client
            .from('messages')
            .select('content, type')
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        String lastMessage = chat['last_message'] ?? '';
        if (lastMessageResult != null) {
          final content = lastMessageResult['content'] as String? ?? '';
          final type = lastMessageResult['type'] as String? ?? 'text';
          lastMessage = _formatLastMessageByType(content, type);
        }

        // Unread count hesapla
        int unreadCount = 0;
        try {
          if (lastReadAt == null) {
            // Hiç okumamış, tüm gelen mesajları say
            final countResult = await _supabase.client
                .from('messages')
                .select('id')
                .eq('chat_id', chatId)
                .neq('sender_id', currentUserId!);
            unreadCount = countResult.length;
          } else {
            // Son okumadan sonraki mesajları say
            final countResult = await _supabase.client
                .from('messages')
                .select('id')
                .eq('chat_id', chatId)
                .neq('sender_id', currentUserId!)
                .gt('created_at', lastReadAt);
            unreadCount = countResult.length;
          }
        } catch (e) {
          debugPrint('ChatService: Error calculating unread for $chatId: $e');
        }

        _unreadCounts[chatId] = unreadCount;

        formattedChats.add({
          ...chat,
          'last_message': lastMessage,
          'unread_count': unreadCount,
        });
      }

      _chats = formattedChats;
      debugPrint('ChatService: Loaded ${_chats.length} chats');
    } catch (e) {
      debugPrint('ChatService: Error loading chats: $e');
    }

    _isLoadingChats = false;
    notifyListeners();
  }

  /// Kullanıcıya mesaj gönderilip gönderilemeyeceğini kontrol et
  /// privacy_messages = 'everyone' -> herkes gönderebilir
  /// privacy_messages = 'contacts' -> sadece kişileri gönderebilir
  Future<Map<String, dynamic>> canSendMessageTo(String otherUserId) async {
    if (currentUserId == null) {
      return {'allowed': false, 'reason': 'not_logged_in'};
    }

    try {
      // Karşı kullanıcının gizlilik ayarını al
      final profile = await _supabase.client
          .from('profiles')
          .select('privacy_messages')
          .eq('id', otherUserId)
          .maybeSingle();

      final privacySetting = profile?['privacy_messages'] ?? 'everyone';

      // Herkes gönderebilir
      if (privacySetting == 'everyone') {
        return {'allowed': true};
      }

      // Sadece kişileri - rehberinde mi kontrol et
      if (privacySetting == 'contacts') {
        // Karşı kullanıcının contacts tablosunda biz var mıyız?
        final contact = await _supabase.client
            .from('contacts')
            .select('id')
            .eq('user_id', otherUserId)
            .eq('contact_id', currentUserId!)
            .maybeSingle();

        if (contact != null) {
          return {'allowed': true};
        } else {
          return {
            'allowed': false,
            'reason': 'contacts_only',
            'message': 'Bu kullanıcı sadece kişilerinden mesaj alıyor'
          };
        }
      }

      return {'allowed': true};
    } catch (e) {
      debugPrint('ChatService: Error checking message permission: $e');
      return {'allowed': true}; // Hata durumunda izin ver
    }
  }

  /// Yeni birebir sohbet oluştur
  Future<String?> createDirectChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Önce mevcut sohbet var mı kontrol et
      final existingChat = await _findExistingDirectChat(otherUserId);
      if (existingChat != null) {
        return existingChat;
      }

      // Yeni chat oluştur
      final chatResponse = await _supabase.client
          .from('chats')
          .insert({'is_group': false, 'created_by': currentUserId})
          .select()
          .single();

      final chatId = chatResponse['id'] as String;

      // Her iki kullanıcıyı da ekle
      await _supabase.client.from('chat_participants').insert([
        {'chat_id': chatId, 'user_id': currentUserId},
        {'chat_id': chatId, 'user_id': otherUserId},
      ]);

      await loadChats();
      debugPrint('ChatService: Created direct chat: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('ChatService: Error creating chat: $e');
      return null;
    }
  }

  /// Mevcut birebir sohbet bul (public)
  Future<String?> findExistingDirectChat(String otherUserId) async {
    return _findExistingDirectChat(otherUserId);
  }

  /// Mevcut birebir sohbet bul (internal)
  Future<String?> _findExistingDirectChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Kullanıcının tüm chatlerini al
      final myChats = await _supabase.client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId!);

      if (myChats.isEmpty) return null;

      final myChatsIds = (myChats as List)
          .map((c) => c['chat_id'] as String)
          .toList();

      // Bu chatlerin hangisinde other user var
      final otherUserChats = await _supabase.client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', otherUserId)
          .inFilter('chat_id', myChatsIds);

      if (otherUserChats.isEmpty) return null;

      // Group olmayan ilk chat'i bul
      for (final chat in otherUserChats) {
        final chatId = chat['chat_id'] as String;
        final chatInfo = await _supabase.client
            .from('chats')
            .select('is_group')
            .eq('id', chatId)
            .single();

        if (chatInfo['is_group'] == false) {
          return chatId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('ChatService: Error finding existing chat: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Kullanıcı ara (username veya full_name ile)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('ChatService: Searching users with query: "$query"');
      debugPrint('ChatService: Current user ID: $currentUserId');

      // Username veya full_name içinde ara
      final results = await _supabase.client
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, bio, is_online, last_seen',
          )
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .neq('id', currentUserId ?? '') // Kendini hariç tut
          .limit(20);

      debugPrint('ChatService: Found ${results.length} users for "$query"');
      for (var user in results) {
        debugPrint('  - ${user['username']} (${user['full_name']})');
      }
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ChatService: Error searching users: $e');
      return [];
    }
  }

  /// Tüm kullanıcıları getir (contact listesi için)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      debugPrint('ChatService: Loading all users, excluding: $currentUserId');

      final results = await _supabase.client
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, bio, is_online, last_seen',
          )
          .neq('id', currentUserId ?? '')
          .order('full_name', ascending: true)
          .limit(100);

      debugPrint('ChatService: Loaded ${results.length} users from Supabase');
      for (var user in results) {
        debugPrint(
          '  - ${user['username']} (${user['full_name']}) id: ${user['id']}',
        );
      }
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ChatService: Error loading users: $e');
      return [];
    }
  }

  /// UUID ile tek kullanıcı bilgisi al
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    if (userId.isEmpty) return null;

    try {
      debugPrint('ChatService: Getting user by ID: $userId');
      final result = await _supabase.client
          .from('profiles')
          .select('id, username, full_name, avatar_url, bio, is_online, last_seen')
          .eq('id', userId)
          .maybeSingle();
      
      if (result != null) {
        debugPrint('ChatService: Found user: ${result['username']} (${result['full_name']})');
      } else {
        debugPrint('ChatService: User not found for ID: $userId');
      }
      return result;
    } catch (e) {
      debugPrint('ChatService: Error getting user by ID: $e');
      return null;
    }
  }

  /// Telefon numaralarına göre kullanıcıları bul (rehber entegrasyonu için)
  Future<List<Map<String, dynamic>>> findUsersByPhones(
    List<String> phoneNumbers,
  ) async {
    if (phoneNumbers.isEmpty) return [];

    try {
      debugPrint(
        'ChatService: Finding users by ${phoneNumbers.length} phone numbers',
      );

      // Telefon numaralarını normalize et ve filtrele
      final normalizedPhones = phoneNumbers
          .map((p) => p.replaceAll(RegExp(r'[^\d+]'), ''))
          .where((p) => p.length >= 10)
          .toSet()
          .toList();

      if (normalizedPhones.isEmpty) return [];

      // Supabase'de IN query ile ara
      final results = await _supabase.client
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, bio, is_online, last_seen, phone',
          )
          .inFilter('phone', normalizedPhones)
          .neq('id', currentUserId ?? '');

      debugPrint(
        'ChatService: Found ${results.length} users from phone contacts',
      );
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ChatService: Error finding users by phones: $e');
      return [];
    }
  }

  /// Kullanıcı profilini getir
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final result = await _supabase.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return result;
    } catch (e) {
      debugPrint('ChatService: Error getting user profile: $e');
      return null;
    }
  }

  /// Grup sohbeti oluştur
  Future<String?> createGroupChat({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    if (currentUserId == null) return null;

    try {
      debugPrint(
        'ChatService: Creating group "$name" with ${memberIds.length} members',
      );

      // Grup oluştur
      final chatResponse = await _supabase.client
          .from('chats')
          .insert({
            'name': name,
            'is_group': true,
            'avatar_url': avatarUrl,
            'created_by': currentUserId,
          })
          .select()
          .single();

      final chatId = chatResponse['id'] as String;
      debugPrint('ChatService: Group created with ID: $chatId');

      // Tüm üyeleri ekle (oluşturan dahil)
      final allMemberIds = <String>{
        currentUserId!,
        ...memberIds,
      }.toList(); // Set ile duplicate engelle
      final participants = allMemberIds
          .map(
            (userId) => {
              'chat_id': chatId,
              'user_id': userId,
              'role': userId == currentUserId ? 'admin' : 'member',
            },
          )
          .toList();

      debugPrint('ChatService: Adding ${participants.length} participants');
      await _supabase.client.from('chat_participants').insert(participants);

      // Chat listesini güncelle (background'da)
      loadChats();
      debugPrint('ChatService: Group chat created successfully: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('ChatService: Error creating group: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP MANAGEMENT (3.1, 3.2, 3.3)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Grup bilgilerini getir
  Future<Map<String, dynamic>?> getGroupInfo(String chatId) async {
    try {
      final chat = await _supabase.client
          .from('chats')
          .select('''
            *,
            chat_participants(
              user_id,
              role,
              joined_at,
              profiles(id, username, full_name, avatar_url, is_online, last_seen)
            )
          ''')
          .eq('id', chatId)
          .single();

      return chat;
    } catch (e) {
      debugPrint('ChatService: Error getting group info: $e');
      return null;
    }
  }

  /// Grup üyelerini getir
  Future<List<Map<String, dynamic>>> getGroupMembers(String chatId) async {
    try {
      debugPrint('ChatService: Getting members for chat $chatId');

      final participants = await _supabase.client
          .from('chat_participants')
          .select('''
            user_id,
            role,
            joined_at,
            profiles:user_id(id, username, full_name, avatar_url, is_online, last_seen)
          ''')
          .eq('chat_id', chatId);

      debugPrint('ChatService: Found ${participants.length} members');
      for (var p in participants) {
        debugPrint('  - ${p['user_id']}: ${p['profiles']}');
      }

      return List<Map<String, dynamic>>.from(participants);
    } catch (e) {
      debugPrint('ChatService: Error getting group members: $e');
      return [];
    }
  }

  /// Kullanıcının gruptaki rolünü getir
  Future<String?> getUserRoleInGroup(String chatId, {String? userId}) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) return null;

    try {
      final participant = await _supabase.client
          .from('chat_participants')
          .select('role')
          .eq('chat_id', chatId)
          .eq('user_id', targetUserId)
          .maybeSingle();

      return participant?['role'] as String?;
    } catch (e) {
      debugPrint('ChatService: Error getting user role: $e');
      return null;
    }
  }

  /// Kullanıcı admin mi kontrol et
  Future<bool> isUserAdmin(String chatId, {String? userId}) async {
    final role = await getUserRoleInGroup(chatId, userId: userId);
    return role == 'admin';
  }

  /// Gruba üye ekle (3.2)
  Future<bool> addMembersToGroup({
    required String chatId,
    required List<String> userIds,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Admin kontrolü
      final isAdmin = await isUserAdmin(chatId);
      if (!isAdmin) {
        debugPrint('ChatService: Only admins can add members');
        return false;
      }

      // Mevcut üyeleri kontrol et
      final existingMembers = await _supabase.client
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId);

      final existingUserIds = (existingMembers as List)
          .map((p) => p['user_id'] as String)
          .toSet();

      // Sadece yeni üyeleri ekle
      final newMembers = userIds
          .where((id) => !existingUserIds.contains(id))
          .map(
            (userId) => {
              'chat_id': chatId,
              'user_id': userId,
              'role': 'member',
            },
          )
          .toList();

      if (newMembers.isEmpty) {
        debugPrint('ChatService: All users are already members');
        return true;
      }

      await _supabase.client.from('chat_participants').insert(newMembers);

      await loadChats();
      debugPrint(
        'ChatService: Added ${newMembers.length} members to group $chatId',
      );
      return true;
    } catch (e) {
      debugPrint('ChatService: Error adding members: $e');
      return false;
    }
  }

  /// Gruptan üye çıkar (3.3 - Admin kontrolü)
  Future<bool> removeMemberFromGroup({
    required String chatId,
    required String userId,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Kendini çıkarmıyorsa admin kontrolü yap
      if (userId != currentUserId) {
        final isAdmin = await isUserAdmin(chatId);
        if (!isAdmin) {
          debugPrint('ChatService: Only admins can remove members');
          return false;
        }

        // Çıkarılacak kişi de admin mi kontrol et
        final targetRole = await getUserRoleInGroup(chatId, userId: userId);
        if (targetRole == 'admin') {
          debugPrint('ChatService: Cannot remove another admin');
          return false;
        }
      }

      // Üyeyi çıkar
      await _supabase.client
          .from('chat_participants')
          .delete()
          .eq('chat_id', chatId)
          .eq('user_id', userId);

      await loadChats();
      debugPrint('ChatService: Removed member $userId from group $chatId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error removing member: $e');
      return false;
    }
  }

  /// Gruptan ayrıl
  Future<bool> leaveGroup(String chatId) async {
    return removeMemberFromGroup(chatId: chatId, userId: currentUserId!);
  }

  /// Kullanıcıyı admin yap
  Future<bool> makeUserAdmin({
    required String chatId,
    required String userId,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Admin kontrolü
      final isAdmin = await isUserAdmin(chatId);
      if (!isAdmin) {
        debugPrint('ChatService: Only admins can promote members');
        return false;
      }

      await _supabase.client
          .from('chat_participants')
          .update({'role': 'admin'})
          .eq('chat_id', chatId)
          .eq('user_id', userId);

      debugPrint('ChatService: Made $userId admin in group $chatId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error making user admin: $e');
      return false;
    }
  }

  /// Adminlikten çıkar
  Future<bool> removeUserAdmin({
    required String chatId,
    required String userId,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Admin kontrolü
      final isAdmin = await isUserAdmin(chatId);
      if (!isAdmin) {
        debugPrint('ChatService: Only admins can demote members');
        return false;
      }

      // Kendisini düşüremez eğer tek admin ise
      if (userId == currentUserId) {
        final members = await getGroupMembers(chatId);
        final adminCount = members.where((m) => m['role'] == 'admin').length;
        if (adminCount <= 1) {
          debugPrint('ChatService: Cannot demote last admin');
          return false;
        }
      }

      await _supabase.client
          .from('chat_participants')
          .update({'role': 'member'})
          .eq('chat_id', chatId)
          .eq('user_id', userId);

      debugPrint('ChatService: Removed admin from $userId in group $chatId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error removing user admin: $e');
      return false;
    }
  }

  /// Grup adını güncelle
  Future<bool> updateGroupName(String chatId, String newName) async {
    if (currentUserId == null) return false;

    try {
      final isAdmin = await isUserAdmin(chatId);
      if (!isAdmin) {
        debugPrint('ChatService: Only admins can update group name');
        return false;
      }

      await _supabase.client
          .from('chats')
          .update({
            'name': newName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      await loadChats();
      debugPrint('ChatService: Updated group name to "$newName"');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error updating group name: $e');
      return false;
    }
  }

  /// Grup avatarını güncelle
  Future<bool> updateGroupAvatar(String chatId, String avatarUrl) async {
    if (currentUserId == null) return false;

    try {
      final isAdmin = await isUserAdmin(chatId);
      if (!isAdmin) {
        debugPrint('ChatService: Only admins can update group avatar');
        return false;
      }

      await _supabase.client
          .from('chats')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      await loadChats();
      debugPrint('ChatService: Updated group avatar');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error updating group avatar: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bir sohbetin mesajlarını getir
  Future<List<Map<String, dynamic>>> loadMessages(
    String chatId, {
    int limit = 50,
  }) async {
    if (currentUserId == null) return [];

    _isLoadingMessages = true;
    notifyListeners();

    try {
      debugPrint('ChatService: Loading messages for $chatId...');
      final messagesRaw = await _supabase.client
          .from('messages')
          .select('''
            *,
            sender:profiles!sender_id(id, username, full_name, avatar_url, mood_aura)
          ''')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('ChatService: Raw messages count: ${messagesRaw.length}');

      final List<Map<String, dynamic>> messages = (messagesRaw as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      final List<String> messageIds = messages
          .map((m) => m['id'] as String)
          .toList();

      if (messageIds.isNotEmpty) {
        // 1. Reaksiyonları çek (İzole)
        try {
          debugPrint(
            'ChatService: Fetching reactions for ${messageIds.length} messages...',
          );
          final reactionsRaw = await _supabase.client
              .from('message_reactions')
              .select('*')
              .inFilter('message_id', messageIds);

          final reactions = reactionsRaw as List;
          debugPrint('ChatService: Found ${reactions.length} reactions');

          for (var m in messages) {
            final mid = m['id'];
            m['message_reactions'] = reactions
                .where((r) => r['message_id'] == mid)
                .toList();
          }
        } catch (reE) {
          debugPrint(
            'ChatService: INFO - message_reactions table may be missing or inaccessible: $reE',
          );
          for (var m in messages) {
            m['message_reactions'] ??= [];
          }
        }

        // 2. Yıldızları çek (İzole)
        try {
          if (currentUserId != null) {
            final starsRaw = await _supabase.client
                .from('starred_messages')
                .select('message_id')
                .eq('user_id', currentUserId!)
                .inFilter('message_id', messageIds);

            final stars = starsRaw as List;
            debugPrint('ChatService: Found ${stars.length} stars');

            for (var m in messages) {
              final mid = m['id'];
              m['starred_messages'] = stars
                  .where((s) => s['message_id'] == mid)
                  .toList();
            }
          }
        } catch (starE) {
          debugPrint(
            'ChatService: INFO - starred_messages table may be missing or inaccessible: $starE',
          );
          for (var m in messages) {
            m['starred_messages'] ??= [];
          }
        }
      }

      _messagesByChat[chatId] = messages;
      debugPrint(
        'ChatService: Successfully loaded ${messages.length} messages for chat $chatId',
      );

      _isLoadingMessages = false;
      notifyListeners();

      return _messagesByChat[chatId]!;
    } catch (e) {
      debugPrint('ChatService: Critical error in loadMessages: $e');
      _isLoadingMessages = false;
      notifyListeners();
      return [];
    }
  }

  /// Mesajları cache'den getir
  List<Map<String, dynamic>> getMessages(String chatId) {
    return _messagesByChat[chatId] ?? [];
  }

  /// Mesaj gönder
  Future<bool> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    if (currentUserId == null) return false;

    try {
      final response = await _supabase.client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': currentUserId,
            'content': content,
            'type': type,
            'media_url': mediaUrl,
            'metadata': metadata,
            'reply_to': replyToId,
          })
          .select('id')
          .single();

      final messageId = response['id'] as String;

      // Mesajı "sent" olarak işaretle (gönderen için)
      await _markMessageAsSent(messageId);

      // Chat'in son mesajını güncelle
      await _updateChatLastMessage(chatId, content, type);

      debugPrint('ChatService: Message sent to chat $chatId (id: $messageId)');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error sending message: $e');
      return false;
    }
  }

  /// Chat'in son mesaj bilgisini güncelle
  Future<void> _updateChatLastMessage(
    String chatId,
    String content,
    String type,
  ) async {
    try {
      // Mesaj tipine göre görüntülenecek metni formatla
      final displayMessage = _formatLastMessageByType(content, type);

      await _supabase.client
          .from('chats')
          .update({
            'last_message': displayMessage,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      // Chat listesini background'da güncelle (delay önlemek için await yok)
      loadChats();
    } catch (e) {
      debugPrint('ChatService: Error updating chat last message: $e');
    }
  }

  /// Mesaj tipine göre son mesaj metnini formatla
  String _formatLastMessageByType(String content, String type) {
    switch (type) {
      case 'text':
        return content;
      case 'image':
        return content.isNotEmpty ? '📷 $content' : '📷 Fotoğraf';
      case 'video':
        return content.isNotEmpty ? '🎥 $content' : '🎥 Video';
      case 'voice':
        return '🎤 Sesli mesaj';
      case 'audio':
        return '🎵 Ses dosyası';
      case 'file':
        return '📎 ${content.isNotEmpty ? content : 'Dosya'}';
      case 'gif':
        return 'GIF';
      case 'location':
        return '📍 ${content.isNotEmpty ? content : 'Konum'}';
      case 'contact':
        return '👤 ${content.isNotEmpty ? content : 'Kişi kartı'}';
      case 'sticker':
        return '🏷️ Çıkartma';
      default:
        return content.isNotEmpty ? content : 'Mesaj';
    }
  }

  /// Mesajı gönderildi olarak işaretle (internal)
  Future<void> _markMessageAsSent(String messageId) async {
    // Gönderen için otomatik "sent" durumu
    // Karşı taraf mesajı aldığında delivered, okuduğunda read olacak
    debugPrint('ChatService: Message $messageId marked as sent');
  }

  /// Mesajı düzenle
  Future<bool> editMessage(String messageId, String newContent) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', currentUserId!);

      debugPrint('ChatService: Message edited: $messageId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error editing message: $e');
      return false;
    }
  }

  /// Mesaja tepki ekle/kaldır
  Future<bool> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Önce mevcut tepkiyi kontrol et
      final existing = await _supabase.client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', currentUserId!)
          .eq('emoji', emoji)
          .maybeSingle();

      if (existing != null) {
        // Tepki varsa kaldır
        await _supabase.client
            .from('message_reactions')
            .delete()
            .eq('id', existing['id']);
        debugPrint('ChatService: Reaction removed from $messageId');
      } else {
        // Tepki yoksa ekle
        await _supabase.client.from('message_reactions').insert({
          'message_id': messageId,
          'user_id': currentUserId,
          'emoji': emoji,
        });
        debugPrint('ChatService: Reaction $emoji added to $messageId');
      }

      return true;
    } catch (e) {
      if (e is PostgrestException) {
        debugPrint(
          'ChatService: PostgrestError adding reaction: ${e.message} (Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint})',
        );
      } else {
        debugPrint('ChatService: Unexpected error adding reaction: $e');
      }
      return false;
    }
  }

  /// Mesajın tepkilerini getir
  Future<List<Map<String, dynamic>>> getMessageReactions(
    String messageId,
  ) async {
    try {
      final reactions = await _supabase.client
          .from('message_reactions')
          .select(
            '*, user:profiles!user_id(id, username, full_name, avatar_url)',
          )
          .eq('message_id', messageId);

      return List<Map<String, dynamic>>.from(reactions);
    } catch (e) {
      debugPrint('ChatService: Error getting reactions: $e');
      return [];
    }
  }

  /// Mesajı sil (soft delete)
  Future<bool> deleteMessage(String messageId) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('messages')
          .update({
            'is_deleted': true,
            'content': 'Bu mesaj silindi',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', currentUserId!);

      debugPrint('ChatService: Message deleted: $messageId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error deleting message: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STARRED MESSAGES (5c)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mesajı yıldızla / yıldızı kaldır
  Future<bool> toggleStarMessage(String messageId) async {
    if (currentUserId == null) return false;

    try {
      // Önce mevcut yıldızı kontrol et
      final existing = await _supabase.client
          .from('starred_messages')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existing != null) {
        // Yıldız varsa kaldır
        await _supabase.client
            .from('starred_messages')
            .delete()
            .eq('id', existing['id']);
        debugPrint('ChatService: Star removed from $messageId');
      } else {
        // Yıldız yoksa ekle
        await _supabase.client.from('starred_messages').insert({
          'message_id': messageId,
          'user_id': currentUserId,
        });
        debugPrint('ChatService: Star added to $messageId');
      }
      // Cache'i güncelle
      for (final chatId in _messagesByChat.keys) {
        final messages = _messagesByChat[chatId];
        if (messages != null) {
          final idx = messages.indexWhere((m) => m['id'] == messageId);
          if (idx != -1) {
            final isCurrentlyStarred = existing != null;
            // Eklendiyse artık yıldızlı, silindiyse değil
            messages[idx]['starred_messages'] = isCurrentlyStarred
                ? []
                : [
                    {'id': 'temp'},
                  ];
            notifyListeners();
            break;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('ChatService: Error toggling star: $e');
      return false;
    }
  }

  /// Mesajın yıldızlı olup olmadığını kontrol et
  Future<bool> isMessageStarred(String messageId) async {
    if (currentUserId == null) return false;

    try {
      final existing = await _supabase.client
          .from('starred_messages')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      debugPrint('ChatService: Error checking star: $e');
      return false;
    }
  }

  /// Tüm yıldızlı mesajları getir
  Future<List<Map<String, dynamic>>> getStarredMessages() async {
    if (currentUserId == null) return [];

    try {
      final starred = await _supabase.client
          .from('starred_messages')
          .select('''
            id,
            starred_at,
            message:messages!message_id(
              id,
              content,
              type,
              media_url,
              created_at,
              sender:profiles!sender_id(id, username, full_name, avatar_url),
              chat:chats!chat_id(id, name, is_group)
            )
          ''')
          .eq('user_id', currentUserId!)
          .order('starred_at', ascending: false);

      return List<Map<String, dynamic>>.from(starred);
    } catch (e) {
      debugPrint('ChatService: Error getting starred messages: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sohbetleri dinle
  void _subscribeToChats() {
    if (currentUserId == null) return;

    // Listen to chats table changes
    _chatsChannel = _supabase.client
        .channel('chats_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (payload) {
            debugPrint('ChatService: Chat change: ${payload.eventType}');
            loadChats();
          },
        )
        .subscribe();

    // Listen to chat_participants table changes (for unread counts and last_read_at)
    // Temporarily disabled - channel subscription
    /*
    _participantsChannel = _supabase.client
        .channel('participants_${currentUserId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            debugPrint(
              'ChatService: Participation change: ${payload.eventType}',
            );
            loadChats();
          },
        )
        .subscribe();
    */

    debugPrint('ChatService: Subscribed to chats and participations');
  }

  /// Tüm mesajları global olarak dinle (unread count için)
  void _subscribeToGlobalMessages() {
    if (currentUserId == null) return;

    _globalMessagesChannel = _supabase.client
        .channel('global_messages_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            final newMessage = payload.newRecord;
            final chatId = newMessage['chat_id'] as String?;
            final senderId = newMessage['sender_id'] as String?;
            final content = newMessage['content'] as String?;
            final type = newMessage['type'] as String? ?? 'text';
            final createdAt = newMessage['created_at'] as String?;

            // Başkasından gelen mesaj
            if (chatId != null &&
                senderId != null &&
                senderId != currentUserId) {
              debugPrint(
                'ChatService: New message from $senderId in chat $chatId',
              );

              // Unread count'u artır
              _unreadCounts[chatId] = (_unreadCounts[chatId] ?? 0) + 1;

              // Chat listesindeki ilgili chat'i bul ve güncelle
              final chatIndex = _chats.indexWhere((c) => c['id'] == chatId);
              if (chatIndex != -1) {
                // Last message'ı formatla
                final formattedMessage = _formatLastMessageByType(
                  content ?? '',
                  type,
                );

                // Chat'i güncelle
                _chats[chatIndex] = {
                  ..._chats[chatIndex],
                  'last_message': formattedMessage,
                  'last_message_at': createdAt,
                  'unread_count': _unreadCounts[chatId],
                };

                // Chat'i listenin başına taşı (en son mesaj)
                final updatedChat = _chats.removeAt(chatIndex);
                _chats.insert(0, updatedChat);
              } else {
                // Chat listede yoksa, yeniden yükle
                await loadChats();
              }

              // UI'ı güncelle
              notifyListeners();
            }
          },
        )
        .subscribe();

    debugPrint('ChatService: Subscribed to global messages');
  }

  /// Message status değişikliklerini dinle
  void _subscribeToMessageStatus() {
    if (currentUserId == null) return;

    _messageStatusChannel = _supabase.client
        .channel('message_status_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_status',
          callback: (payload) {
            debugPrint(
              'ChatService: Message status change: ${payload.eventType}',
            );
            // Status değişikliği olduğunda notify et
            notifyListeners();
          },
        )
        .subscribe();

    debugPrint('ChatService: Subscribed to message status');
  }

  /// Belirli bir sohbetin mesajlarını dinle
  RealtimeChannel subscribeToMessages(
    String chatId,
    Function(Map<String, dynamic>) onMessage,
  ) {
    final channel = _supabase.client
        .channel('messages_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            debugPrint('ChatService: New message in chat $chatId');
            final newMessage = payload.newRecord;

            // Cache'e ekle
            _messagesByChat[chatId] ??= [];
            _messagesByChat[chatId]!.insert(0, newMessage);

            onMessage(newMessage);
            notifyListeners();
          },
        )
        .subscribe();

    return channel;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sohbetteki karşı tarafın bilgisini al (birebir sohbet için)
  Map<String, dynamic>? getOtherUser(Map<String, dynamic> chat) {
    if (currentUserId == null) return null;

    final participants = chat['chat_participants'] as List?;
    if (participants == null) return null;

    for (final p in participants) {
      final profile = p['profiles'] as Map<String, dynamic>?;
      if (profile != null && profile['id'] != currentUserId) {
        return profile;
      }
    }
    return null;
  }

  /// Chat adını al (grup için grup adı, birebir için karşı tarafın adı)
  String getChatName(Map<String, dynamic> chat) {
    if (chat['is_group'] == true) {
      return chat['name'] ?? 'Grup';
    }

    final otherUser = getOtherUser(chat);
    return otherUser?['full_name'] ?? otherUser?['username'] ?? 'Bilinmeyen';
  }

  /// Chat avatarını al
  String? getChatAvatar(Map<String, dynamic> chat) {
    if (chat['is_group'] == true) {
      return chat['avatar_url'];
    }

    final otherUser = getOtherUser(chat);
    return otherUser?['avatar_url'];
  }

  /// Karşı taraf online mı
  /// is_online true VE last_seen 3 dakikadan yeniyse online say
  bool isOtherUserOnline(Map<String, dynamic> chat) {
    if (chat['is_group'] == true) return false;

    final otherUser = getOtherUser(chat);
    if (otherUser == null) return false;

    // Önce is_online değerini kontrol et
    final isOnlineFlag = otherUser['is_online'] as bool? ?? false;
    if (!isOnlineFlag) {
      return false; // Kullanıcı kendini offline olarak işaretlemiş
    }

    final lastSeenStr = otherUser['last_seen'] as String?;
    if (lastSeenStr == null) return false;

    try {
      final lastSeen = DateTime.parse(lastSeenStr);
      final now = DateTime.now().toUtc();

      // is_online true olsa bile, son görülme 3 dakikadan eskiyse offline kabul et
      // (Heartbeat mekanizması çalışmıyor olabilir)
      final diff = now.difference(lastSeen).inMinutes.abs();
      return diff <= 3;
    } catch (e) {
      return isOnlineFlag; // Tarih parse edilemiyorsa flag'e güven
    }
  }

  Future<void> fetchUserOnlineStatus(String userId) async {
    try {
      final response = await _supabase.client
          .from('profiles')
          .select('is_online, last_seen')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return;

      final isOnline = response['is_online'] as bool? ?? false;
      final lastSeenStr = response['last_seen'] as String?;
      final lastSeen = lastSeenStr != null
          ? DateTime.tryParse(lastSeenStr)
          : null;

      // Update store
      ChatStore.instance.updatePresence(
        userId,
        online: isOnline,
        lastSeenAt: lastSeen,
      );
    } catch (e) {
      debugPrint('ChatService: Error fetching online status: $e');
    }
  }

  StreamSubscription<List<Map<String, dynamic>>> subscribeToPresence(
    String userId,
  ) {
    // Initial fetch
    fetchUserOnlineStatus(userId);

    // Realtime subscription to profiles table
    return _supabase.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final profile = data.first;
            final isOnline = profile['is_online'] as bool? ?? false;
            final lastSeenStr = profile['last_seen'] as String?;
            final lastSeen = lastSeenStr != null
                ? DateTime.tryParse(lastSeenStr)
                : null;

            ChatStore.instance.updatePresence(
              userId,
              online: isOnline,
              lastSeenAt: lastSeen,
            );
          }
        });
  }

  /// Karşı tarafın son görülme bilgisini görebilir miyim (gizlilik kontrolü ile)
  Future<bool> canSeeLastSeen(String otherUserId) async {
    try {
      // Önce kendi ayarımı kontrol et
      final myProfile = await _supabase.client
          .from('profiles')
          .select('privacy_last_seen')
          .eq('id', currentUserId!)
          .maybeSingle();

      // Kendi ayarım "nobody" ise başkalarınınkini göremem
      if (myProfile?['privacy_last_seen'] == 'nobody') {
        return false;
      }

      // Karşı tarafın gizlilik ayarını kontrol et
      final otherProfile = await _supabase.client
          .from('profiles')
          .select('privacy_last_seen')
          .eq('id', otherUserId)
          .maybeSingle();

      if (otherProfile == null) return true;

      final privacy = otherProfile['privacy_last_seen'] ?? 'everyone';

      switch (privacy) {
        case 'everyone':
          return true;
        case 'contacts':
          // Karşı taraf beni kişi olarak eklemiş mi?
          final isInContacts = await _supabase.client
              .from('contacts')
              .select('id')
              .eq('user_id', otherUserId)
              .eq('contact_id', currentUserId!)
              .eq('is_blocked', false)
              .maybeSingle();
          return isInContacts != null;
        case 'nobody':
          return false;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('ChatService: Error checking last seen visibility: $e');
      return true;
    }
  }

  /// Karşı tarafın profil fotoğrafını görebilir miyim
  Future<bool> canSeeProfilePhoto(String otherUserId) async {
    return _canSeePrivateInfo(otherUserId, 'privacy_profile_photo');
  }

  /// Karşı tarafın okundu bilgisini görebilir miyim (her iki tarafın ayarına bağlı)
  Future<bool> canSeeReadReceipts(String otherUserId) async {
    try {
      // Önce kendi ayarımı kontrol et
      final myProfile = await _supabase.client
          .from('profiles')
          .select('privacy_read_receipts')
          .eq('id', currentUserId!)
          .maybeSingle();

      // Kendi okundu bilgim kapalıysa karşıdakini göremem
      if (myProfile?['privacy_read_receipts'] == false) {
        return false;
      }

      // Karşı tarafın ayarını kontrol et
      final otherProfile = await _supabase.client
          .from('profiles')
          .select('privacy_read_receipts')
          .eq('id', otherUserId)
          .maybeSingle();

      // Karşı tarafın okundu bilgisi kapalıysa bana da gösterme
      return otherProfile?['privacy_read_receipts'] ?? true;
    } catch (e) {
      debugPrint('ChatService: Error checking read receipts: $e');
      return true;
    }
  }

  Future<bool> _canSeePrivateInfo(String userId, String privacyKey) async {
    try {
      final result = await _supabase.client
          .from('profiles')
          .select(privacyKey)
          .eq('id', userId)
          .maybeSingle();

      if (result == null) return true;

      final privacy = result[privacyKey] ?? 'everyone';

      switch (privacy) {
        case 'everyone':
          return true;
        case 'contacts':
          final isInContacts = await _supabase.client
              .from('contacts')
              .select('id')
              .eq('user_id', userId)
              .eq('contact_id', currentUserId!)
              .eq('is_blocked', false)
              .maybeSingle();
          return isInContacts != null;
        case 'nobody':
          return false;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('ChatService: Error checking $privacyKey visibility: $e');
      return true;
    }
  }

  /// Son mesaj zamanını formatla
  String formatLastMessageTime(Map<String, dynamic> chat) {
    final lastMessageAt = chat['last_message_at'];
    if (lastMessageAt == null) return '';

    final dateTime = DateTime.parse(lastMessageAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 2) {
      return 'Şimdi';
    } else if (now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(dateTime).inDays == 1 ||
        (now.day - dateTime.day == 1 && now.month == dateTime.month)) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  /// İki kullanıcı arasındaki ortak grupları getir
  Future<List<Map<String, dynamic>>> getCommonGroups(String otherUserId) async {
    if (currentUserId == null) return [];

    try {
      // Mevcut kullanıcının grup katılımları
      final myGroups = await _supabase.client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId!)
          .then((result) async {
            final chatIds = (result as List)
                .map((r) => r['chat_id'] as String)
                .toList();
            if (chatIds.isEmpty) return [];

            // Sadece grupları filtrele
            final groups = await _supabase.client
                .from('chats')
                .select('id, name, avatar_url')
                .inFilter('id', chatIds)
                .eq('is_group', true);
            return List<Map<String, dynamic>>.from(groups);
          });

      if (myGroups.isEmpty) return [];

      // Diğer kullanıcının da katıldığı grupları bul
      final otherUserParticipations = await _supabase.client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', otherUserId);

      final otherUserGroupIds = (otherUserParticipations as List)
          .map((r) => r['chat_id'] as String)
          .toSet();

      // Ortak grupları filtrele
      final commonGroups = myGroups
          .where((g) => otherUserGroupIds.contains(g['id']))
          .toList();

      // Her grup için üye sayısını al
      for (final group in commonGroups) {
        final memberCount = await _supabase.client
            .from('chat_participants')
            .select('id')
            .eq('chat_id', group['id']);
        group['member_count'] = (memberCount as List).length;
      }

      debugPrint('ChatService: Found ${commonGroups.length} common groups');
      return List<Map<String, dynamic>>.from(commonGroups);
    } catch (e) {
      debugPrint('ChatService: Error getting common groups: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESENCE (ONLINE STATUS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Online durumunu güncelle - UTC zamanını kullan
  Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    try {
      // last_seen sadece ONLINE olurken güncellenmeli
      // Offline olurken last_seen sabit kalmalı (en son ne zaman aktifti)
      final updateData = <String, dynamic>{'is_online': isOnline};

      // Sadece online olurken last_seen'i güncelle
      if (isOnline) {
        updateData['last_seen'] = DateTime.now().toUtc().toIso8601String();
      }

      await _supabase.client
          .from('profiles')
          .update(updateData)
          .eq('id', currentUserId!);

      debugPrint('ChatService: Online status set to $isOnline');
    } catch (e) {
      debugPrint('ChatService: Error setting online status: $e');
    }
  }

  /// Kullanıcının online durumunu al
  Future<bool> getUserOnlineStatus(String userId) async {
    try {
      final response = await _supabase.client
          .from('profiles')
          .select('is_online')
          .eq('id', userId)
          .single();

      return response['is_online'] ?? false;
    } catch (e) {
      debugPrint('ChatService: Error getting online status: $e');
      return false;
    }
  }

  /// Son görülme zamanını formatla
  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return ''; // Loading or unknown state

    final localLastSeen = lastSeen.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localLastSeen);

    if (diff.inMinutes < 3) {
      return 'şimdi aktif';
    }

    final hh = localLastSeen.hour.toString().padLeft(2, '0');
    final mm = localLastSeen.minute.toString().padLeft(2, '0');

    if (now.year == localLastSeen.year &&
        now.month == localLastSeen.month &&
        now.day == localLastSeen.day) {
      return 'bugün saat $hh:$mm';
    } else if (now.difference(localLastSeen).inDays == 1 ||
        (now.day - localLastSeen.day == 1 &&
            now.month == localLastSeen.month)) {
      return 'dün saat $hh:$mm';
    } else if (diff.inDays < 7) {
      final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return '${days[localLastSeen.weekday - 1]} saat $hh:$mm';
    } else {
      return '${localLastSeen.day}.${localLastSeen.month}.${localLastSeen.year}';
    }
  }

  /// Karşı tarafın son görülme zamanını al
  /// is_online true olsa bile last_seen 3 dakikadan eskiyse offline kabul et
  String getOtherUserLastSeen(Map<String, dynamic> chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser == null) return '';

    final isOnline = isOtherUserOnline(chat);
    if (isOnline) return 'çevrimiçi';

    final lastSeenStr = otherUser['last_seen'] as String?;
    if (lastSeenStr == null) return 'uzun süre önce';

    try {
      final lastSeen = DateTime.parse(lastSeenStr);
      return 'son görülme ${formatLastSeen(lastSeen)}';
    } catch (e) {
      return 'uzun süre önce';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. MESAJ ÖZELLİKLERİ (Reply, Delete, Edit, Forward)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mesaja yanıt ver
  Future<bool> replyToMessage({
    required String chatId,
    required String content,
    required String replyToMessageId,
    String type = 'text',
  }) async {
    return sendMessage(
      chatId: chatId,
      content: content,
      type: type,
      replyToId: replyToMessageId,
    );
  }

  /// Mesajı ilet (forward)
  Future<bool> forwardMessage({
    required String messageId,
    required List<String> targetChatIds,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Orijinal mesajı al
      final originalMessage = await _supabase.client
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();

      // Her hedef chate ilet
      for (final chatId in targetChatIds) {
        await _supabase.client.from('messages').insert({
          'chat_id': chatId,
          'sender_id': currentUserId,
          'content': originalMessage['content'],
          'type': originalMessage['type'],
          'media_url': originalMessage['media_url'],
          'metadata': {
            ...?(originalMessage['metadata'] as Map<String, dynamic>?),
            'forwarded_from': messageId,
          },
        });
      }

      debugPrint(
        'ChatService: Message forwarded to ${targetChatIds.length} chats',
      );
      return true;
    } catch (e) {
      debugPrint('ChatService: Error forwarding message: $e');
      return false;
    }
  }

  /// Reply edilen mesajı getir
  Future<Map<String, dynamic>?> getReplyToMessage(String messageId) async {
    try {
      final message = await _supabase.client
          .from('messages')
          .select('*, sender:profiles!sender_id(id, username, full_name)')
          .eq('id', messageId)
          .single();
      return message;
    } catch (e) {
      debugPrint('ChatService: Error getting reply message: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. MEDYA PAYLAŞIMI
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fotoğraf gönder
  Future<bool> sendPhoto({
    required String chatId,
    required Uint8List fileBytes,
    required String fileName,
    String? caption,
  }) async {
    if (currentUserId == null) return false;

    try {
      // Dosyayı Supabase Storage'a yükle
      final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath = 'chat_media/$chatId/$storageName';

      debugPrint('ChatService: Uploading photo to media/$storagePath');
      debugPrint('ChatService: File size: ${fileBytes.length} bytes');

      await _supabase.client.storage
          .from('media')
          .uploadBinary(storagePath, fileBytes);

      final publicUrl = _supabase.client.storage
          .from('media')
          .getPublicUrl(storagePath);

      debugPrint('ChatService: Photo uploaded, URL: $publicUrl');

      // Mesaj olarak gönder
      return sendMessage(
        chatId: chatId,
        content: caption ?? '',
        type: 'image',
        mediaUrl: publicUrl,
        metadata: {'file_name': fileName},
      );
    } catch (e) {
      debugPrint('ChatService: Error sending photo: $e');
      debugPrint('ChatService: Error details: ${e.toString()}');
      return false;
    }
  }

  /// Ses mesajı gönder
  Future<bool> sendVoiceMessage({
    required String chatId,
    required Uint8List audioBytes,
    required int durationSeconds,
  }) async {
    if (currentUserId == null) return false;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_voice.m4a';
      final storagePath = 'chat_media/$chatId/$fileName';

      await _supabase.client.storage
          .from('media')
          .uploadBinary(storagePath, audioBytes);

      final publicUrl = _supabase.client.storage
          .from('media')
          .getPublicUrl(storagePath);

      return sendMessage(
        chatId: chatId,
        content: '',
        type: 'voice',
        mediaUrl: publicUrl,
        metadata: {'duration': durationSeconds},
      );
    } catch (e) {
      debugPrint('ChatService: Error sending voice message: $e');
      return false;
    }
  }

  /// Dosya gönder
  Future<bool> sendFile({
    required String chatId,
    required Uint8List fileBytes,
    required String fileName,
    required int fileSize,
  }) async {
    if (currentUserId == null) return false;

    try {
      final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath = 'chat_media/$chatId/$storageName';

      await _supabase.client.storage
          .from('media')
          .uploadBinary(storagePath, fileBytes);

      final publicUrl = _supabase.client.storage
          .from('media')
          .getPublicUrl(storagePath);

      return sendMessage(
        chatId: chatId,
        content: fileName,
        type: 'file',
        mediaUrl: publicUrl,
        metadata: {'file_name': fileName, 'file_size': fileSize},
      );
    } catch (e) {
      debugPrint('ChatService: Error sending file: $e');
      return false;
    }
  }

  /// Video gönder (4.2)
  Future<bool> sendVideo({
    required String chatId,
    required Uint8List videoBytes,
    required String fileName,
    String? caption,
    int? durationMs,
    Uint8List? thumbnailBytes,
  }) async {
    if (currentUserId == null) return false;

    try {
      final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath = 'chat_media/$chatId/$storageName';

      // Video yükle
      await _supabase.client.storage
          .from('media')
          .uploadBinary(storagePath, videoBytes);

      final publicUrl = _supabase.client.storage
          .from('media')
          .getPublicUrl(storagePath);

      // Thumbnail varsa yükle
      String? thumbnailUrl;
      if (thumbnailBytes != null) {
        final thumbPath = 'chat_media/$chatId/thumb_$storageName.jpg';
        await _supabase.client.storage
            .from('media')
            .uploadBinary(thumbPath, thumbnailBytes);
        thumbnailUrl = _supabase.client.storage
            .from('media')
            .getPublicUrl(thumbPath);
      }

      return sendMessage(
        chatId: chatId,
        content: caption ?? '',
        type: 'video',
        mediaUrl: publicUrl,
        metadata: {
          'file_name': fileName,
          'duration_ms': durationMs,
          'thumbnail_url': thumbnailUrl,
          'file_size': videoBytes.length,
        },
      );
    } catch (e) {
      debugPrint('ChatService: Error sending video: $e');
      return false;
    }
  }

  /// GIF gönder
  Future<bool> sendGif({required String chatId, required String gifUrl}) async {
    return sendMessage(
      chatId: chatId,
      content: '',
      type: 'gif',
      mediaUrl: gifUrl,
    );
  }

  /// Konum gönder
  Future<bool> sendLocation({
    required String chatId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    return sendMessage(
      chatId: chatId,
      content: address ?? 'Konum',
      type: 'location',
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }

  /// Kişi kartı gönder
  Future<bool> sendContact({
    required String chatId,
    required String contactName,
    required String contactPhone,
    String? contactUserId,
  }) async {
    return sendMessage(
      chatId: chatId,
      content: contactName,
      type: 'contact',
      metadata: {
        'name': contactName,
        'phone': contactPhone,
        'user_id': contactUserId,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ARAMA FONKSİYONU
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sohbet içinde mesaj ara
  Future<List<Map<String, dynamic>>> searchMessagesInChat(
    String chatId,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = await _supabase.client
          .from('messages')
          .select('*, sender:profiles!sender_id(id, username, full_name)')
          .eq('chat_id', chatId)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(50);

      debugPrint(
        'ChatService: Found ${results.length} messages for "$query" in chat $chatId',
      );
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ChatService: Error searching messages: $e');
      return [];
    }
  }

  /// Sohbetteki medya mesajlarını getir (fotoğraf, video, dosya)
  Future<Map<String, List<Map<String, dynamic>>>> getChatMedia(
    String chatId,
  ) async {
    try {
      final results = await _supabase.client
          .from('messages')
          .select('*, sender:profiles!sender_id(id, username, full_name)')
          .eq('chat_id', chatId)
          .inFilter('type', ['image', 'video', 'file', 'voice'])
          .order('created_at', ascending: false);

      final messages = List<Map<String, dynamic>>.from(results);

      // Tipe göre grupla
      final photos = messages.where((m) => m['type'] == 'image').toList();
      final videos = messages.where((m) => m['type'] == 'video').toList();
      final files = messages.where((m) => m['type'] == 'file').toList();
      final voices = messages.where((m) => m['type'] == 'voice').toList();

      debugPrint(
        'ChatService: Found ${photos.length} photos, ${videos.length} videos, ${files.length} files',
      );

      return {
        'photos': photos,
        'videos': videos,
        'files': files,
        'voices': voices,
      };
    } catch (e) {
      debugPrint('ChatService: Error getting chat media: $e');
      return {'photos': [], 'videos': [], 'files': [], 'voices': []};
    }
  }

  /// Tüm sohbetlerde mesaj ara
  Future<List<Map<String, dynamic>>> searchAllMessages(String query) async {
    if (query.trim().isEmpty || currentUserId == null) return [];

    try {
      // Kullanıcının katıldığı chatlerdeki mesajları ara
      final participations = await _supabase.client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId!);

      final chatIds = participations.map((p) => p['chat_id']).toList();
      if (chatIds.isEmpty) return [];

      final results = await _supabase.client
          .from('messages')
          .select('''
            *,
            sender:profiles!sender_id(id, username, full_name),
            chat:chats!chat_id(id, name, is_group)
          ''')
          .inFilter('chat_id', chatIds)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(100);

      debugPrint(
        'ChatService: Found ${results.length} messages for "$query" globally',
      );
      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ChatService: Error searching all messages: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SOHBET YÖNETİMİ (Pin, Archive, Mute, Delete)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sohbeti sabitle/sabitlemesini kaldır
  Future<bool> togglePinChat(String chatId) async {
    if (currentUserId == null) return false;

    try {
      // Mevcut participant'ı kontrol et
      await _supabase.client
          .from('chat_participants')
          .select('id')
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!)
          .single();

      // metadata içinde pinned bilgisi tutulacak
      // Şimdilik local state kullanıyoruz
      _pinnedChats[chatId] = !(_pinnedChats[chatId] ?? false);
      notifyListeners();

      debugPrint('ChatService: Chat $chatId pinned: ${_pinnedChats[chatId]}');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error toggling pin: $e');
      return false;
    }
  }

  // Pin durumları (local)
  final Map<String, bool> _pinnedChats = {};
  final Map<String, bool> _archivedChats = {};

  bool isChatPinned(String chatId) => _pinnedChats[chatId] ?? false;
  bool isChatArchived(String chatId) => _archivedChats[chatId] ?? false;

  /// Sohbeti arşivle/arşivden çıkar
  Future<bool> toggleArchiveChat(String chatId) async {
    _archivedChats[chatId] = !(_archivedChats[chatId] ?? false);
    notifyListeners();
    debugPrint('ChatService: Chat $chatId archived: ${_archivedChats[chatId]}');
    return true;
  }

  /// Sohbeti sessize al/aç
  Future<bool> toggleMuteChat(String chatId) async {
    if (currentUserId == null) return false;

    try {
      // Mevcut mute durumunu al
      final participant = await _supabase.client
          .from('chat_participants')
          .select('is_muted')
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!)
          .single();

      final isMuted = participant['is_muted'] ?? false;

      // Güncelle
      await _supabase.client
          .from('chat_participants')
          .update({'is_muted': !isMuted})
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!);

      await loadChats();
      debugPrint('ChatService: Chat $chatId muted: ${!isMuted}');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error toggling mute: $e');
      return false;
    }
  }

  /// Sohbet sessize alınmış mı kontrol et
  bool isChatMuted(String chatId) {
    final chat = _chats.firstWhere((c) => c['id'] == chatId, orElse: () => {});

    final participants = chat['chat_participants'] as List?;
    if (participants == null) return false;

    for (final p in participants) {
      if (p['user_id'] == currentUserId) {
        return p['is_muted'] ?? false;
      }
    }
    return false;
  }

  /// Sohbeti sil (soft delete - sadece bu kullanıcı için)
  Future<bool> deleteChat(String chatId) async {
    if (currentUserId == null) return false;

    try {
      // Kullanıcıyı katılımcılardan çıkar
      await _supabase.client
          .from('chat_participants')
          .delete()
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!);

      await loadChats();
      debugPrint('ChatService: Left chat $chatId');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error leaving chat: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. OKUNDU BİLGİSİ (Read Receipts)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mesaj durumu bilgisini getir (delivered_at, read_at)
  Future<Map<String, dynamic>?> getMessageStatus(String messageId) async {
    try {
      final result = await _supabase.client
          .from('message_status')
          .select('delivered_at, read_at')
          .eq('message_id', messageId)
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('ChatService: Error getting message status: $e');
      return null;
    }
  }

  /// Mesajı iletildi olarak işaretle
  Future<void> markMessageAsDelivered(String messageId) async {
    if (currentUserId == null) return;

    try {
      await _supabase.client.from('message_status').upsert({
        'message_id': messageId,
        'user_id': currentUserId,
        'delivered_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
      debugPrint('ChatService: Message $messageId marked as delivered');
    } catch (e) {
      debugPrint('ChatService: Error marking message as delivered: $e');
    }
  }

  /// Mesajı okundu olarak işaretle
  Future<void> markMessageAsRead(String messageId) async {
    if (currentUserId == null) return;

    try {
      // Gizlilik kontrolü: read receipts kapalıysa read_at güncelleme (cache kullan)
      if (_readReceiptsEnabled == null) {
        final myProfile = await _supabase.client
            .from('profiles')
            .select('privacy_read_receipts')
            .eq('id', currentUserId!)
            .maybeSingle();
        _readReceiptsEnabled = myProfile?['privacy_read_receipts'] ?? true;
      }

      await _supabase.client.from('message_status').upsert({
        'message_id': messageId,
        'user_id': currentUserId,
        'read_at': _readReceiptsEnabled!
            ? DateTime.now().toIso8601String()
            : null,
        'delivered_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
      debugPrint(
        'ChatService: Message $messageId marked as ${_readReceiptsEnabled! ? "read" : "delivered only"}',
      );
    } catch (e) {
      debugPrint('ChatService: Error marking message as read: $e');
    }
  }

  /// Sohbetteki tüm mesajları okundu olarak işaretle
  Future<void> markChatAsRead(String chatId) async {
    if (currentUserId == null) return;

    try {
      final now = DateTime.now().toIso8601String();

      // Son okuma zamanını güncelle
      await _supabase.client
          .from('chat_participants')
          .update({'last_read_at': now})
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!);

      // Unread count'u sıfırla
      _unreadCounts[chatId] = 0;

      // Yüklü chat'lerdeki sayıyı da güncelle
      for (var i = 0; i < _chats.length; i++) {
        if (_chats[i]['id'] == chatId) {
          _chats[i] = {..._chats[i], 'unread_count': 0};
          break;
        }
      }

      notifyListeners();
      debugPrint('ChatService: Marked chat $chatId as read');

      // Arka planda mesaj durumlarını güncelle (performans için)
      _updateMessageStatusesInBackground(chatId, now);
    } catch (e) {
      debugPrint('ChatService: Error marking chat as read: $e');
    }
  }

  /// Mesaj durumlarını arka planda güncelle
  Future<void> _updateMessageStatusesInBackground(
    String chatId,
    String timestamp,
  ) async {
    try {
      // Gizlilik kontrolü: read receipts kapalıysa read_at güncelleme (cache kullan)
      if (_readReceiptsEnabled == null) {
        final myProfile = await _supabase.client
            .from('profiles')
            .select('privacy_read_receipts')
            .eq('id', currentUserId!)
            .maybeSingle();
        _readReceiptsEnabled = myProfile?['privacy_read_receipts'] ?? true;
      }

      // Tüm okunmamış mesajları güncelle (limit kaldırıldı)
      final messages = await _supabase.client
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId!)
          .order('created_at', ascending: false);

      // Batch işlem için Future.wait kullan
      final futures = <Future>[];
      for (final msg in messages) {
        final messageId = msg['id'] as String;
        futures.add(
          _supabase.client
              .from('message_status')
              .upsert({
                'message_id': messageId,
                'user_id': currentUserId,
                'delivered_at': timestamp,
                'read_at': _readReceiptsEnabled! ? timestamp : null,
              }, onConflict: 'message_id,user_id')
              .catchError((e) {
                // Hataları yut
                return null;
              }),
        );
      }

      await Future.wait(futures);
      debugPrint(
        'ChatService: Updated ${messages.length} message statuses (read receipts: $_readReceiptsEnabled)',
      );
    } catch (e) {
      debugPrint('ChatService: Error updating message statuses: $e');
    }
  }

  /// Mesajın okundu durumunu al
  Future<Map<String, dynamic>> getMessageReadStatus(String messageId) async {
    try {
      final statuses = await _supabase.client
          .from('message_status')
          .select('user_id, read_at, delivered_at')
          .eq('message_id', messageId);

      int deliveredCount = 0;
      int readCount = 0;

      for (final status in statuses) {
        if (status['delivered_at'] != null) deliveredCount++;
        if (status['read_at'] != null) readCount++;
      }

      return {
        'delivered': deliveredCount > 0,
        'read': readCount > 0,
        'delivered_count': deliveredCount,
        'read_count': readCount,
      };
    } catch (e) {
      debugPrint('ChatService: Error getting message status: $e');
      return {'delivered': false, 'read': false};
    }
  }

  /// Cache'den okunmamış mesaj sayısını al (hızlı)
  int getCachedUnreadCount(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }

  /// Unread count'u sıfırla (chat açıldığında)
  void clearUnreadCount(String chatId) {
    _unreadCounts[chatId] = 0;
    notifyListeners();
  }

  /// Okunmamış mesaj sayısını al (Supabase'den)
  Future<int> getUnreadCount(String chatId) async {
    if (currentUserId == null) return 0;

    try {
      // Kullanıcının son okuma zamanını al
      final participant = await _supabase.client
          .from('chat_participants')
          .select('last_read_at')
          .eq('chat_id', chatId)
          .eq('user_id', currentUserId!)
          .single();

      final lastReadAt = participant['last_read_at'];

      int count = 0;
      if (lastReadAt == null) {
        // Hiç okumamış, tüm mesajları say
        final result = await _supabase.client
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', currentUserId!);
        count = result.length;
      } else {
        // Son okumadan sonraki mesajları say
        final result = await _supabase.client
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', currentUserId!)
            .gt('created_at', lastReadAt);
        count = result.length;
      }

      // Cache'i güncelle
      _unreadCounts[chatId] = count;
      return count;
    } catch (e) {
      debugPrint('ChatService: Error getting unread count: $e');
      return _unreadCounts[chatId] ?? 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. YAZIYOR... GÖSTERGESİ (Typing Indicator)
  // ═══════════════════════════════════════════════════════════════════════════

  // Typing durumları
  final Map<String, Map<String, DateTime>> _typingUsers = {};

  /// Yazıyor durumunu gönder
  Future<void> sendTypingIndicator(String chatId) async {
    if (currentUserId == null) return;

    try {
      await _supabase.client
          .channel('typing_$chatId')
          .sendBroadcastMessage(
            event: 'typing',
            payload: {
              'user_id': currentUserId,
              'chat_id': chatId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
    } catch (e) {
      debugPrint('ChatService: Error sending typing indicator: $e');
    }
  }

  /// Yazıyor durumunu dinle
  RealtimeChannel subscribeToTyping(
    String chatId,
    Function(String userId) onTyping,
  ) {
    final channel = _supabase.client
        .channel('typing_$chatId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final userId = payload['user_id'] as String?;
            if (userId != null && userId != currentUserId) {
              _typingUsers[chatId] ??= {};
              _typingUsers[chatId]![userId] = DateTime.now();
              onTyping(userId);
              notifyListeners();

              // 3 saniye sonra typing durumunu kaldır
              Future.delayed(const Duration(seconds: 3), () {
                _typingUsers[chatId]?.remove(userId);
                notifyListeners();
              });
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Sohbette yazıyor olan kullanıcıları al
  List<String> getTypingUsers(String chatId) {
    final typing = _typingUsers[chatId];
    if (typing == null) return [];

    final now = DateTime.now();
    // 3 saniyeden eski olanları filtrele
    typing.removeWhere((_, time) => now.difference(time).inSeconds > 3);

    return typing.keys.toList();
  }

  /// Yazıyor... metni oluştur
  String getTypingText(String chatId) {
    final typingUserIds = getTypingUsers(chatId);
    if (typingUserIds.isEmpty) return '';

    if (typingUserIds.length == 1) {
      return 'yazıyor...';
    } else if (typingUserIds.length == 2) {
      return '2 kişi yazıyor...';
    } else {
      return '${typingUserIds.length} kişi yazıyor...';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. @MENTION SİSTEMİ (3.6)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Metindeki @mention'ları parse et
  /// Returns: List of {userId, username, startIndex, endIndex}
  static List<Map<String, dynamic>> parseMentions(
    String text,
    List<Map<String, dynamic>> chatMembers,
  ) {
    final mentions = <Map<String, dynamic>>[];
    final mentionPattern = RegExp(r'@(\w+)');

    for (final match in mentionPattern.allMatches(text)) {
      final username = match.group(1)?.toLowerCase() ?? '';

      // Chat üyeleri arasında bu username'i bul
      for (final member in chatMembers) {
        final profile = member['profiles'] as Map<String, dynamic>?;
        final memberUsername = (profile?['username'] ?? '')
            .toString()
            .toLowerCase();

        if (memberUsername == username) {
          mentions.add({
            'user_id': profile?['id'] ?? member['user_id'],
            'username': profile?['username'] ?? memberUsername,
            'start_index': match.start,
            'end_index': match.end,
          });
          break;
        }
      }
    }

    return mentions;
  }

  /// Mesaj gönderirken mention metadata'sı oluştur
  static Map<String, dynamic>? createMentionMetadata(
    String text,
    List<Map<String, dynamic>> chatMembers,
  ) {
    final mentions = parseMentions(text, chatMembers);
    if (mentions.isEmpty) return null;

    return {
      'mentions': mentions
          .map((m) => {'user_id': m['user_id'], 'username': m['username']})
          .toList(),
    };
  }

  /// Mention ile mesaj gönder
  Future<bool> sendMessageWithMentions({
    required String chatId,
    required String content,
    List<Map<String, dynamic>>? mentions,
    String? replyToId,
  }) async {
    Map<String, dynamic>? metadata;
    if (mentions != null && mentions.isNotEmpty) {
      metadata = {
        'mentions': mentions
            .map((m) => {'user_id': m['user_id'], 'username': m['username']})
            .toList(),
      };
    }

    return sendMessage(
      chatId: chatId,
      content: content,
      replyToId: replyToId,
      metadata: metadata,
    );
  }

  /// Mention ve efekt ile mesaj gönder (Premium)
  Future<bool> sendMessageWithMentionsAndEffect({
    required String chatId,
    required String content,
    List<Map<String, dynamic>>? mentions,
    String? replyToId,
    String? effect,
  }) async {
    Map<String, dynamic>? metadata;

    // Metadata oluştur
    if ((mentions != null && mentions.isNotEmpty) || effect != null) {
      metadata = {};

      if (mentions != null && mentions.isNotEmpty) {
        metadata['mentions'] = mentions
            .map((m) => {'user_id': m['user_id'], 'username': m['username']})
            .toList();
      }

      if (effect != null) {
        metadata['effect'] = effect;
      }
    }

    return sendMessage(
      chatId: chatId,
      content: content,
      replyToId: replyToId,
      metadata: metadata,
    );
  }

  /// Gruptaki kullanıcıları @ araması için getir
  Future<List<Map<String, dynamic>>> searchMentionableUsers(
    String chatId,
    String query,
  ) async {
    try {
      final members = await getGroupMembers(chatId);

      if (query.isEmpty) {
        return members;
      }

      final lowerQuery = query.toLowerCase();
      return members.where((member) {
        final profile = member['profiles'] as Map<String, dynamic>?;
        final username = (profile?['username'] ?? '').toString().toLowerCase();
        final fullName = (profile?['full_name'] ?? '').toString().toLowerCase();

        return username.contains(lowerQuery) || fullName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('ChatService: Error searching mentionable users: $e');
      return [];
    }
  }

  /// Kullanıcının mention edildiği mesajları getir
  Future<List<Map<String, dynamic>>> getMentionedMessages(String chatId) async {
    if (currentUserId == null) return [];

    try {
      final messages = await _supabase.client
          .from('messages')
          .select(
            '*, sender:profiles!sender_id(id, username, full_name, avatar_url)',
          )
          .eq('chat_id', chatId)
          .contains('metadata->mentions', [
            {'user_id': currentUserId},
          ])
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      debugPrint('ChatService: Error getting mentioned messages: $e');
      return [];
    }
  }
}
