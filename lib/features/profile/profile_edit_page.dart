import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../shared/widgets/image_editor.dart';
import '../../shared/auth_service.dart';
import '../../shared/supabase_service.dart';

class ProfileEditPage extends StatefulWidget {
  static const route = '/profile/edit';
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  String _phoneNumber = '';
  String? _email;
  String? _avatarUrl;
  String _username = '';
  final _picker = ImagePicker();
  
  final _authService = AuthService.instance;
  final _supabase = SupabaseService.instance;

  XFile? _pickedImage;
  bool _isEditingName = false;
  bool _isEditingAbout = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  
  final _nameFocusNode = FocusNode();
  final _aboutFocusNode = FocusNode();

  // Önceden tanımlı hakkında seçenekleri (WhatsApp tarzı)
  final List<String> _aboutPresets = [
    'Müsait',
    'Meşgul',
    'Okulda',
    'İşte',
    'Toplantıda',
    'Sadece acil aramalar',
    'Uyuyor 💤',
    'Şu an Near\'da! 🚀',
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onNameFocusChange);
    _aboutFocusNode.addListener(_onAboutFocusChange);
    _loadProfile();
  }

  /// Profil bilgilerini Supabase'den yükle
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _authService.getCurrentProfile();
      final user = _authService.currentUser;
      
      if (mounted && profile != null) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _username = profile['username'] ?? '';
          _aboutController.text = profile['bio'] ?? 'Hey there! I\'m using Near.';
          _avatarUrl = profile['avatar_url'];
          _phoneNumber = profile['phone'] ?? user?.phone ?? '';
          _email = user?.email;
          _isLoading = false;
        });
      } else if (mounted && user != null) {
        // Profil yoksa user metadata'dan al
        setState(() {
          _nameController.text = user.userMetadata?['full_name'] ?? '';
          _username = user.userMetadata?['username'] ?? '';
          _email = user.email;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _toast('Profil yüklenemedi');
      }
    }
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName) {
      setState(() => _isEditingName = false);
      _save();
    }
  }

  void _onAboutFocusChange() {
    if (!_aboutFocusNode.hasFocus && _isEditingAbout) {
      setState(() => _isEditingAbout = false);
      _save();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _nameFocusNode.dispose();
    _aboutFocusNode.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        // Fotoğrafı düzenleyicide aç (crop only mode)
        final editedFile = await ImageEditorPage.open(
          context,
          File(file.path),
          cropOnly: true,
        );
        
        if (editedFile != null && mounted) {
          setState(() => _pickedImage = XFile(editedFile.path));
          // Avatarı hemen yükle
          _uploadAvatar(editedFile);
        }
      }
    } catch (_) {
      if (!mounted) return;
      _toast('Fotoğraf seçilemedi. İzinleri kontrol edin.');
    }
  }

  /// Avatarı Supabase Storage'a yükle
  Future<void> _uploadAvatar(File imageFile) async {
    final userId = _authService.userId;
    if (userId == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      // Dosyayı byte'a çevir
      final bytes = await imageFile.readAsBytes();
      
      // Eski avatarları sil
      await _supabase.deleteOldAvatars(userId);
      
      // Yeni avatarı yükle
      final avatarUrl = await _supabase.uploadAvatar(userId, bytes);
      
      // Profili güncelle
      await _supabase.client.from('profiles').update({
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      // Auth metadata'yı da güncelle
      await _authService.updateProfile(avatarUrl: avatarUrl);
      
      if (mounted) {
        setState(() {
          _avatarUrl = avatarUrl;
          _isUploadingAvatar = false;
        });
        _toast('Profil fotoğrafı güncellendi');
      }
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _toast('Fotoğraf yüklenemedi: ${e.toString().split(':').last}');
      }
    }
  }

  void _showPhotoOptions() {
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
              const SizedBox(height: 20),

              // Başlık
              Text(
                'Profil Fotoğrafı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Seçenekler - yatay düzen
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PhotoOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      color: NearTheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _PhotoOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      color: NearTheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_pickedImage != null)
                      _PhotoOption(
                        icon: Icons.delete_rounded,
                        label: 'Kaldır',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _pickedImage = null);
                          _toast('Profil fotoğrafı kaldırıldı');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutPresets() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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

            // Başlık
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Hakkında Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

            // Preset listesi
            Expanded(
              child: ListView.builder(
                itemCount: _aboutPresets.length,
                itemBuilder: (context, index) {
                  final preset = _aboutPresets[index];
                  final isSelected = _aboutController.text == preset;

                  return ListTile(
                    onTap: () {
                      setState(() => _aboutController.text = preset);
                      Navigator.pop(context);
                      _save();
                    },
                    title: Text(
                      preset,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: NearTheme.primary)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    _saveToBackend();
    HapticFeedback.lightImpact();
  }

  /// Profil bilgilerini Supabase'e kaydet
  Future<void> _saveToBackend() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final userId = _authService.userId;
      if (userId == null) {
        _toast('Oturum açık değil');
        setState(() => _isSaving = false);
        return;
      }

      final updateData = {
        'full_name': _nameController.text.trim(),
        'bio': _aboutController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Telefon varsa ekle
      if (_phoneNumber.isNotEmpty) {
        updateData['phone'] = _phoneNumber;
      }

      await _supabase.client
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // Auth metadata'yı da güncelle
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
      );

      debugPrint('Profile saved to Supabase');
      if (mounted) {
        _toast('Profil güncellendi');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('duplicate') || errorMsg.contains('unique')) {
          _toast('Bu kullanıcı adı zaten kullanılıyor');
        } else {
          _toast('Kaydetme başarısız');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          title: Text('Profil', style: TextStyle(color: cs.onSurface)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        title: Text(
          'Profil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Profil Fotoğrafı
            Center(
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        border: Border.all(
                          color: NearTheme.primary.withAlpha(50),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploadingAvatar
                            ? Container(
                                width: 140,
                                height: 140,
                                color: isDark ? Colors.black26 : Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: NearTheme.primary,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : _pickedImage != null
                                ? Image.file(
                                    File(_pickedImage!.path),
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  )
                                : _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        _avatarUrl!,
                                        fit: BoxFit.cover,
                                        width: 140,
                                        height: 140,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 140,
                                            height: 140,
                                            color: isDark ? Colors.black26 : Colors.grey.shade200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: NearTheme.primary,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.person,
                                          size: 70,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 70,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey.shade600,
                                      ),
                      ),
                    ),
                    // Kamera ikonu
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: NearTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF000000)
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Profil Bilgileri
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Ad
                  _ProfileField(
                    icon: Icons.person_outline_rounded,
                    label: 'Ad',
                    value: _nameController.text,
                    hint: 'Adınızı girin',
                    isEditing: _isEditingName,
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    onTap: () {
                      setState(() => _isEditingName = true);
                      _nameFocusNode.requestFocus();
                    },
                    onEditingComplete: () {
                      setState(() => _isEditingName = false);
                      _save();
                    },
                    isDark: isDark,
                    maxLength: 25,
                    helperText: 'Bu ad kişilerinize görünür',
                  ),

                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),

                  // Hakkında
                  _ProfileField(
                    icon: Icons.info_outline_rounded,
                    label: 'Hakkında',
                    value: _aboutController.text,
                    hint: 'Hakkında bilgisi ekle',
                    isEditing: _isEditingAbout,
                    controller: _aboutController,
                    focusNode: _aboutFocusNode,
                    onTap: () {
                      setState(() => _isEditingAbout = true);
                      _aboutFocusNode.requestFocus();
                    },
                    onEditingComplete: () {
                      setState(() => _isEditingAbout = false);
                      _save();
                    },
                    isDark: isDark,
                    maxLength: 139,
                    showPresets: true,
                    onPresetsPressed: _showAboutPresets,
                  ),

                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),

                  _ProfileInfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Kullanıcı Adı',
                    value: _username.isNotEmpty ? '@$_username' : 'Henüz belirlenmedi',
                    isDark: isDark,
                  ),

                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),

                  // Email (salt okunur)
                  if (_email != null && _email!.isNotEmpty)
                    _ProfileInfoTile(
                      icon: Icons.email_outlined,
                      label: 'E-posta',
                      value: _email!,
                      isDark: isDark,
                    ),

                  if (_email != null && _email!.isNotEmpty)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),

                  // Telefon (salt okunur)
                  if (_phoneNumber.isNotEmpty)
                    _ProfileInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Telefon',
                      value: _phoneNumber,
                      isDark: isDark,
                    ),

                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bilgi notu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu bilgiler uçtan uca şifreli değildir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Fotoğraf seçeneği widget'ı
class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Profil alanı widget'ı
class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback onEditingComplete;
  final ValueChanged<String>? onChanged;
  final bool isDark;
  final int maxLength;
  final String? helperText;
  final bool showPresets;
  final VoidCallback? onPresetsPressed;
  final String? errorText;
  final bool isLoading;
  final bool enabled;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onEditingComplete,
    this.onChanged,
    required this.isDark,
    this.maxLength = 25,
    this.helperText,
    this.showPresets = false,
    this.onPresetsPressed,
    this.errorText,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: !enabled ? null : (isEditing ? null : onTap),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                icon,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isEditing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLength: maxLength,
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            counterStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                          onChanged: onChanged,
                          onEditingComplete: onEditingComplete,
                          cursorColor: NearTheme.primary,
                        ),
                        if (helperText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              helperText!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Text(
                      value.isEmpty ? hint : value,
                      style: TextStyle(
                        fontSize: 16,
                        color: value.isEmpty
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  if (errorText != null && isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        errorText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NearTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isEditing)
              Icon(Icons.edit, size: 18, color: NearTheme.primary),
            if (showPresets && !isEditing)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: onPresetsPressed,
                  child: Icon(
                    Icons.emoji_emotions_outlined,
                    size: 18,
                    color: NearTheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Profil salt okunur bilgi tile'ı
class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
