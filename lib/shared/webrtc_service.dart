import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'incoming_call_handler.dart';

/// WebRTC Service - P2P sesli ve görüntülü arama
///
/// Özellikler:
/// - 1-1 sesli arama
/// - 1-1 görüntülü arama
/// - ICE candidate exchange
/// - Supabase Realtime signaling
/// - Call timeout (45 saniye)
class WebRTCService extends ChangeNotifier {
  WebRTCService._();
  static final instance = WebRTCService._();

  final _supabase = SupabaseService.instance;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Realtime channels
  RealtimeChannel? _callChannel;
  RealtimeChannel? _iceCandidateChannel;

  // Call timeout
  Timer? _callTimeoutTimer;
  Timer? _connectionFailedTimer;
  static const int _callTimeoutSeconds = 45; // 45 saniye sonra cevapsız
  static const int _connectionFailedTimeoutSeconds = 15; // 15 saniye bekleme

  // Call state
  String? _currentCallId;
  String? _remoteUserId;
  bool _isVideoCall = false;
  bool _isCaller = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  bool _isEnding = false; // Arama sonlandırılıyor mu
  
  // ICE Candidate Queue
  final List<RTCIceCandidate> _queuedRemoteCandidates = [];
  bool _isRemoteDescriptionSet = false;

  // Callbacks
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionState;
  Function(String)? onCallEnded;
  Function()? onCallAccepted;
  Function()? onCallRejected;
  Function()? onCallTimeout; // Cevapsız arama callback

  // Getters
  String? get currentCallId => _currentCallId;
  String? get remoteUserId => _remoteUserId;
  bool get isInCall => _currentCallId != null;
  bool get isVideoCall => _isVideoCall;
  bool get isCaller => _isCaller;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isFrontCamera => _isFrontCamera;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get currentUserId => _supabase.currentUser?.id;

