enum MessageStatus { sending, sent, delivered, read }

class ChatPreview {
  final String id;         // chatId
  final String oderId;     // karşı tarafın id'si (grup için boş olabilir)
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
  }) : oderId = userId;
  
  /// userId getter (eski kodlarla uyumluluk)
  String get userId => oderId;
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
  final DateTime lastSeenAt;

  const Presence({required this.online, required this.lastSeenAt});
}
