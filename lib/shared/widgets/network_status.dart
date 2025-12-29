import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Network Status Indicator
/// - Bağlantı durumu gösterimi
/// - Otomatik yeniden bağlanma
/// - Animated banner
class NetworkStatusIndicator extends StatefulWidget {
  final Widget child;
  final NetworkStatus status;
  final VoidCallback? onRetry;
  final bool showWhenConnected;

  const NetworkStatusIndicator({
    super.key,
    required this.child,
    this.status = NetworkStatus.connected,
    this.onRetry,
    this.showWhenConnected = false,
  });

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(NetworkStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    final shouldShow = widget.status != NetworkStatus.connected ||
        widget.showWhenConnected;

    if (shouldShow) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status banner
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _slideAnimation.value + 1,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: _buildBanner(),
                ),
              ),
            );
          },
        ),

        // Main content
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner() {
    final config = _getBannerConfig();

    return Material(
      color: config.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animation
              if (widget.status == NetworkStatus.connecting)
                _PulsingIcon(
                  icon: config.icon,
                  color: config.textColor,
                )
              else
                Icon(config.icon, color: config.textColor, size: 18),

              const SizedBox(width: 8),

              // Status text
              Text(
                config.message,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Retry button
              if (widget.status == NetworkStatus.disconnected &&
                  widget.onRetry != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onRetry?.call();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: config.textColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        color: config.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _BannerConfig _getBannerConfig() {
    switch (widget.status) {
      case NetworkStatus.connected:
        return _BannerConfig(
          backgroundColor: Colors.green,
          textColor: Colors.white,
          icon: Icons.wifi,
          message: 'Bağlandı',
        );
      case NetworkStatus.connecting:
        return _BannerConfig(
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          icon: Icons.sync,
          message: 'Bağlanıyor...',
        );
      case NetworkStatus.disconnected:
        return _BannerConfig(
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
          icon: Icons.wifi_off,
          message: 'Bağlantı Yok',
        );
      case NetworkStatus.slow:
        return _BannerConfig(
          backgroundColor: Colors.amber.shade700,
          textColor: Colors.white,
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
          message: 'Yavaş Bağlantı',
        );
    }
  }
}

class _BannerConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String message;

  const _BannerConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.message,
  });
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Icon(widget.icon, color: widget.color, size: 18),
        );
      },
    );
  }
}

/// Network status types
enum NetworkStatus {
  connected,
  connecting,
  disconnected,
  slow,
}

/// Standalone Network Banner Widget
/// App bar altında kullanılabilir
class NetworkBanner extends StatelessWidget {
  final NetworkStatus status;
  final VoidCallback? onRetry;

  const NetworkBanner({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == NetworkStatus.connected) {
      return const SizedBox.shrink();
    }

    final config = _getConfig();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: config.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == NetworkStatus.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(config.textColor),
              ),
            )
          else
            Icon(config.icon, color: config.textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            config.message,
            style: TextStyle(
              color: config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status == NetworkStatus.disconnected && onRetry != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Tekrar Dene',
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BannerConfig _getConfig() {
    switch (status) {
      case NetworkStatus.connected:
        return _BannerConfig(
          backgroundColor: Colors.green,
          textColor: Colors.white,
          icon: Icons.wifi,
          message: 'Bağlandı',
        );
      case NetworkStatus.connecting:
        return _BannerConfig(
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          icon: Icons.sync,
          message: 'Bağlanıyor...',
        );
      case NetworkStatus.disconnected:
        return _BannerConfig(
          backgroundColor: Colors.red.shade600,
          textColor: Colors.white,
          icon: Icons.wifi_off,
          message: 'İnternet bağlantısı yok',
        );
      case NetworkStatus.slow:
        return _BannerConfig(
          backgroundColor: Colors.amber.shade700,
          textColor: Colors.white,
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
          message: 'Yavaş bağlantı',
        );
    }
  }
}

/// Connection Status Service (Mock)
/// Gerçek uygulamada connectivity_plus paketi kullanılır
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._();
  static ConnectionService get instance => _instance;

  ConnectionService._();

  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  NetworkStatus _currentStatus = NetworkStatus.connected;
  NetworkStatus get currentStatus => _currentStatus;

  void setStatus(NetworkStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }

  /// Simulate connection check
  Future<bool> checkConnection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentStatus == NetworkStatus.connected;
  }
}

/// Network Aware Widget
/// Bağlantı durumuna göre UI değiştirir
class NetworkAwareBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, NetworkStatus status) builder;
  final NetworkStatus? initialStatus;

  const NetworkAwareBuilder({
    super.key,
    required this.builder,
    this.initialStatus,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      initialData: initialStatus ?? ConnectionService.instance.currentStatus,
      stream: ConnectionService.instance.statusStream,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? NetworkStatus.connected);
      },
    );
  }
}

/// Offline Mode Indicator
class OfflineModeIndicator extends StatelessWidget {
  final Widget child;
  final String? message;

  const OfflineModeIndicator({
    super.key,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkAwareBuilder(
      builder: (context, status) {
        if (status == NetworkStatus.connected) {
          return child;
        }

        return Stack(
          children: [
            // Grayscale filter when offline
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: child,
            ),

            // Offline overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message ?? 'Çevrimdışı mod - Bazı özellikler kullanılamaz',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
