import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/countries.dart';
import '../../shared/auth_service.dart';
import '../../app/theme.dart';

/// Auth sayfası - Telefon + Şifre ile giriş/kayıt
///
/// Flow:
/// - Kayıt: Telefon + Şifre → SMS OTP → Profil Setup
/// - Giriş: Telefon + Şifre → Ana Sayfa
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = AuthService.instance;

  // Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _isLoading = false;
  bool _codeSent = false;
  bool _showPassword = false;
  String _errorMessage = '';
  String _pendingPhone = '';

  // Country
  Country _selectedCountry = allCountries.firstWhere(
    (c) => c.code == 'TR',
    orElse: () => allCountries.first,
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telefon + Şifre ile giriş yap
  Future<void> _signIn() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showError('Telefon numarası ve şifre gerekli');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final fullPhone = '${_selectedCountry.dial}$phone';
      await _auth.signInWithPhone(phone: fullPhone, password: password);

      if (!mounted) return;

      // Profil kontrolü
      final profile = await _auth.getCurrentProfile();
      if (!mounted) return;

      if (profile == null ||
          profile['full_name'] == null ||
          profile['username'] == null) {
        _showProfileSetup();
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      _showError(_auth.getErrorMessage(e));
    } catch (e) {
      _showError('Giriş başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Telefon + Şifre ile kayıt ol
  Future<void> _signUp() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty) {
      _showError('Telefon numarası gerekli');
      return;
    }

    if (password.isEmpty) {
      _showError('Şifre gerekli');
      return;
    }

    if (password.length < 6) {
      _showError('Şifre en az 6 karakter olmalı');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final fullPhone = '${_selectedCountry.dial}$phone';

      // Telefon + Şifre ile kayıt ol (OTP gönderir)
      await _auth.signUpWithPhone(phone: fullPhone, password: password);

      setState(() {
        _codeSent = true;
        _pendingPhone = fullPhone;
      });

      _showSuccess('SMS doğrulama kodu gönderildi');
    } on AuthException catch (e) {
      _showError(_auth.getErrorMessage(e));
    } catch (e) {
      _showError('Kayıt başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// SMS OTP kodu doğrula
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showError('6 haneli kodu girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.verifyOTP(phone: _pendingPhone, token: code);

      setState(() {
        _codeSent = false;
      });

      if (!mounted) return;

      // Profile setup'a git
      _showProfileSetup();
    } on AuthException catch (e) {
      _showError(_auth.getErrorMessage(e));
    } catch (e) {
      _showError('Doğrulama başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Kodu tekrar gönder
  Future<void> _resendCode() async {
    if (_pendingPhone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.resendOTP(_pendingPhone);
      _showSuccess('Doğrulama kodu tekrar gönderildi');
    } on AuthException catch (e) {
      _showError(_auth.getErrorMessage(e));
    } catch (e) {
      _showError('Kod gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Profile setup sheet göster
  void _showProfileSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileSetupSheet(
        onComplete: (name) {
          Navigator.pop(context);
          context.go('/');
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _resetState() {
    setState(() {
      _codeSent = false;
      _pendingPhone = '';
      _errorMessage = '';
      _codeController.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    // SMS OTP doğrulama ekranı
    if (_codeSent) {
      return _buildOTPVerification(isDark, cs);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama
              Text(
                _isLogin
                    ? 'Telefon numaranız ve şifrenizle giriş yapın.'
                    : 'Hesap oluşturmak için telefon numaranızı ve şifrenizi girin.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Telefon input
              _buildPhoneInput(isDark, cs),
              const SizedBox(height: 16),

              // Şifre input
              _buildPasswordField(isDark, cs),
              const SizedBox(height: 32),

              // Ana buton
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isLogin ? _signIn : _signUp),
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
                          _isLogin ? 'Giriş Yap' : 'Devam Et',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle giriş/kayıt
              Center(
                child: TextButton(
                  onPressed: () {
                    _resetState();
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: _isLogin
                          ? 'Hesabınız yok mu? '
                          : 'Zaten hesabınız var mı? ',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                          style: TextStyle(
                            color: NearTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

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

  /// OTP doğrulama ekranı
  Widget _buildOTPVerification(bool isDark, ColorScheme cs) {
    final phone = '${_selectedCountry.dial} ${_phoneController.text}';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: NearTheme.primary),
          onPressed: () => setState(() {
            _codeSent = false;
            _codeController.clear();
          }),
        ),
        title: Text(
          'Doğrulama',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$phone numarasına gönderilen 6 haneli kodu girin.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // OTP input
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

              // Tekrar gönder
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: Text(
                    'Kodu tekrar gönder',
                    style: TextStyle(
                      color: NearTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Doğrula butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
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
                      : const Text(
                          'Doğrula',
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

  /// Phone input with country selector
  Widget _buildPhoneInput(bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country selector
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _selectedCountry.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry.name,
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
        const SizedBox(height: 12),

        // Phone number
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
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
                  _selectedCountry.dial,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
      ],
    );
  }

  /// Password field
  Widget _buildPasswordField(bool isDark, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
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
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTRY PICKER SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onSelect;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _filteredCountries = allCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    setState(() {
      _filteredCountries = searchCountries(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ülke Seçin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ülke ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Popular countries header
          if (_searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popüler',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: popularCountries.length,
                itemBuilder: (context, index) {
                  final country = popularCountries[index];
                  final isSelected =
                      country.code == widget.selectedCountry.code;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar: Text(country.flag),
                      label: Text(country.dial),
                      backgroundColor: isSelected
                          ? NearTheme.primary.withAlpha(30)
                          : null,
                      side: isSelected
                          ? BorderSide(color: NearTheme.primary)
                          : null,
                      onPressed: () => widget.onSelect(country),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 16),
          ],

          // Country list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? NearTheme.primary : cs.onSurface,
                    ),
                  ),
                  trailing: Text(
                    country.dial,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: NearTheme.primary.withAlpha(20),
                  onTap: () => widget.onSelect(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE SETUP SHEET (Yeni kullanıcı için)
// ═══════════════════════════════════════════════════════════════════════════

class ProfileSetupSheet extends StatefulWidget {
  final void Function(String name) onComplete;

  const ProfileSetupSheet({super.key, required this.onComplete});

  @override
  State<ProfileSetupSheet> createState() => _ProfileSetupSheetState();
}

class _ProfileSetupSheetState extends State<ProfileSetupSheet> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  bool _usernameAvailable = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    _debounce?.cancel();

    final username = _usernameController.text.trim().toLowerCase();

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
        _usernameError =
            'Sadece harf, rakam ve alt çizgi kullanın (3-20 karakter)';
        _usernameAvailable = false;
      });
      return;
    }

    // Debounce ile uniqueness kontrolü
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      final result = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', currentUserId ?? '')
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (result != null) {
          _usernameError = 'Bu kullanıcı adı zaten alınmış';
          _usernameAvailable = false;
        } else {
          _usernameError = null;
          _usernameAvailable = true;
        }
        _isCheckingUsername = false;
      });
    } catch (e) {
      debugPrint('Username check error: $e');
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _usernameAvailable = true; // Hata durumunda devam et
        });
      }
    }
  }

  void _complete() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İsminizi girin')));
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı adı girin')));
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
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'full_name': name,
              'username': username,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }

      if (!mounted) return;
      widget.onComplete(name);
    } catch (e) {
      debugPrint('ProfileSetup error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil kaydedilemedi: $e')));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

              // Avatar placeholder
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
                  helperText: 'İnsanlar seni bu isimle arayabilir',
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
