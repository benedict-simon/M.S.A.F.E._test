// lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_form_widgets.dart' show AppFormField, PrimaryButton;
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();

    _newCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _newCtrl.removeListener(_onPasswordChanged);
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int _passwordStrength(String pw) {
    if (pw.isEmpty) return 0;
    if (pw.length < 6) return 1;

    var varietyScore = 0;
    if (RegExp(r'[a-z]').hasMatch(pw)) varietyScore++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) varietyScore++;
    if (RegExp(r'[0-9]').hasMatch(pw)) varietyScore++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) varietyScore++;

    if (pw.length >= 10 && varietyScore >= 3) return 3;
    if (pw.length >= 8 && varietyScore >= 2) return 2;
    return 1;
  }

  Widget _buildStrengthIndicator(bool isEn) {
    final strength = _passwordStrength(_newCtrl.text);
    if (strength == 0) return const SizedBox.shrink();

    final (label, color) = switch (strength) {
      1 => (isEn ? 'Weak' : 'Mahina', AppTheme.spoiledRed),
      2 => (isEn ? 'Medium' : 'Katamtaman', AppTheme.accentGold),
      _ => (isEn ? 'Strong' : 'Malakas', AppTheme.freshGreen),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength ? color : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i != 2) const SizedBox(width: 4),
          ],
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _auth.updatePasswordAfterReset(_newCtrl.text);

      SessionService.markLoggedIn();
      await UserService.loadCurrentProfile();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(_isEn
          ? "We couldn't update your password. Please try again."
          : 'Hindi namin na-update ang iyong password. Pakisubukang muli.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
    ));

  Widget _visibilityToggle(bool obscured, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: AppTheme.textMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: AppTheme.bgColor,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.lock_reset_rounded, color: AppTheme.primaryRed, size: 30),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isEn ? 'Set a New Password' : 'Magtakda ng Bagong Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn
                          ? "You're verified — choose a new password to finish resetting it."
                          : 'Na-verify ka na — pumili ng bagong password para matapos ang pag-reset.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    AppTheme.fieldLabel(isEn ? 'NEW PASSWORD' : 'BAGONG PASSWORD'),
                    const SizedBox(height: 8),
                    AppFormField(
                      controller: _newCtrl,
                      hint: isEn ? 'Enter new password' : 'Ilagay ang bagong password',
                      icon: Icons.lock_reset_rounded,
                      obscure: _obscureNew,
                      suffix: _visibilityToggle(_obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return isEn ? 'New password is required' : 'Kinakailangan ang bagong password';
                        if (v.length < 6) return isEn ? 'Must be at least 6 characters' : 'Dapat hindi bababa sa 6 characters';
                        return null;
                      },
                    ),
                    _buildStrengthIndicator(isEn),
                    const SizedBox(height: 18),
                    AppTheme.fieldLabel(isEn ? 'CONFIRM NEW PASSWORD' : 'KUMPIRMAHIN ANG BAGONG PASSWORD'),
                    const SizedBox(height: 8),
                    AppFormField(
                      controller: _confirmCtrl,
                      hint: isEn ? 'Re-enter new password' : 'Ilagay muli ang bagong password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureConfirm,
                      suffix: _visibilityToggle(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      validator: (v) =>
                          (v != _newCtrl.text) ? (isEn ? 'Passwords do not match' : 'Hindi magkatugma ang mga password') : null,
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: isEn ? 'Update Password' : 'I-update ang Password',
                      loading: _saving,
                      onPressed: _handleSubmit,
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
