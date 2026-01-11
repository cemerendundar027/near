import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/theme.dart';
import '../../shared/device_service.dart';

/// Bağlı Cihazlar Sayfası (WhatsApp Style)
class LinkedDevicesPage extends StatefulWidget {
  static const route = '/linked-devices';
  const LinkedDevicesPage({super.key});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  final _deviceService = DeviceService.instance;
  
  List<DeviceSession> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final devices = await _deviceService.getUserSessions();
    setState(() {
      _devices = devices;
      _isLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  Future<void> _logoutDevice(DeviceSession device) async {
    if (device.isCurrent) {
      _showSnackBar('Mevcut cihazın oturumunu kapatamazsınız');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: NearTheme.primary),
            const SizedBox(width: 16),
            const Text('Oturum kapatılıyor...'),
          ],
        ),
      ),
    );

    final success = await _deviceService.deleteSession(device.id);
    
    if (!mounted) return;
    Navigator.pop(context);
    
    if (success) {
      _loadDevices();
      _showSnackBar('${device.deviceName} oturumu kapatıldı');
    } else {
      _showSnackBar('Oturum kapatılamadı');
    }
  }

  Future<void> _logoutAllDevices() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tüm Diğer Oturumları Kapat'),
        content: const Text(
          'Tüm diğer cihazların oturumu kapatılacak. Mevcut cihazınız etkilenmeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oturumları Kapat'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: NearTheme.primary),
            const SizedBox(width: 16),
            const Text('Oturumlar kapatılıyor...'),
          ],
        ),
      ),
    );

    final success = await _deviceService.deleteAllOtherSessions();
    
    if (!mounted) return;
    Navigator.pop(context);
    
    if (success) {
      _loadDevices();
      _showSnackBar('Tüm diğer oturumlar kapatıldı');
    } else {
      _showSnackBar('Oturumlar kapatılamadı');
    }
  }

  // _getDeviceIcon kaldırıldı, _getDeviceEmoji kullanılıyor
  
  String _getDeviceEmoji(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'desktop':
        return '💻';
      case 'web':
        return '🌐';
      case 'tablet':
        return '📱';
      case 'mobile':
      default:
        return '📱';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: const Text('Bağlı Cihazlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: CustomScrollView(
                slivers: [
                  // Info header
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NearTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: NearTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hesabınıza bağlı tüm cihazları görüntüleyin',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty state or device list
                  if (_devices.isEmpty) ...[
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_rounded,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz bağlı cihaz yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Aktif Oturumlar (${_devices.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            if (_devices.where((d) => !d.isCurrent).length > 1)
                              TextButton(
                                onPressed: _logoutAllDevices,
                                child: const Text(
                                  'Tümünü Kapat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final device = _devices[index];
                          final emoji = _getDeviceEmoji(device.deviceType);
                          final timeAgo = timeago.format(device.lastActiveAt, locale: 'tr');
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: device.isCurrent
                                  ? Border.all(color: NearTheme.primary, width: 1.5)
                                  : null,
                            ),
                            child: ListTile(
                              onTap: device.isCurrent
                                  ? null
                                  : () => _logoutDevice(device),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 32)),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.deviceName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (device.isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NearTheme.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Bu Cihaz',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: NearTheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (device.deviceOS != null)
                                    Text(
                                      device.deviceOS!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Son aktif: $timeAgo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                  if (device.city != null || device.country != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        [device.city, device.country]
                                            .where((e) => e != null)
                                            .join(', '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: device.isCurrent
                                  ? null
                                  : Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                            ),
                          );
                        },
                        childCount: _devices.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ],
              ),
            ),
    );
  }
}
