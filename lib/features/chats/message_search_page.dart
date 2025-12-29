import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/models.dart';

/// Mesaj arama sayfası - chat içinde mesaj arama
class MessageSearchPage extends StatefulWidget {
  static const route = '/message-search';
  final String chatId;
  final String chatName;
  final List<Message> messages;

  const MessageSearchPage({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.messages,
  });

  @override
  State<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends State<MessageSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<Message> _results = [];
  int _currentIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query == _query) return;

    setState(() {
      _query = query;
      if (query.isEmpty) {
        _results = [];
        _currentIndex = 0;
      } else {
        _results = widget.messages
            .where((m) => m.text.toLowerCase().contains(query))
            .toList()
            .reversed
            .toList(); // En yeni mesajlar önce
        _currentIndex = _results.isEmpty ? 0 : 0;
      }
    });
  }

  void _goToPrevious() {
    if (_results.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _results.length) % _results.length;
    });
  }

  void _goToNext() {
    if (_results.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _results.length;
    });
  }

  void _selectResult(Message message) {
    Navigator.pop(context, message);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: NearTheme.primary.withAlpha(60),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: NearTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: '${widget.chatName} içinde ara...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark ? Colors.white38 : Colors.black38,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _focusNode.requestFocus();
                      },
                    )
                  : null,
            ),
          ),
        ),
        actions: [
          if (_results.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.keyboard_arrow_up, color: NearTheme.primary),
              onPressed: _goToPrevious,
            ),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_down, color: NearTheme.primary),
              onPressed: _goToNext,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Sonuç sayısı
          if (_query.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: Row(
                children: [
                  Text(
                    _results.isEmpty
                        ? 'Sonuç bulunamadı'
                        : '${_currentIndex + 1} / ${_results.length} sonuç',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Sonuç listesi
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? 'Mesaj aramak için yazın'
                              : 'Sonuç bulunamadı',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final message = _results[index];
                      final isSelected = index == _currentIndex;

                      return Container(
                        color: isSelected
                            ? NearTheme.primary.withAlpha(20)
                            : Colors.transparent,
                        child: ListTile(
                          onTap: () => _selectResult(message),
                          leading: CircleAvatar(
                            backgroundColor: message.isMe
                                ? NearTheme.primary.withAlpha(30)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                            child: Icon(
                              message.isMe
                                  ? Icons.person
                                  : Icons.person_outline,
                              color: message.isMe
                                  ? NearTheme.primary
                                  : (isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.isMe ? 'Sen' : widget.chatName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(message.createdAt),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _highlightText(message.text, _query),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
