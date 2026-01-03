import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/models.dart';
import '../../shared/chat_service.dart';

/// Mesaj okundu/iletildi bilgisi detay bottom sheet
class MessageInfoSheet extends StatefulWidget {
  final Message message;
  final String chatName;

  const MessageInfoSheet({
    super.key,
    required this.message,
    required this.chatName,
  });

  static Future<void> show(
    BuildContext context, {
    required Message message,
    required String chatName,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          MessageInfoSheet(message: message, chatName: chatName),
    );
  }

  @override
  State<MessageInfoSheet> createState() => _MessageInfoSheetState();
}

class _MessageInfoSheetState extends State<MessageInfoSheet> {
  DateTime? _deliveredAt;
  DateTime? _readAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessageStatus();
  }

  Future<void> _loadMessageStatus() async {
    try {
      final chatService = ChatService.instance;
      final status = await chatService.getMessageStatus(widget.message.id);
      
      if (mounted) {
        setState(() {
          _deliveredAt = status?['delivered_at'] != null 
              ? DateTime.tryParse(status!['delivered_at']) 
              : null;
          _readAt = status?['read_at'] != null 
              ? DateTime.tryParse(status!['read_at']) 
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} $hh:$mm';
  }

  Message get message => widget.message;
  String get chatName => widget.chatName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // Gerçek veriler veya mesaj durumuna göre tahmin
    final sentAt = message.createdAt;
    final deliveredAt = _deliveredAt ?? (message.status == MessageStatus.delivered || message.status == MessageStatus.read 
        ? sentAt.add(const Duration(seconds: 2)) 
        : null);
    final readAt = _readAt ?? (message.status == MessageStatus.read 
        ? sentAt.add(const Duration(minutes: 1))
        : null);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  'Mesaj Bilgisi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mesaj önizleme
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isMe
                          ? NearTheme.primary
                          : (isDark
                                ? const Color(0xFF2C2C2E)
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isMe ? Colors.white : cs.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Okundu bilgisi (sadece benim mesajlarım için)
                  if (message.isMe) ...[
                    _InfoSection(
                      isDark: isDark,
                      icon: Icons.done_all_rounded,
                      iconColor: readAt != null
                          ? const Color(0xFF53BDEB)
                          : Colors.grey,
                      title: 'Okundu',
                      contacts: readAt != null
                          ? [
                              _ReadInfo(
                                name: chatName,
                                time: _formatDateTime(readAt),
                              ),
                            ]
                          : [],
                      emptyText: 'Henüz okunmadı',
                    ),

                    const SizedBox(height: 16),

                    _InfoSection(
                      isDark: isDark,
                      icon: Icons.done_all_rounded,
                      iconColor: Colors.grey,
                      title: 'İletildi',
                      contacts: deliveredAt != null
                          ? [
                        _ReadInfo(
                          name: chatName,
                          time: _formatDateTime(deliveredAt),
                        ),
                            ]
                          : [],
                      emptyText: 'Henüz iletilmedi',
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Gönderim zamanı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: NearTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.isMe ? 'Gönderildi' : 'Alındı',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                              Text(
                                _formatDateTime(sentAt),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mesaj tipi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uçtan uca şifreli',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_ReadInfo> contacts;
  final String? emptyText;

  const _InfoSection({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.contacts,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contacts.isEmpty)
              Text(
                emptyText ?? '-',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              )
            else
              ...contacts.map(
                (info) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          info.name,
                          style: TextStyle(color: cs.onSurface),
                        ),
                      ),
                      Text(
                        info.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadInfo {
  final String name;
  final String time;

  const _ReadInfo({required this.name, required this.time});
}
