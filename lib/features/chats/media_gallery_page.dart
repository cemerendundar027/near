import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';

/// Medya Galerisi Sayfası
/// - Fotoğraflar tab
/// - Videolar tab
/// - Belgeler tab
/// - Linkler tab
class MediaGalleryPage extends StatefulWidget {
  static const route = '/media-gallery';

  final String chatId;
  final String chatName;
  final int initialTab;

  const MediaGalleryPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.initialTab = 0,
  });

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Supabase'den yüklenen veriler
  List<MediaItem> _photos = [];
  List<MediaItem> _videos = [];
  List<DocumentItem> _documents = [];
  final List<LinkItem> _links = []; // Linkler mesaj içeriğinden parse edilebilir

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      final chatService = ChatService.instance;
      final media = await chatService.getChatMedia(widget.chatId);
      
      if (mounted) {
        setState(() {
          // Fotoğrafları dönüştür
          _photos = (media['photos'] ?? []).map<MediaItem>((m) {
            final createdAt = DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now();
            return MediaItem(
              id: m['id'] ?? '',
              type: MediaType.photo,
              date: createdAt,
              size: _formatSize(m['metadata']?['file_size']),
              url: m['media_url'],
            );
          }).toList();
          
          // Videoları dönüştür
          _videos = (media['videos'] ?? []).map<MediaItem>((m) {
            final createdAt = DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now();
            return MediaItem(
              id: m['id'] ?? '',
              type: MediaType.video,
              date: createdAt,
              size: _formatSize(m['metadata']?['file_size']),
              duration: Duration(seconds: m['metadata']?['duration'] ?? 0),
              url: m['media_url'],
            );
          }).toList();
          
          // Dosyaları dönüştür
          _documents = (media['files'] ?? []).map<DocumentItem>((m) {
            final createdAt = DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now();
            return DocumentItem(
              id: m['id'] ?? '',
              name: m['metadata']?['file_name'] ?? 'Dosya',
              size: _formatSize(m['metadata']?['file_size']),
              date: createdAt,
              url: m['media_url'],
            );
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatSize(dynamic bytes) {
    if (bytes == null) return '';
    final b = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: NearTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Medya, Bağlantılar, Belgeler',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: NearTheme.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: NearTheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text('${_photos.length}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text('${_videos.length}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text('${_documents.length}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text('${_links.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Photos Tab
          _buildPhotosGrid(),

          // Videos Tab
          _buildVideosGrid(),

          // Documents Tab
          _buildDocumentsList(),

          // Links Tab
          _buildLinksList(),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    if (_photos.isEmpty) {
      return _buildEmptyState(
        Icons.photo_library_rounded,
        'Fotoğraf Yok',
        'Paylaşılan fotoğraflar burada görünecek',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return GestureDetector(
          onTap: () => _openPhotoViewer(photo),
          child: Container(
            color: NearTheme.primary.withAlpha(50),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gerçek fotoğraf önizlemesi
                if (photo.url != null)
                  Image.network(
                    photo.url!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image_rounded,
                      size: 40,
                      color: NearTheme.primary.withAlpha(100),
                    ),
                  )
                else
                  Icon(
                    Icons.photo_rounded,
                    size: 40,
                    color: NearTheme.primary.withAlpha(100),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      photo.size,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPhotoViewer(MediaItem photo) {
    if (photo.url == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          imageUrl: photo.url!,
          date: photo.date,
        ),
      ),
    );
  }

  Widget _buildVideosGrid() {
    if (_videos.isEmpty) {
      return _buildEmptyState(
        Icons.videocam_rounded,
        'Video Yok',
        'Paylaşılan videolar burada görünecek',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 16 / 9,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return GestureDetector(
          onTap: () => _showSnackBar('Video oynatılıyor'),
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: NearTheme.primaryDark.withAlpha(50),
                  child: Icon(
                    Icons.movie_rounded,
                    size: 40,
                    color: Colors.white30,
                  ),
                ),
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(video.duration!),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.size,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_documents.isEmpty) {
      return _buildEmptyState(
        Icons.description_rounded,
        'Belge Yok',
        'Paylaşılan belgeler burada görünecek',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getDocColor(doc.name).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getDocIcon(doc.name), color: _getDocColor(doc.name)),
            ),
            title: Text(
              doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              '${doc.size} • ${_formatDate(doc.date)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.download_rounded, color: NearTheme.primary),
              onPressed: () => _showSnackBar('İndiriliyor...'),
            ),
            onTap: () => _showSnackBar('Belge açılıyor...'),
          ),
        );
      },
    );
  }

  Widget _buildLinksList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_links.isEmpty) {
      return _buildEmptyState(
        Icons.link_rounded,
        'Bağlantı Yok',
        'Paylaşılan bağlantılar burada görünecek',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _links.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final link = _links[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showSnackBar('Bağlantı açılıyor: ${link.url}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Link icon/preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: NearTheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: NearTheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Link details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (link.description != null) ...[
                          Text(
                            link.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          link.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: NearTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(link.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  IconButton(
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: NearTheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _showSnackBar('Tarayıcıda açılıyor'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NearTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: NearTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }

  IconData _getDocIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getDocColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

// Models
enum MediaType { photo, video }

class MediaItem {
  final String id;
  final MediaType type;
  final DateTime date;
  final String size;
  final Duration? duration;
  final String? url;

  MediaItem({
    required this.id,
    required this.type,
    required this.date,
    required this.size,
    this.duration,
    this.url,
  });
}

class DocumentItem {
  final String id;
  final String name;
  final String size;
  final DateTime date;
  final String? url;

  DocumentItem({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
    this.url,
  });
}

class LinkItem {
  final String id;
  final String url;
  final String title;
  final String? description;
  final DateTime date;

  LinkItem({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    required this.date,
  });
}

/// Tam ekran fotoğraf görüntüleyici
class _FullScreenPhotoViewer extends StatelessWidget {
  final String imageUrl;
  final DateTime date;

  const _FullScreenPhotoViewer({
    required this.imageUrl,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(180),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _formatDate(date),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaşım yakında eklenecek')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İndirme yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                const Text(
                  'Fotoğraf yüklenemedi',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
