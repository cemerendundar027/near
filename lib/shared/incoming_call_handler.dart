import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gelen Arama İşleyici
/// iOS'ta CallKit, Android'de custom notification kullanır
class IncomingCallHandler {
  IncomingCallHandler._();
  static final IncomingCallHandler instance = IncomingCallHandler._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _callChannel;
  bool _isInitialized = false;

  // Callbacks
  Function(Map<String, dynamic> callData)? onIncomingCall;
  Function(String callId)? onCallAccepted;
  Function(String callId)? onCallRejected;
  Function(String callId)? onCallEnded;

  /// Handler'ı başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Önce bekleyen tüm aramaları temizle (eski/orphan calls)
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('IncomingCallHandler: Error clearing old calls: $e');
    }

    // CallKit eventlerini dinle
    FlutterCallkitIncoming.onEvent.listen(_handleCallKitEvent);

    // Supabase realtime'dan gelen aramaları dinle - sadece kullanıcı giriş yaptıysa
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _subscribeToIncomingCalls();
    }

    _isInitialized = true;
    debugPrint('IncomingCallHandler: Initialized');
  }

  /// Gelen aramaları dinle
  void _subscribeToIncomingCalls() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _callChannel?.unsubscribe();
    _callChannel = _supabase.channel('incoming_calls_$userId');

    _callChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'calls',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'callee_id',
          value: userId,
        ),
        callback: (payload) {
          final newCall = payload.newRecord;
          if (newCall['status'] == 'calling') {
            _handleIncomingCall(newCall);
          }
        },
      )
      .subscribe();

    debugPrint('IncomingCallHandler: Subscribed to incoming calls');
  }

  /// Gelen arama işle
  Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
    debugPrint('IncomingCallHandler: Incoming call: ${callData['id']}');

    final callId = callData['id'] as String;
    final callerId = callData['caller_id'] as String;
    final isVideo = callData['is_video'] as bool? ?? false;

    // Arayan bilgilerini al
    final callerInfo = await _getCallerInfo(callerId);
    final callerName = callerInfo['name'] ?? 'Unknown';
    final callerAvatar = callerInfo['avatar'];

    // Platform bazlı bildirim göster
    if (Platform.isIOS) {
      await _showCallKitNotification(
        callId: callId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        isVideo: isVideo,
      );
    } else if (Platform.isAndroid) {
      await _showAndroidCallNotification(
        callId: callId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        isVideo: isVideo,
      );
    }

    // Callback'i çağır
    callData['caller_name'] = callerName;
    callData['caller_avatar'] = callerAvatar;
    onIncomingCall?.call(callData);
  }

  /// Arayan bilgilerini al
  Future<Map<String, String?>> _getCallerInfo(String callerId) async {
    try {
      final response = await _supabase
        .from('profiles')
        .select('full_name, username, avatar_url')
        .eq('id', callerId)
        .single();
      
      return {
        'name': response['full_name'] ?? response['username'],
        'avatar': response['avatar_url'],
      };
    } catch (e) {
      debugPrint('IncomingCallHandler: Error getting caller info: $e');
      return {'name': null, 'avatar': null};
    }
  }

  /// iOS CallKit bildirimi
  Future<void> _showCallKitNotification({
    required String callId,
    required String callerName,
    String? callerAvatar,
    required bool isVideo,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Near',
      avatar: callerAvatar,
      handle: callerName,
      type: isVideo ? 1 : 0, // 0 = audio, 1 = video
      textAccept: 'Kabul Et',
      textDecline: 'Reddet',
      duration: 45000, // 45 saniye timeout
      extra: <String, dynamic>{
        'callId': callId,
        'isVideo': isVideo,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#6C63FF',
        backgroundUrl: '',
        actionColor: '#6C63FF',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Gelen Arama',
        missedCallNotificationChannelName: 'Cevapsız Arama',
        isShowCallID: false,
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Android custom bildirim
  Future<void> _showAndroidCallNotification({
    required String callId,
    required String callerName,
    String? callerAvatar,
    required bool isVideo,
  }) async {
    // flutter_callkit_incoming Android'de de çalışır
    await _showCallKitNotification(
      callId: callId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      isVideo: isVideo,
    );
  }

  /// CallKit event işleyici
  void _handleCallKitEvent(CallEvent? event) {
    if (event == null) return;

    debugPrint('IncomingCallHandler: CallKit event: ${event.event}');

    switch (event.event) {
      case Event.actionCallAccept:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          onCallAccepted?.call(callId);
        }
        break;

      case Event.actionCallDecline:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          onCallRejected?.call(callId);
          _rejectCallInDb(callId);
        }
        break;

      case Event.actionCallEnded:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          onCallEnded?.call(callId);
        }
        break;

      case Event.actionCallTimeout:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          _missedCall(callId);
        }
        break;

      case Event.actionCallCallback:
        // Cevapsız aramayı geri ara
        final callId = event.body['id'] as String?;
        if (callId != null) {
          // Callback işle
        }
        break;

      default:
        break;
    }
  }

  /// DB'de aramayı reddet
  Future<void> _rejectCallInDb(String callId) async {
    try {
      await _supabase
        .from('calls')
        .update({
          'status': 'rejected',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);
    } catch (e) {
      debugPrint('IncomingCallHandler: Error rejecting call: $e');
    }
  }

  /// Cevapsız arama işle
  Future<void> _missedCall(String callId) async {
    try {
      await _supabase
        .from('calls')
        .update({
          'status': 'missed',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', callId);

      // Bildirimi kapat
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('IncomingCallHandler: Error handling missed call: $e');
    }
  }

  /// Aktif aramaları kontrol et (app başlangıcında)
  Future<List<dynamic>> getActiveCalls() async {
    return await FlutterCallkitIncoming.activeCalls();
  }

  /// Tüm bildirimleri kapat
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  /// Aramayı sonlandır
  Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  /// Temizle
  void dispose() {
    _callChannel?.unsubscribe();
    _isInitialized = false;
  }
}
