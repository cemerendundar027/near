import 'package:hive/hive.dart';
import 'models.dart';

// MessageType için Hive Adapter
class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 3;

  @override
  MessageType read(BinaryReader reader) {
    return MessageType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    writer.writeInt(obj.index);
  }
}

// MessageStatus için Hive Adapter
class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 0;

  @override
  MessageStatus read(BinaryReader reader) {
    return MessageStatus.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    writer.writeInt(obj.index);
  }
}

// Message için Hive Adapter (güncellenmiş - medya desteği)
class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 1;

  @override
  Message read(BinaryReader reader) {
    final id = reader.readString();
    final chatId = reader.readString();
    final senderId = reader.readString();
    final text = reader.readString();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final status = MessageStatus.values[reader.readInt()];
    final typeIndex = reader.readInt();
    final type = MessageType.values[typeIndex];
    final hasMediaUrl = reader.readBool();
    final mediaUrl = hasMediaUrl ? reader.readString() : null;
    final hasMetadata = reader.readBool();
    Map<String, dynamic>? metadata;
    if (hasMetadata) {
      final metadataLength = reader.readInt();
      metadata = {};
      for (var i = 0; i < metadataLength; i++) {
        final key = reader.readString();
        final valueType = reader.readInt(); // 0: String, 1: int, 2: double, 3: bool
        dynamic value;
        switch (valueType) {
          case 0:
            value = reader.readString();
            break;
          case 1:
            value = reader.readInt();
            break;
          case 2:
            value = reader.readDouble();
            break;
          case 3:
            value = reader.readBool();
            break;
          default:
            value = reader.readString();
        }
        metadata[key] = value;
      }
    }
    
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      createdAt: createdAt,
      status: status,
      type: type,
      mediaUrl: mediaUrl,
      metadata: metadata,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.chatId);
    writer.writeString(obj.senderId);
    writer.writeString(obj.text);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.status.index);
    writer.writeInt(obj.type.index);
    writer.writeBool(obj.mediaUrl != null);
    if (obj.mediaUrl != null) {
      writer.writeString(obj.mediaUrl!);
    }
    writer.writeBool(obj.metadata != null);
    if (obj.metadata != null) {
      writer.writeInt(obj.metadata!.length);
      for (final entry in obj.metadata!.entries) {
        writer.writeString(entry.key);
        final value = entry.value;
        if (value is String) {
          writer.writeInt(0);
          writer.writeString(value);
        } else if (value is int) {
          writer.writeInt(1);
          writer.writeInt(value);
        } else if (value is double) {
          writer.writeInt(2);
          writer.writeDouble(value);
        } else if (value is bool) {
          writer.writeInt(3);
          writer.writeBool(value);
        } else {
          writer.writeInt(0);
          writer.writeString(value.toString());
        }
      }
    }
  }
}

// ChatPreview için Hive Adapter (güncellenmiş - isGroup, avatarUrl)
class ChatPreviewAdapter extends TypeAdapter<ChatPreview> {
  @override
  final int typeId = 2;

  @override
  ChatPreview read(BinaryReader reader) {
    final id = reader.readString();
    final oderId = reader.readString();
    final name = reader.readString();
    final lastMessage = reader.readString();
    final time = reader.readString();
    final online = reader.readBool();
    final isGroup = reader.readBool();
    final hasAvatarUrl = reader.readBool();
    final avatarUrl = hasAvatarUrl ? reader.readString() : null;
    
    return ChatPreview(
      id: id,
      userId: oderId,
      name: name,
      lastMessage: lastMessage,
      time: time,
      online: online,
      isGroup: isGroup,
      avatarUrl: avatarUrl,
    );
  }

  @override
  void write(BinaryWriter writer, ChatPreview obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.name);
    writer.writeString(obj.lastMessage);
    writer.writeString(obj.time);
    writer.writeBool(obj.online);
    writer.writeBool(obj.isGroup);
    writer.writeBool(obj.avatarUrl != null);
    if (obj.avatarUrl != null) {
      writer.writeString(obj.avatarUrl!);
    }
  }
}

// Hive kutuları için sabitler
class HiveBoxes {
  static const String messages = 'messages';
  static const String chats = 'chats';
  static const String settings = 'settings';
  static const int cacheVersion = 2; // Adapter değişikliği için versiyon
  
  /// Eski cache'i temizle (format değişikliğinde)
  static Future<void> clearOldCache() async {
    try {
      // Settings box'ından versiyon kontrol et
      final settingsBox = await Hive.openBox('_hive_settings');
      final storedVersion = settingsBox.get('cache_version', defaultValue: 1);
      
      if (storedVersion < cacheVersion) {
        // Eski kutuları sil
        await Hive.deleteBoxFromDisk(messages);
        await Hive.deleteBoxFromDisk(chats);
        
        // Yeni versiyonu kaydet
        await settingsBox.put('cache_version', cacheVersion);
        print('HiveBoxes: Old cache cleared (v$storedVersion -> v$cacheVersion)');
      }
      
      await settingsBox.close();
    } catch (e) {
      print('HiveBoxes: Error clearing old cache: $e');
      // Hata durumunda kutuları silmeyi dene
      try {
        await Hive.deleteBoxFromDisk(messages);
        await Hive.deleteBoxFromDisk(chats);
      } catch (_) {}
    }
  }
  
  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatPreviewAdapter());
    }
  }
  
  static Future<void> openBoxes() async {
    await Hive.openBox<Message>(messages);
    await Hive.openBox<ChatPreview>(chats);
    await Hive.openBox(settings);
  }
}
