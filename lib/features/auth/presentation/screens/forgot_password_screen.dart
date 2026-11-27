import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/auth_exception.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_banners.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_submit_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _emailSent = false;
  String _sentEmail = '';
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool isResend = false}) async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!isResend && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthCubit>().sendPasswordReset(
        isResend ? _sentEmail : _emailController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sentEmail = isResend ? _sentEmail : _emailController.text.trim();
        _emailSent = true;
      });

      if (isResend) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tautan reset telah dikirim ulang ke $_sentEmail.'),
          ),
        );
      }
    } on AuthRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(
        () => _errorMessage = 'Tautan reset gagal dikirim. Silakan coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return _buildSuccessView(context);
    }

    return AuthScaffold(
      title: 'Lupa Kata Sandi',
      subtitle:
          'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat '
          'kata sandi baru.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: 'Kirim Tautan Reset',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: () => _submit(),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke Masuk'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthScaffold(
      title: 'Email Terkirim',
      subtitle:
          'Tautan reset kata sandi telah dikirim ke $_sentEmail. Buka tautan '
          'tersebut pada perangkat ini untuk membuat kata sandi baru.',
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.outgoing_mail,
                size: 42,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const AuthInfoBanner(
            message:
                'Tautan hanya berlaku untuk waktu terbatas. Jika email tidak '
                'ditemukan, periksa folder spam atau kirim ulang.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Kembali ke Masuk'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(isResend: true),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('Kirim Ulang Email'),
          ),
        ],
      ),
    );
  }
}
