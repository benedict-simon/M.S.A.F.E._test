import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_form_widgets.dart' show AppFormField, PrimaryButton;
import '../services/settings_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Future<void> Function(String currentPassword, String newPassword)? onChangePassword;

  const ChangePasswordScreen({super.key, this.onChangePassword});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.onChangePassword != null) {
        await widget.onChangePassword!(_currentCtrl.text, _newCtrl.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Password updated successfully' : 'Matagumpay na na-update ang password')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Could not update password: $e' : 'Hindi na-update ang password: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                _ScreenHeader(title: isEn ? 'Change Password' : 'Palitan ang Password'),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isEn
                                      ? 'Use at least 8 characters, with a mix of letters and numbers.'
                                      : 'Gumamit ng hindi bababa sa 8 characters, may halong letra at numero.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        AppTheme.fieldLabel(isEn ? 'CURRENT PASSWORD' : 'KASALUKUYANG PASSWORD'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _currentCtrl,
                          hint: isEn ? 'Enter current password' : 'Ilagay ang kasalukuyang password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureCurrent,
                          suffix: _visibilityToggle(_obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
                          validator: (v) => (v == null || v.isEmpty)
                              ? (isEn ? 'Current password is required' : 'Kinakailangan ang kasalukuyang password')
                              : null,
                        ),
                        const SizedBox(height: 18),
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
                            if (v.length < 8) return isEn ? 'Must be at least 8 characters' : 'Dapat hindi bababa sa 8 characters';
                            if (v == _currentCtrl.text) {
                              return isEn ? 'Must differ from current password' : 'Dapat iba sa kasalukuyang password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'CONFIRM NEW PASSWORD' : 'KUMPIRMAHIN ANG BAGONG PASSWORD'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _confirmCtrl,
                          hint: isEn ? 'Re-enter new password' : 'Ilagay muli ang bagong password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          suffix: _visibilityToggle(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                          validator: (v) => (v != _newCtrl.text) ? (isEn ? 'Passwords do not match' : 'Hindi magkatugma ang mga password') : null,
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: isEn ? 'Update Password' : 'I-update ang Password',
                          loading: _saving,
                          onPressed: _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final String title;
  const _ScreenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
          ),
          Text(
            title,
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
