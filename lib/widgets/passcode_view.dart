import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/stitch_theme.dart';

class PasscodeView extends StatefulWidget {
  final String mode; // 'create' or 'verify'
  final void Function(String passcode) onSuccess;
  final VoidCallback? onCancel;
  final String? title;

  const PasscodeView({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
    this.title,
  });

  @override
  State<PasscodeView> createState() => _PasscodeViewState();
}

class _PasscodeViewState extends State<PasscodeView> with SingleTickerProviderStateMixin {
  String _enteredPin = "";
  String _firstEnteredPin = "";
  bool _isConfirming = false;
  String _errorMessage = "";

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerErrorShake(String msg) {
    setState(() {
      _errorMessage = msg;
      _enteredPin = "";
    });
    _shakeController.forward(from: 0.0);
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = "";
    });

    if (_enteredPin.length == 4) {
      // Small delay for visual satisfaction
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _processPin();
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = "";
    });
  }

  void _processPin() {
    if (widget.mode == 'verify') {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.verifyPasscode(_enteredPin)) {
        widget.onSuccess(_enteredPin);
      } else {
        _triggerErrorShake("Incorrect PIN. Try again.");
      }
    } else {
      // create mode
      if (!_isConfirming) {
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = "";
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstEnteredPin) {
          widget.onSuccess(_enteredPin);
        } else {
          _triggerErrorShake("PINs do not match. Start over.");
          setState(() {
            _isConfirming = false;
            _firstEnteredPin = "";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final primaryColor = isDark ? StitchTheme.primaryFixedDim : StitchTheme.primary;
    final onSurfaceColor = isDark ? StitchTheme.darkOnSurface : StitchTheme.onSurface;
    final secondaryTextColor = isDark ? StitchTheme.darkOnSurfaceVariant : StitchTheme.onSurfaceVariant;
    final keyboardBtnBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final keyboardBtnBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

    String promptTitle = widget.title ?? (widget.mode == 'verify' ? "Enter Passcode" : "Create Passcode");
    String promptSubtitle = widget.mode == 'verify'
        ? "Enter your 4-digit PIN to unlock."
        : (_isConfirming ? "Confirm your 4-digit PIN." : "Choose a 4-digit PIN to lock this chat.");

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF09090C),
                    const Color(0xFF13111C),
                  ]
                : [
                    const Color(0xFFF9FAFB),
                    const Color(0xFFEEF2FF),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  const SizedBox(height: 16),
                  Icon(
                    Icons.lock,
                    size: 44,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    promptTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      promptSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Animated Dots
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final double offsetValue = math.sin(_shakeController.value * math.pi * 6) * 16.0 * (1.0 - _shakeController.value);
                      return Transform.translate(
                        offset: Offset(offsetValue, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool active = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? primaryColor : Colors.transparent,
                            border: Border.all(
                              color: active ? primaryColor : (isDark ? Colors.white24 : Colors.grey.shade400),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Error Message
                  SizedBox(
                    height: 24,
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: StitchTheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keyboard
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    alignment: Alignment.center,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        if (index == 9) {
                          // Left bottom action: Cancel or Clear
                          return widget.onCancel != null
                              ? _buildIconButton(
                                  icon: Icons.close,
                                  bgColor: keyboardBtnBg,
                                  borderColor: keyboardBtnBorder,
                                  iconColor: onSurfaceColor,
                                  onTap: widget.onCancel!,
                                )
                              : const SizedBox.shrink();
                        } else if (index == 10) {
                          // Number 0
                          return _buildNumButton(
                            "0",
                            bgColor: keyboardBtnBg,
                            borderColor: keyboardBtnBorder,
                            textColor: onSurfaceColor,
                          );
                        } else if (index == 11) {
                          // Backspace
                          return _buildIconButton(
                            icon: Icons.backspace_outlined,
                            bgColor: keyboardBtnBg,
                            borderColor: keyboardBtnBorder,
                            iconColor: onSurfaceColor,
                            onTap: _onBackspace,
                          );
                        } else {
                          // Numbers 1-9
                          String digit = (index + 1).toString();
                          return _buildNumButton(
                            digit,
                            bgColor: keyboardBtnBg,
                            borderColor: keyboardBtnBorder,
                            textColor: onSurfaceColor,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
    ),
  );
}

  Widget _buildNumButton(String digit, {required Color bgColor, required Color borderColor, required Color textColor}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // Exposed helper to trigger error externally (e.g. wrong passcode verify)
  void showVerifyError() {
    _triggerErrorShake("Incorrect PIN. Try again.");
  }
}
