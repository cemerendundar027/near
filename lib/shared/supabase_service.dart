import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase servis sınıfı - Tüm backend işlemleri için merkezi nokta
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Supabase client'a kolay erişim
  SupabaseClient get client => Supabase.instance.client;

  /// Auth servisine kolay erişim
  GoTrueClient get auth => client.auth;

  /// Mevcut kullanıcı
  User? get currentUser => auth.currentUser;

  /// Kullanıcı oturum açmış mı?
  bool get isAuthenticated => currentUser != null;

  /// Mevcut session
  Session? get currentSession => auth.currentSession;

  /// Supabase'i başlat
  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Email/Password ile kayıt ol
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    return await auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'full_name': fullName,
      },
    );
  }

  /// Email/Password ile giriş yap
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Telefon numarası ile OTP gönder
  Future<void> signInWithPhone(String phone) async {
    await auth.signInWithOtp(phone: phone);
  }

  /// OTP doğrula
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return await auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Google ile giriş
  Future<void> signInWithGoogle() async {
    await auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.near://login-callback/',
    );
  }

  /// Apple ile giriş
  Future<void> signInWithApple() async {
    await auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.near://login-callback/',
    );
  }

  /// Şifre sıfırlama maili gönder
  Future<void> resetPassword(String email) async {
    await auth.resetPasswordForEmail(email);
  }

  /// Çıkış yap
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Auth state değişikliklerini dinle
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tablo sorgusu
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Profil oluştur/güncelle
  Future<void> upsertProfile({
    required String id,
    required String username,
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    await from('profiles').upsert({
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Profil getir
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Kullanıcı ara
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESAJLAŞMA İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sohbetleri getir
  Future<List<Map<String, dynamic>>> getChats() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await from('chat_participants')
        .select('''
          chat_id,
          chats (
            id,
            name,
            is_group,
            created_at,
            last_message,
            last_message_at
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mesajları getir
  Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await from('messages')
        .select('''
          *,
          sender:profiles!sender_id (
            id,
            username,
            avatar_url
          )
        ''')
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Mesaj gönder
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await from('messages').insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // Son mesajı güncelle
    await from('chats').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);

    return response;
  }

  /// Yeni mesajları dinle (Realtime)
  RealtimeChannel subscribeToMessages(
    String chatId,
    void Function(Map<String, dynamic> payload) onMessage,
  ) {
    return client
        .channel('messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) => onMessage(payload.newRecord),
        )
        .subscribe();
  }

  /// Kullanıcı durumunu dinle (online/offline)
  RealtimeChannel subscribeToPresence(
    void Function(List<Map<String, dynamic>> users) onPresenceChange,
  ) {
    return client
        .channel('presence')
        .onPresenceSync((payload) {
          final presenceState = client.channel('presence').presenceState();
          final users = presenceState
              .map((state) => state.presences.first)
              .toList();
          onPresenceChange(List<Map<String, dynamic>>.from(users));
        })
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Online durumunu bildir
            client.channel('presence').track({
              'user_id': currentUser?.id,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORAGE İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Dosya yükle (upsert - varsa güncelle)
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    bool upsert = true,
  }) async {
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: upsert,
        ),
      );
      
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('SupabaseService: File uploaded to $bucket/$path');
      return publicUrl;
    } catch (e) {
      debugPrint('SupabaseService: Upload error: $e');
      rethrow;
    }
  }

  /// Profil fotoğrafı yükle
  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    // Dosya adına timestamp ekle (cache busting için)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$timestamp.jpg';
    
    return uploadFile(
      bucket: 'avatars',
      path: path,
      bytes: bytes,
      contentType: 'image/jpeg',
      upsert: true,
    );
  }

  /// Eski avatarı sil
  Future<void> deleteOldAvatars(String userId) async {
    try {
      final files = await client.storage.from('avatars').list(path: userId);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await client.storage.from('avatars').remove(paths);
        debugPrint('SupabaseService: Deleted ${paths.length} old avatars');
      }
    } catch (e) {
      debugPrint('SupabaseService: Delete old avatars error: $e');
    }
  }

  /// Mesaj medyası yükle
  Future<String> uploadMessageMedia({
    required String chatId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return uploadFile(
      bucket: 'media',
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Sesli mesaj yükle
  Future<String> uploadVoiceMessage({
    required String chatId,
    required Uint8List bytes,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    return uploadMessageMedia(
      chatId: chatId,
      fileName: fileName,
      bytes: bytes,
      contentType: 'audio/m4a',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USERNAME İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Username'in kullanılabilirliğini kontrol et
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      var query = client.from('profiles').select('id').eq('username', username.toLowerCase());
      
      if (excludeUserId != null) {
        query = query.neq('id', excludeUserId);
      }
      
      final result = await query.maybeSingle();
      return result == null;
    } catch (e) {
      debugPrint('SupabaseService: Username check error: $e');
      return false;
    }
  }

  /// Username validasyonu
  static bool isValidUsername(String username) {
    // 3-20 karakter, sadece harf, rakam ve alt çizgi
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return regex.hasMatch(username);
  }

  /// Username önerileri getir
  Future<List<String>> suggestUsernames(String baseName) async {
    final suggestions = <String>[];
    final cleanBase = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    
    for (var i = 0; i < 5; i++) {
      final suggestion = i == 0 ? cleanBase : '${cleanBase}${100 + i}';
      if (await isUsernameAvailable(suggestion)) {
        suggestions.add(suggestion);
      }
    }
    
    return suggestions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // YARDIMCI METODLAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Channel'ı kapat
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  /// Tüm channel'ları kapat
  Future<void> unsubscribeAll() async {
    await client.removeAllChannels();
  }
}
