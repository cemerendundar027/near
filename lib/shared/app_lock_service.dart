import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama kilidi servisi
class AppLockService extends ChangeNotifier {
  static final AppLockService _instance = AppLockService._internal();
  static AppLockService get instance => _instance;
  AppLockService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _isLocked = false;
  bool _isEnabled = false;
  bool _useBiometric = true;
  String? _pin;
  int _lockAfterSeconds = 0; // 0 = anında
  DateTime? _lastPausedTime;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  bool get isLocked => _isLocked;
  bool get isEnabled => _isEnabled;
  bool get useBiometric => _useBiometric;
  bool get canCheckBiometrics => _canCheckBiometrics;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  int get lockAfterSeconds => _lockAfterSeconds;

  String get lockAfterText {
    switch (_lockAfterSeconds) {
      case 0: return 'Anında';
      case 30: return '30 saniye';
      case 60: return '1 dakika';
      case 300: return '5 dakika';
      case 900: return '15 dakika';
      case 3600: return '1 saat';
      case -1: return 'Hiçbir zaman';
      default: return '$_lockAfterSeconds saniye';
    }
  }

  /// Servisi başlat
  Future<void> init() async {
    try {
      _canCheckBiometrics = await _auth.canCheckBiometrics;
      
      if (_canCheckBiometrics) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
      }

      // Kayıtlı ayarları yükle
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _useBiometric = prefs.getBool('app_lock_biometric') ?? true;
      _pin = prefs.getString('app_lock_pin');
      _lockAfterSeconds = prefs.getInt('app_lock_after') ?? 0;
      
      // Eğer kilit aktifse ve PIN varsa, başlangıçta kilitle
      if (_isEnabled && _pin != null) {
        _isLocked = true;
      }

      debugPrint('AppLockService: initialized, enabled=$_isEnabled, canCheck=$_canCheckBiometrics');
      debugPrint('AppLockService: available biometrics: $_availableBiometrics');
      
      notifyListeners();
    } catch (e) {
      debugPrint('AppLockService: Error initializing: $e');
    }
  }

  /// Uygulama kilidini etkinleştir
  Future<void> enable({required String pin}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', true);
      await prefs.setString('app_lock_pin', pin);
      
      _isEnabled = true;
      _pin = pin;
      _isLocked = false;
      
      notifyListeners();
      debugPrint('AppLockService: enabled with PIN');
    } catch (e) {
      debugPrint('AppLockService: Error enabling: $e');
    }
  }

  /// Uygulama kilidini devre dışı bırak
  Future<void> disable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_enabled', false);
      await prefs.remove('app_lock_pin');
      
      _isEnabled = false;
      _pin = null;
      _isLocked = false;
      
      notifyListeners();
      debugPrint('AppLockService: disabled');
    } catch (e) {
      debugPrint('AppLockService: Error disabling: $e');
    }
  }

  /// PIN değiştir
  Future<void> changePin(String newPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lock_pin', newPin);
      _pin = newPin;
      notifyListeners();
      debugPrint('AppLockService: PIN changed');
    } catch (e) {
      debugPrint('AppLockService: Error changing PIN: $e');
    }
  }

  /// Biyometrik ayarını değiştir
  Future<void> setBiometric(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_lock_biometric', enabled);
      _useBiometric = enabled;
      notifyListeners();
      debugPrint('AppLockService: biometric=$enabled');
    } catch (e) {
      debugPrint('AppLockService: Error setting biometric: $e');
    }
  }

  /// Kilit gecikmesini ayarla
  Future<void> setLockAfter(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_lock_after', seconds);
      _lockAfterSeconds = seconds;
      notifyListeners();
      debugPrint('AppLockService: lock after $seconds seconds');
    } catch (e) {
      debugPrint('AppLockService: Error setting lock after: $e');
    }
  }

  /// PIN ile kilidi aç
  bool unlockWithPin(String pin) {
    if (pin == _pin) {
      _isLocked = false;
      notifyListeners();
      debugPrint('AppLockService: unlocked with PIN');
      return true;
    }
    return false;
  }

  /// Biyometrik ile kilidi aç
  Future<bool> unlockWithBiometric() async {
    if (!_canCheckBiometrics || !_useBiometric) {
      return false;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Uygulamanın kilidini açmak için doğrulayın',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        _isLocked = false;
        notifyListeners();
        debugPrint('AppLockService: unlocked with biometric');
      }

      return authenticated;
    } catch (e) {
      debugPrint('AppLockService: Error with biometric: $e');
      return false;
    }
  }

  /// Uygulama arka plana geçince çağrılır
  void onAppPaused() {
    _lastPausedTime = DateTime.now();
    debugPrint('AppLockService: app paused');
  }

  /// Uygulama ön plana gelince çağrılır
  void onAppResumed() {
    if (!_isEnabled || _pin == null) return;
    
    // Hiçbir zaman kilitlenme
    if (_lockAfterSeconds == -1) return;
    
    // Süre kontrolü
    if (_lastPausedTime != null) {
      final elapsed = DateTime.now().difference(_lastPausedTime!).inSeconds;
      if (elapsed >= _lockAfterSeconds) {
        _isLocked = true;
        notifyListeners();
        debugPrint('AppLockService: locked after $elapsed seconds');
      }
    }
  }

  /// Uygulamayı manuel kilitle
  void lock() {
    if (_isEnabled && _pin != null) {
      _isLocked = true;
      notifyListeners();
      debugPrint('AppLockService: manually locked');
    }
  }
}
