import 'package:flutter/material.dart';

/// Mesaj formatlaması için helper widget
/// Desteklenen formatlar:
/// - *bold* → kalın
/// - _italic_ → italik  
/// - ~strikethrough~ → üstü çizili
/// - `code` → mono font kod
/// - ```code block``` → kod bloğu
class FormattedText extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;

  const FormattedText({
    super.key,
    required this.text,
    required this.textColor,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          height: 1.3,
        ),
        children: _parseText(text),
      ),
    );
  }

  List<InlineSpan> _parseText(String input) {
    final List<InlineSpan> spans = [];
    final RegExp pattern = RegExp(
      r'(\*[^*]+\*)|(_[^_]+_)|(~[^~]+~)|(`[^`]+`)|(\n)',
      multiLine: true,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(input)) {
      // Add plain text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: input.substring(lastEnd, match.start)));
      }

      final matchedText = match.group(0)!;

      if (matchedText == '\n') {
        spans.add(const TextSpan(text: '\n'));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        // Bold
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        // Italic
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (matchedText.startsWith('~') && matchedText.endsWith('~')) {
        // Strikethrough
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        // Code
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              matchedText.substring(1, matchedText.length - 1),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize - 1,
                color: textColor,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastEnd)));
    }

    return spans;
  }
}

/// Input için format toolbar widget
class FormatToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFormatApplied;

  const FormatToolbar({
    super.key,
    required this.controller,
    this.onFormatApplied,
  });

  void _applyFormat(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isCollapsed) {
      // Hiçbir şey seçili değil, cursor'a ekle
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length,
        ),
      );
    } else {
      // Seçili metin var
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + selectedText.length,
        ),
      );
    }
    onFormatApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          _FormatButton(
            icon: Icons.format_bold,
            tooltip: 'Kalın (*text*)',
            color: iconColor,
            onTap: () => _applyFormat('*', '*'),
          ),
          _FormatButton(
            icon: Icons.format_italic,
            tooltip: 'İtalik (_text_)',
            color: iconColor,
            onTap: () => _applyFormat('_', '_'),
          ),
          _FormatButton(
            icon: Icons.strikethrough_s,
            tooltip: 'Üstü çizili (~text~)',
            color: iconColor,
            onTap: () => _applyFormat('~', '~'),
          ),
          _FormatButton(
            icon: Icons.code,
            tooltip: 'Kod (`code`)',
            color: iconColor,
            onTap: () => _applyFormat('`', '`'),
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
