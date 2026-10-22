import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';

/// Enter the emailed 6-digit code; skippable, only unlocks the verified badge.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.onSkip});

  /// Called on skip or successful verify; defaults to popping the route.
  final VoidCallback? onSkip;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final updated = await AuthRepository(auth.client).verifyEmail(code);
      auth.setUser(updated);
      // AuthGate swaps to MainShell on its own; from Profile this pops back.
      _dismiss();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _dismiss() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);

    try {
      final auth = context.read<AuthProvider>();
      final message = await AuthRepository(
        auth.client,
      ).resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Verify your email',
                subtitle: email == null
                    ? 'Enter the 6-digit code we emailed you.'
                    : "Enter the 6-digit code we sent to\n$email",
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isVerifying ? null : _verify,
                      child: _isVerifying
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: Text(_isResending ? 'Sending…' : 'Resend code'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _dismiss,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: AppColors.textSecondary),
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
  }
}
