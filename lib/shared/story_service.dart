import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'chat_service.dart';

/// Story Model
class Story {
  final String id;
  final String userId;
  final String? mediaUrl;
  final String type; // 'image', 'video', or 'text'
  final String? caption;
  final int duration;
  final int viewsCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? metadata; // For text stories: backgroundColor, gradient, fontSize, etc.

  Story({
    required this.id,
    required this.userId,
    this.mediaUrl,
    required this.type,
    this.caption,
    this.duration = 5,
    this.viewsCount = 0,
    required this.expiresAt,
    required this.createdAt,
    this.userData,
    this.metadata,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mediaUrl: json['media_url'] as String?,
      type: json['type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      duration: json['duration'] as int? ?? 5,
      viewsCount: json['views_count'] as int? ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      userData: json['user'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  String get userName => userData?['full_name'] ?? userData?['username'] ?? 'Unknown';
  String? get userAvatar => userData?['avatar_url'];
}

/// Story Viewer Model
class StoryViewer {
  final String id;
  final String viewerId;
  final DateTime viewedAt;
  final Map<String, dynamic>? viewerData;

  StoryViewer({
    required this.id,
    required this.viewerId,
    required this.viewedAt,
    this.viewerData,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      id: json['id'] as String,
      viewerId: json['viewer_id'] as String,
      viewedAt: DateTime.parse(json['viewed_at'] as String),
      viewerData: json['viewer'] as Map<String, dynamic>?,
    );
  }

  String get viewerName => viewerData?['full_name'] ?? viewerData?['username'] ?? 'Unknown';
  String? get viewerAvatar => viewerData?['avatar_url'];
}

/// User Stories Group - bir kullanıcının tüm story'leri
class UserStories {
  final String userId;
  final String userName;
  final String? userAvatar;
  final List<Story> stories;
  final bool hasUnviewed;

  UserStories({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.stories,
    required this.hasUnviewed,
  });
}

/// Story Service - Supabase entegrasyonu
class StoryService extends ChangeNotifier {
  StoryService._();
  static final instance = StoryService._();

  final _supabase = SupabaseService.instance;
  
  // Cached data
  List<UserStories> _userStories = [];
  List<Story> _myStories = [];
  Map<String, List<StoryViewer>> _storyViewers = {};
  Set<String> _viewedStoryIds = {};
  
  bool _isLoading = false;
  
  // Getters
  List<UserStories> get userStories => _userStories;
  List<Story> get myStories => _myStories;
  bool get isLoading => _isLoading;
  
  String? get currentUserId => _supabase.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY OLUŞTURMA (5.1)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fotoğraf story oluştur
  Future<Story?> createImageStory({
    required File imageFile,
    String? caption,
  }) async {
    if (currentUserId == null) return null;

    try {
      // 1. Dosyayı Supabase Storage'a yükle
      final fileName = 'story_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.client.storage
          .from('stories')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(
            contentType: 'image/jpeg',
          ));

      // 2. Public URL al
      final mediaUrl = _supabase.client.storage
          .from('stories')
          .getPublicUrl(fileName);

      // 3. Story kaydını oluştur
      final response = await _supabase.client.from('stories').insert({
        'user_id': currentUserId,
        'media_url': mediaUrl,
        'type': 'image',
        'caption': caption,
        'duration': 5,
      }).select('*, user:profiles!user_id(id, username, full_name, avatar_url)').single();

      debugPrint('StoryService: Image story created');
      
      final story = Story.fromJson(response);
      _myStories.insert(0, story);
      notifyListeners();
      
      return story;
    } catch (e) {
      debugPrint('StoryService: Error creating image story: $e');
      return null;
    }
  }

  /// Metin story oluştur
  Future<Story?> createTextStory({
    required String text,
    required Map<String, dynamic> metadata, // backgroundColor, gradient, fontSize, textAlign, isBold
  }) async {
    if (currentUserId == null) {
      debugPrint('StoryService: createTextStory - User not logged in');
      return null;
    }

    try {
      debugPrint('StoryService: Creating text story for user: $currentUserId');
      debugPrint('StoryService: Text: $text');
      debugPrint('StoryService: Metadata: $metadata');
      
      // Önce metadata ile dene
      try {
        final response = await _supabase.client.from('stories').insert({
          'user_id': currentUserId,
          'type': 'text',
          'media_url': '', // Text story'lerde media_url boş olmalı
          'caption': text,
          'duration': 5,
          'metadata': metadata,
        }).select('*, user:profiles!user_id(id, username, full_name, avatar_url)').single();

        debugPrint('StoryService: Text story created successfully: ${response['id']}');
        
        final story = Story.fromJson(response);
        _myStories.insert(0, story);
        notifyListeners();
        
        return story;
      } catch (e) {
        // Metadata kolonu yoksa, metadata olmadan dene
        debugPrint('StoryService: Metadata column not found, trying without metadata: $e');
        
        final response = await _supabase.client.from('stories').insert({
          'user_id': currentUserId,
          'type': 'text',
          'media_url': '', // Text story'lerde media_url boş olmalı
          'caption': text,
          'duration': 5,
        }).select('*, user:profiles!user_id(id, username, full_name, avatar_url)').single();

        debugPrint('StoryService: Text story created successfully (without metadata): ${response['id']}');
        
        final story = Story.fromJson(response);
        _myStories.insert(0, story);
        notifyListeners();
        
        return story;
      }
    } catch (e) {
      debugPrint('StoryService: Error creating text story: $e');
      debugPrint('StoryService: Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Video story oluştur (max 60 saniye)
  Future<Story?> createVideoStory({
    required File videoFile,
    String? caption,
    Duration? trimStart,
    Duration? trimEnd,
  }) async {
    if (currentUserId == null) return null;

    try {
      // 1. Dosyayı Supabase Storage'a yükle
      final fileName = 'story_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final bytes = await videoFile.readAsBytes();
      
      await _supabase.client.storage
          .from('stories')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(
            contentType: 'video/mp4',
          ));

      // 2. Public URL al
      final mediaUrl = _supabase.client.storage
          .from('stories')
          .getPublicUrl(fileName);

      // 3. Video süresini hesapla
      int duration = 60; // varsayılan
      if (trimStart != null && trimEnd != null) {
        duration = (trimEnd - trimStart).inSeconds.clamp(1, 60);
      }

      // 4. Story kaydını oluştur
      final response = await _supabase.client.from('stories').insert({
        'user_id': currentUserId,
        'media_url': mediaUrl,
        'type': 'video',
        'caption': caption,
        'duration': duration,
        'metadata': {
          'trimStart': trimStart?.inMilliseconds,
          'trimEnd': trimEnd?.inMilliseconds,
        },
      }).select('*, user:profiles!user_id(id, username, full_name, avatar_url)').single();

      debugPrint('StoryService: Video story created, duration: $duration seconds');
      
      final story = Story.fromJson(response);
      _myStories.insert(0, story);
      notifyListeners();
      
      return story;
    } catch (e) {
      debugPrint('StoryService: Error creating video story: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY GÖRÜNTÜLEME (5.2)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm story'leri yükle (kişilerin ve kendi story'lerim)
  Future<void> loadStories() async {
    if (currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Aktif (süresi dolmamış) story'leri yükle
      final now = DateTime.now().toIso8601String();
      
      final stories = await _supabase.client
          .from('stories')
          .select('*, user:profiles!user_id(id, username, full_name, avatar_url)')
          .gt('expires_at', now)
          .order('created_at', ascending: false);

      // 2. Görüntülediğim story'leri yükle
      final viewedStories = await _supabase.client
          .from('story_views')
          .select('story_id')
          .eq('viewer_id', currentUserId!);
      
      _viewedStoryIds = Set<String>.from(
        (viewedStories as List).map((v) => v['story_id'] as String)
      );

      // 3. Story'leri kullanıcılara göre grupla
      final Map<String, List<Story>> storiesByUser = {};
      final Map<String, Map<String, dynamic>> userDataMap = {};
      
      for (final storyJson in stories) {
        final story = Story.fromJson(storyJson);
        storiesByUser.putIfAbsent(story.userId, () => []);
        storiesByUser[story.userId]!.add(story);
        userDataMap[story.userId] = storyJson['user'] as Map<String, dynamic>;
      }

      // 4. Kendi story'lerimi ayır
      _myStories = storiesByUser[currentUserId] ?? [];
      storiesByUser.remove(currentUserId);

      // 5. UserStories listesi oluştur
      _userStories = storiesByUser.entries.map((entry) {
        final userData = userDataMap[entry.key]!;
        final hasUnviewed = entry.value.any((s) => !_viewedStoryIds.contains(s.id));
        
        return UserStories(
          userId: entry.key,
          userName: userData['full_name'] ?? userData['username'] ?? 'Unknown',
          userAvatar: userData['avatar_url'],
          stories: entry.value,
          hasUnviewed: hasUnviewed,
        );
      }).toList();

      // 6. Görüntülenmemişler önce, sonra son story zamanına göre sırala
      _userStories.sort((a, b) {
        if (a.hasUnviewed && !b.hasUnviewed) return -1;
        if (!a.hasUnviewed && b.hasUnviewed) return 1;
        return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
      });

      debugPrint('StoryService: Loaded ${_userStories.length} users with stories, ${_myStories.length} my stories');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('StoryService: Error loading stories: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Belirli bir story'yi görüntülenmiş olarak işaretle
  Future<void> markStoryAsViewed(String storyId) async {
    if (currentUserId == null) return;
    if (_viewedStoryIds.contains(storyId)) return;

    try {
      await _supabase.client.from('story_views').upsert({
        'story_id': storyId,
        'viewer_id': currentUserId,
      }, onConflict: 'story_id,viewer_id');

      _viewedStoryIds.add(storyId);
      
      // views_count güncelle
      await _supabase.client.rpc('increment_story_views', params: {
        'story_id': storyId,
      }).catchError((_) {
        // RPC yoksa manuel güncelle
        return _supabase.client
            .from('stories')
            .update({'views_count': 1}) // Bu basit bir increment değil ama şimdilik yeterli
            .eq('id', storyId);
      });

      debugPrint('StoryService: Story $storyId marked as viewed');
      notifyListeners();
    } catch (e) {
      debugPrint('StoryService: Error marking story as viewed: $e');
    }
  }

  /// Story görüntülenmiş mi kontrol et
  bool isStoryViewed(String storyId) {
    return _viewedStoryIds.contains(storyId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY GÖRÜNTÜLEYENLERİ (5.3)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bir story'yi görüntüleyenleri yükle (sadece story sahibi görebilir)
  Future<List<StoryViewer>> loadStoryViewers(String storyId) async {
    if (currentUserId == null) return [];

    try {
      final viewers = await _supabase.client
          .from('story_views')
          .select('*, viewer:profiles!viewer_id(id, username, full_name, avatar_url)')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      final viewerList = (viewers as List)
          .map((v) => StoryViewer.fromJson(v))
          .toList();

      _storyViewers[storyId] = viewerList;
      debugPrint('StoryService: Loaded ${viewerList.length} viewers for story $storyId');
      
      return viewerList;
    } catch (e) {
      debugPrint('StoryService: Error loading story viewers: $e');
      return [];
    }
  }

  /// Cache'den story görüntüleyenlerini getir
  List<StoryViewer> getStoryViewers(String storyId) {
    return _storyViewers[storyId] ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY SİLME
  // ═══════════════════════════════════════════════════════════════════════════

  /// Kendi story'mi sil
  Future<bool> deleteStory(String storyId) async {
    if (currentUserId == null) return false;

    try {
      // Story'yi bul ve medya URL'sini al
      final story = _myStories.firstWhere(
        (s) => s.id == storyId,
        orElse: () => throw Exception('Story not found'),
      );

      // Storage'dan sil (eğer image story ise)
      if (story.type == 'image' && story.mediaUrl != null) {
        final uri = Uri.parse(story.mediaUrl!);
        final fileName = uri.pathSegments.last;
        await _supabase.client.storage.from('stories').remove([fileName]);
      }

      // Database'den sil
      await _supabase.client
          .from('stories')
          .delete()
          .eq('id', storyId)
          .eq('user_id', currentUserId!);

      _myStories.removeWhere((s) => s.id == storyId);
      _storyViewers.remove(storyId);
      
      debugPrint('StoryService: Story $storyId deleted');
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('StoryService: Error deleting story: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STORY YANITLAMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Story'ye yanıt gönder (DM olarak)
  Future<bool> replyToStory({
    required String storyId,
    required String storyOwnerId,
    required String message,
  }) async {
    if (currentUserId == null) return false;

    try {
      final chatService = ChatService.instance;
      
      // Önce story sahibiyle chat var mı kontrol et
      String? chatId = await chatService.findExistingDirectChat(storyOwnerId);
      
      // Yoksa yeni chat oluştur
      if (chatId == null) {
        chatId = await chatService.createDirectChat(storyOwnerId);
      }
      
      if (chatId == null) {
        debugPrint('StoryService: Could not create/find chat');
        return false;
      }
      
      // Story yanıtını gönder (metadata'da story bilgisi)
      final success = await chatService.sendMessage(
        chatId: chatId,
        content: message,
        metadata: {
          'story_reply': storyId,
          'story_owner': storyOwnerId,
        },
      );
      
      debugPrint('StoryService: Reply to story $storyId sent: $success');
      return success;
    } catch (e) {
      debugPrint('StoryService: Error replying to story: $e');
      return false;
    }
  }

  /// Cache'i temizle
  void clearCache() {
    _userStories.clear();
    _myStories.clear();
    _storyViewers.clear();
    _viewedStoryIds.clear();
    notifyListeners();
  }
}