  // STUN/TURN servers configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      // Google STUN servers
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // Twilio STUN
      {'urls': 'stun:global.stun.twilio.com:3478'},
      // Metered.ca Free TURN (güncel ve aktif)
      {
        'urls': 'turn:a.relay.metered.ca:80',
        'username': 'e8dd65c92bf707b5c0e439bb',
        'credential': '8t8Ua/xvvmHyEhid',
      },
      {
        'urls': 'turn:a.relay.metered.ca:80?transport=tcp',
        'username': 'e8dd65c92bf707b5c0e439bb',
        'credential': '8t8Ua/xvvmHyEhid',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443',
        'username': 'e8dd65c92bf707b5c0e439bb',
        'credential': '8t8Ua/xvvmHyEhid',
      },
      {
        'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
        'username': 'e8dd65c92bf707b5c0e439bb',
        'credential': '8t8Ua/xvvmHyEhid',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARAMA BAŞLATMA (CALLER)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Arama başlat
  Future<String?> startCall({
    required String calleeId,
    required bool isVideo,
  }) async {
    if (currentUserId == null) {
      debugPrint('WebRTC: User not logged in');
      return null;
    }

    // Önceki arama state'ini kontrol et ve temizle
    if (isInCall || _isEnding) {
      debugPrint('WebRTC: Previous call state detected, cleaning up first...');
      await _forceCleanup();
    }

    try {
      _isVideoCall = isVideo;
      _isCaller = true;
      _remoteUserId = calleeId;
      _isRemoteDescriptionSet = false;
      _queuedRemoteCandidates.clear();

      // 1. Supabase'de call kaydı oluştur
      final callData = await _supabase.client
          .from('calls')
          .insert({
            'caller_id': currentUserId,
            'callee_id': calleeId,
            'type': isVideo ? 'video' : 'voice',
            'status': 'ringing',
          })
          .select()
          .single();

      _currentCallId = callData['id'] as String;
      debugPrint(
        'WebRTC: 📞 Call created: $_currentCallId (type: ${isVideo ? "video" : "voice"})',
      );

      // 2. Local media stream al
      debugPrint('WebRTC: Requesting media...');
      await _getUserMedia();
      debugPrint('WebRTC: Media ready');

      // 2.1 Enable speakerphone by default for better audio (mobile only)
      if (Platform.isAndroid || Platform.isIOS) {
        // Video ise speaker, sesli ise earpiece (false)
        await Helper.setSpeakerphoneOn(_isVideoCall);
        _isSpeakerOn = _isVideoCall;
        debugPrint('WebRTC: Audio output set to: ${_isVideoCall ? "Speaker" : "Earpiece"}');
      }

      // 3. Peer connection oluştur
      await _createPeerConnection();

      // 4. Offer oluştur ve gönder
      debugPrint('WebRTC: Creating offer...');
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      debugPrint('WebRTC: ✅ Offer created (${offer.sdp?.length ?? 0} bytes)');

      // 5. Offer'ı Supabase'e kaydet
      await _supabase.client
          .from('calls')
          .update({
            'offer_sdp': offer.sdp,
            'ringing_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentCallId!);

      debugPrint('WebRTC: ✅ Offer sent to DB');

      // 6. Signaling dinle
      debugPrint('WebRTC: Subscribing to call updates and ICE candidates...');
      _subscribeToCallUpdates();
      _subscribeToIceCandidates();

      // 7. Timeout başlat (45 saniye sonra cevapsız)
      _startCallTimeout();

      notifyListeners();
      return _currentCallId;
    } catch (e) {
      debugPrint('WebRTC: Error starting call: $e');
      await endCall(reason: 'error');
      return null;
    }
  }

  /// Call timeout başlat (arayan için)
  void _startCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(Duration(seconds: _callTimeoutSeconds), () {
      if (_isCaller && _currentCallId != null) {
        debugPrint('WebRTC: Call timeout - no answer');
        _handleCallTimeout();
      }
    });
  }

  /// Timeout'u iptal et (arama kabul edildiğinde)
  void _cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
    _connectionFailedTimer?.cancel();
    _connectionFailedTimer = null;
  }
  
  /// Connection failed timeout schedule
  void _scheduleConnectionFailedTimeout() {
    _connectionFailedTimer?.cancel();
    debugPrint('WebRTC: Scheduling connection failed timeout (${_connectionFailedTimeoutSeconds}s)');
    _connectionFailedTimer = Timer(Duration(seconds: _connectionFailedTimeoutSeconds), () {
      if (_currentCallId != null && !_isEnding) {
        debugPrint('WebRTC: Connection failed timeout - ending call');
        endCall(reason: 'connection_failed');
      }
    });
  }

  /// Cevapsız arama işle
  Future<void> _handleCallTimeout() async {
    if (_currentCallId == null) return;

    try {
      await _supabase.client
          .from('calls')
          .update({
            'status': 'missed',
            'ended_at': DateTime.now().toIso8601String(),
            'end_reason': 'no_answer',
          })
          .eq('id', _currentCallId!);

      debugPrint('WebRTC: Call marked as missed');
    } catch (e) {
      debugPrint('WebRTC: Error marking call as missed: $e');
    }

    onCallTimeout?.call();
    await endCall(reason: 'no_answer');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GELEN ARAMA (CALLEE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gelen aramayı kabul et
  Future<bool> acceptCall({
    required String callId,
    required String callerId,
    required bool isVideo,
    required String offerSdp,
  }) async {
    if (currentUserId == null) return false;

    debugPrint(
      'WebRTC: acceptCall started - callId: $callId, callerId: $callerId',
    );
    debugPrint('WebRTC: offerSdp length: ${offerSdp.length}');

    // Önceki arama state'ini kontrol et ve temizle
    if (isInCall || _isEnding) {
      debugPrint('WebRTC: Previous call state detected, cleaning up first...');
      await _forceCleanup();
    }

    try {
      _currentCallId = callId;
      _remoteUserId = callerId;
      _isVideoCall = isVideo;
      _isCaller = false;
      _isRemoteDescriptionSet = false;
      _queuedRemoteCandidates.clear();

      // 1. Local media stream al
      debugPrint(
        'WebRTC: 📞 Incoming call from: $callerId, type: ${isVideo ? "video" : "voice"}',
      );
      debugPrint('WebRTC: Requesting media...');
      await _getUserMedia();
      debugPrint('WebRTC: Media ready');

      // 1.1 Speakerphone ayarı
      if (Platform.isAndroid || Platform.isIOS) {
        await Helper.setSpeakerphoneOn(_isVideoCall);
        _isSpeakerOn = _isVideoCall;
        debugPrint('WebRTC: Audio output set to: ${_isVideoCall ? "Speaker" : "Earpiece"}');
      }

      // 2. Peer connection oluştur
      debugPrint('WebRTC: Creating peer connection...');
      await _createPeerConnection();
      debugPrint('WebRTC: Peer connection created');

      // 3. Remote offer'ı set et
      debugPrint('WebRTC: Setting remote description (offer)...');
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerSdp, 'offer'),
      );
      _isRemoteDescriptionSet = true;
      debugPrint('WebRTC: Remote description set');
      
      // 3.1 Kuyrukta bekleyen ICE adaylarını işle
      await _processQueuedIceCandidates();

      // 4. Answer oluştur
      debugPrint('WebRTC: Creating answer...');
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      debugPrint('WebRTC: Local description (answer) set');

      // 5. Answer'ı Supabase'e kaydet
      debugPrint('WebRTC: Saving answer to Supabase...');
      await _supabase.client
          .from('calls')
          .update({
            'answer_sdp': answer.sdp,
            'status': 'connected',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', callId);

      debugPrint('WebRTC: Answer sent to Supabase');

      // 6. Signaling dinle
      _subscribeToCallUpdates();
      _subscribeToIceCandidates();

      // 7. CRITICAL: Fetch existing ICE candidates from caller
      await _fetchExistingIceCandidates();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('WebRTC: Error accepting call: $e');
      await endCall(reason: 'error');
      return false;
    }
  }

  /// Gelen aramayı reddet
  Future<void> rejectCall(String callId) async {
    try {
      await _supabase.client
          .from('calls')
          .update({
            'status': 'rejected',
            'ended_at': DateTime.now().toIso8601String(),
            'end_reason': 'rejected',
          })
          .eq('id', callId);

      debugPrint('WebRTC: Call rejected');
    } catch (e) {
      debugPrint('WebRTC: Error rejecting call: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ARAMA SONLANDIRMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aramayı sonlandır (kullanıcı tarafından)
  Future<void> endCall({String reason = 'ended'}) async {
    if (_isEnding) {
      debugPrint('WebRTC: endCall already in progress, skipping');
      return;
    }
    _isEnding = true;

    debugPrint('WebRTC: 🔴 Ending call - reason: $reason');

    // Supabase'de güncelle - sadece biz sonlandırıyorsak
    if (_currentCallId != null) {
      try {
        await _supabase.client
            .from('calls')
            .update({
              'status': 'ended',
              'ended_at': DateTime.now().toIso8601String(),
              'end_reason': reason,
            })
            .eq('id', _currentCallId!);
        debugPrint('WebRTC: Call status updated in DB');
      } catch (e) {
        debugPrint('WebRTC: Error updating call status: $e');
      }
    }

    // Cleanup
    await _cleanup();

    onCallEnded?.call(reason);
    notifyListeners();

    _isEnding = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDYA KONTROLÜ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mikrofonu aç/kapat
  void toggleMute() {
    if (_localStream == null) {
      debugPrint('WebRTC: toggleMute - no local stream');
      return;
    }

    try {
      _isMuted = !_isMuted;
      final audioTracks = _localStream!.getAudioTracks();
      debugPrint('WebRTC: Audio tracks count: ${audioTracks.length}');
      for (final track in audioTracks) {
        track.enabled = !_isMuted;
      }
      debugPrint('WebRTC: Mute toggled: $_isMuted');
      notifyListeners();
    } catch (e) {
      debugPrint('WebRTC: Error toggling mute: $e');
    }
  }

  /// Hoparlörü aç/kapat
  void toggleSpeaker() {
    // Speaker toggle only works on mobile
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('WebRTC: Speaker toggle not supported on this platform');
      return;
    }
    
    try {
      _isSpeakerOn = !_isSpeakerOn;
      Helper.setSpeakerphoneOn(_isSpeakerOn);
      debugPrint('WebRTC: Speaker toggled: $_isSpeakerOn');
      notifyListeners();
    } catch (e) {
      debugPrint('WebRTC: Error toggling speaker: $e');
    }
  }

  /// Videoyu aç/kapat
  void toggleVideo() {
    if (_localStream == null || !_isVideoCall) {
      debugPrint('WebRTC: toggleVideo - no local stream or not video call');
      return;
    }

    try {
      _isVideoEnabled = !_isVideoEnabled;
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = _isVideoEnabled;
      }
      debugPrint('WebRTC: Video toggled: $_isVideoEnabled');
      notifyListeners();
    } catch (e) {
      debugPrint('WebRTC: Error toggling video: $e');
    }
  }

  /// Kamerayı değiştir (ön/arka)
  Future<void> switchCamera() async {
    if (_localStream == null || !_isVideoCall) {
      debugPrint('WebRTC: switchCamera - no local stream or not video call');
      return;
    }

    try {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isEmpty) {
        debugPrint('WebRTC: No video tracks to switch');
        return;
      }

      _isFrontCamera = !_isFrontCamera;
      await Helper.switchCamera(videoTracks.first);
      debugPrint(
        'WebRTC: Camera switched: ${_isFrontCamera ? 'front' : 'back'}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('WebRTC: Error switching camera: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GELEN ARAMALARI DİNLE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gelen aramaları dinle
  RealtimeChannel subscribeToIncomingCalls(
    Function(Map<String, dynamic> call) onIncomingCall,
  ) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final channel = _supabase.client.channel('incoming_calls_$userId');

    channel
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
            final call = payload.newRecord;
            debugPrint('WebRTC: Incoming call: ${call['id']}');
            onIncomingCall(call);
          },
        )
        .subscribe();

    return channel;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRİVATE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Local media stream al
  Future<void> _getUserMedia() async {
    final constraints = {
      'audio': {
        'mandatory': {
          'googEchoCancellation': true,
          'googNoiseSuppression': true,
          'googAutoGainControl': true,
        },
        'optional': [],
      },
      'video': _isVideoCall
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      debugPrint('WebRTC: ✅ Local stream acquired');
      debugPrint(
        'WebRTC: Audio tracks: ${_localStream?.getAudioTracks().length ?? 0}',
      );
      debugPrint(
        'WebRTC: Video tracks: ${_localStream?.getVideoTracks().length ?? 0}',
      );

      // Tracks kontrol et
      for (final track in _localStream?.getTracks() ?? []) {
        debugPrint(
          'WebRTC: Track - kind: ${track.kind}, id: ${track.id}, enabled: ${track.enabled}',
        );
      }

      onLocalStream?.call(_localStream!);
    } catch (e) {
      debugPrint('WebRTC: ❌ Error getting user media: $e');
      rethrow;
    }
  }

  /// Peer connection oluştur
  Future<void> _createPeerConnection() async {
    debugPrint(
      'WebRTC: Creating peer connection with ICE servers: $_iceServers',
    );
    _peerConnection = await createPeerConnection(_iceServers);

    // Local tracks ekle
    debugPrint(
      'WebRTC: Local stream tracks: ${_localStream?.getTracks().length ?? 0}',
    );
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        try {
          await _peerConnection!.addTrack(track, _localStream!);
          debugPrint('WebRTC: ✅ Added local ${track.kind} track');
        } catch (e) {
          debugPrint('WebRTC: ❌ Error adding track ${track.kind}: $e');
        }
      }
    } else {
      debugPrint('WebRTC: ⚠️ Local stream is NULL!');
    }

    // Remote stream handler (yeni API)
    _peerConnection!.onTrack = (event) {
      debugPrint('WebRTC: 🎵 onTrack event received!');
      debugPrint(
        'WebRTC: onTrack - kind: ${event.track.kind}, track enabled: ${event.track.enabled}',
      );
      debugPrint('WebRTC: onTrack - streams: ${event.streams.length}');

      // Track'ı aktif et
      event.track.enabled = true;

      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        debugPrint(
          'WebRTC: ✅ Remote stream assigned, id: ${_remoteStream?.id}',
        );
        debugPrint(
          'WebRTC: ✅ Remote stream tracks: ${_remoteStream?.getTracks().map((t) => "${t.kind}(${t.id})").join(", ")}',
        );

        // Tüm track'ları enable et
        for (final track in _remoteStream!.getTracks()) {
          track.enabled = true;
          debugPrint('WebRTC: ✅ Enabled remote ${track.kind} track');
        }

        onRemoteStream?.call(_remoteStream!);
        debugPrint('WebRTC: ✅ onRemoteStream callback called');
      } else {
        // Stream yoksa track'i manuel olarak bir stream'e ekle
        debugPrint(
          'WebRTC: ⚠️ onTrack but no streams in event, creating stream manually',
        );
        _remoteStream ??= _peerConnection!.getRemoteStreams().firstOrNull;
        if (_remoteStream != null) {
          onRemoteStream?.call(_remoteStream!);
        }
      }
    };

    // Remote stream handler (eski API - fallback)
    // ignore: deprecated_member_use
    _peerConnection!.onAddStream = (stream) {
      debugPrint('WebRTC: 🎵 onAddStream event received! (legacy API)');
      debugPrint('WebRTC: onAddStream - stream id: ${stream.id}');
      debugPrint(
        'WebRTC: onAddStream - video tracks: ${stream.getVideoTracks().length}',
      );
      debugPrint(
        'WebRTC: onAddStream - audio tracks: ${stream.getAudioTracks().length}',
      );

      _remoteStream = stream;
      onRemoteStream?.call(_remoteStream!);
      debugPrint('WebRTC: ✅ Remote stream set via onAddStream');
    };

    // ICE candidate handler
    _peerConnection!.onIceCandidate = (candidate) {
      debugPrint(
        'WebRTC: ICE candidate generated: ${candidate.candidate?.substring(0, 50)}...',
      );
      if (candidate.candidate != null && _currentCallId != null) {
        _sendIceCandidate(candidate);
      }
    };

    // ICE connection state handler - CRITICAL for debugging
    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('WebRTC: 🧊 ICE connection state: $state');
      
      // ICE checking durumundan 30 saniye içinde connected'a geçmezse timeout
      if (state == RTCIceConnectionState.RTCIceConnectionStateChecking) {
        debugPrint('WebRTC: ICE checking started - waiting for connection...');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        debugPrint('WebRTC: 🧊✅ ICE Connected!');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        debugPrint('WebRTC: 🧊✅ ICE Completed!');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('WebRTC: 🧊❌ ICE Failed! Check TURN servers.');
      }
    };

    // ICE gathering state handler
    _peerConnection!.onIceGatheringState = (state) {
      debugPrint('WebRTC: ICE gathering state: $state');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        debugPrint('WebRTC: ✅ ICE gathering complete - all candidates collected');
      }
    };

    // Connection state handler
    _peerConnection!.onConnectionState = (state) {
      debugPrint('WebRTC: Connection state: $state');
      onConnectionState?.call(state);

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        // Bağlantı kuruldu
        debugPrint('WebRTC: ✅ Connection established!');
        _updateCallConnected();

        // Debug: Track durumlarını kontrol et
        _debugTrackStates();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        // FAILED - ICE bağlantısı kurulamadı, ama hemen kapatma
        // Kullanıcıya bilgi ver ama aramayı devam ettir
        debugPrint('WebRTC: ❌ Connection FAILED - ICE negotiation failed');
        debugPrint('WebRTC: This usually means TURN servers are not working or network issue');
        // NOT: Hemen kapatmıyoruz, kullanıcı manuel kapatabilir
        // Bazı durumlarda yeniden bağlanabilir
        _scheduleConnectionFailedTimeout();
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // Disconnected - geçici kopukluk, bekle
        debugPrint(
          'WebRTC: ⚠️ Connection disconnected - waiting for reconnection...',
        );
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        // Closed - peer connection kapatıldı
        debugPrint('WebRTC: Connection closed');
      }
    };

