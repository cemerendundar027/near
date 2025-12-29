import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../shared/app_lock_service.dart';

/// Uygulama kilit ekranı
class LockScreen extends StatefulWidget {
  final Widget child;
  
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _lockService = AppLockService.instance;
  final _pinController = TextEditingController();
  String _enteredPin = '';
  bool _isError = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockService.addListener(_onLockStateChanged);
    
    // Biyometrik ile otomatik kilit açma dene
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lockService.isLocked && _lockService.useBiometric) {
        _tryBiometricUnlock();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockService.removeListener(_onLockStateChanged);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _lockService.onAppResumed();
      if (_lockService.isLocked && _lockService.useBiometric) {
        _tryBiometricUnlock();
      }
    }
  }

  void _onLockStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _tryBiometricUnlock() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);
    
    final success = await _lockService.unlockWithBiometric();
    
    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _isError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
    });
  }

  void _verifyPin() {
    if (_lockService.unlockWithPin(_enteredPin)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_lockService.isEnabled || !_lockService.isLocked) {
      return widget.child;
    }

    return _buildLockScreen(context);
  }

  Widget _buildLockScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            // Logo veya ikon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Near',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _isError ? 'Yanlış PIN' : 'PIN kodunuzu girin',
              style: TextStyle(
                fontSize: 16,
                color: _isError 
                    ? Colors.red 
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // PIN göstergeleri
            _buildPinIndicators(),
            
            const Spacer(),
            
            // Sayı tuşları
            _buildNumPad(isDark),
            
            const SizedBox(height: 16),
            
            // Biyometrik buton
            if (_lockService.canCheckBiometrics && _lockService.useBiometric)
              TextButton.icon(
                onPressed: _isAuthenticating ? null : _tryBiometricUnlock,
                icon: Icon(
                  _getBiometricIcon(),
                  color: primaryColor,
                ),
                label: Text(
                  _getBiometricLabel(),
                  style: TextStyle(color: primaryColor),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPinIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isError
                ? Colors.red
                : (isFilled
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3'], isDark),
          _buildNumRow(['4', '5', '6'], isDark),
          _buildNumRow(['7', '8', '9'], isDark),
          _buildNumRow(['', '0', 'del'], isDark),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        if (digit.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        
        if (digit == 'del') {
          return _buildKeyButton(
            child: const Icon(Icons.backspace_outlined, size: 24),
            onPressed: _onBackspacePressed,
            isDark: isDark,
          );
        }
        
        return _buildKeyButton(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => _onPinDigitPressed(digit),
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
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

  IconData _getBiometricIcon() {
    if (_lockService.availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  String _getBiometricLabel() {
    if (_lockService.availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID ile aç';
    }
    return 'Touch ID ile aç';
  }
}
