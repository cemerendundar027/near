import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Contact Service - Kişi yönetimi için Supabase entegrasyonu
/// 
/// Özellikler:
/// - Kişi ekleme/çıkarma
/// - Kişi engelleme/engel kaldırma
/// - Son görülme gizlilik ayarları
class ContactService extends ChangeNotifier {
  ContactService._();
  static final instance = ContactService._();

  final _supabase = SupabaseService.instance;
  
  // Cached data
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _blockedUsers = [];
  Map<String, dynamic>? _privacySettings;
  
  // Loading states
  bool _isLoading = false;
  
  // Getters
  List<Map<String, dynamic>> get contacts => _contacts;
  List<Map<String, dynamic>> get blockedUsers => _blockedUsers;
  Map<String, dynamic>? get privacySettings => _privacySettings;
  bool get isLoading => _isLoading;
  
  String? get currentUserId => _supabase.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Servisi başlat
  Future<void> init() async {
    if (currentUserId == null) {
      debugPrint('ContactService: User not logged in');
      return;
    }
    
    await Future.wait([
      loadContacts(),
      loadBlockedUsers(),
      loadPrivacySettings(),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2.4 - KİŞİ EKLEME (CONTACT MANAGEMENT)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm kişileri yükle
  Future<void> loadContacts() async {
    if (currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _supabase.client
          .from('contacts')
          .select('''
            *,
            contact:profiles!contact_id(
              id, username, full_name, avatar_url, bio, is_online, last_seen
            )
          ''')
          .eq('user_id', currentUserId!)
          .eq('is_blocked', false)
          .order('created_at', ascending: false);

      _contacts = List<Map<String, dynamic>>.from(result);
      debugPrint('ContactService: Loaded ${_contacts.length} contacts');
    } catch (e) {
      debugPrint('ContactService: Error loading contacts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Kişi ekle
  Future<bool> addContact(String contactUserId, {String? nickname}) async {
    if (currentUserId == null) return false;
    if (currentUserId == contactUserId) return false; // Kendini ekleyemez

    try {
      // Önce mevcut kişi var mı kontrol et
      final existing = await _supabase.client
          .from('contacts')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('contact_id', contactUserId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('ContactService: Contact already exists');
        return false;
      }

      await _supabase.client.from('contacts').insert({
        'user_id': currentUserId,
        'contact_id': contactUserId,
        'nickname': nickname,
        'is_blocked': false,
      });

      await loadContacts();
      debugPrint('ContactService: Contact added: $contactUserId');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error adding contact: $e');
      return false;
    }
  }

  /// Kişiyi sil
  Future<bool> removeContact(String contactUserId) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('contacts')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('contact_id', contactUserId);

      await loadContacts();
      debugPrint('ContactService: Contact removed: $contactUserId');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error removing contact: $e');
      return false;
    }
  }

  /// Kişi takma adını güncelle
  Future<bool> updateContactNickname(String contactUserId, String? nickname) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('contacts')
          .update({'nickname': nickname})
          .eq('user_id', currentUserId!)
          .eq('contact_id', contactUserId);

      await loadContacts();
      debugPrint('ContactService: Contact nickname updated');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error updating nickname: $e');
      return false;
    }
  }

  /// Kişi mi kontrol et
  bool isContact(String userId) {
    return _contacts.any((c) => c['contact_id'] == userId);
  }

  /// Kişi bilgisini getir
  Map<String, dynamic>? getContact(String userId) {
    try {
      return _contacts.firstWhere((c) => c['contact_id'] == userId);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2.5 - KİŞİ ENGELLEME (BLOCKING)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Engellenen kullanıcıları yükle
  Future<void> loadBlockedUsers() async {
    if (currentUserId == null) return;

    try {
      final result = await _supabase.client
          .from('contacts')
          .select('''
            *,
            contact:profiles!contact_id(
              id, username, full_name, avatar_url
            )
          ''')
          .eq('user_id', currentUserId!)
          .eq('is_blocked', true)
          .order('created_at', ascending: false);

      _blockedUsers = List<Map<String, dynamic>>.from(result);
      debugPrint('ContactService: Loaded ${_blockedUsers.length} blocked users');
    } catch (e) {
      debugPrint('ContactService: Error loading blocked users: $e');
    }

    notifyListeners();
  }

  /// Kullanıcıyı engelle
  Future<bool> blockUser(String userId) async {
    if (currentUserId == null) return false;
    if (currentUserId == userId) return false; // Kendini engelleyemez

    try {
      // Önce mevcut contact kaydı var mı kontrol et
      final existing = await _supabase.client
          .from('contacts')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('contact_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Mevcut kaydı güncelle
        await _supabase.client
            .from('contacts')
            .update({'is_blocked': true})
            .eq('user_id', currentUserId!)
            .eq('contact_id', userId);
      } else {
        // Yeni kayıt oluştur
        await _supabase.client.from('contacts').insert({
          'user_id': currentUserId,
          'contact_id': userId,
          'is_blocked': true,
        });
      }

      await Future.wait([
        loadContacts(),
        loadBlockedUsers(),
      ]);
      
      debugPrint('ContactService: User blocked: $userId');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error blocking user: $e');
      return false;
    }
  }

  /// Engeli kaldır
  Future<bool> unblockUser(String userId) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('contacts')
          .update({'is_blocked': false})
          .eq('user_id', currentUserId!)
          .eq('contact_id', userId);

      await Future.wait([
        loadContacts(),
        loadBlockedUsers(),
      ]);
      
      debugPrint('ContactService: User unblocked: $userId');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error unblocking user: $e');
      return false;
    }
  }

  /// Kullanıcı engellenmiş mi kontrol et
  bool isBlocked(String userId) {
    return _blockedUsers.any((b) => b['contact_id'] == userId);
  }

  /// Beni engellemiş mi kontrol et (karşı taraf)
  Future<bool> isBlockedByUser(String userId) async {
    if (currentUserId == null) return false;

    try {
      final result = await _supabase.client
          .from('contacts')
          .select('id')
          .eq('user_id', userId)
          .eq('contact_id', currentUserId!)
          .eq('is_blocked', true)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('ContactService: Error checking if blocked by user: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2.6 - SON GÖRÜLME AYARLARI (PRIVACY SETTINGS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gizlilik ayarlarını yükle
  Future<void> loadPrivacySettings() async {
    if (currentUserId == null) return;

    try {
      final result = await _supabase.client
          .from('profiles')
          .select('privacy_last_seen, privacy_profile_photo, privacy_about, privacy_read_receipts')
          .eq('id', currentUserId!)
          .maybeSingle();

      _privacySettings = result ?? {
        'privacy_last_seen': 'everyone',
        'privacy_profile_photo': 'everyone',
        'privacy_about': 'everyone',
        'privacy_read_receipts': true,
      };
      
      debugPrint('ContactService: Privacy settings loaded');
    } catch (e) {
      debugPrint('ContactService: Error loading privacy settings: $e');
      // Default değerler
      _privacySettings = {
        'privacy_last_seen': 'everyone',
        'privacy_profile_photo': 'everyone',
        'privacy_about': 'everyone',
        'privacy_messages': 'everyone',
        'privacy_read_receipts': true,
      };
    }

    notifyListeners();
  }

  /// Son görülme ayarını güncelle
  /// [value]: 'everyone', 'contacts', 'nobody'
  Future<bool> updateLastSeenPrivacy(String value) async {
    return _updatePrivacySetting('privacy_last_seen', value);
  }

  /// Profil fotoğrafı gizlilik ayarını güncelle
  /// [value]: 'everyone', 'contacts', 'nobody'
  Future<bool> updateProfilePhotoPrivacy(String value) async {
    return _updatePrivacySetting('privacy_profile_photo', value);
  }

  /// Hakkında gizlilik ayarını güncelle
  /// [value]: 'everyone', 'contacts', 'nobody'
  Future<bool> updateAboutPrivacy(String value) async {
    return _updatePrivacySetting('privacy_about', value);
  }

  /// Mesaj gizlilik ayarını güncelle
  /// [value]: 'everyone' (herkes mesaj atabilir), 'contacts' (sadece rehberdekiler)
  Future<bool> updateMessagePrivacy(String value) async {
    return _updatePrivacySetting('privacy_messages', value);
  }

  /// Okundu bilgisi ayarını güncelle
  Future<bool> updateReadReceiptsPrivacy(bool enabled) async {
    return _updatePrivacySetting('privacy_read_receipts', enabled);
  }

  /// Genel privacy ayarı güncelleme metodu
  Future<bool> _updatePrivacySetting(String key, dynamic value) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.client
          .from('profiles')
          .update({
            key: value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUserId!);

      _privacySettings?[key] = value;
      notifyListeners();
      
      debugPrint('ContactService: Privacy setting updated: $key = $value');
      return true;
    } catch (e) {
      debugPrint('ContactService: Error updating privacy setting: $e');
      return false;
    }
  }

  /// Kullanıcının son görülme bilgisini görebilir miyim?
  Future<bool> canSeeLastSeen(String userId) async {
    if (currentUserId == null) return false;
    
    try {
      // Kendi son görülme ayarım "nobody" ise başkalarınınkini de göremem
      if (_privacySettings?['privacy_last_seen'] == 'nobody') {
        return false;
      }

      // Karşı tarafın ayarlarını kontrol et
      final result = await _supabase.client
          .from('profiles')
          .select('privacy_last_seen')
          .eq('id', userId)
          .maybeSingle();

      if (result == null) return true; // Default: görünür

      final privacy = result['privacy_last_seen'] ?? 'everyone';

      switch (privacy) {
        case 'everyone':
          return true;
        case 'contacts':
          // Karşı taraf beni kişi olarak eklemiş mi?
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
      debugPrint('ContactService: Error checking last seen visibility: $e');
      return true;
    }
  }

  /// Kullanıcının profil fotoğrafını görebilir miyim?
  Future<bool> canSeeProfilePhoto(String userId) async {
    return _canSeePrivateInfo(userId, 'privacy_profile_photo');
  }

  /// Kullanıcının hakkında bilgisini görebilir miyim?
  Future<bool> canSeeAbout(String userId) async {
    return _canSeePrivateInfo(userId, 'privacy_about');
  }

  Future<bool> _canSeePrivateInfo(String userId, String privacyKey) async {
    if (currentUserId == null) return false;
    
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
      debugPrint('ContactService: Error checking $privacyKey visibility: $e');
      return true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Kullanıcı arama (kişi ekleme için)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    if (currentUserId == null) return [];

    try {
      final results = await _supabase.client
          .from('profiles')
          .select('id, username, full_name, avatar_url, bio, is_online, last_seen')
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .neq('id', currentUserId!)
          .limit(20);

      return List<Map<String, dynamic>>.from(results);
    } catch (e) {
      debugPrint('ContactService: Error searching users: $e');
      return [];
    }
  }

  /// Privacy değerini Türkçe'ye çevir
  String getPrivacyLabel(String value) {
    switch (value) {
      case 'everyone':
        return 'Herkes';
      case 'contacts':
        return 'Kişilerim';
      case 'nobody':
        return 'Hiç kimse';
      default:
        return value;
    }
  }

  /// Türkçe değeri privacy değerine çevir
  String getPrivacyValue(String label) {
    switch (label) {
      case 'Herkes':
      case 'Everyone':
        return 'everyone';
      case 'Kişilerim':
      case 'My Contacts':
        return 'contacts';
      case 'Hiç kimse':
      case 'Nobody':
        return 'nobody';
      default:
        return 'everyone';
    }
  }
}

