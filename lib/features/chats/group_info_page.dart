import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/disappearing_messages.dart';
import 'media_gallery_page.dart';

/// Grup Bilgi/Detay Sayfası
/// - Grup avatar ve isim
/// - Üye listesi
/// - Yöneticiler
/// - Medya/Linkler/Belgeler
/// - Grup ayarları
class GroupInfoPage extends StatefulWidget {
  static const route = '/group-info';

  final String groupId;
  final String groupName;
  final String? groupAvatar;
  final List<GroupMember> members;

  const GroupInfoPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    this.members = const [],
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late List<GroupMember> _members;
  String _groupDescription = 'Aile ve arkadaşlarla iletişimde kalın 💬';
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _members = widget.members.isNotEmpty
        ? widget.members
        : [
            GroupMember(id: 'u1', name: 'Sen', isAdmin: true, isMe: true),
            GroupMember(id: 'u2', name: 'Ahmet', phone: '+90 555 111 22 33'),
            GroupMember(
              id: 'u3',
              name: 'Ayşe',
              phone: '+90 555 222 33 44',
              isAdmin: true,
            ),
            GroupMember(id: 'u4', name: 'Mehmet', phone: '+90 555 333 44 55'),
            GroupMember(id: 'u5', name: 'Fatma', phone: '+90 555 444 55 66'),
          ];
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

