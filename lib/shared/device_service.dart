import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'supabase_service.dart';

/// Device ve Session yönetimi servisi
class DeviceService {
  DeviceService._();
  static final instance = DeviceService._();

  final _supabase = SupabaseService.instance;
  final _deviceInfo = DeviceInfoPlugin();

  String? _currentSessionId;

  /// Mevcut cihazın session ID'si
  String? get currentSessionId => _currentSessionId;

  /// Login sonrası cihaz session'ı kaydet
  Future<void> saveDeviceSession() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      final deviceInfo = await _getDeviceInfo();

      // Önce mevcut session'ları is_current=false yap
      await _supabase.client
          .from('user_sessions')
          .update({'is_current': false})
          .eq('user_id', user.id)
          .eq('is_current', true);

      // Yeni session kaydet
      final response = await _supabase.client
          .from('user_sessions')
          .insert({
            'user_id': user.id,
            'device_name': deviceInfo['name'],
            'device_type': deviceInfo['type'],
            'device_os': deviceInfo['os'],
            'device_model': deviceInfo['model'],
            'app_version': '1.0.0',
            'user_agent': deviceInfo['userAgent'],
            'last_active_at': DateTime.now().toIso8601String(),
            'is_current': true,
          })
          .select()
          .single();

      _currentSessionId = response['id'] as String;
      
      debugPrint('DeviceService: Session saved: $_currentSessionId');
    } catch (e) {
      debugPrint('DeviceService: Error saving session: $e');
    }
  }

  /// Session aktivitesini güncelle
  Future<void> updateSessionActivity() async {
    final user = _supabase.currentUser;
    if (user == null || _currentSessionId == null) return;

    try {
      await _supabase.client
          .from('user_sessions')
          .update({
            'last_active_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSessionId!);
      
      debugPrint('DeviceService: Session activity updated');
    } catch (e) {
      debugPrint('DeviceService: Error updating session: $e');
    }
  }

  /// Logout sırasında mevcut session'ı sil
  Future<void> removeCurrentSession() async {
    if (_currentSessionId == null) return;

    try {
      await _supabase.client
          .from('user_sessions')
          .delete()
          .eq('id', _currentSessionId!);
      
      _currentSessionId = null;
      debugPrint('DeviceService: Session removed');
    } catch (e) {
      debugPrint('DeviceService: Error removing session: $e');
    }
  }

  /// Tüm session'ları getir
  Future<List<DeviceSession>> getUserSessions() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase.client
          .from('user_sessions')
          .select()
          .eq('user_id', user.id)
          .order('last_active_at', ascending: false);

      return (response as List)
          .map((e) => DeviceSession.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('DeviceService: Error loading sessions: $e');
      return [];
    }
  }

  /// Belirli bir session'ı sil (başka cihazdan çıkış)
  Future<bool> deleteSession(String sessionId) async {
    try {
      await _supabase.client
          .from('user_sessions')
          .delete()
          .eq('id', sessionId);
      
      debugPrint('DeviceService: Deleted session: $sessionId');
      return true;
    } catch (e) {
      debugPrint('DeviceService: Error deleting session: $e');
      return false;
    }
  }

  /// Diğer tüm cihazlardan çıkış
  Future<bool> deleteAllOtherSessions() async {
    final user = _supabase.currentUser;
    if (user == null || _currentSessionId == null) return false;

    try {
      await _supabase.client
          .from('user_sessions')
          .delete()
          .eq('user_id', user.id)
          .neq('id', _currentSessionId!);
      
      debugPrint('DeviceService: Deleted all other sessions');
      return true;
    } catch (e) {
      debugPrint('DeviceService: Error deleting other sessions: $e');
      return false;
    }
  }

  /// Cihaz bilgilerini al
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'name': '${info.manufacturer} ${info.model}',
          'type': 'mobile',
          'os': 'Android ${info.version.release}',
          'model': info.model,
          'userAgent': 'Android/${info.version.release} (${info.model})',
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'name': info.name, // "Ahmet'in iPhone"
          'type': 'mobile',
          'os': 'iOS ${info.systemVersion}',
          'model': info.utsname.machine,
          'userAgent': 'iOS/${info.systemVersion} (${info.model})',
        };
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return {
          'name': info.computerName,
          'type': 'desktop',
          'os': 'macOS ${info.osRelease}',
          'model': info.model,
          'userAgent': 'macOS/${info.osRelease}',
        };
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return {
          'name': info.computerName,
          'type': 'desktop',
          'os': 'Windows ${info.majorVersion}.${info.minorVersion}',
          'model': info.computerName,
          'userAgent': 'Windows/${info.majorVersion}',
        };
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return {
          'name': info.name,
          'type': 'desktop',
          'os': '${info.name} ${info.version}',
          'model': info.prettyName,
          'userAgent': 'Linux/${info.version}',
        };
      } else if (kIsWeb) {
        final info = await _deviceInfo.webBrowserInfo;
        return {
          'name': info.browserName.toString().split('.').last,
          'type': 'web',
          'os': info.platform ?? 'Unknown',
          'model': info.userAgent ?? 'Web Browser',
          'userAgent': info.userAgent,
        };
      }
    } catch (e) {
      debugPrint('DeviceService: Error getting device info: $e');
    }

    // Fallback
    return {
      'name': 'Unknown Device',
      'type': 'mobile',
      'os': 'Unknown',
      'model': 'Unknown',
      'userAgent': 'Unknown',
    };
  }
}

/// Cihaz session modeli
class DeviceSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String? deviceOS;
  final String? deviceModel;
  final String? appVersion;
  final String? country;
  final String? city;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;

  DeviceSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.deviceOS,
    this.deviceModel,
    this.appVersion,
    this.country,
    this.city,
    required this.lastActiveAt,
    required this.createdAt,
    required this.isCurrent,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as String,
      deviceName: json['device_name'] as String,
      deviceType: json['device_type'] as String,
      deviceOS: json['device_os'] as String?,
      deviceModel: json['device_model'] as String?,
      appVersion: json['app_version'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  /// Cihaz icon'u
  String get icon {
    switch (deviceType) {
      case 'mobile':
        if (deviceOS?.toLowerCase().contains('ios') ?? false) {
          return '📱'; // iPhone
        }
        return '📱'; // Android
      case 'desktop':
        if (deviceOS?.toLowerCase().contains('mac') ?? false) {
          return '💻'; // Mac
        } else if (deviceOS?.toLowerCase().contains('windows') ?? false) {
          return '🖥️'; // Windows
        }
        return '💻'; // Linux
      case 'web':
        return '🌐'; // Web
      default:
        return '📱';
    }
  }

  /// Relative time string
  String get lastActiveText {
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);

    if (diff.inMinutes < 1) {
      return 'Şimdi aktif';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${(diff.inDays / 7).floor()} hafta önce';
    }
  }

  /// Lokasyon string
  String? get locationText {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (country != null) {
      return country;
    }
    return null;
  }
}
