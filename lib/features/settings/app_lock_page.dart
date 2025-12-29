import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../shared/app_lock_service.dart';

/// Uygulama kilidi ayarları sayfası
class AppLockSettingsPage extends StatefulWidget {
  static const route = '/settings/app-lock';

  const AppLockSettingsPage({super.key});

  @override
  State<AppLockSettingsPage> createState() => _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends State<AppLockSettingsPage> {
  final _lockService = AppLockService.instance;

  @override
  void initState() {
    super.initState();
    _lockService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _lockService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Kilidi'),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // Ana switch
          _buildSection(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: const Text('Uygulama Kilidi'),
                subtitle: Text(
                  _lockService.isEnabled 
                      ? 'Etkin' 
                      : 'Devre dışı',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                value: _lockService.isEnabled,
                onChanged: (value) {
                  if (value) {
                    _showSetPinDialog();
                  } else {
                    _showDisableConfirmation();
                  }
                },
              ),
            ],
          ),
          
          if (_lockService.isEnabled) ...[
            const SizedBox(height: 20),
            
            // Biyometrik
            if (_lockService.canCheckBiometrics)
              _buildSection(
                isDark: isDark,
                children: [
                  SwitchListTile(
                    title: Text(_getBiometricTitle()),
                    subtitle: Text(
                      'Kilidi açmak için ${_getBiometricName()} kullan',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    secondary: Icon(_getBiometricIcon()),
                    value: _lockService.useBiometric,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      _lockService.setBiometric(value);
                    },
                  ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // Kilit gecikmesi
            _buildSection(
              isDark: isDark,
              children: [
                ListTile(
                  title: const Text('Kilitle'),
                  subtitle: Text(
                    _lockService.lockAfterText,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLockAfterPicker,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // PIN değiştir
            _buildSection(
              isDark: isDark,
              children: [
                ListTile(
                  title: const Text('PIN Değiştir'),
                  leading: const Icon(Icons.lock_outline),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePinDialog,
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Uygulama kilidi etkinleştirildiğinde, Near\'ı her açtığınızda PIN kodunuz veya biyometrik doğrulama istenecektir.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  String _getBiometricTitle() {
    if (_lockService.availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    return 'Touch ID';
  }

  String _getBiometricName() {
    if (_lockService.availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    return 'parmak izini';
  }

  IconData _getBiometricIcon() {
    if (_lockService.availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  void _showSetPinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinSetupDialog(
        onPinSet: (pin) {
          _lockService.enable(pin: pin);
          Navigator.pop(context);
          _toast('Uygulama kilidi etkinleştirildi');
        },
      ),
    );
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinSetupDialog(
        isChange: true,
        onPinSet: (pin) {
          _lockService.changePin(pin);
          Navigator.pop(context);
          _toast('PIN değiştirildi');
        },
      ),
    );
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulama Kilidini Kapat'),
        content: const Text(
          'Uygulama kilidini kapatmak istediğinizden emin misiniz? '
          'Mesajlarınız koruma altında olmayacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _lockService.disable();
              Navigator.pop(context);
              _toast('Uygulama kilidi devre dışı bırakıldı');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showLockAfterPicker() {
    final options = [
      (0, 'Anında'),
      (30, '30 saniye'),
      (60, '1 dakika'),
      (300, '5 dakika'),
      (900, '15 dakika'),
      (3600, '1 saat'),
      (-1, 'Hiçbir zaman'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kilitle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...options.map((option) => ListTile(
              title: Text(option.$2),
              trailing: _lockService.lockAfterSeconds == option.$1
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                _lockService.setLockAfter(option.$1);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// PIN kurulum dialog'u
class _PinSetupDialog extends StatefulWidget {
  final bool isChange;
  final Function(String) onPinSet;

  const _PinSetupDialog({
    this.isChange = false,
    required this.onPinSet,
  });

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  String _pin = '';
  String? _confirmPin;
  String? _error;
  bool _isConfirmStep = false;

  void _onDigit(String digit) {
    if (_pin.length >= 4 && !_isConfirmStep) return;
    if (_isConfirmStep && _confirmPin != null && _confirmPin!.length >= 4) return;

    HapticFeedback.lightImpact();
    
    setState(() {
      if (_isConfirmStep) {
        _confirmPin = (_confirmPin ?? '') + digit;
        if (_confirmPin!.length == 4) {
          _verifyPins();
        }
      } else {
        _pin += digit;
        if (_pin.length == 4) {
          _goToConfirm();
        }
      }
      _error = null;
    });
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isConfirmStep && _confirmPin != null && _confirmPin!.isNotEmpty) {
        _confirmPin = _confirmPin!.substring(0, _confirmPin!.length - 1);
      } else if (!_isConfirmStep && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
      _error = null;
    });
  }

  void _goToConfirm() {
    setState(() {
      _isConfirmStep = true;
      _confirmPin = '';
    });
  }

  void _verifyPins() {
    if (_pin == _confirmPin) {
      widget.onPinSet(_pin);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'PIN\'ler eşleşmiyor';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPin = _isConfirmStep ? (_confirmPin ?? '') : _pin;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isChange
                  ? (_isConfirmStep ? 'PIN\'i Onayla' : 'Yeni PIN')
                  : (_isConfirmStep ? 'PIN\'i Onayla' : 'PIN Oluştur'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _isConfirmStep
                  ? 'PIN\'inizi tekrar girin'
                  : '4 haneli PIN oluşturun',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // PIN göstergeleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _error != null
                        ? Colors.red
                        : (isFilled
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Mini numpad
            _buildMiniNumpad(isDark),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniNumpad(bool isDark) {
    return Column(
      children: [
        _buildNumRow(['1', '2', '3'], isDark),
        _buildNumRow(['4', '5', '6'], isDark),
        _buildNumRow(['7', '8', '9'], isDark),
        _buildNumRow(['', '0', 'del'], isDark),
      ],
    );
  }

  Widget _buildNumRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return const SizedBox(width: 56, height: 56);
        }
        
        if (digit == 'del') {
          return _buildKey(
            child: const Icon(Icons.backspace_outlined, size: 20),
            onTap: _onBackspace,
            isDark: isDark,
          );
        }
        
        return _buildKey(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onTap: () => _onDigit(digit),
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildKey({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
