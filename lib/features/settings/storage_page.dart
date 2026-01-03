import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/chat_service.dart';

class StoragePage extends StatefulWidget {
  static const route = '/settings/storage';
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  bool _autoDownloadPhotos = true;
  bool _autoDownloadVideos = false;
  bool _autoDownloadDocuments = true;
  bool _useLessData = false;
  
  // Storage bilgileri
  int _totalStorageBytes = 0;
  int _usedStorageBytes = 0;
  int _cacheBytes = 0;
  int _photosBytes = 0;
  int _videosBytes = 0;
  int _documentsBytes = 0;
  int _otherBytes = 0;
  bool _loadingStorage = true;
  
  // Gerçek sohbet verileri
  List<Map<String, dynamic>> _chatStorageData = [];
  
  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }
  
  Future<void> _loadStorageInfo() async {
    try {
      // Uygulama dizinlerini al
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = await getTemporaryDirectory();
      
      // Cache boyutunu hesapla
      _cacheBytes = await _calculateDirectorySize(cacheDir);
      
      // App storage boyutunu hesapla
      _usedStorageBytes = await _calculateDirectorySize(appDir) + _cacheBytes;
      
      // Medya dosyalarını kategorize et
      await _categorizeMediaFiles(appDir);
      
      // Gerçek sohbet verilerini yükle
      await _loadChatStorageData();
      
      // Toplam disk alanı (tahmini)
      _totalStorageBytes = 64 * 1024 * 1024 * 1024; // 64 GB varsayılan
      
      if (mounted) {
        setState(() => _loadingStorage = false);
      }
    } catch (e) {
      debugPrint('Storage info error: $e');
      if (mounted) {
        setState(() => _loadingStorage = false);
      }
    }
  }
  
  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      // Erişim hatası olabilir
    }
    return size;
  }
  
  Future<void> _categorizeMediaFiles(Directory dir) async {
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          final size = await entity.length();
          
          if (path.endsWith('.jpg') || path.endsWith('.jpeg') || 
              path.endsWith('.png') || path.endsWith('.gif') || 
              path.endsWith('.webp')) {
            _photosBytes += size;
          } else if (path.endsWith('.mp4') || path.endsWith('.mov') || 
                     path.endsWith('.avi') || path.endsWith('.mkv')) {
            _videosBytes += size;
          } else if (path.endsWith('.pdf') || path.endsWith('.doc') || 
                     path.endsWith('.docx') || path.endsWith('.xls') ||
                     path.endsWith('.xlsx') || path.endsWith('.txt')) {
            _documentsBytes += size;
          } else {
            _otherBytes += size;
          }
        }
      }
    } catch (e) {
      // Hata yoksay
    }
  }
  
  Future<void> _loadChatStorageData() async {
    try {
      final chatService = ChatService.instance;
      final chats = chatService.chats;
      
      _chatStorageData = chats.map((chat) {
        // Her sohbet için tahmini boyut (gerçek implementasyonda
        // her sohbetin medya dosyalarını sayabilirsiniz)
        return {
          'id': chat['id'] ?? '',
          'name': chat['name'] ?? 'Sohbet',
          'isGroup': chat['is_group'] ?? false,
          'size': 0, // Gerçek boyut hesaplanabilir
          'photos': 0,
          'videos': 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Chat storage data error: $e');
    }
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ));
  }

  void _showManageChatsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gerçek sohbet verilerini kullan
    final chats = _chatStorageData.isEmpty 
        ? <Map<String, dynamic>>[] 
        : _chatStorageData;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sohbet Verileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showClearAllDialog();
                      },
                      child: Text(
                        'Tümünü Sil',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chats.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz sohbet verisi yok',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isGroup = chat['isGroup'] as bool? ?? false;
                    final chatName = chat['name'] as String? ?? 'Sohbet';
                    final photos = chat['photos'] as int? ?? 0;
                    final videos = chat['videos'] as int? ?? 0;
                    final sizeBytes = chat['size'] as int? ?? 0;
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: NearTheme.primary.withAlpha(30),
                        child: Icon(
                          isGroup ? Icons.group_rounded : Icons.person_rounded,
                          color: NearTheme.primary,
                        ),
                      ),
                      title: Text(
                        chatName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        photos > 0 || videos > 0 
                            ? '$photos fotoğraf, $videos video'
                            : 'Medya dosyası yok',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatBytes(sizeBytes),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: NearTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                            onPressed: () => _showDeleteChatDataDialog(chatName),
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
      ),
    );
  }

  void _showDeleteChatDataDialog(String chatName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Verileri Sil',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          '$chatName sohbetine ait tüm medya dosyaları silinecek. Mesajlar korunacak.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('$chatName verileri silindi');
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tüm Verileri Sil',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Tüm sohbetlere ait medya dosyaları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('Tüm sohbet verileri silindi');
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
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        title: Text(
          'Storage and Data',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Storage Usage Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SettingsColors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storage_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage Used',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            _loadingStorage 
                                ? 'Hesaplanıyor...'
                                : '${_formatBytes(_usedStorageBytes)} of ${_formatBytes(_totalStorageBytes)}',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _totalStorageBytes > 0 
                        ? _usedStorageBytes / _totalStorageBytes 
                        : 0,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(SettingsColors.blue),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _storageItem('Photos', _formatBytes(_photosBytes), SettingsColors.green),
                    _storageItem('Videos', _formatBytes(_videosBytes), SettingsColors.red),
                    _storageItem('Documents', _formatBytes(_documentsBytes), SettingsColors.orange),
                    _storageItem('Other', _formatBytes(_otherBytes), SettingsColors.gray),
                  ],
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Auto-Download'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.photo_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Photos',
                  subtitle: 'Otomatik fotoğraf indir',
                  value: _autoDownloadPhotos,
                  onChanged: (v) {
                    setState(() => _autoDownloadPhotos = v);
                    _toast(v ? 'Fotoğraf otomatik indir: Açık' : 'Fotoğraf otomatik indir: Kapalı');
                  },
                ),
                _divider(isDark),
                SettingsSwitchTile(
                  icon: Icons.videocam_rounded,
                  iconBackgroundColor: SettingsColors.red,
                  title: 'Videos',
                  subtitle: 'Otomatik video indir',
                  value: _autoDownloadVideos,
                  onChanged: (v) {
                    setState(() => _autoDownloadVideos = v);
                    _toast(v ? 'Video otomatik indir: Açık' : 'Video otomatik indir: Kapalı');
                  },
                ),
                _divider(isDark),
                SettingsSwitchTile(
                  icon: Icons.description_rounded,
                  iconBackgroundColor: SettingsColors.orange,
                  title: 'Documents',
                  subtitle: 'Otomatik döküman indir',
                  value: _autoDownloadDocuments,
                  onChanged: (v) {
                    setState(() => _autoDownloadDocuments = v);
                    _toast(v ? 'Döküman otomatik indir: Açık' : 'Döküman otomatik indir: Kapalı');
                  },
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Network'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.data_saver_on_rounded,
                  iconBackgroundColor: SettingsColors.teal,
                  title: 'Use Less Data for Calls',
                  subtitle: 'Aramalarda daha az veri kullan',
                  value: _useLessData,
                  onChanged: (v) {
                    setState(() => _useLessData = v);
                    _toast(v ? 'Az veri modu: Açık' : 'Az veri modu: Kapalı');
                  },
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.network_check_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'Network Usage',
                  subtitle: 'Detaylı veri kullanımı',
                  onTap: () => _showNetworkUsage(),
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Manage Storage'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.cleaning_services_rounded,
                  iconBackgroundColor: SettingsColors.red,
                  title: 'Clear Cache',
                  subtitle: 'Önbelleği temizle (${_formatBytes(_cacheBytes)})',
                  onTap: () => _showClearCacheDialog(),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.folder_delete_rounded,
                  iconBackgroundColor: SettingsColors.orange,
                  title: 'Manage Chats',
                  subtitle: 'Sohbet verilerini yönet',
                  onTap: _showManageChatsDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _storageItem(String label, String size, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        Text(
          size,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 70,
        color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
      );

  void _showNetworkUsage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Network Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _usageRow('Messages Sent', '0 B'),
              _usageRow('Messages Received', '0 B'),
              _usageRow('Media Sent', '0 B'),
              _usageRow('Media Received', '0 B'),
              _usageRow('Voice Calls', '0 B'),
              _usageRow('Video Calls', '0 B'),
              const SizedBox(height: 8),
              Text(
                'Ağ kullanımı istatistikleri yakında eklenecek',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _toast('İstatistikler sıfırlandı');
                  },
                  child: const Text('Reset Statistics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _usageRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Önbellek temizlenecek. Medya dosyaları tekrar indirilmesi gerekebilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SettingsColors.red),
            onPressed: () {
              Navigator.pop(context);
              _toast('Önbellek temizlendi ✓');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
