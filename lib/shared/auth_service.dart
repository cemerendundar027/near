import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication servisi - Supabase Auth ile entegre
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = SupabaseService.instance;

  /// Mevcut kullanıcı
  User? get currentUser => _supabase.currentUser;

  /// Kullanıcı ID'si
  String? get userId => currentUser?.id;

  /// Oturum açık mı?
  bool get isAuthenticated => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // ═══════════════════════════════════════════════════════════════════════════
  // TELEFON İLE AUTH (OTP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Telefon numarasına OTP gönder
  Future<void> sendOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
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
      return response;
    } catch (e) {
      debugPrint('OTP verify error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMAIL İLE AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Email ile kayıt ol
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
          'full_name': fullName,
        },
      );
      debugPrint('User signed up: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  /// Email ile giriş yap
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  /// Şifre sıfırlama emaili gönder
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Password reset error: $e');
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
      await _supabase.client.from('profiles').update({
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

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
          return 'Email veya şifre hatalı';
        case 'Email not confirmed':
          return 'Email adresinizi doğrulayın';
        case 'User already registered':
          return 'Bu email zaten kayıtlı';
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
