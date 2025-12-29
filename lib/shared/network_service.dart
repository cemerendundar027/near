import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Ağ durumu servisi
class NetworkService extends ChangeNotifier {
  static final NetworkService instance = NetworkService._internal();
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  bool _wasOffline = false;
  
  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;

  /// Servisi başlat
  Future<void> init() async {
    // İlk durumu kontrol et
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    
    // Değişiklikleri dinle
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hadConnection = _isOnline;
    
    // Herhangi bir bağlantı var mı kontrol et
    _isOnline = results.isNotEmpty && 
        !results.every((r) => r == ConnectivityResult.none);
    
    // Tekrar çevrimiçi olduysa bayrak ayarla
    if (!hadConnection && _isOnline) {
      _wasOffline = true;
      // 3 saniye sonra bayrağı sıfırla
      Future.delayed(const Duration(seconds: 3), () {
        _wasOffline = false;
        notifyListeners();
      });
    }
    
    notifyListeners();
  }

  /// Bağlantı tipini al
  Future<String> getConnectionType() async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return 'Bağlantı yok';
    }
    
    if (results.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobil veri';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    }
    return 'Bilinmiyor';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Çevrimdışı durumu gösteren banner widget'ı
class OfflineBanner extends StatelessWidget {
  final Widget child;
  
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkService.instance,
      builder: (context, _) {
        final network = NetworkService.instance;
        
        return Column(
          children: [
            // Çevrimdışı banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: network.isOnline ? 0 : 28,
              color: Colors.red.shade700,
              child: network.isOnline 
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Çevrimdışı',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            // Tekrar çevrimiçi banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: network.wasOffline && network.isOnline ? 28 : 0,
              color: Colors.green.shade600,
              child: !network.wasOffline || !network.isOnline
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bağlantı sağlandı',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            
            // Ana içerik
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// Ağ durumu göstergesi widget'ı (küçük)
class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkService.instance,
      builder: (context, _) {
        final isOnline = NetworkService.instance.isOnline;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}