    debugPrint('WebRTC: Peer connection created');
  }

  /// Debug: Track durumlarını logla
  Future<void> _debugTrackStates() async {
    debugPrint('WebRTC: ═══════ TRACK STATUS DEBUG ═══════');

    // Local tracks
    if (_localStream != null) {
      debugPrint('WebRTC: LOCAL STREAM - id: ${_localStream!.id}');
      for (final track in _localStream!.getAudioTracks()) {
        debugPrint(
          'WebRTC:   Audio track - enabled: ${track.enabled}, muted: ${track.muted}',
        );
      }
      for (final track in _localStream!.getVideoTracks()) {
        debugPrint(
          'WebRTC:   Video track - enabled: ${track.enabled}, muted: ${track.muted}',
        );
      }
    } else {
      debugPrint('WebRTC: LOCAL STREAM - NULL');
    }

    // Remote tracks
    if (_remoteStream != null) {
      debugPrint('WebRTC: REMOTE STREAM - id: ${_remoteStream!.id}');
      for (final track in _remoteStream!.getAudioTracks()) {
        debugPrint(
          'WebRTC:   Audio track - enabled: ${track.enabled}, muted: ${track.muted}',
        );
      }
      for (final track in _remoteStream!.getVideoTracks()) {
        debugPrint(
          'WebRTC:   Video track - enabled: ${track.enabled}, muted: ${track.muted}',
        );
      }
    } else {
      debugPrint('WebRTC: REMOTE STREAM - NULL');
    }

    // Senders
    try {
      final sendersRaw = await _peerConnection?.getSenders();
      final senders = sendersRaw ?? <RTCRtpSender>[];
      debugPrint('WebRTC: SENDERS - count: ${senders.length}');
      for (final sender in senders) {
        final track = sender.track;
        debugPrint(
          'WebRTC:   Sender track - kind: ${track?.kind}, enabled: ${track?.enabled}',
        );
      }
    } catch (e) {
      debugPrint('WebRTC: Error getting senders: $e');
    }

    // Receivers
    try {
      final receiversRaw = await _peerConnection?.getReceivers();
      final receivers = receiversRaw ?? <RTCRtpReceiver>[];
      debugPrint('WebRTC: RECEIVERS - count: ${receivers.length}');
      for (final receiver in receivers) {
        final track = receiver.track;
        debugPrint(
          'WebRTC:   Receiver track - kind: ${track?.kind}, enabled: ${track?.enabled}',
        );
      }
    } catch (e) {
      debugPrint('WebRTC: Error getting receivers: $e');
    }

    debugPrint('WebRTC: ═══════════════════════════════════');
  }

  /// ICE candidate gönder
  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _supabase.client.from('ice_candidates').insert({
        'call_id': _currentCallId,
        'sender_id': currentUserId,
        'candidate': candidate.candidate,
        'sdp_mid': candidate.sdpMid,
        'sdp_m_line_index': candidate.sdpMLineIndex,
      });
      debugPrint('WebRTC: ICE candidate sent to DB');
    } catch (e) {
      debugPrint('WebRTC: Error sending ICE candidate: $e');
    }
  }

  /// Call updates dinle
  void _subscribeToCallUpdates() {
    if (_currentCallId == null) return;

    debugPrint('WebRTC: Subscribing to call updates for: $_currentCallId');
    _callChannel = _supabase.client.channel('call_$_currentCallId');

    _callChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentCallId,
          ),
          callback: (payload) async {
            final call = payload.newRecord;
            final status = call['status'] as String?;

            debugPrint('WebRTC: 📢 Call update received - status: $status');

            if (status == 'connected' && _isCaller) {
              // Caller: Answer geldi - timeout iptal et
              _cancelCallTimeout();
              final answerSdp = call['answer_sdp'] as String?;
              if (answerSdp != null) {
                await _peerConnection!.setRemoteDescription(
                  RTCSessionDescription(answerSdp, 'answer'),
                );
                _isRemoteDescriptionSet = true;
                debugPrint('WebRTC: ✅ Answer received and set');
                
                // Kuyrukta bekleyen adayları işle
                await _processQueuedIceCandidates();

                // CRITICAL: Fetch existing ICE candidates from callee
                await _fetchExistingIceCandidates();

                onCallAccepted?.call();
              }
            } else if (status == 'rejected') {
              debugPrint('WebRTC: 📢 Call was rejected');
              _cancelCallTimeout();
              onCallRejected?.call();
              await _handleRemoteCallEnded('rejected');
            } else if (status == 'ended') {
              debugPrint('WebRTC: 📢 Call was ended by remote');
              _cancelCallTimeout();
              final endReason = call['end_reason'] as String? ?? 'ended';
              await _handleRemoteCallEnded(endReason);
            } else if (status == 'missed') {
              debugPrint('WebRTC: 📢 Call was marked as missed');
              _cancelCallTimeout();
              await _handleRemoteCallEnded('no_answer');
            }
          },
        )
        .subscribe((status, error) {
          debugPrint(
            'WebRTC: Call updates subscription status: $status, error: $error',
          );
        });
  }

  /// Karşı taraf aramayı kapattığında
  Future<void> _handleRemoteCallEnded(String reason) async {
    if (_isEnding) {
      debugPrint(
        'WebRTC: _handleRemoteCallEnded already in progress, skipping',
      );
      return;
    }
    _isEnding = true;

    debugPrint('WebRTC: Remote ended call with reason: $reason');

    // DB güncellemesi YAPMA - zaten karşı taraf güncelledi
    // Sadece cleanup yap
    await _cleanup();

    onCallEnded?.call(reason);
    notifyListeners();

    _isEnding = false;
  }

  /// Fetch existing ICE candidates from database (for late-joining)
  Future<void> _fetchExistingIceCandidates() async {
    if (_currentCallId == null || currentUserId == null) return;

    debugPrint('WebRTC: Fetching existing ICE candidates...');

    try {
      final candidates = await _supabase.client
          .from('ice_candidates')
          .select()
          .eq('call_id', _currentCallId!)
          .neq('sender_id', currentUserId!);

      debugPrint(
        'WebRTC: Found ${candidates.length} existing remote ICE candidates',
      );

      for (final data in candidates) {
        try {
          final candidate = RTCIceCandidate(
            data['candidate'] as String?,
            data['sdp_mid'] as String?,
            data['sdp_m_line_index'] as int?,
          );
          
          if (_isRemoteDescriptionSet && _peerConnection != null) {
            await _peerConnection!.addCandidate(candidate);
            debugPrint('WebRTC: ✅ Added existing ICE candidate');
          } else {
            _queuedRemoteCandidates.add(candidate);
            debugPrint('WebRTC: ⏳ Queued existing ICE candidate');
          }
        } catch (e) {
          debugPrint('WebRTC: ❌ Error adding existing ICE candidate: $e');
        }
      }
    } catch (e) {
      debugPrint('WebRTC: ❌ Error fetching ICE candidates: $e');
    }
  }
  
  /// Kuyrukta bekleyen ICE adaylarını işle
  Future<void> _processQueuedIceCandidates() async {
    if (_queuedRemoteCandidates.isEmpty || _peerConnection == null) return;
    
    debugPrint('WebRTC: Processing ${_queuedRemoteCandidates.length} queued ICE candidates...');
    
    for (final candidate in List.from(_queuedRemoteCandidates)) {
        try {
          await _peerConnection!.addCandidate(candidate);
          debugPrint('WebRTC: ✅ Added queued ICE candidate');
        } catch (e) {
          debugPrint('WebRTC: ❌ Error adding queued ICE candidate: $e');
        }
    }
    
    _queuedRemoteCandidates.clear();
  }

  /// ICE candidates dinle
  void _subscribeToIceCandidates() {
    if (_currentCallId == null) return;

    debugPrint(
      'WebRTC: Subscribing to ICE candidates for call: $_currentCallId',
    );
    _iceCandidateChannel = _supabase.client.channel('ice_$_currentCallId');

    _iceCandidateChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ice_candidates',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'call_id',
            value: _currentCallId,
          ),
          callback: (payload) async {
            final data = payload.newRecord;
            final senderId = data['sender_id'] as String?;

            debugPrint('WebRTC: Received ICE candidate from: $senderId');

            // Kendi gönderdiğimiz candidate'leri ignore et
            if (senderId == currentUserId) {
              debugPrint('WebRTC: Ignoring own ICE candidate');
              return;
            }

            try {
              final candidate = RTCIceCandidate(
                data['candidate'] as String?,
                data['sdp_mid'] as String?,
                data['sdp_m_line_index'] as int?,
              );
              
              if (_isRemoteDescriptionSet && _peerConnection != null) {
                await _peerConnection!.addCandidate(candidate);
                debugPrint('WebRTC: ✅ Remote ICE candidate added directly');
              } else {
                _queuedRemoteCandidates.add(candidate);
                debugPrint('WebRTC: ⏳ Remote ICE candidate queued (pending remote description)');
              }

            } catch (e) {
              debugPrint('WebRTC: ❌ Error adding ICE candidate: $e');
            }
          },
        )
        .subscribe((status, error) {
          debugPrint(
            'WebRTC: ICE candidates subscription status: $status, error: $error',
          );
        });
  }

  /// Call connected güncelle
  Future<void> _updateCallConnected() async {
    if (_currentCallId == null) return;

    try {
      await _supabase.client
          .from('calls')
          .update({'connected_at': DateTime.now().toIso8601String()})
          .eq('id', _currentCallId!);
    } catch (e) {
      debugPrint('WebRTC: Error updating connected_at: $e');
    }
  }

  /// Force cleanup - önceki aramadan kalan state'i zorla temizle
  Future<void> _forceCleanup() async {
    debugPrint('WebRTC: Force cleanup started');
    _isEnding = false; // Reset flag
    await _cleanup();
    // Kısa bir bekleme - kaynakların serbest kalması için
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('WebRTC: Force cleanup completed');
  }

  /// Cleanup
  Future<void> _cleanup() async {
    debugPrint('WebRTC: Cleanup started');

    // Timer iptal
    _cancelCallTimeout();
    
    // Connection failed timer iptal
    _connectionFailedTimer?.cancel();
    _connectionFailedTimer = null;
    
    // Bildirim kapat (sadece callId varsa)
    final callId = _currentCallId;
    if (callId != null) {
      try {
        // Import yok, sadece Platform check ile çalışır
        if (Platform.isAndroid || Platform.isIOS) {
          await IncomingCallHandler.instance.endCall(callId);
          debugPrint('WebRTC: Notification closed for call: $callId');
        }
      } catch (e) {
        debugPrint('WebRTC: Error closing notification: $e');
      }
    }

    // Channels unsubscribe - try-catch ile
    try {
      await _callChannel?.unsubscribe();
    } catch (e) {
      debugPrint('WebRTC: Error unsubscribing call channel: $e');
    }
    try {
      await _iceCandidateChannel?.unsubscribe();
    } catch (e) {
      debugPrint('WebRTC: Error unsubscribing ICE channel: $e');
    }
    _callChannel = null;
    _iceCandidateChannel = null;

    // Media streams dispose - try-catch ile
    try {
      _localStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (e) {
          debugPrint('WebRTC: Error stopping local track: $e');
        }
      });
      _remoteStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (e) {
          debugPrint('WebRTC: Error stopping remote track: $e');
        }
      });
      await _localStream?.dispose();
      await _remoteStream?.dispose();
    } catch (e) {
      debugPrint('WebRTC: Error disposing streams: $e');
    }
    _localStream = null;
    _remoteStream = null;

    // Peer connection close - try-catch ile
    try {
      await _peerConnection?.close();
    } catch (e) {
      debugPrint('WebRTC: Error closing peer connection: $e');
    }
    _peerConnection = null;

    // State reset
    _currentCallId = null;
    _remoteUserId = null;
    _isVideoCall = false;
    _isCaller = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _isVideoEnabled = true;
    _isFrontCamera = true;
    // _isEnding burada sıfırlanMAMALI - çağıran fonksiyon sıfırlar

    _isRemoteDescriptionSet = false;
    _queuedRemoteCandidates.clear();

    debugPrint('WebRTC: Cleanup completed');
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
