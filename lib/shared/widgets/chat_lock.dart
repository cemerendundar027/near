import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Sohbet kilitleme ayarları
enum ChatLockType { none, pin, biometric, both }

/// Chat Lock Settings Widget
class ChatLockSettings extends StatefulWidget {
  final ChatLockType currentLockType;
  final String? savedPin;
  final Function(ChatLockType type, String? pin) onLockChanged;

  const ChatLockSettings({
    super.key,
    required this.currentLockType,
    this.savedPin,
    required this.onLockChanged,
  });

  @override
  State<ChatLockSettings> createState() => _ChatLockSettingsState();
}

class _ChatLockSettingsState extends State<ChatLockSettings> {
  late ChatLockType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentLockType;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NearTheme.primary.withAlpha(40),
                NearTheme.primaryDark.withAlpha(20),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: NearTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sohbet Kilidi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bu sohbeti koruma altına al',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lock options
        _buildLockOption(
          context,
          icon: Icons.lock_open_rounded,
          title: 'Kilit Yok',
          subtitle: 'Sohbet herkese açık',
          type: ChatLockType.none,
          isDark: isDark,
        ),
        _buildLockOption(
          context,
          icon: Icons.pin_rounded,
          title: 'PIN Kilidi',
          subtitle: '4 haneli PIN ile koru',
          type: ChatLockType.pin,
          isDark: isDark,
        ),
        _buildLockOption(
          context,
          icon: Icons.fingerprint_rounded,
          title: 'Biyometrik',
          subtitle: 'Face ID veya parmak izi',
          type: ChatLockType.biometric,
          isDark: isDark,
        ),
        _buildLockOption(
          context,
          icon: Icons.security_rounded,
          title: 'PIN + Biyometrik',
          subtitle: 'En güvenli seçenek',
          type: ChatLockType.both,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // Info section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kilitli sohbetler bildirimde içerik göstermez ve arama sonuçlarında görünmez.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ChatLockType type,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? NearTheme.primary.withAlpha(30)
              : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? NearTheme.primary
              : (isDark ? Colors.white60 : Colors.black54),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: NearTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
          : null,
      onTap: () async {
        if (type == ChatLockType.pin || type == ChatLockType.both) {
          // PIN gerekiyor
          final pin = await _showPinDialog(context);
          if (pin != null && pin.length == 4) {
            setState(() {
              _selectedType = type;
            });
            widget.onLockChanged(type, pin);
          }
        } else {
          setState(() {
            _selectedType = type;
          });
          widget.onLockChanged(type, null);
        }
      },
    );
  }

  Future<String?> _showPinDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _PinDialog(),
    );
  }
}

/// PIN giriş dialogu
class _PinDialog extends StatefulWidget {
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final List<String> _pin = [];
  String? _error;

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(digit);
        _error = null;
      });
      HapticFeedback.lightImpact();

      if (_pin.length == 4) {
        // PIN tamamlandı
        Navigator.pop(context, _pin.join());
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 48,
              color: NearTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '4 Haneli PIN Oluştur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sohbetinizi korumak için\n4 haneli bir PIN girin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? NearTheme.primary
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                );
              }),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),

            // Number pad
            _buildNumberPad(isDark),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: buttons.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((label) {
            if (label.isEmpty) {
              return const SizedBox(width: 72, height: 56);
            }
            return _buildNumberButton(label, isDark);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton(String label, bool isDark) {
    final isBackspace = label == '⌫';

    return SizedBox(
      width: 72,
      height: 56,
      child: TextButton(
        onPressed: isBackspace ? _removeDigit : () => _addDigit(label),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
        ),
        child: isBackspace
            ? Icon(
                Icons.backspace_outlined,
                color: isDark ? Colors.white60 : Colors.black54,
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
      ),
    );
  }
}

/// Lock Screen - Sohbet kilidi açma ekranı
class ChatLockScreen extends StatefulWidget {
  final String? savedPin;
  final bool supportsBiometric;
  final VoidCallback onUnlocked;
  final VoidCallback? onCancel;

  const ChatLockScreen({
    super.key,
    this.savedPin,
    this.supportsBiometric = true,
    required this.onUnlocked,
    this.onCancel,
  });

  @override
  State<ChatLockScreen> createState() => _ChatLockScreenState();
}

class _ChatLockScreenState extends State<ChatLockScreen> {
  final List<String> _pin = [];
  String? _error;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    // Biyometrik destekliyorsa otomatik başlat
    if (widget.supportsBiometric && widget.savedPin == null) {
      _authenticateBiometric();
    }
  }

  void _authenticateBiometric() {
    // Simüle - gerçekte local_auth paketi kullanılır
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onUnlocked();
    });
  }

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(digit);
        _error = null;
      });
      HapticFeedback.lightImpact();

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _verifyPin() {
    if (_pin.join() == widget.savedPin) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Yanlış PIN. Tekrar deneyin.';
        _pin.clear();
        _attempts++;
      });

      if (_attempts >= 3) {
        setState(() {
          _error = 'Çok fazla deneme. Lütfen bekleyin.';
        });
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _attempts = 0;
              _error = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ),

            const Spacer(),

            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NearTheme.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: NearTheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Sohbet Kilitli',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.savedPin != null
                  ? 'PIN kodunuzu girin'
                  : 'Kilit açmak için doğrulayın',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),

            const SizedBox(height: 32),

            if (widget.savedPin != null) ...[
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isFilled ? 14 : 12,
                    height: isFilled ? 14 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? NearTheme.primary
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                  );
                }),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Number pad
              _buildNumberPad(isDark),
            ],

            // Biometric button
            if (widget.supportsBiometric) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _authenticateBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Biyometrik ile Aç'),
              ),
            ],

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: buttons.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((label) {
            if (label.isEmpty) {
              return const SizedBox(width: 72, height: 60);
            }
            return _buildNumberButton(label, isDark);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildNumberButton(String label, bool isDark) {
    final isBackspace = label == '⌫';
    final isDisabled = _attempts >= 3;

    return SizedBox(
      width: 72,
      height: 60,
      child: TextButton(
        onPressed: isDisabled
            ? null
            : (isBackspace ? _removeDigit : () => _addDigit(label)),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor:
              isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
        ),
        child: isBackspace
            ? Icon(
                Icons.backspace_outlined,
                color: isDisabled
                    ? Colors.grey
                    : (isDark ? Colors.white60 : Colors.black54),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
      ),
    );
  }
}
