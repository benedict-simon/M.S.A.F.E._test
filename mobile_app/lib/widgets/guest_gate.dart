import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class GuestGate extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? message;
  final IconData icon;

  const GuestGate({
    super.key,
    required this.child,
    this.title,
    this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SessionStatus>(
      valueListenable: SessionService.status,
      builder: (context, status, _) {
        if (status == SessionStatus.loggedIn) return child;
        return Center(
          child: SingleChildScrollView(
            child: GuestLoginPrompt(title: title, message: message, icon: icon),
          ),
        );
      },
    );
  }
}

class GuestLoginPrompt extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData icon;
  final EdgeInsetsGeometry padding;
  final bool showActions;

  const GuestLoginPrompt({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.lock_outline_rounded,
    this.padding = const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final resolvedTitle = title ?? (isEn ? 'Login Required' : 'Kailangan Mag-login');
        final resolvedMessage =
            message ?? (isEn ? 'Create a free account or log in to use this feature.' : 'Gumawa ng libreng account o mag-login para magamit ang feature na ito.');
        return Padding(
          padding: padding,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),

            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppTheme.roleAccent.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconBadge(icon),
                const SizedBox(height: 18),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  resolvedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.45),
                ),
                if (showActions) ...[
                  const SizedBox(height: 22),
                  _primaryCta(
                    icon: Icons.login_rounded,
                    label: isEn ? 'Log In' : 'Mag-login',
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  const SizedBox(height: 10),
                  _secondaryCta(
                    icon: Icons.person_add_alt_rounded,
                    label: isEn ? 'Create an Account' : 'Gumawa ng Account',
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _iconBadge(IconData icon, {double size = 72, double iconSize = 30}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppTheme.roleGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.roleAccent.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
Widget _primaryCta({required IconData icon, required String label, required VoidCallback onPressed}) => AppTheme.gradientButton(
      onPressed: onPressed,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );

Widget _secondaryCta({required IconData icon, required String label, required VoidCallback onPressed}) => SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.roleAccentDark,
          side: BorderSide(color: AppTheme.roleAccent, width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );

Widget _dismissLink({required String label, required VoidCallback onPressed}) => TextButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
    );

Widget _sheetShell(
  BuildContext sheetContext, {
  required IconData icon,
  required String title,
  required String message,
  required List<Widget> actions,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.fromLTRB(
      24,
      14,
      24,
      MediaQuery.of(sheetContext).viewInsets.bottom + 28,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Center(child: _iconBadge(icon, size: 68, iconSize: 28)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 22),
        ...actions,
      ],
    ),
  );
}

Future<void> showLoginRequiredSheet(
  BuildContext context, {
  String? title,
  String? message,
  IconData icon = Icons.lock_outline_rounded,
}) {
  final isEn = SettingsService.isEnglish;
  final resolvedTitle = title ?? (isEn ? 'Login Required' : 'Kailangan Mag-login');
  final resolvedMessage =
      message ?? (isEn ? 'Create a free account or log in to use this feature.' : 'Gumawa ng libreng account o mag-login para magamit ang feature na ito.');
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _sheetShell(
      sheetContext,
      icon: icon,
      title: resolvedTitle,
      message: resolvedMessage,
      actions: [
        _primaryCta(
          icon: Icons.login_rounded,
          label: isEn ? 'Log In' : 'Mag-login',
          onPressed: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pushNamed('/login');
          },
        ),
        const SizedBox(height: 10),
        _secondaryCta(
          icon: Icons.person_add_alt_rounded,
          label: isEn ? 'Create an Account' : 'Gumawa ng Account',
          onPressed: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pushNamed('/signup');
          },
        ),
        const SizedBox(height: 6),
        Center(
          child: _dismissLink(
            label: isEn ? 'Maybe Later' : 'Sa Ibang Pagkakataon Na Lang',
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ],
    ),
  );
}

Future<void> showSaveScanPrompt(
  BuildContext context, {
  required String meatType,
}) {
  final isEn = SettingsService.isEnglish;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    isScrollControlled: true,
    builder: (sheetContext) => _sheetShell(
      sheetContext,
      icon: Icons.save_outlined,
      title: isEn ? 'Save This Result?' : 'I-save Ang Resulta?',
      message: isEn
          ? "You're browsing as a guest, so this $meatType scan wasn't saved. "
              'Log in or create an account to keep it in your scan history.'
          : 'Guest ka pa lang kaya hindi na-save ang $meatType scan na ito. '
              'Mag-login o gumawa ng account para ma-save ito sa iyong scan history.',
      actions: [
        _primaryCta(
          icon: Icons.login_rounded,
          label: isEn ? 'Log In to Save' : 'Mag-login Para I-save',
          onPressed: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pushNamed('/login');
          },
        ),
        const SizedBox(height: 10),
        _secondaryCta(
          icon: Icons.person_add_alt_rounded,
          label: isEn ? 'Create an Account' : 'Gumawa ng Account',
          onPressed: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pushNamed('/signup');
          },
        ),
        const SizedBox(height: 6),
        Center(
          child: _dismissLink(
            label: isEn ? 'Continue Without Saving' : 'Ituloy Nang Walang I-save',
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ],
    ),
  );
}
