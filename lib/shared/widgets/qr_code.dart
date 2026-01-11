import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../contact_service.dart';
import '../supabase_service.dart';
import '../../app/theme.dart';

/// QR Code display widget using qr_flutter
class QRCodeDisplay extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const QRCodeDisplay({
    super.key,
    required this.data,
    this.size = 200,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size - 32,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor,
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// QR Code scanner page with backend integration using mobile_scanner
class QRScannerPage extends StatefulWidget {
  final void Function(String data)? onScanned;

  const QRScannerPage({super.key, this.onScanned});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _isProcessing = false;
  bool _flashOn = false;
  final _contactService = ContactService.instance;
  
  // mobile_scanner controller
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && !_isProcessing) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(milliseconds: 2000),
      ));
  }

  /// QR kodu çözümle ve kişiyi ekle
  Future<void> _processQRCode(String data) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      // QR formatı: near://user/{userId}
      final uri = Uri.tryParse(data);
      
      if (uri == null || uri.scheme != 'near') {
        _toast('Geçersiz QR kodu', isError: true);
        setState(() => _isProcessing = false);
        return;
      }

      if (uri.host == 'user' && uri.pathSegments.isNotEmpty) {
        final userId = uri.pathSegments.first;
        await _addContactFromQR(userId);
      } else {
        _toast('Tanınmayan QR kodu formatı', isError: true);
      }
    } catch (e) {
      _toast('QR kodu işlenemedi', isError: true);
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _addContactFromQR(String userId) async {
    // Kendi QR kodumuz mu kontrol et
    if (userId == SupabaseService.instance.currentUser?.id) {
      _toast('Bu senin kendi QR kodun', isError: true);
      return;
    }

    // Zaten kişilerimde mi kontrol et
    if (_contactService.isContact(userId)) {
      _toast('Bu kişi zaten kişilerinde');
      return;
    }

    // Kullanıcı bilgilerini getir
    final profile = await SupabaseService.instance.getProfile(userId);
    
    if (!mounted) return;
    
    if (profile == null) {
      _toast('Kullanıcı bulunamadı', isError: true);
      return;
    }

    final name = profile['full_name'] ?? profile['username'] ?? 'Bilinmeyen';

    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kişi Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: NearTheme.primary,
              backgroundImage: profile['avatar_url'] != null
                  ? NetworkImage(profile['avatar_url'])
                  : null,
              child: profile['avatar_url'] == null
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (profile['username'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '@${profile['username']}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Bu kişiyi eklemek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _contactService.addContact(userId);
      if (mounted) {
        if (success) {
          _toast('$name kişilere eklendi');
          Navigator.pop(context, userId);
        } else {
          _toast('Kişi eklenemedi', isError: true);
        }
      }
    }
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kodunu Yapıştır'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'near://user/...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _processQRCode(controller.text);
              }
            },
            child: const Text('İşle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR Kodu Tara',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          StatefulBuilder(
            builder: (context, setState) {
              return IconButton(
                icon: Icon(
                  _flashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _scannerController?.toggleTorch();
                  setState(() => _flashOn = !_flashOn);
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mobile Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Overlay with scan frame
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: NearTheme.primary,
                borderRadius: 16,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: 280,
              ),
            ),
          ),

          // Scan line animation
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: _scanLineAnimation.value * 260 + 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                NearTheme.primary,
                                NearTheme.primary,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Text(
              'QR kodunu çerçevenin içine yerleştirin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
          ),

          // Action buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Galeriden QR seçme
                    _scannerController?.analyzeImage('/path/to/image');
                  },
                  icon: const Icon(Icons.photo_library, color: Colors.white70),
                  label: const Text(
                    'Galeriden',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 32),
                TextButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  label: const Text(
                    'Elle Gir',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.borderRadius = 12,
    this.borderLength = 30,
    this.cutOutSize = 280,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutLeft = (width - cutOutSize) / 2;
    final cutOutTop = (height - cutOutSize) / 2;
    final cutOutRight = cutOutLeft + cutOutSize;
    final cutOutBottom = cutOutTop + cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTRB(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cutOutLeft, cutOutTop, cutOutRight, cutOutBottom),
        Radius.circular(borderRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft, cutOutTop + borderLength)
        ..lineTo(cutOutLeft, cutOutTop + borderRadius)
        ..arcToPoint(
          Offset(cutOutLeft + borderRadius, cutOutTop),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft + borderLength, cutOutTop),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRight - borderLength, cutOutTop)
        ..lineTo(cutOutRight - borderRadius, cutOutTop)
        ..arcToPoint(
          Offset(cutOutRight, cutOutTop + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRight, cutOutTop + borderLength),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRight, cutOutBottom - borderLength)
        ..lineTo(cutOutRight, cutOutBottom - borderRadius)
        ..arcToPoint(
          Offset(cutOutRight - borderRadius, cutOutBottom),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRight - borderLength, cutOutBottom),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + borderLength, cutOutBottom)
        ..lineTo(cutOutLeft + borderRadius, cutOutBottom)
        ..arcToPoint(
          Offset(cutOutLeft, cutOutBottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft, cutOutBottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}

/// My QR Code page showing user's profile QR
class MyQRCodePage extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userAvatar;

  const MyQRCodePage({
    super.key,
    this.userId,
    this.userName,
    this.userAvatar,
  });

  @override
  State<MyQRCodePage> createState() => _MyQRCodePageState();
}

class _MyQRCodePageState extends State<MyQRCodePage> {
  String? _userId;
  String? _userName;
  String? _userAvatar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (widget.userId != null) {
      _userId = widget.userId;
      _userName = widget.userName;
      _userAvatar = widget.userAvatar;
    } else {
      // Mevcut kullanıcı bilgilerini yükle
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        _userId = user.id;
        final profile = await SupabaseService.instance.getProfile(user.id);
        if (profile != null) {
          _userName = profile['full_name'] ?? profile['username'] ?? 'Kullanıcı';
          _userAvatar = profile['avatar_url'];
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _shareQRCode() {
    final qrData = 'near://user/$_userId';
    SharePlus.instance.share(
      ShareParams(
        text: 'Near\'da beni ekle: $qrData\n\nNear uygulamasını indir ve bu linki kullanarak beni kişilerine ekle!',
        title: 'Near - Kişi Ekle',
      ),
    );
  }

  void _copyLink() {
    final qrData = 'near://user/$_userId';
    Clipboard.setData(ClipboardData(text: qrData));
    _toast('Link kopyalandı');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'QR Kodum',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _userName ?? 'Kullanıcı';
    final qrData = 'near://user/$_userId';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QR Kodum',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: _shareQRCode,
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User info card with QR
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _userAvatar != null
                          ? ClipOval(
                              child: Image.network(
                                _userAvatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Code
                    QRCodeDisplay(
                      data: qrData,
                      size: 220,
                      foregroundColor: NearTheme.primary,
                      backgroundColor: isDark
                          ? const Color(0xFF3C3C3E)
                          : Colors.grey.shade50,
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    Text(
                      'Bu QR kodu taratarak beni ekleyebilirsin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scan button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerPage(),
                          ),
                        );
                        if (result != null && mounted) {
                          _toast('Kişi eklendi');
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('QR Tara'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NearTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Copy link button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.copy),
                      label: const Text('Kopyala'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NearTheme.primary,
                        side: BorderSide(color: NearTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _shareQRCode,
                  icon: const Icon(Icons.share),
                  label: const Text('Arkadaşlarınla Paylaş'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
