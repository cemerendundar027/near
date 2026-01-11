import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NearThemeMode { system, light, dark }

enum NearWallpaper { none, softPurple, graphite }

/// Wallpaper türü
enum WallpaperType { none, solidColor, gradient }

/// Wallpaper ayarı
class WallpaperSetting {
  final WallpaperType type;
  final Color? solidColor;
  final LinearGradient? gradient;

  const WallpaperSetting({
    this.type = WallpaperType.none,
    this.solidColor,
    this.gradient,
  });

  static const WallpaperSetting none = WallpaperSetting(
    type: WallpaperType.none,
  );

  factory WallpaperSetting.solid(Color color) {
    return WallpaperSetting(type: WallpaperType.solidColor, solidColor: color);
  }

  factory WallpaperSetting.withGradient(LinearGradient gradient) {
    return WallpaperSetting(type: WallpaperType.gradient, gradient: gradient);
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  NearThemeMode themeMode = NearThemeMode.system;
  NearWallpaper wallpaper = NearWallpaper.none;

  // Yeni wallpaper sistemi
  WallpaperSetting chatWallpaper = WallpaperSetting.none;

  // 0.90 - 1.20 arası
  double fontScale = 1.0;

  // Bildirim ayarları
  bool notificationsEnabled = true;
  bool messagePreview = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // Onboarding durumu
  bool onboardingCompleted = false;

  // Gizlilik ayarları
  String lastSeenPrivacy = 'everyone'; // everyone, contacts, nobody
  String profilePhotoPrivacy = 'everyone';
  String aboutPrivacy = 'everyone';
  bool readReceipts = true;

  // Erişilebilirlik
  bool reduceMotion = false;
  bool highContrast = false;
  bool largeText = false;

  /// SharedPreferences'ı yükle ve ayarları geri al
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _initialized = true;
    notifyListeners();
  }

  void _loadSettings() {
    if (_prefs == null) return;

    // Tema
    final themeModeIndex = _prefs!.getInt('themeMode') ?? 0;
    themeMode = NearThemeMode.values[themeModeIndex.clamp(0, 2)];

    // Font
    fontScale = _prefs!.getDouble('fontScale') ?? 1.0;

    // Wallpaper
    final wallpaperIndex = _prefs!.getInt('wallpaper') ?? 0;
    wallpaper = NearWallpaper.values[wallpaperIndex.clamp(0, 2)];

    // Chat Wallpaper
    final wallpaperType = _prefs!.getInt('chatWallpaperType') ?? 0;
    if (wallpaperType == 1) {
      final colorValue = _prefs!.getInt('chatWallpaperColor');
      if (colorValue != null) {
        chatWallpaper = WallpaperSetting.solid(Color(colorValue));
      }
    }

    // Bildirimler
    notificationsEnabled = _prefs!.getBool('notificationsEnabled') ?? true;
    messagePreview = _prefs!.getBool('messagePreview') ?? true;
    soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
    vibrationEnabled = _prefs!.getBool('vibrationEnabled') ?? true;

    // Gizlilik
    lastSeenPrivacy = _prefs!.getString('lastSeenPrivacy') ?? 'everyone';
    profilePhotoPrivacy = _prefs!.getString('profilePhotoPrivacy') ?? 'everyone';
    aboutPrivacy = _prefs!.getString('aboutPrivacy') ?? 'everyone';
    readReceipts = _prefs!.getBool('readReceipts') ?? true;

    // Erişilebilirlik
    reduceMotion = _prefs!.getBool('reduceMotion') ?? false;
    highContrast = _prefs!.getBool('highContrast') ?? false;
    largeText = _prefs!.getBool('largeText') ?? false;

    // Onboarding
    onboardingCompleted = _prefs!.getBool('onboardingCompleted') ?? false;
  }

  Future<void> _save(String key, dynamic value) async {
    if (_prefs == null) return;
    if (value is int) {
      await _prefs!.setInt(key, value);
    } else if (value is double) {
      await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is String) {
      await _prefs!.setString(key, value);
    }
  }

  void setThemeMode(NearThemeMode m) {
    themeMode = m;
    _save('themeMode', m.index);
    notifyListeners();
  }

  void setWallpaper(NearWallpaper w) {
    wallpaper = w;
    _save('wallpaper', w.index);
    notifyListeners();
  }

  void setChatWallpaper(WallpaperSetting w) {
    chatWallpaper = w;
    _save('chatWallpaperType', w.type.index);
    notifyListeners();
  }

  void setChatWallpaperColor(Color color) {
    chatWallpaper = WallpaperSetting.solid(color);
    _save('chatWallpaperType', 1);
    _save('chatWallpaperColor', color.toARGB32());
    notifyListeners();
  }

  void setChatWallpaperGradient(LinearGradient gradient) {
    chatWallpaper = WallpaperSetting.withGradient(gradient);
    _save('chatWallpaperType', 2);
    notifyListeners();
  }

  void clearChatWallpaper() {
    chatWallpaper = WallpaperSetting.none;
    _save('chatWallpaperType', 0);
    notifyListeners();
  }

  void setFontScale(double v) {
    fontScale = v.clamp(0.90, 1.20);
    _save('fontScale', fontScale);
    notifyListeners();
  }

  // Bildirim ayarları
  void setNotificationsEnabled(bool v) {
    notificationsEnabled = v;
    _save('notificationsEnabled', v);
    notifyListeners();
  }

  void setMessagePreview(bool v) {
    messagePreview = v;
    _save('messagePreview', v);
    notifyListeners();
  }

  void setSoundEnabled(bool v) {
    soundEnabled = v;
    _save('soundEnabled', v);
    notifyListeners();
  }

  void setVibrationEnabled(bool v) {
    vibrationEnabled = v;
    _save('vibrationEnabled', v);
    notifyListeners();
  }

  // Gizlilik ayarları
  void setLastSeenPrivacy(String v) {
    lastSeenPrivacy = v;
    _save('lastSeenPrivacy', v);
    notifyListeners();
  }

  void setProfilePhotoPrivacy(String v) {
    profilePhotoPrivacy = v;
    _save('profilePhotoPrivacy', v);
    notifyListeners();
  }

  void setAboutPrivacy(String v) {
    aboutPrivacy = v;
    _save('aboutPrivacy', v);
    notifyListeners();
  }

  void setReadReceipts(bool v) {
    readReceipts = v;
    _save('readReceipts', v);
    notifyListeners();
  }

  // Erişilebilirlik
  void setReduceMotion(bool v) {
    reduceMotion = v;
    _save('reduceMotion', v);
    notifyListeners();
  }

  void setHighContrast(bool v) {
    highContrast = v;
    _save('highContrast', v);
    notifyListeners();
  }

  void setLargeText(bool v) {
    largeText = v;
    _save('largeText', v);
    notifyListeners();
  }

  // Onboarding
  void setOnboardingCompleted(bool v) {
    onboardingCompleted = v;
    _save('onboardingCompleted', v);
    notifyListeners();
  }
}
