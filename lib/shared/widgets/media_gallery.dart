import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Sohbet medya galerisi
class MediaGalleryPage extends StatefulWidget {
  final String chatName;
  final List<MediaItem> mediaItems;

  const MediaGalleryPage({
    super.key,
    required this.chatName,
    required this.mediaItems,
  });

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // ignore: unused_field
  MediaFilter _filter = MediaFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '${widget.mediaItems.length} medya',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () {
              // Search functionality
            },
          ),
          PopupMenuButton<MediaFilter>(
            icon: Icon(Icons.filter_list,
                color: isDark ? Colors.white : Colors.black87),
            onSelected: (filter) {
              setState(() {
                _filter = filter;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: MediaFilter.all,
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: MediaFilter.photos,
                child: Text('Fotoğraflar'),
              ),
              const PopupMenuItem(
                value: MediaFilter.videos,
                child: Text('Videolar'),
              ),
              const PopupMenuItem(
                value: MediaFilter.documents,
                child: Text('Belgeler'),
              ),
              const PopupMenuItem(
                value: MediaFilter.links,
                child: Text('Bağlantılar'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: NearTheme.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: NearTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded)),
            Tab(icon: Icon(Icons.photo_library_rounded)),
            Tab(icon: Icon(Icons.insert_drive_file_rounded)),
            Tab(icon: Icon(Icons.link_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGridView(widget.mediaItems),
          _buildGridView(widget.mediaItems
              .where((m) =>
                  m.type == MediaType.photo || m.type == MediaType.video)
              .toList()),
          _buildDocumentsList(widget.mediaItems
              .where((m) => m.type == MediaType.document)
              .toList()),
          _buildLinksList(
              widget.mediaItems.where((m) => m.type == MediaType.link).toList()),
        ],
      ),
    );
  }

  Widget _buildGridView(List<MediaItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState('Medya bulunamadı');
    }

    // Group by month
    final groupedItems = <String, List<MediaItem>>{};
    for (final item in items) {
      final monthKey =
          '${_getMonthName(item.date.month)} ${item.date.year}';
      groupedItems.putIfAbsent(monthKey, () => []).add(item);
    }

    return CustomScrollView(
      slivers: groupedItems.entries.map((entry) {
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildMediaTile(entry.value[index]),
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMediaTile(MediaItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openMedia(item),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (item.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(item),
                ),
              )
            else
              _buildPlaceholder(item),

            // Video indicator
            if (item.type == MediaType.video)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        item.duration ?? '0:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Selection overlay (for multi-select)
            if (item.isSelected)
              Container(
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(MediaItem item) {
    return Center(
      child: Icon(
        item.type == MediaType.video
            ? Icons.videocam_rounded
            : Icons.image_rounded,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildDocumentsList(List<MediaItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState('Belge bulunamadı');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDocumentColor(item.fileName),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getDocumentExtension(item.fileName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName ?? 'Belge',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.fileSize ?? '?'} • ${_formatDate(item.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () => _downloadDocument(item),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinksList(List<MediaItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState('Bağlantı bulunamadı');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NearTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.link_rounded,
                          color: NearTheme.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.link_rounded, color: NearTheme.primary),
            ),
            title: Text(
              item.title ?? item.url ?? 'Bağlantı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.url ?? '',
              style: const TextStyle(fontSize: 12, color: NearTheme.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => _openLink(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _openMedia(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerPage(item: item),
      ),
    );
  }

  void _downloadDocument(MediaItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.fileName} indiriliyor...')),
    );
  }

  void _openLink(MediaItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Açılıyor: ${item.url}')),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)}';
  }

  Color _getDocumentColor(String? fileName) {
    final ext = _getDocumentExtension(fileName).toLowerCase();
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

  String _getDocumentExtension(String? fileName) {
    if (fileName == null) return '?';
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '?';
  }
}

/// Medya görüntüleme sayfası
class MediaViewerPage extends StatelessWidget {
  final MediaItem item;

  const MediaViewerPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (_) => [
              const PopupMenuItem(child: Text('İlet')),
              const PopupMenuItem(child: Text('Favori')),
              const PopupMenuItem(
                child: Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: item.thumbnailUrl != null
              ? Image.network(
                  item.thumbnailUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: Colors.white38,
                  ),
                )
              : Icon(
                  item.type == MediaType.video
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                  size: 64,
                  color: Colors.white38,
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDateTime(item.date),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              if (item.fileSize != null) ...[
                const Text(' • ', style: TextStyle(color: Colors.white60)),
                Text(
                  item.fileSize!,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Medya türü
enum MediaType { photo, video, document, link }

/// Filtre seçenekleri
enum MediaFilter { all, photos, videos, documents, links }

/// Medya item modeli
class MediaItem {
  final String id;
  final MediaType type;
  final DateTime date;
  final String? thumbnailUrl;
  final String? url;
  final String? fileName;
  final String? fileSize;
  final String? duration;
  final String? title;
  bool isSelected;

  MediaItem({
    required this.id,
    required this.type,
    required this.date,
    this.thumbnailUrl,
    this.url,
    this.fileName,
    this.fileSize,
    this.duration,
    this.title,
    this.isSelected = false,
  });
}
