enum MessageStatus { sending, sent, delivered, read }

class ChatPreview {
  final String id;         // chatId
  final String otherUserId; // karşı tarafın id'si (grup için boş olabilir)
  final String name;
  final String lastMessage;
  final String time;       // UI string
  final bool online;
  final bool isGroup;      // grup sohbeti mi?
  final String? avatarUrl; // profil/grup fotoğrafı

  const ChatPreview({
    required this.id,
    required String userId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.online,
    this.isGroup = false,
    this.avatarUrl,
  }) : otherUserId = userId;
  
  /// userId getter (eski kodlarla uyumluluk)
  String get userId => otherUserId;
}

/// Mesaj tipleri
enum MessageType { text, image, video, voice, file, gif, location, contact }

class Message {
  final String id;
  final String chatId;
  final String senderId; // 'me' veya karşı taraf id
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final MessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool isStarred;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.type = MessageType.text,
    this.mediaUrl,
    this.metadata,
    this.isStarred = false,
  });

  bool get isMe => senderId == 'me';

  /// Metadata'dan duration (sesli mesaj için)
  int? get duration => metadata?['duration'] as int?;
  
  /// Metadata'dan dosya adı
  String? get fileName => metadata?['file_name'] as String?;
  
  /// Metadata'dan dosya boyutu
  int? get fileSize => metadata?['file_size'] as int?;

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    MessageStatus? status,
    MessageType? type,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
    bool? isStarred,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  /// String'den MessageType'a dönüştür
  static MessageType parseType(String? typeStr) {
    switch (typeStr) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      case 'file':
        return MessageType.file;
      case 'gif':
        return MessageType.gif;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      default:
        return MessageType.text;
    }
  }
}


class Presence {
  final bool online;
  final DateTime? lastSeenAt;

  const Presence({required this.online, this.lastSeenAt});

  /// Kullanıcının gerçekten çevrimiçi olup olmadığını kontrol eder.
  /// is_online bayrağı true olsa bile, son görülme 3 dakikadan eskiyse offline kabul eder.
  bool get isEffectivelyOnline {
    if (!online) return false;
    if (lastSeenAt == null) return true; // Bilinmiyor durumu, bayrağa güven
    
    final diff = DateTime.now().toUtc().difference(lastSeenAt!.toUtc()).inMinutes.abs();
    return diff <= 3;
  }
}

class ChatParticipant {
  final String userId;
  final String role; // 'admin' | 'member'
  final DateTime? joinedAt;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const ChatParticipant({
    required this.userId,
    required this.role,
    this.joinedAt,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    return ChatParticipant(
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      username: profile['username'] as String?,
      fullName: profile['full_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      isOnline: profile['is_online'] as bool? ?? false,
      lastSeen: profile['last_seen'] != null ? DateTime.parse(profile['last_seen']) : null,
    );
  }
}
