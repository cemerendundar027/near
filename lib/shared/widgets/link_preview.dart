import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// URL önizleme kartı
class LinkPreviewCard extends StatelessWidget {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isCompact;

  const LinkPreviewCard({
    super.key,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
    this.onTap,
    this.isLoading = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingState(isDark);
    }

    if (isCompact) {
      return _buildCompactCard(context, isDark);
    }

    return _buildFullCard(context, isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skeleton image
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          // Skeleton title
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Skeleton description
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            if (imageUrl != null)
              Container(
                height: 140,
                width: double.infinity,
                color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade100,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(
                      Icons.image_rounded,
                      size: 40,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site info
                  Row(
                    children: [
                      if (favicon != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            favicon!,
                            width: 16,
                            height: 16,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          siteName ?? _extractDomain(url),
                          style: TextStyle(
                            fontSize: 11,
                            color: NearTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ],
                  ),

                  if (title != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                    child: Icon(
                      Icons.link_rounded,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: NearTheme.primary,
                ),
              ),

            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    siteName ?? _extractDomain(url),
                    style: TextStyle(
                      fontSize: 11,
                      color: NearTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title ?? url,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

/// Link preview data model
class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? favicon;
  final String? type; // website, article, video, etc.
  final DateTime? fetchedAt;

  LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.favicon,
    this.type,
    this.fetchedAt,
  });

  factory LinkPreviewData.fromMap(Map<String, dynamic> map) {
    return LinkPreviewData(
      url: map['url'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image'] as String?,
      siteName: map['site_name'] as String?,
      favicon: map['favicon'] as String?,
      type: map['type'] as String?,
    );
  }
}

/// Mesaj içindeki linkleri tespit eden helper
class LinkDetector {
  static final _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );

  /// Metindeki tüm URL'leri bulur
  static List<String> extractUrls(String text) {
    return _urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// İlk URL'yi bulur
  static String? extractFirstUrl(String text) {
    final match = _urlRegex.firstMatch(text);
    return match?.group(0);
  }

  /// URL içerip içermediğini kontrol eder
  static bool containsUrl(String text) {
    return _urlRegex.hasMatch(text);
  }

  /// URL'nin geçerli olup olmadığını kontrol eder
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }
}

/// URL'leri tıklanabilir yapan text widget
class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final Function(String url)? onLinkTap;
  final int? maxLines;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.onLinkTap,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = style ??
        TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        );
    final defaultLinkStyle = linkStyle ??
        TextStyle(
          color: NearTheme.primary,
          fontSize: 15,
          decoration: TextDecoration.underline,
        );

    final spans = _buildTextSpans(defaultStyle, defaultLinkStyle);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  List<InlineSpan> _buildTextSpans(TextStyle style, TextStyle linkStyle) {
    final spans = <InlineSpan>[];
    final urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    int lastEnd = 0;

    for (final match in urlRegex.allMatches(text)) {
      // Text before URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      // URL
      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: () => onLinkTap?.call(url),
            child: Text(
              url,
              style: linkStyle,
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return spans;
  }
}

/// Sohbet girişinde URL girildiğinde önizleme gösteren widget
class InputLinkPreview extends StatelessWidget {
  final LinkPreviewData? previewData;
  final bool isLoading;
  final VoidCallback? onRemove;

  const InputLinkPreview({
    super.key,
    this.previewData,
    this.isLoading = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (previewData == null && !isLoading) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: NearTheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          if (isLoading)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: NearTheme.primary,
                  ),
                ),
              ),
            )
          else if (previewData?.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                previewData!.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(isDark),
              ),
            )
          else
            _buildPlaceholder(isDark),

          const SizedBox(width: 10),

          // Content
          Expanded(
            child: isLoading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 150,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewData!.siteName ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: NearTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        previewData!.title ?? previewData!.url,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),

          // Remove button
          if (onRemove != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: NearTheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.link_rounded,
        color: NearTheme.primary,
        size: 24,
      ),
    );
  }
}
