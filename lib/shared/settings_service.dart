import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings Service - Tüm uygulama ayarlarını kalıcı olarak saklar
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final instance = SettingsService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _showPreview = true;
  bool _vibrate = true;
  bool _sound = true;
  bool _inAppSounds = true;
  bool _inAppVibrate = true;

  bool get messageNotifications => _messageNotifications;
  bool get groupNotifications => _groupNotifications;
  bool get showPreview => _showPreview;
  bool get vibrate => _vibrate;
  bool get sound => _sound;
  bool get inAppSounds => _inAppSounds;
  bool get inAppVibrate => _inAppVibrate;

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool _enterToSend = true;
  bool _mediaVisibility = true;

  bool get enterToSend => _enterToSend;
  bool get mediaVisibility => _mediaVisibility;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _initialized = true;
    
    debugPrint('SettingsService: Initialized');
  }

  void _loadSettings() {
    // Notification settings
    _messageNotifications = _prefs?.getBool('notif_messages') ?? true;
    _groupNotifications = _prefs?.getBool('notif_groups') ?? true;
    _showPreview = _prefs?.getBool('notif_preview') ?? true;
    _vibrate = _prefs?.getBool('notif_vibrate') ?? true;
    _sound = _prefs?.getBool('notif_sound') ?? true;
    _inAppSounds = _prefs?.getBool('notif_inapp_sounds') ?? true;
    _inAppVibrate = _prefs?.getBool('notif_inapp_vibrate') ?? true;

    // Chat settings
    _enterToSend = _prefs?.getBool('chat_enter_to_send') ?? true;
    _mediaVisibility = _prefs?.getBool('chat_media_visibility') ?? true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION SETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> setMessageNotifications(bool value) async {
    _messageNotifications = value;
    await _prefs?.setBool('notif_messages', value);
    notifyListeners();
  }

  Future<void> setGroupNotifications(bool value) async {
    _groupNotifications = value;
    await _prefs?.setBool('notif_groups', value);
    notifyListeners();
  }

  Future<void> setShowPreview(bool value) async {
    _showPreview = value;
    await _prefs?.setBool('notif_preview', value);
    notifyListeners();
  }

  Future<void> setVibrate(bool value) async {
    _vibrate = value;
    await _prefs?.setBool('notif_vibrate', value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _sound = value;
    await _prefs?.setBool('notif_sound', value);
    notifyListeners();
  }

  Future<void> setInAppSounds(bool value) async {
    _inAppSounds = value;
    await _prefs?.setBool('notif_inapp_sounds', value);
    notifyListeners();
  }

  Future<void> setInAppVibrate(bool value) async {
    _inAppVibrate = value;
    await _prefs?.setBool('notif_inapp_vibrate', value);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT SETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> setEnterToSend(bool value) async {
    _enterToSend = value;
    await _prefs?.setBool('chat_enter_to_send', value);
    notifyListeners();
  }

  Future<void> setMediaVisibility(bool value) async {
    _mediaVisibility = value;
    await _prefs?.setBool('chat_media_visibility', value);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> resetNotificationSettings() async {
    _messageNotifications = true;
    _groupNotifications = true;
    _showPreview = true;
    _vibrate = true;
    _sound = true;
    _inAppSounds = true;
    _inAppVibrate = true;

    await _prefs?.setBool('notif_messages', true);
    await _prefs?.setBool('notif_groups', true);
    await _prefs?.setBool('notif_preview', true);
    await _prefs?.setBool('notif_vibrate', true);
    await _prefs?.setBool('notif_sound', true);
    await _prefs?.setBool('notif_inapp_sounds', true);
    await _prefs?.setBool('notif_inapp_vibrate', true);

    notifyListeners();
  }

  Future<void> resetChatSettings() async {
    _enterToSend = true;
    _mediaVisibility = true;

    await _prefs?.setBool('chat_enter_to_send', true);
    await _prefs?.setBool('chat_media_visibility', true);

    notifyListeners();
  }
}

