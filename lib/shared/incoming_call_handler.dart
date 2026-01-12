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
  
  // Pending calls cache - callId -> call data
  final Map<String, Map<String, dynamic>> _pendingCalls = {};

  // Callbacks
  Function(Map<String, dynamic> callData)? onIncomingCall;
  Function(Map<String, dynamic> callData)? onCallAccepted; // callId yerine full call data
  Function(String callId)? onCallRejected;
  Function(String callId)? onCallEnded;
  
  String? _currentUserId;

  /// Handler'ı başlat
  Future<void> initialize() async {
    // Önce bekleyen tüm aramaları temizle (eski/orphan calls)
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('IncomingCallHandler: Error clearing old calls: $e');
    }

    // CallKit eventlerini dinle (sadece bir kez)
    if (!_isInitialized) {
      FlutterCallkitIncoming.onEvent.listen(_handleCallKitEvent);
    }

    // Supabase realtime'dan gelen aramaları dinle - sadece kullanıcı giriş yaptıysa
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && userId != _currentUserId) {
      _currentUserId = userId;
      _subscribeToIncomingCalls();
    }

    _isInitialized = true;
    debugPrint('IncomingCallHandler: Initialized for user: $userId');
  }
  
  /// Kullanıcı değiştiğinde veya yeniden giriş yaptığında çağır
  Future<void> restart() async {
    _currentUserId = null;
    _callChannel?.unsubscribe();
    _callChannel = null;
    _pendingCallsCheckTimer?.cancel();
    _pendingCallsCheckTimer = null;
    await initialize();
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
          debugPrint('IncomingCallHandler: Received call event: ${payload.newRecord}');
          final newCall = payload.newRecord;
          // Yeni gelen arama 'ringing' statusuyla başlar
          final status = newCall['status'] as String?;
          debugPrint('IncomingCallHandler: Call status: $status');
          if (status == 'ringing') {
            _handleIncomingCall(newCall);
          }
        },
      )
      .subscribe((status, error) {
        debugPrint('IncomingCallHandler: Subscription status: $status, error: $error');
      });

    debugPrint('IncomingCallHandler: Subscribed to incoming calls for user: $userId');
    
    // Ayrıca periyodik olarak pending calls kontrol et (backup mechanism)
    _startPendingCallsCheck();
  }
  
  Timer? _pendingCallsCheckTimer;
  
  /// Periyodik olarak pending calls kontrol et (Realtime backup)
  void _startPendingCallsCheck() {
    _pendingCallsCheckTimer?.cancel();
    // Her 2 saniyede bir kontrol et
    _pendingCallsCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkPendingCalls();
    });
    debugPrint('IncomingCallHandler: Started polling for pending calls');
  }
  
  /// DB'den pending (ringing) calls kontrol et
  Future<void> _checkPendingCalls() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('IncomingCallHandler: Polling skipped - no user');
      return;
    }
    
    try {
      debugPrint('IncomingCallHandler: Polling for calls... (user: $userId)');
      final calls = await _supabase
        .from('calls')
        .select()
        .eq('callee_id', userId)
        .eq('status', 'ringing')
        .gt('created_at', DateTime.now().subtract(const Duration(seconds: 60)).toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);
      
      debugPrint('IncomingCallHandler: Polling found ${calls.length} ringing calls');
      
      if (calls.isNotEmpty) {
        final call = calls[0];
        final callId = call['id'] as String;
        
        // Eğer zaten işlenmemişse işle
        if (!_pendingCalls.containsKey(callId)) {
          debugPrint('IncomingCallHandler: Found NEW pending call via polling: $callId');
          _handleIncomingCall(call);
        }
      }
    } catch (e) {
      debugPrint('IncomingCallHandler: Error checking pending calls: $e');
    }
  }

  /// Gelen arama işle
  Future<void> _handleIncomingCall(Map<String, dynamic> callData) async {
    debugPrint('IncomingCallHandler: Incoming call: ${callData['id']}');

    final callId = callData['id'] as String;
    final callerId = callData['caller_id'] as String;
    // DB'de 'type' kolonu var (voice/video), 'is_video' yok
    final callType = callData['type'] as String? ?? 'voice';
    final isVideo = callType == 'video';

    // Arayan bilgilerini al
    final callerInfo = await _getCallerInfo(callerId);
    final callerName = callerInfo['name'] ?? 'Unknown';
    final callerAvatar = callerInfo['avatar'];

    // Call data'yı cache'le (accept edildiğinde kullanılacak)
    callData['caller_name'] = callerName;
    callData['caller_avatar'] = callerAvatar;
    callData['is_video'] = isVideo;
    _pendingCalls[callId] = callData;

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

  /// DB'den arama bilgisi al
  Future<Map<String, dynamic>?> _getCallFromDb(String callId) async {
    try {
      final response = await _supabase
        .from('calls')
        .select('*, caller:profiles!calls_caller_id_fkey(full_name, username, avatar_url)')
        .eq('id', callId)
        .single();
      
      final caller = response['caller'] as Map<String, dynamic>?;
      response['caller_name'] = caller?['full_name'] ?? caller?['username'] ?? 'Unknown';
      response['caller_avatar'] = caller?['avatar_url'];
      response['is_video'] = response['type'] == 'video';
      
      return response;
    } catch (e) {
      debugPrint('IncomingCallHandler: Error getting call from DB: $e');
      return null;
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
  void _handleCallKitEvent(CallEvent? event) async {
    if (event == null) return;

    debugPrint('IncomingCallHandler: CallKit event: ${event.event}');

    switch (event.event) {
      case Event.actionCallAccept:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          // Cache'den call data'yı al, yoksa DB'den çek
          var callData = _pendingCalls[callId];
          callData ??= await _getCallFromDb(callId);
          if (callData != null) {
            _pendingCalls.remove(callId);
            onCallAccepted?.call(callData);
          }
        }
        break;

      case Event.actionCallDecline:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          _pendingCalls.remove(callId);
          onCallRejected?.call(callId);
          _rejectCallInDb(callId);
        }
        break;

      case Event.actionCallEnded:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          _pendingCalls.remove(callId);
          onCallEnded?.call(callId);
        }
        break;

      case Event.actionCallTimeout:
        final callId = event.body['id'] as String?;
        if (callId != null) {
          _pendingCalls.remove(callId);
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
    _pendingCallsCheckTimer?.cancel();
    _pendingCallsCheckTimer = null;
    _isInitialized = false;
  }
}
