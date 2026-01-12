import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../app/theme.dart';
import '../../shared/webrtc_service.dart';
import '../../shared/chat_service.dart';

/// Arama Ekranı - Sesli ve Görüntülü Arama UI
class CallScreen extends StatefulWidget {
  final String? callId;
  final String? remoteUserId;
  final bool isVideo;
  final bool isIncoming;
  final String? offerSdp;
  
  // Deep link için
  final String? deepLinkUserId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    this.callId,
    this.remoteUserId,
    this.isVideo = false,
    this.isIncoming = false,
    this.offerSdp,
    this.deepLinkUserId,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final _webrtc = WebRTCService.instance;
  final _chatService = ChatService.instance;

  // Renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // State
  String _callStatus = 'connecting';
  String? _remoteUserName;
  String? _remoteUserAvatar;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _showControls = true;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _renderersInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAll();
  }
  
  Future<void> _initializeAll() async {
    await _initRenderers();
    _setupCallbacks();
    _initCall();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _renderersInitialized = true;
      debugPrint('CallScreen: ✅ Renderers initialized');
    } catch (e) {
      debugPrint('CallScreen: ❌ Error initializing renderers: $e');
    }
  }

  void _setupCallbacks() {
    _webrtc.onLocalStream = (stream) {
      debugPrint('CallScreen: onLocalStream callback - stream id: ${stream.id}');
      debugPrint('CallScreen: onLocalStream - video tracks: ${stream.getVideoTracks().length}');
      if (mounted && _renderersInitialized) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
        debugPrint('CallScreen: ✅ Local stream set to renderer');
      } else {
        debugPrint('CallScreen: ⚠️ Cannot set local stream - mounted: $mounted, initialized: $_renderersInitialized');
      }
    };

    _webrtc.onRemoteStream = (stream) {
      debugPrint('CallScreen: 🎥 onRemoteStream callback - stream id: ${stream.id}');
      debugPrint('CallScreen: onRemoteStream - video tracks: ${stream.getVideoTracks().length}');
      debugPrint('CallScreen: onRemoteStream - audio tracks: ${stream.getAudioTracks().length}');
      if (mounted && _renderersInitialized) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          _callStatus = 'connected';
          _startCallTimer();
        });
        debugPrint('CallScreen: ✅ Remote stream set to renderer');
      } else {
        debugPrint('CallScreen: ⚠️ Cannot set remote stream - mounted: $mounted, initialized: $_renderersInitialized');
      }
    };

    _webrtc.onConnectionState = (state) {
      debugPrint('CallScreen: Connection state changed: $state');
      if (!mounted) return;
      
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() => _callStatus = 'connected');
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _handleCallEnded('connection_failed');
      }
    };

    _webrtc.onCallAccepted = () {
      if (mounted) {
        setState(() => _callStatus = 'connected');
      }
    };

    _webrtc.onCallRejected = () {
      _handleCallEnded('rejected');
    };

    _webrtc.onCallEnded = (reason) {
      debugPrint('CallScreen: onCallEnded callback - reason: $reason');
      _handleCallEnded(reason);
    };
    
    _webrtc.onCallTimeout = () {
      _handleCallEnded('no_answer');
    };
  }

  Future<void> _initCall() async {
    debugPrint('CallScreen: _initCall started');
    debugPrint('CallScreen: callId=${widget.callId}, remoteUserId=${widget.remoteUserId}, deepLinkUserId=${widget.deepLinkUserId}');
    debugPrint('CallScreen: isVideo=${widget.isVideo}, isVideoCall=${widget.isVideoCall}, isIncoming=${widget.isIncoming}');
    
    // Remote user bilgisi al
    final remoteId = widget.remoteUserId ?? widget.deepLinkUserId;
    
    // Geçersiz parametre kontrolü - userId yoksa ekranı kapat
    if (remoteId == null || remoteId.isEmpty) {
      debugPrint('CallScreen: No valid userId provided, closing screen');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
      return;
    }
    
    debugPrint('CallScreen: Loading remote user info for: $remoteId');
    await _loadRemoteUserInfo(remoteId);

    if (widget.isIncoming) {
      // Gelen arama - kullanıcı zaten CallKit'ten kabul etti, aramayı başlat
      debugPrint('CallScreen: Incoming call mode - accepting call');
      setState(() => _callStatus = 'connecting');
      
      // Aramayı kabul et
      await _acceptIncomingCall();
    } else {
      // Giden arama - başlat
      debugPrint('CallScreen: Outgoing call mode - starting call');
      setState(() => _callStatus = 'calling');
      
      final targetUserId = widget.remoteUserId ?? widget.deepLinkUserId;
      final isVideo = widget.isVideo || widget.isVideoCall;
      
      if (targetUserId != null && targetUserId.isNotEmpty) {
        debugPrint('CallScreen: Calling WebRTCService.startCall(calleeId: $targetUserId, isVideo: $isVideo)');
        try {
          final callId = await _webrtc.startCall(
            calleeId: targetUserId,
            isVideo: isVideo,
          );
          
          debugPrint('CallScreen: startCall returned callId: $callId');
          
          if (callId == null) {
            debugPrint('CallScreen: startCall returned null, ending call');
            _handleCallEnded('error');
          }
        } catch (e) {
          debugPrint('CallScreen: startCall exception: $e');
          _handleCallEnded('error');
        }
      } else {
        debugPrint('CallScreen: No target userId, ending call');
        _handleCallEnded('error');
      }
    }
  }

  /// Gelen aramayı kabul et
  Future<void> _acceptIncomingCall() async {
    final callId = widget.callId;
    final callerId = widget.remoteUserId ?? widget.deepLinkUserId;
    final isVideo = widget.isVideo || widget.isVideoCall;
    
    if (callId == null || callerId == null) {
      debugPrint('CallScreen: Missing callId or callerId for incoming call');
      _handleCallEnded('error');
      return;
    }
    
    // DB'den offer_sdp'yi çek
    try {
      final call = await _chatService.supabase
          .from('calls')
          .select('offer_sdp')
          .eq('id', callId)
          .single();
      
      final offerSdp = call['offer_sdp'] as String?;
      if (offerSdp == null) {
        debugPrint('CallScreen: No offer_sdp found for call');
        _handleCallEnded('error');
        return;
      }
      
      debugPrint('CallScreen: Accepting call with offer_sdp');
      final success = await _webrtc.acceptCall(
        callId: callId,
        callerId: callerId,
        isVideo: isVideo,
        offerSdp: offerSdp,
      );
      
      if (!success) {
        debugPrint('CallScreen: Failed to accept call');
        _handleCallEnded('error');
      }
    } catch (e) {
      debugPrint('CallScreen: Error accepting call: $e');
      _handleCallEnded('error');
    }
  }

  Future<void> _loadRemoteUserInfo(String userId) async {
    try {
      debugPrint('CallScreen: Loading user info by ID: $userId');
      // UUID ile direkt profiles tablosundan çek
      final user = await _chatService.getUserById(userId);
      if (user != null) {
        setState(() {
          _remoteUserName = user['full_name'] ?? user['username'] ?? 'Unknown';
          _remoteUserAvatar = user['avatar_url'];
        });
        debugPrint('CallScreen: User loaded: $_remoteUserName');
      } else {
        debugPrint('CallScreen: User not found for ID: $userId');
      }
    } catch (e) {
      debugPrint('CallScreen: Error loading user info: $e');
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool _isEnding = false;
  
  void _handleCallEnded(String reason) {
    // Birden fazla kez çağrılmasını önle
    if (_isEnding) {
      debugPrint('CallScreen: _handleCallEnded already in progress, skipping');
      return;
    }
    _isEnding = true;
    
    debugPrint('CallScreen: _handleCallEnded called with reason: $reason');
    _callTimer?.cancel();
    
    String message;
    switch (reason) {
      case 'rejected':
        message = 'Arama reddedildi';
        break;
      case 'busy':
        message = 'Kullanıcı meşgul';
        break;
      case 'no_answer':
        message = 'Cevap yok';
        break;
      case 'connection_failed':
        message = 'Bağlantı hatası';
        break;
      case 'ended':
        message = 'Arama sonlandırıldı';
        break;
      default:
        message = 'Arama bitti';
    }

    if (mounted) {
      debugPrint('CallScreen: Showing snackbar and popping screen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    } else {
      debugPrint('CallScreen: Not mounted, cannot pop');
    }
  }

  Future<void> _acceptCall() async {
    if (widget.callId == null || widget.offerSdp == null) return;

    setState(() => _callStatus = 'connecting');

    final success = await _webrtc.acceptCall(
      callId: widget.callId!,
      callerId: widget.remoteUserId!,
      isVideo: widget.isVideo,
      offerSdp: widget.offerSdp!,
    );

    if (!success) {
      _handleCallEnded('error');
    }
  }

  Future<void> _rejectCall() async {
    if (widget.callId != null) {
      await _webrtc.rejectCall(widget.callId!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _endCall() async {
    await _webrtc.endCall(reason: 'ended');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    debugPrint('CallScreen: dispose called');
    _callTimer?.cancel();
    _pulseController.dispose();
    
    // Önce stream'leri temizle, sonra renderer'ları dispose et
    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    } catch (e) {
      debugPrint('CallScreen: Error clearing renderer sources: $e');
    }
    
    // Küçük bir gecikme ile dispose et (stream temizlenmesini bekle)
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _localRenderer.dispose();
        _remoteRenderer.dispose();
        debugPrint('CallScreen: ✅ Renderers disposed');
      } catch (e) {
        debugPrint('CallScreen: Error disposing renderers: $e');
      }
    });
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.isVideo || widget.isVideoCall;
    
    debugPrint('CallScreen: BUILD called - status=$_callStatus, isVideo=$isVideo, showControls=$_showControls');
    debugPrint('CallScreen: remoteUserName=$_remoteUserName, remoteUserAvatar=$_remoteUserAvatar');

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Background
            if (isVideo && _callStatus == 'connected')
              _buildVideoView()
            else
              _buildAudioView(),

            // Top bar
            if (_showControls) _buildTopBar(),

            // Controls
            if (_showControls) _buildControls(),

            // Incoming call actions
            if (_callStatus == 'incoming') _buildIncomingCallActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    debugPrint('CallScreen: Building video view - remote stream: ${_remoteRenderer.srcObject != null}');
    
    return Stack(
      children: [
        // Remote video (full screen)
        Positioned.fill(
          child: _remoteRenderer.srcObject != null
              ? RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('Video bekleniyor...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
        ),

        // Local video (PIP)
        if (_localRenderer.srcObject != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: GestureDetector(
              onTap: () {
                try {
                  _webrtc.switchCamera();
                } catch (e) {
                  debugPrint('CallScreen: Error switching camera: $e');
                }
              },
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: RTCVideoView(
                  _localRenderer,
                  mirror: _webrtc.isFrontCamera,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NearTheme.primary.withAlpha(150),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Avatar
            ScaleTransition(
              scale: _callStatus == 'calling' || _callStatus == 'incoming'
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NearTheme.primary.withAlpha(50),
                  border: Border.all(
                    color: NearTheme.primary.withAlpha(100),
                    width: 3,
                  ),
                ),
                child: _remoteUserAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          _remoteUserAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),

            const SizedBox(height: 24),

            // Name
            Text(
              _remoteUserName ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Status
            Text(
              _getStatusText(),
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 16,
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(Icons.person, size: 60, color: Colors.white54),
    );
  }

  String _getStatusText() {
    switch (_callStatus) {
      case 'incoming':
        return widget.isVideo ? 'Görüntülü Arama Geliyor...' : 'Sesli Arama Geliyor...';
      case 'calling':
        return 'Aranıyor...';
      case 'connecting':
        return 'Bağlanıyor...';
      case 'connected':
        return _formatDuration(_callDuration);
      default:
        return '';
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(150),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),

            const Spacer(),

            // Call type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isVideo || widget.isVideoCall
                        ? Icons.videocam
                        : Icons.call,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isVideo || widget.isVideoCall ? 'Video' : 'Sesli',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Encryption indicator
            const Icon(Icons.lock, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_callStatus == 'incoming') return const SizedBox();
    final isVideo = widget.isVideo || widget.isVideoCall;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(200),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute
            _buildControlButton(
              icon: _webrtc.isMuted ? Icons.mic_off : Icons.mic,
              label: _webrtc.isMuted ? 'Aç' : 'Kapat',
              isActive: _webrtc.isMuted,
              onTap: () {
                try {
                  _webrtc.toggleMute();
                  if (mounted) setState(() {});
                } catch (e) {
                  debugPrint('CallScreen: Error toggling mute: $e');
                }
              },
            ),

            // Video toggle (sadece video aramada)
            if (isVideo)
              _buildControlButton(
                icon: _webrtc.isVideoEnabled
                    ? Icons.videocam
                    : Icons.videocam_off,
                label: _webrtc.isVideoEnabled ? 'Kapat' : 'Aç',
                isActive: !_webrtc.isVideoEnabled,
                onTap: () {
                  try {
                    _webrtc.toggleVideo();
                    if (mounted) setState(() {});
                  } catch (e) {
                    debugPrint('CallScreen: Error toggling video: $e');
                  }
                },
              ),

            // End call
            _buildControlButton(
              icon: Icons.call_end,
              label: 'Bitir',
              isDestructive: true,
              onTap: _endCall,
            ),

            // Speaker
            _buildControlButton(
              icon: _webrtc.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              label: 'Hoparlör',
              isActive: _webrtc.isSpeakerOn,
              onTap: () {
                try {
                  _webrtc.toggleSpeaker();
                  if (mounted) setState(() {});
                } catch (e) {
                  debugPrint('CallScreen: Error toggling speaker: $e');
                }
              },
            ),

            // Flip camera (sadece video aramada)
            if (isVideo)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                label: 'Çevir',
                onTap: () async {
                  try {
                    await _webrtc.switchCamera();
                    if (mounted) setState(() {});
                  } catch (e) {
                    debugPrint('CallScreen: Error switching camera: $e');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDestructive
                  ? Colors.red
                  : isActive
                      ? Colors.white
                      : Colors.white.withAlpha(30),
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? Colors.white
                  : isActive
                      ? Colors.black
                      : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallActions() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 48,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject
          GestureDetector(
            onTap: _rejectCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Accept
          GestureDetector(
            onTap: _acceptCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: Icon(
                widget.isVideo || widget.isVideoCall
                    ? Icons.videocam
                    : Icons.call,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
