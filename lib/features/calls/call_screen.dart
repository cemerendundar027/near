import 'package:flutter/material.dart';
import 'dart:async';
import '../../app/theme.dart';
import '../../shared/chat_store.dart';
import '../../shared/models.dart';

class CallArgs {
  final String name;
  final bool video;
  const CallArgs({required this.name, required this.video});
}

class CallScreen extends StatefulWidget {
  static const route = '/call';

  /// Deep link parameters
  final String? deepLinkUserId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    this.deepLinkUserId,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  bool _muted = false;
  bool _speaker = false;
  late bool _cameraOn;
  bool _cameraFront = true;
  bool _isConnected = false;
  int _callDuration = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  String? _callerName;
  bool? _isVideo;

  @override
  void initState() {
    super.initState();
    _cameraOn = widget.isVideoCall;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Handle deep link user
    if (widget.deepLinkUserId != null) {
      final store = ChatStore.instance;
      final chat = store.chats.firstWhere(
        (c) => c.userId == widget.deepLinkUserId,
        orElse: () => const ChatPreview(
          id: '',
          userId: '',
          name: 'Kullanıcı',
          lastMessage: '',
          time: '',
          online: false,
        ),
      );
      _callerName = chat.name;
      _isVideo = widget.isVideoCall;
    }

    // Simüle edilen bağlantı
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _startTimer();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get caller info from route arguments if not from deep link
    if (_callerName == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is CallArgs) {
        _callerName = arg.name;
        _isVideo = arg.video;
        _cameraOn = arg.video;
      } else {
        _callerName = 'Kullanıcı';
        _isVideo = false;
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _endCall() {
    Navigator.pop(context);
  }

  void _showAddPersonDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contacts = [
      {'name': 'Ayşe Demir', 'phone': '+90 532 XXX XX XX'},
      {'name': 'Mehmet Kaya', 'phone': '+90 533 XXX XX XX'},
      {'name': 'Zeynep Yıldız', 'phone': '+90 534 XXX XX XX'},
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aramaya Kişi Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ...contacts.map((contact) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: NearTheme.primary.withAlpha(30),
                  child: Text(
                    (contact['name'] as String)[0],
                    style: TextStyle(
                      color: NearTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  contact['name'] as String,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  contact['phone'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.call_rounded, color: NearTheme.primary),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${contact['name']} aramaya eklendi'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showScreenShareDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ekran Paylaşımı',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.screen_share_rounded,
              size: 64,
              color: NearTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ekranınızı diğer katılımcılarla paylaşmak istediğinizden emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ekranınızdaki tüm içerikler görünür olacak.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ekran paylaşımı başlatıldı'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NearTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Paylaş'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_rounded),
                title: const Text('Kişi Ekle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddPersonDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.screen_share_rounded),
                title: const Text('Ekranı Paylaş'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showScreenShareDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bluetooth_audio_rounded),
                title: const Text('Bluetooth Cihazlar'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideo ?? false;

    return Scaffold(
      backgroundColor: isVideo ? Colors.black : NearTheme.primaryDark,
      body: Stack(
        children: [
          // Video arka plan (video arama için)
          if (isVideo && _cameraOn)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Icon(
                    Icons.videocam,
                    size: 100,
                    color: Colors.white.withAlpha(30),
                  ),
                ),
              ),
            ),

          // Gradient overlay
          if (!isVideo)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      NearTheme.primaryDark,
                      NearTheme.primary,
                      NearTheme.primaryDark,
                    ],
                  ),
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Encryption badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Colors.white.withAlpha(200),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Uçtan uca şifreli',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // More button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _showMoreOptions,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Profile section
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) {
                    final scale = _isConnected
                        ? 1.0
                        : 1.0 + (_pulseController.value * 0.05);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Column(
                    children: [
                      // Avatar with rings
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring (animasyonlu)
                          if (!_isConnected)
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(40),
                                  width: 2,
                                ),
                              ),
                            ),
                          // Inner ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 3,
                              ),
                            ),
                          ),
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 55,
                              color: Colors.white.withAlpha(230),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Name
                      Text(
                        _callerName ?? 'Kullanıcı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isConnected
                              ? _formatDuration(_callDuration)
                              : (isVideo
                                    ? 'Video arama bağlanıyor...'
                                    : 'Aranıyor...'),
                          key: ValueKey(
                            _isConnected ? 'connected' : 'connecting',
                          ),
                          style: TextStyle(
                            color: Colors.white.withAlpha(
                              _isConnected ? 230 : 180,
                            ),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Expanded(flex: 1, child: SizedBox()),

                // Video arama için küçük pencere (self view)
                if (isVideo && _cameraOn)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white38,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _cameraFront = !_cameraFront,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.cameraswitch_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Expanded(flex: 1, child: SizedBox()),

                // Control buttons
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      // Primary controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: _speaker
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            label: 'Hoparlör',
                            isActive: _speaker,
                            onTap: () => setState(() => _speaker = !_speaker),
                          ),
                          if (isVideo)
                            _ControlButton(
                              icon: _cameraOn
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              label: 'Kamera',
                              isActive: !_cameraOn,
                              onTap: () =>
                                  setState(() => _cameraOn = !_cameraOn),
                            ),
                          _ControlButton(
                            icon: _muted
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: 'Mikrofon',
                            isActive: _muted,
                            onTap: () => setState(() => _muted = !_muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // End call button
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withAlpha(100),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aramayı Bitir',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? NearTheme.primaryDark : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
