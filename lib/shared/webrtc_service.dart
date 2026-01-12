import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

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
  static const int _callTimeoutSeconds = 45; // 45 saniye sonra cevapsız
  
  // Call state
  String? _currentCallId;
  String? _remoteUserId;
  bool _isVideoCall = false;
  bool _isCaller = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  
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
      // Google STUN (ücretsiz)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // OpenRelay TURN (ücretsiz)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
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

    if (isInCall) {
      debugPrint('WebRTC: Already in a call');
      return null;
    }

    try {
      _isVideoCall = isVideo;
      _isCaller = true;
      _remoteUserId = calleeId;

      // 1. Supabase'de call kaydı oluştur
      final callData = await _supabase.client.from('calls').insert({
        'caller_id': currentUserId,
        'callee_id': calleeId,
        'type': isVideo ? 'video' : 'voice', // DB'de 'type' kolonu var, default 'voice'
        'status': 'ringing',
      }).select().single();

      _currentCallId = callData['id'] as String;
      debugPrint('WebRTC: Call created: $_currentCallId');

      // 2. Local media stream al
      await _getUserMedia();

      // 3. Peer connection oluştur
      await _createPeerConnection();

      // 4. Offer oluştur ve gönder
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // 5. Offer'ı Supabase'e kaydet
      await _supabase.client.from('calls').update({
        'offer_sdp': offer.sdp,
        'ringing_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentCallId!);

      debugPrint('WebRTC: Offer sent');

      // 6. Signaling dinle
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
  }

  /// Cevapsız arama işle
  Future<void> _handleCallTimeout() async {
    if (_currentCallId == null) return;

    try {
      await _supabase.client.from('calls').update({
        'status': 'missed',
        'ended_at': DateTime.now().toIso8601String(),
        'end_reason': 'no_answer',
      }).eq('id', _currentCallId!);

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

    debugPrint('WebRTC: acceptCall started - callId: $callId, callerId: $callerId');
    debugPrint('WebRTC: offerSdp length: ${offerSdp.length}');

    try {
      _currentCallId = callId;
      _remoteUserId = callerId;
      _isVideoCall = isVideo;
      _isCaller = false;

      // 1. Local media stream al
      debugPrint('WebRTC: Getting user media...');
      await _getUserMedia();
      debugPrint('WebRTC: User media acquired');

      // 2. Peer connection oluştur
      debugPrint('WebRTC: Creating peer connection...');
      await _createPeerConnection();
      debugPrint('WebRTC: Peer connection created');

      // 3. Remote offer'ı set et
      debugPrint('WebRTC: Setting remote description (offer)...');
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerSdp, 'offer'),
      );
      debugPrint('WebRTC: Remote description set');

      // 4. Answer oluştur
      debugPrint('WebRTC: Creating answer...');
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      debugPrint('WebRTC: Local description (answer) set');

      // 5. Answer'ı Supabase'e kaydet
      debugPrint('WebRTC: Saving answer to Supabase...');
      await _supabase.client.from('calls').update({
        'answer_sdp': answer.sdp,
        'status': 'connected',
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', callId);

      debugPrint('WebRTC: Answer sent to Supabase');

      // 6. Signaling dinle
      _subscribeToCallUpdates();
      _subscribeToIceCandidates();

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
      await _supabase.client.from('calls').update({
        'status': 'rejected',
        'ended_at': DateTime.now().toIso8601String(),
        'end_reason': 'rejected',
      }).eq('id', callId);

      debugPrint('WebRTC: Call rejected');
    } catch (e) {
      debugPrint('WebRTC: Error rejecting call: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ARAMA SONLANDIRMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Aramayı sonlandır
  Future<void> endCall({String reason = 'ended'}) async {
    debugPrint('WebRTC: Ending call - reason: $reason');

    // Supabase'de güncelle
    if (_currentCallId != null) {
      try {
        await _supabase.client.from('calls').update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
          'end_reason': reason,
        }).eq('id', _currentCallId!);
      } catch (e) {
        debugPrint('WebRTC: Error updating call status: $e');
      }
    }

    // Cleanup
    await _cleanup();
    
    onCallEnded?.call(reason);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDYA KONTROLÜ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mikrofonu aç/kapat
  void toggleMute() {
    if (_localStream == null) return;

    _isMuted = !_isMuted;
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    
    debugPrint('WebRTC: Mute toggled: $_isMuted');
    notifyListeners();
  }

  /// Hoparlörü aç/kapat
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    Helper.setSpeakerphoneOn(_isSpeakerOn);
    
    debugPrint('WebRTC: Speaker toggled: $_isSpeakerOn');
    notifyListeners();
  }

  /// Videoyu aç/kapat
  void toggleVideo() {
    if (_localStream == null || !_isVideoCall) return;

    _isVideoEnabled = !_isVideoEnabled;
    _localStream!.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });
    
    debugPrint('WebRTC: Video toggled: $_isVideoEnabled');
    notifyListeners();
  }

  /// Kamerayı değiştir (ön/arka)
  Future<void> switchCamera() async {
    if (_localStream == null || !_isVideoCall) return;

    _isFrontCamera = !_isFrontCamera;
    await Helper.switchCamera(
      _localStream!.getVideoTracks().first,
    );
    
    debugPrint('WebRTC: Camera switched: ${_isFrontCamera ? 'front' : 'back'}');
    notifyListeners();
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
      'audio': true,
      'video': _isVideoCall
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    onLocalStream?.call(_localStream!);
    
    debugPrint('WebRTC: Local stream acquired');
  }

  /// Peer connection oluştur
  Future<void> _createPeerConnection() async {
    debugPrint('WebRTC: Creating peer connection with ICE servers: $_iceServers');
    _peerConnection = await createPeerConnection(_iceServers);

    // Local tracks ekle
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
      debugPrint('WebRTC: Added local track: ${track.kind}');
    });

    // Remote stream handler
    _peerConnection!.onTrack = (event) {
      debugPrint('WebRTC: onTrack event - streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
        debugPrint('WebRTC: Remote stream received - tracks: ${_remoteStream?.getTracks().length}');
      }
    };

    // ICE candidate handler
    _peerConnection!.onIceCandidate = (candidate) {
      debugPrint('WebRTC: ICE candidate generated: ${candidate.candidate?.substring(0, 50)}...');
      if (candidate.candidate != null && _currentCallId != null) {
        _sendIceCandidate(candidate);
      }
    };
    
    // ICE connection state handler
    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('WebRTC: ICE connection state: $state');
    };
    
    // ICE gathering state handler
    _peerConnection!.onIceGatheringState = (state) {
      debugPrint('WebRTC: ICE gathering state: $state');
    };

    // Connection state handler
    _peerConnection!.onConnectionState = (state) {
      debugPrint('WebRTC: Connection state: $state');
      onConnectionState?.call(state);
      
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        // Bağlantı kuruldu
        debugPrint('WebRTC: ✅ Connection established!');
        _updateCallConnected();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // Bağlantı kesildi
        debugPrint('WebRTC: ❌ Connection failed or disconnected');
        endCall(reason: 'connection_failed');
      }
    };

    debugPrint('WebRTC: Peer connection created');
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
          
          debugPrint('WebRTC: Call update - status: $status');

          if (status == 'connected' && _isCaller) {
            // Caller: Answer geldi - timeout iptal et
            _cancelCallTimeout();
            final answerSdp = call['answer_sdp'] as String?;
            if (answerSdp != null) {
              await _peerConnection?.setRemoteDescription(
                RTCSessionDescription(answerSdp, 'answer'),
              );
              onCallAccepted?.call();
              debugPrint('WebRTC: Answer received and set');
            }
          } else if (status == 'rejected') {
            _cancelCallTimeout();
            onCallRejected?.call();
            await endCall(reason: 'rejected');
          } else if (status == 'ended') {
            _cancelCallTimeout();
            final endReason = call['end_reason'] as String? ?? 'ended';
            await endCall(reason: endReason);
          } else if (status == 'missed') {
            _cancelCallTimeout();
            await endCall(reason: 'no_answer');
          }
        },
      )
      .subscribe();
  }

  /// ICE candidates dinle
  void _subscribeToIceCandidates() {
    if (_currentCallId == null) return;

    debugPrint('WebRTC: Subscribing to ICE candidates for call: $_currentCallId');
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
            await _peerConnection?.addCandidate(candidate);
            debugPrint('WebRTC: ✅ Remote ICE candidate added successfully');
          } catch (e) {
            debugPrint('WebRTC: ❌ Error adding ICE candidate: $e');
          }
        },
      )
      .subscribe((status, error) {
        debugPrint('WebRTC: ICE candidates subscription status: $status, error: $error');
      });
  }

  /// Call connected güncelle
  Future<void> _updateCallConnected() async {
    if (_currentCallId == null) return;

    try {
      await _supabase.client.from('calls').update({
        'connected_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentCallId!);
    } catch (e) {
      debugPrint('WebRTC: Error updating connected_at: $e');
    }
  }

  /// Cleanup
  Future<void> _cleanup() async {
    // Timer iptal
    _cancelCallTimeout();
    
    // Channels unsubscribe
    await _callChannel?.unsubscribe();
    await _iceCandidateChannel?.unsubscribe();
    _callChannel = null;
    _iceCandidateChannel = null;

    // Media streams dispose
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;

    // Peer connection close
    await _peerConnection?.close();
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

    debugPrint('WebRTC: Cleanup completed');
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
