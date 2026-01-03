import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/near_branding.dart';

/// Arama geçmişi modeli
class CallRecord {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isVideo;
  final bool isOutgoing;
  final bool isMissed;
  final DateTime time;
  final int callCount;

  const CallRecord({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isVideo,
    required this.isOutgoing,
    required this.isMissed,
    required this.time,
    this.callCount = 1,
  });
}

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  bool _isEditing = false;
  final Set<String> _selectedCalls = {};

  // Gerçek arama geçmişi - Supabase'den yüklenecek
  final List<CallRecord> _calls = [];
  // Not: Arama özelliği yakında eklenecek

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24 && now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inHours < 48) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  void _startCall(CallRecord call) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arama özelliği yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNewCallSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: NearTheme.primary, fontSize: 17),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Yeni Arama',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Create Link
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NearTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link, color: Colors.white, size: 20),
                ),
                title: Text(
                  'Arama Linki Oluştur',
                  style: TextStyle(
                    color: NearTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Near kullanmayan kişilerle paylaş',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Arama linki panoya kopyalandı'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Contacts header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SIRALANAN KİŞİLER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Contacts list
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (_, i) {
                  final names = ['Mert', 'Ayşe', 'Selin', 'Ahmet', 'Zeynep'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.grey.shade300,
                      child: Icon(
                        Icons.person,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    title: Text(
                      names[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/call/$i?video=false');
                          },
                          icon: Icon(Icons.call, color: NearTheme.primary),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/call/$i?video=true');
                          },
                          icon: Icon(Icons.videocam, color: NearTheme.primary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSelectedCalls() {
    setState(() {
      _calls.removeWhere((call) => _selectedCalls.contains(call.id));
      _selectedCalls.clear();
      _isEditing = false;
    });
  }

  void _clearAllCalls() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Aramaları Sil'),
        content: const Text(
          'Tüm arama geçmişini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _calls.clear();
                _isEditing = false;
              });
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: _isEditing
            ? Text(
                _selectedCalls.isEmpty
                    ? 'Seç'
                    : '${_selectedCalls.length} seçildi',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              )
            : Text(
                'Aramalar',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
        leading: _isEditing
            ? TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _selectedCalls.clear();
                  });
                },
                child: Text(
                  'İptal',
                  style: TextStyle(color: NearTheme.primary, fontSize: 17),
                ),
              )
            : null,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _selectedCalls.isEmpty
                  ? _clearAllCalls
                  : _deleteSelectedCalls,
              child: Text(
                _selectedCalls.isEmpty ? 'Tümünü Sil' : 'Sil',
                style: TextStyle(color: Colors.red, fontSize: 17),
              ),
            )
          else ...[
            TextButton(
              onPressed: () {
                setState(() => _isEditing = true);
              },
              child: Text(
                'Düzenle',
                style: TextStyle(color: NearTheme.primary, fontSize: 17),
              ),
            ),
          ],
        ],
      ),
      body: _calls.isEmpty
          ? _buildEmptyState(isDark, cs)
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GestureDetector(
                    onTap: () => _showNewCallSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ara',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Call list
                Expanded(
                  child: ListView.builder(
                    itemCount: _calls.length,
                    itemBuilder: (context, i) {
                      final call = _calls[i];
                      final isSelected = _selectedCalls.contains(call.id);

                      return                       _CallListTile(
                        call: call,
                        formattedTime: _formatTime(call.time),
                        isEditing: _isEditing,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          if (_isEditing) {
                            setState(() {
                              if (isSelected) {
                                _selectedCalls.remove(call.id);
                              } else {
                                _selectedCalls.add(call.id);
                              }
                            });
                          } else {
                            // Kişiye tıklayınca arama yap
                            _startCall(call);
                          }
                        },
                        // Info butonuna tıklayınca kişi kartı aç
                        onInfoTap: () => _showCallDetail(call),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: !_isEditing
          ? FloatingActionButton(
              heroTag: 'calls_fab',
              backgroundColor: NearTheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              onPressed: _showNewCallSheet,
              child: const Icon(Icons.add_call, size: 26),
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_rounded,
              size: 50,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz Arama Yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir arama başlatmak için\naşağıdaki butona dokun',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDetail(CallRecord call) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                const SizedBox(height: 20),
                // Profile
                CircleAvatar(
                  radius: 40,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                call.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NearLogoText(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                  Text(
                    ' · Mobil',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.message_rounded,
                    label: 'Mesaj',
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Sesli',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/call/${call.id}?video=false');
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Görüntülü',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/call/${call.id}?video=true');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Call history
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arama Geçmişi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          call.isOutgoing
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded,
                          size: 16,
                          color: call.isMissed
                              ? Colors.red
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          call.isOutgoing ? 'Giden' : 'Gelen',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(call.time),
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NearTheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NearTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: NearTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallListTile extends StatelessWidget {
  final CallRecord call;
  final String formattedTime;
  final bool isEditing;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _CallListTile({
    required this.call,
    required this.formattedTime,
    required this.isEditing,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Edit mode checkbox
            if (isEditing) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? NearTheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? NearTheme.primary
                        : (isDark ? Colors.white38 : Colors.black38),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
            ],
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
              child: Icon(
                Icons.person,
                size: 28,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: call.isMissed ? Colors.red : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        call.isOutgoing
                            ? Icons.call_made_rounded
                            : Icons.call_received_rounded,
                        size: 14,
                        color: call.isMissed
                            ? Colors.red
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        call.isVideo ? Icons.videocam : Icons.call,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      if (call.callCount > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${call.callCount})',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Time
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            // Info button (not in edit mode) - kişi kartını açar
            if (!isEditing) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onInfoTap,
                child: Icon(
                  Icons.info_outline,
                  color: NearTheme.primary,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
