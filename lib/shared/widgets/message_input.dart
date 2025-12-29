import 'package:flutter/material.dart';

/// Enhanced message input bar with attachment options
class MessageInputBar extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onSend;
  final VoidCallback? onAttachment;
  final VoidCallback? onCamera;
  final VoidCallback? onVoiceRecord;
  final VoidCallback? onEmoji;
  final void Function(String)? onChanged;
  final bool showEmoji;
  final String? replyTo;
  final VoidCallback? onCancelReply;
  final bool isRecording;

  const MessageInputBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onSend,
    this.onAttachment,
    this.onCamera,
    this.onVoiceRecord,
    this.onEmoji,
    this.onChanged,
    this.showEmoji = false,
    this.replyTo,
    this.onCancelReply,
    this.isRecording = false,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyTo != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: Border(
                    left: const BorderSide(color: Color(0xFF7B3FF2), width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yanıtlanıyor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7B3FF2),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.replyTo!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancelReply,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Emoji button
                  IconButton(
                    onPressed: widget.onEmoji,
                    icon: Icon(
                      widget.showEmoji
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: widget.focusNode,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Mesaj',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          // Attachment button
                          IconButton(
                            onPressed: widget.onAttachment,
                            icon: Icon(
                              Icons.attach_file,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          // Camera button (only when no text)
                          if (!_hasText)
                            IconButton(
                              onPressed: widget.onCamera,
                              icon: Icon(
                                Icons.camera_alt_outlined,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send or Voice button
                  GestureDetector(
                    onTap: _hasText ? widget.onSend : null,
                    onLongPressStart: _hasText
                        ? null
                        : (_) => widget.onVoiceRecord?.call(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B3FF2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasText ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Attachment options bottom sheet
class AttachmentOptionsSheet extends StatelessWidget {
  final VoidCallback? onDocument;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onAudio;
  final VoidCallback? onLocation;
  final VoidCallback? onContact;

  const AttachmentOptionsSheet({
    super.key,
    this.onDocument,
    this.onCamera,
    this.onGallery,
    this.onAudio,
    this.onLocation,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Options grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Dosya',
                  color: const Color(0xFF7B61FF),
                  onTap: onDocument,
                ),
                _AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  color: const Color(0xFFE91E63),
                  onTap: onCamera,
                ),
                _AttachmentOption(
                  icon: Icons.photo,
                  label: 'Galeri',
                  color: const Color(0xFF9C27B0),
                  onTap: onGallery,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.headphones,
                  label: 'Ses',
                  color: const Color(0xFFFF5722),
                  onTap: onAudio,
                ),
                _AttachmentOption(
                  icon: Icons.location_on,
                  label: 'Konum',
                  color: const Color(0xFF4CAF50),
                  onTap: onLocation,
                ),
                _AttachmentOption(
                  icon: Icons.person,
                  label: 'Kişi',
                  color: const Color(0xFF2196F3),
                  onTap: onContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
