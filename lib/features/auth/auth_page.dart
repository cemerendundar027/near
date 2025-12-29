import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme.dart';
import '../../shared/auth_service.dart';

class AuthPage extends StatefulWidget {
  static const route = '/auth';
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _auth = AuthService.instance;

  bool _isLoading = false;
  bool _codeSent = false;
  bool _useEmail = true; // Email auth varsayılan (OTP için SMS kurulumu gerekli)
  bool _isLogin = true; // Giriş mi, kayıt mı
  String _selectedCountry = 'TR';
  String _countryCode = '+90';

  final List<_Country> _countries = const [
    _Country(code: 'TR', dial: '+90', name: 'Türkiye', flag: '🇹🇷'),
    _Country(code: 'US', dial: '+1', name: 'ABD', flag: '🇺🇸'),
    _Country(code: 'GB', dial: '+44', name: 'İngiltere', flag: '🇬🇧'),
    _Country(code: 'DE', dial: '+49', name: 'Almanya', flag: '🇩🇪'),
    _Country(code: 'FR', dial: '+33', name: 'Fransa', flag: '🇫🇷'),
    _Country(code: 'NL', dial: '+31', name: 'Hollanda', flag: '🇳🇱'),
    _Country(code: 'AZ', dial: '+994', name: 'Azerbaycan', flag: '🇦🇿'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _toast('Geçerli bir telefon numarası girin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullPhone = '$_countryCode$phone';
      await _auth.sendOTP(fullPhone);
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _codeSent = true;
      });
      _toast('Doğrulama kodu gönderildi');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(_auth.getErrorMessage(e));
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _toast('6 haneli kodu girin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final fullPhone = '$_countryCode$phone';
      
      final response = await _auth.verifyOTP(
        phone: fullPhone,
        token: code,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.user != null) {
        // Yeni kullanıcı mı kontrol et
        final profile = await _auth.getCurrentProfile();
        if (profile == null || profile['full_name'] == null) {
          _showProfileSetup();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(_auth.getErrorMessage(e));
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _toast('Geçerli bir email girin');
      return;
    }
    if (password.length < 6) {
      _toast('Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthResponse response;
      
      if (_isLogin) {
        response = await _auth.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        response = await _auth.signUpWithEmail(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.user != null) {
        if (_isLogin) {
          context.go('/');
        } else {
          // Yeni kayıt - profil oluştur
          _showProfileSetup();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast(_auth.getErrorMessage(e));
    }
  }

  void _showProfileSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _ProfileSetupSheet(
        onComplete: (name) {
          Navigator.pop(ctx);
          context.go('/');
        },
      ),
    );
  }

  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
              child: Text(
                'Ülke Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (_, i) {
                  final c = _countries[i];
                  final selected = c.code == _selectedCountry;

                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      c.dial,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: NearTheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCountry = c.code;
                        _countryCode = c.dial;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _useEmail 
              ? (_isLogin ? 'Giriş Yap' : 'Kayıt Ol')
              : (_codeSent ? 'Kodu Doğrula' : 'Telefon Numarası'),
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: _codeSent
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: NearTheme.primary),
                onPressed: () => setState(() => _codeSent = false),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_useEmail) ...[
                // Email Auth UI
                Text(
                  _isLogin
                      ? 'E-posta adresiniz ve şifrenizle giriş yapın.'
                      : 'Hesap oluşturmak için bilgilerinizi girin.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Email input
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'E-posta',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password input
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Şifre',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle login/signup
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Hesabınız yok mu? Kayıt olun'
                          : 'Zaten hesabınız var mı? Giriş yapın',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Divider with "or"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'veya',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch to phone auth
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _useEmail = false),
                    icon: Icon(Icons.phone, color: NearTheme.primary),
                    label: Text(
                      'Telefon ile giriş yap',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (!_codeSent) ...[
                // Phone input
                Text(
                  'Telefon numaranızı girin. Doğrulama kodu göndereceğiz.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Country selector
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _countries
                              .firstWhere((c) => c.code == _selectedCountry)
                              .flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _countries
                                .firstWhere((c) => c.code == _selectedCountry)
                                .name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone number
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Text(
                          _countryCode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '5XX XXX XX XX',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Switch to email auth
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _useEmail = true),
                    icon: Icon(Icons.email_outlined, color: NearTheme.primary),
                    label: Text(
                      'E-posta ile giriş yap',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Code verification
                Text(
                  '$_countryCode ${_phoneController.text} numarasına gönderilen 6 haneli kodu girin.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Code input
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      letterSpacing: 16,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 24),

                // Resend
                Center(
                  child: TextButton(
                    onPressed: _sendCode,
                    child: Text(
                      'Kodu tekrar gönder',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_useEmail
                          ? _handleEmailAuth
                          : (_codeSent ? _verifyCode : _sendCode)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: NearTheme.primary.withAlpha(128),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          _useEmail
                              ? (_isLogin ? 'Giriş Yap' : 'Kayıt Ol')
                              : (_codeSent ? 'Doğrula' : 'Devam'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Terms
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Devam ederek ',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Kullanım Koşulları',
                        style: TextStyle(color: NearTheme.primary),
                      ),
                      const TextSpan(text: ' ve '),
                      TextSpan(
                        text: 'Gizlilik Politikası',
                        style: TextStyle(color: NearTheme.primary),
                      ),
                      const TextSpan(text: '\'nı kabul etmiş olursunuz.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Country {
  final String code;
  final String dial;
  final String name;
  final String flag;

  const _Country({
    required this.code,
    required this.dial,
    required this.name,
    required this.flag,
  });
}

class _ProfileSetupSheet extends StatefulWidget {
  final void Function(String name) onComplete;

  const _ProfileSetupSheet({required this.onComplete});

  @override
  State<_ProfileSetupSheet> createState() => _ProfileSetupSheetState();
}

class _ProfileSetupSheetState extends State<_ProfileSetupSheet> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _auth = AuthService.instance;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  bool _usernameAvailable = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim().toLowerCase();
    
    // Boşsa hata gösterme
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = false;
      });
      return;
    }

    // Format kontrolü
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');
    if (!regex.hasMatch(username)) {
      setState(() {
        _usernameError = 'Sadece harf, rakam ve alt çizgi kullanın (3-20 karakter)';
        _usernameAvailable = false;
      });
      return;
    }

    // Uniqueness kontrolü (debounce ile)
    _checkUsernameAvailability(username);
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _usernameError = 'Bu kullanıcı adı zaten alınmış';
          _usernameAvailable = false;
          _isCheckingUsername = false;
        });
      } else {
        setState(() {
          _usernameError = null;
          _usernameAvailable = true;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  void _complete() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İsminizi girin')),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı girin')),
      );
      return;
    }

    if (!_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir kullanıcı adı seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Profili username ve username_changed_at ile güncelle
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'full_name': name,
          'username': username,
          'username_changed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      widget.onComplete(name);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil oluşturulamadı: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                'Profilini Oluştur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İsmin diğer kullanıcılara görünecek',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // Avatar
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Name input
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'İsminiz',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: NearTheme.primary,
                  ),
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

              // Username input
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                autocorrect: false,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: NearTheme.primary,
                  ),
                  prefixText: '@',
                  prefixStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameAvailable
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _usernameError != null
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                  errorText: _usernameError,
                  helperText: 'Twitter gibi, insanlar seni bu isimle arayabilir',
                  helperStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Tamamla',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
