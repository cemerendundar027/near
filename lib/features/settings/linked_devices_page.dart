import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Bağlı Cihazlar Sayfası
/// - QR ile cihaz bağlama
/// - Bağlı cihazlar listesi
/// - Cihaz çıkış
class LinkedDevicesPage extends StatefulWidget {
  static const route = '/linked-devices';
  const LinkedDevicesPage({super.key});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimController;

  // Mock data - bağlı cihazlar
  final List<LinkedDevice> _devices = [
    LinkedDevice(
      id: 'd1',
      name: 'MacBook Pro',
      type: DeviceType.desktop,
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      isCurrentDevice: false,
    ),
    LinkedDevice(
      id: 'd2',
      name: 'Chrome - Windows',
      type: DeviceType.web,
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      isCurrentDevice: false,
    ),
    LinkedDevice(
      id: 'd3',
      name: 'iPad Air',
      type: DeviceType.tablet,
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
      isCurrentDevice: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  void _showQRScanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'QR Kodu Tara',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR Scanner Frame
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 100,
                          color: NearTheme.primary.withAlpha(100),
                        ),
                      ),
                      // Animated scan line
                      AnimatedBuilder(
                        animation: _scanAnimController,
                        builder: (context, child) {
                          return Positioned(
                            top: 20 + (_scanAnimController.value * 210),
                            child: Container(
                              width: 210,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    NearTheme.primary,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Corner decorations
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _CornerDecoration(corner: Corner.topLeft),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _CornerDecoration(corner: Corner.topRight),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _CornerDecoration(corner: Corner.bottomLeft),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _CornerDecoration(corner: Corner.bottomRight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'near Web veya Desktop\'tan QR kodu tarayın',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Instructions
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NearTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InstructionStep(
                          number: '1',
                          text: 'near Web veya Desktop\'u açın',
                        ),
                        const SizedBox(height: 12),
                        _InstructionStep(
                          number: '2',
                          text: 'QR kodu ekranda görüntüleyin',
                        ),
                        const SizedBox(height: 12),
                        _InstructionStep(
                          number: '3',
                          text: 'Kameranızı QR koduna tutun',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Simüle butonu
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _simulateLinkDevice();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Demo: Cihaz Bağla'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateLinkDevice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: NearTheme.primary),
            const SizedBox(width: 16),
            const Text('Cihaz bağlanıyor...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _devices.insert(
          0,
          LinkedDevice(
            id: 'new_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Yeni Cihaz',
            type: DeviceType.web,
            lastActive: DateTime.now(),
            isCurrentDevice: false,
          ),
        );
      });
      _showSnackBar('Cihaz başarıyla bağlandı!');
    });
  }

  void _showDeviceOptions(LinkedDevice device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
              const SizedBox(height: 24),
              // Device info
              Icon(
                _getDeviceIcon(device.type),
                size: 48,
                color: NearTheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                device.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Son aktif: ${_formatLastActive(device.lastActive)}',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logoutDevice(device);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Oturumu Kapat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(color: NearTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _logoutDevice(LinkedDevice device) {
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

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _devices.removeWhere((d) => d.id == device.id);
      });
      _showSnackBar('${device.name} oturumu kapatıldı');
    });
  }

  void _logoutAllDevices() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tüm Oturumları Kapat',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Tüm bağlı cihazların oturumu kapatılacak. Devam etmek istiyor musunuz?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _devices.clear());
              _showSnackBar('Tüm oturumlar kapatıldı');
            },
            child: const Text('Kapat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    return '${diff.inDays} gün önce';
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.desktop:
        return Icons.desktop_mac_rounded;
      case DeviceType.web:
        return Icons.language_rounded;
      case DeviceType.tablet:
        return Icons.tablet_mac_rounded;
      case DeviceType.phone:
        return Icons.phone_iphone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: NearTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bağlı Cihazlar',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Link New Device Section
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // QR Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 40,
                    color: NearTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cihaz Bağla',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Bilgisayar veya tabletten near kullanmak için QR kodu tarayın',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showQRScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('QR Kodu Tara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NearTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Linked Devices Section
          if (_devices.isNotEmpty) ...[
            Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bağlı Cihazlar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: NearTheme.primary,
                    ),
                  ),
                  if (_devices.length > 1)
                    TextButton(
                      onPressed: _logoutAllDevices,
                      child: const Text(
                        'Tümünü Kapat',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: NearTheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDeviceIcon(device.type),
                        color: NearTheme.primary,
                      ),
                    ),
                    title: Text(
                      device.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Son aktif: ${_formatLastActive(device.lastActive)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    onTap: () => _showDeviceOptions(device),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Security Info
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, color: NearTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mesajlarınız kişisel cihazlarınızda şifrelenir. Bağlı cihazlarda mesajlar eşitlenir ve uçtan uca şifreli kalır.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Corner decoration for QR scanner
enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerDecoration extends StatelessWidget {
  final Corner corner;

  const _CornerDecoration({required this.corner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(painter: _CornerPainter(corner: corner)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Corner corner;

  _CornerPainter({required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NearTheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: NearTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ],
    );
  }
}

// Models
enum DeviceType { desktop, web, tablet, phone }

class LinkedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DateTime lastActive;
  final bool isCurrentDevice;

  LinkedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastActive,
    this.isCurrentDevice = false,
  });
}
