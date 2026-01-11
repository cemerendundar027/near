import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'device_service.dart';

/// Authentication servisi - Supabase Auth ile entegre
///
/// Desteklenen auth flowları:
/// 1. Kayıt: Telefon + Şifre + SMS OTP doğrulama
/// 2. Giriş: Telefon + Şifre
class AuthService {
  AuthService._() {
    _setupAuthListener();
  }
  static final AuthService instance = AuthService._();

  final _supabase = SupabaseService.instance;
  final _deviceService = DeviceService.instance;

  /// Mevcut kullanıcı
  User? get currentUser => _supabase.currentUser;

  /// Kullanıcı ID'si
  String? get userId => currentUser?.id;

  /// Oturum açık mı?
  bool get isAuthenticated => currentUser != null;

  /// Email doğrulanmış mı?
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Telefon doğrulanmış mı?
  bool get isPhoneVerified => currentUser?.phoneConfirmedAt != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  /// Auth listener kurulumu
  void _setupAuthListener() {
    authStateChanges.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // Login olduğunda device session kaydet
        _deviceService.saveDeviceSession();
        debugPrint('AuthService: User signed in, session saved');
      } else if (event == AuthChangeEvent.signedOut) {
        // Logout olduğunda session'ı temizle
        _deviceService.removeCurrentSession();
        debugPrint('AuthService: User signed out, session removed');
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Token yenilendiğinde aktiviteyi güncelle
        _deviceService.updateSessionActivity();
        debugPrint('AuthService: Token refreshed, session updated');
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KAYIT (SIGNUP) - Telefon + Şifre + SMS OTP Doğrulama
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telefon + Şifre ile kayıt ol, SMS OTP gönderir
  Future<void> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // Telefon numarası ile kayıt ol ve OTP gönder
      await _supabase.auth.signUp(phone: phone, password: password);
      debugPrint('User signed up with phone: $phone, OTP sent');
    } catch (e) {
      debugPrint('Sign up with phone error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TELEFON DOĞRULAMA (SMS OTP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telefon numarasına OTP gönder (kayıt veya doğrulama için)
  Future<void> sendOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      debugPrint('OTP sent to $phone');
    } catch (e) {
      debugPrint('OTP send error: $e');
      rethrow;
    }
  }

  /// OTP doğrula
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      debugPrint('OTP verified for $phone');

      // Telefon numarasını profiles tablosuna kaydet
      if (response.user != null) {
        try {
          await _supabase.client
              .from('profiles')
              .update({'phone': phone})
              .eq('id', response.user!.id);
          debugPrint('Phone number saved to profile: $phone');
        } catch (e) {
          debugPrint('Error saving phone to profile: $e');
        }
      }

      return response;
    } catch (e) {
      debugPrint('OTP verify error: $e');
      rethrow;
    }
  }

  /// Mevcut kullanıcının telefonunu güncelle ve doğrulama kodu gönder
  Future<void> updatePhoneNumber(String phone) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(phone: phone));
      debugPrint('Phone update OTP sent to $phone');
    } catch (e) {
      debugPrint('Phone update error: $e');
      rethrow;
    }
  }

  /// Telefon değişikliği OTP doğrula
  Future<AuthResponse> verifyPhoneChange({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.phoneChange,
      );
      debugPrint('Phone change verified for $phone');
      return response;
    } catch (e) {
      debugPrint('Phone change verify error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GİRİŞ (LOGIN) - Telefon + Şifre
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telefon ile giriş yap (şifre ile)
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      debugPrint('User signed in with phone: ${response.user?.phone}');
      return response;
    } catch (e) {
      debugPrint('Phone sign in error: $e');
      rethrow;
    }
  }

  /// SMS OTP ile kayıt sonrası tekrar kod gönder
  Future<void> resendOTP(String phone) async {
    try {
      await _supabase.auth.resend(type: OtpType.sms, phone: phone);
      debugPrint('OTP resent to $phone');
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOSYAL GİRİŞ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Google ile giriş
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.near://login-callback/',
      );
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  /// Apple ile giriş
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.near://login-callback/',
      );
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OTURUM YÖNETİMİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Çıkış yap
  Future<void> signOut() async {
    try {
      // Önce device session'ı temizle
      await _deviceService.removeCurrentSession();

      // Sonra auth signout
      await _supabase.auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Profil güncelle
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Auth user metadata güncelle
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (username != null) 'username': username,
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );

      // Profiles tablosunu da güncelle
      await _supabase.client
          .from('profiles')
          .update({
            if (username != null) 'username': username,
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      debugPrint('Profile updated');
    } catch (e) {
      debugPrint('Profile update error: $e');
      rethrow;
    }
  }

  /// Mevcut kullanıcının profilini getir
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Get profile error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // YARDIMCI METODLAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hata mesajını kullanıcı dostu hale getir
  String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Telefon numarası veya şifre hatalı';
        case 'Phone not confirmed':
          return 'Telefon numaranızı doğrulayın';
        case 'User already registered':
          return 'Bu telefon numarası zaten kayıtlı';
        case 'Invalid OTP':
          return 'Doğrulama kodu hatalı';
        case 'OTP expired':
          return 'Doğrulama kodunun süresi doldu';
        default:
          return error.message;
      }
    }
    return 'Bir hata oluştu: $error';
  }
}