  void _showMessageSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Mesajlarda ara...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (query) {
                  Navigator.pop(ctx);
                  if (query.isNotEmpty) {
                    _showSnackBar('Arıyor: $query');
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditGroupName() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: widget.groupName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grup Adını Düzenle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 25,
                decoration: InputDecoration(
                  hintText: 'Grup adı',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnackBar('Grup adı güncellendi');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDescription() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: _groupDescription);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Grup Açıklaması', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Açıklama girin...',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _groupDescription = controller.text);
                    Navigator.pop(ctx);
                    _showSnackBar('Açıklama güncellendi');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openMediaGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(chatId: widget.groupId, chatName: widget.groupName),
      ),
    );
  }

  void _showDisappearingMessagesSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DisappearingMessagesSheet(
        currentDuration: Duration.zero,
        onDurationChanged: (duration) {
          Navigator.pop(context);
          _showSnackBar(duration == Duration.zero 
            ? 'Kaybolan mesajlar kapatıldı' 
            : 'Kaybolan mesajlar ayarlandı');
        },
      ),
    );
  }

  void _showMemberSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    List<GroupMember> filteredMembers = List.from(_members);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
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
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Üye ara...',
                      prefixIcon: Icon(Icons.search, color: NearTheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredMembers = _members
                            .where((m) => m.name.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: NearTheme.primary.withAlpha(30),
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: TextStyle(
                              color: NearTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: member.isAdmin
                            ? Text(
                                'Yönetici',
                                style: TextStyle(
                                  color: NearTheme.primary,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: member.isOnline
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _showMemberOptions(member);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportGroupDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
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
              const SizedBox(height: 16),
              Text(
                'Grubu Şikayet Et',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _ReportOption(
                icon: Icons.warning_rounded,
                label: 'Spam veya kötüye kullanım',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.person_off_rounded,
                label: 'Sahte grup',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.no_adult_content_rounded,
                label: 'Uygunsuz içerik',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.more_horiz_rounded,
                label: 'Diğer',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberOptions(GroupMember member) {
    if (member.isMe) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
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
              const SizedBox(height: 16),
              // Member info
              CircleAvatar(
                radius: 30,
                backgroundColor: NearTheme.primary.withAlpha(30),
                child: Text(
                  member.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: NearTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (member.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  member.phone!,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Options
              _OptionTile(
                icon: Icons.message_rounded,
                label: '${member.name} ile mesajlaş',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Sohbet açılıyor...');
                },
              ),
              _OptionTile(
                icon: Icons.call_rounded,
                label: 'Sesli arama',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Aranıyor...');
                },
              ),
              _OptionTile(
                icon: Icons.videocam_rounded,
                label: 'Görüntülü arama',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Video arama başlatılıyor...');
                },
              ),
              _OptionTile(
                icon: Icons.person_rounded,
                label: 'Profili görüntüle',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Profil açılıyor...');
                },
              ),
              if (!member.isAdmin)
                _OptionTile(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Yönetici yap',
                  onTap: () {
                    setState(() {
                      final idx = _members.indexWhere((m) => m.id == member.id);
                      if (idx != -1) {
                        _members[idx] = GroupMember(
                          id: member.id,
                          name: member.name,
                          phone: member.phone,
                          isAdmin: true,
                        );
                      }
                    });
                    Navigator.pop(context);
                    _showSnackBar('${member.name} artık yönetici');
                  },
                ),
              _OptionTile(
                icon: Icons.remove_circle_rounded,
                label: 'Gruptan çıkar',
                color: Colors.red,
                onTap: () {
                  setState(() {
                    _members.removeWhere((m) => m.id == member.id);
                  });
                  Navigator.pop(context);
                  _showSnackBar('${member.name} gruptan çıkarıldı');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMembers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Üye Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...['Ali Veli', 'Zeynep Kara', 'Can Yılmaz'].map((name) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: NearTheme.primary.withValues(alpha: 0.2),
                  child: Text(name[0], style: TextStyle(color: NearTheme.primary)),
                ),
                title: Text(name),
                trailing: IconButton(
                  icon: Icon(Icons.add_circle, color: NearTheme.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _members.add(GroupMember(
                        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        isAdmin: false,
                      ));
                    });
                    _showSnackBar('$name gruba eklendi');
                  },
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitGroupDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Gruptan Çık',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          '"${widget.groupName}" grubundan çıkmak istediğinize emin misiniz?',
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
              Navigator.pop(context);
              _showSnackBar('Gruptan çıkıldı');
            },
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final admins = _members.where((m) => m.isAdmin).toList();
    final regularMembers = _members.where((m) => !m.isAdmin).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // App Bar with Group Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _showEditGroupName,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [NearTheme.primary, NearTheme.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Group Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Group Name
                      Text(
                        widget.groupName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_members.length} katılımcı',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Actions
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Sesli',
                    onTap: () => context.push('/call/${widget.groupId}?video=false'),
                  ),
                  _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Görüntülü',
                    onTap: () => context.push('/call/${widget.groupId}?video=true'),
                  ),
                  _ActionButton(
                    icon: Icons.search_rounded,
                    label: 'Ara',
                    onTap: () => _showMessageSearch(),
                  ),
                  _ActionButton(
                    icon: _isMuted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_rounded,
                    label: _isMuted ? 'Aç' : 'Sessize Al',
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      _showSnackBar(
                        _isMuted ? 'Sessize alındı' : 'Bildirimler açıldı',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Description
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grup Açıklaması',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: NearTheme.primary,
                        ),
                        onPressed: () => _showEditDescription(),
                      ),
                    ],
                  ),
                  Text(
                    _groupDescription,
                    style: TextStyle(fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sen tarafından oluşturuldu, 15 Aralık 2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Media, Links, Docs
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: NearTheme.primary,
                  ),
                ),
                title: Text(
                  'Medya, Bağlantılar, Belgeler',
                  style: TextStyle(color: cs.onSurface),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '120',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
                onTap: () => _openMediaGallery(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Starred Messages
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber),
                ),
                title: Text(
                  'Yıldızlı Mesajlar',
                  style: TextStyle(color: cs.onSurface),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                onTap: () => context.push('/starred'),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Disappearing Messages
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_rounded, color: Colors.blue),
                ),
                title: Text(
                  'Kaybolan Mesajlar',
                  style: TextStyle(color: cs.onSurface),
                ),
                subtitle: Text(
                  'Kapalı',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                onTap: () => _showDisappearingMessagesSettings(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Members Header
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_members.length} Katılımcı',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NearTheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: NearTheme.primary),
                    onPressed: _showMemberSearch,
                  ),
                ],
              ),
            ),
          ),

          // Add Member
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: NearTheme.primary.withAlpha(30),
                  child: Icon(
                    Icons.person_add_rounded,
                    color: NearTheme.primary,
                  ),
                ),
                title: Text(
                  'Katılımcı Ekle',
                  style: TextStyle(
                    color: NearTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: _showAddMembers,
              ),
            ),
          ),

          // Group Link
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withAlpha(30),
                  child: const Icon(Icons.link_rounded, color: Colors.green),
                ),
                title: Text(
                  'Bağlantıyla Davet Et',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'https://near.app/group/abc123'),
                  );
                  _showSnackBar('Grup linki kopyalandı');
                },
              ),
            ),
          ),

          // Admins Section
          if (admins.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Yöneticiler',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final member = admins[index];
                return Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: _MemberTile(
                    member: member,
                    onTap: () => _showMemberOptions(member),
                  ),
                );
              }, childCount: admins.length),
            ),
          ],

          // Regular Members Section
          if (regularMembers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Üyeler',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final member = regularMembers[index];
                return Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: _MemberTile(
                    member: member,
                    onTap: () => _showMemberOptions(member),
                  ),
                );
              }, childCount: regularMembers.length),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Exit Group
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Gruptan Çık',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _showExitGroupDialog,
              ),
            ),
          ),

          // Report Group
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: const Icon(
                  Icons.thumb_down_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Grubu Şikayet Et',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _showReportGroupDialog,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class GroupMember {
  final String id;
  final String name;
  final String? phone;
  final String? avatar;
  final bool isAdmin;
  final bool isMe;
  final bool isOnline;

  const GroupMember({
    required this.id,
    required this.name,
    this.phone,
    this.avatar,
    this.isAdmin = false,
    this.isMe = false,
    this.isOnline = false,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: NearTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NearTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: NearTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? Colors.white70 : Colors.black87);

    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: NearTheme.primary.withAlpha(30),
            child: Text(
              member.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: NearTheme.primary,
              ),
            ),
          ),
          if (member.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            member.isMe ? 'Sen' : member.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (member.isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: NearTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Yönetici',
                style: TextStyle(
                  fontSize: 10,
                  color: NearTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: member.phone != null
          ? Text(
              member.phone!,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            )
          : null,
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReportOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
    );
  }
}
