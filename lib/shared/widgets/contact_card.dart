import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Paylaşılabilir kişi kartı widget'ı
class ContactCard extends StatelessWidget {
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;

  const ContactCard({
    super.key,
    required this.name,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.status,
    this.onTap,
    this.onSave,
    this.onMessage,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NearTheme.primary,
                    NearTheme.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withAlpha(50),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            status!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(180),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (phoneNumber != null)
                    _ContactInfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Telefon',
                      value: phoneNumber!,
                      isDark: isDark,
                    ),
                  if (email != null) ...[
                    const SizedBox(height: 12),
                    _ContactInfoRow(
                      icon: Icons.email_rounded,
                      label: 'E-posta',
                      value: email!,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(5)
                    : Colors.grey.withAlpha(20),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Kaydet',
                    onTap: onSave,
                    isDark: isDark,
                  ),
                  _ActionButton(
                    icon: Icons.message_rounded,
                    label: 'Mesaj',
                    onTap: onMessage,
                    isDark: isDark,
                    isPrimary: true,
                  ),
                  _ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Ara',
                    onTap: onCall,
                    isDark: isDark,
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

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: NearTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: NearTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPrimary
                    ? NearTheme.primary
                    : (isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                color: isPrimary
                    ? NearTheme.primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact kişi kartı - sohbet içinde gösterilir
class CompactContactCard extends StatelessWidget {
  final String name;
  final String? phoneNumber;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const CompactContactCard({
    super.key,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: NearTheme.primary.withAlpha(40),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: NearTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: NearTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kişi',
                        style: TextStyle(
                          fontSize: 11,
                          color: NearTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phoneNumber != null)
                    Text(
                      phoneNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
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

/// Kişi seçme sayfası
class ContactPickerSheet extends StatelessWidget {
  final List<Map<String, String>> contacts;
  final Function(Map<String, String>) onContactSelected;

  const ContactPickerSheet({
    super.key,
    required this.contacts,
    required this.onContactSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                Text(
                  'Kişi Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Kişi ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact list
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: NearTheme.primary.withAlpha(40),
                    child: Text(
                      (contact['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(contact['name'] ?? ''),
                  subtitle: Text(contact['phone'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    onContactSelected(contact);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
