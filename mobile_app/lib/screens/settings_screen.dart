import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/profile_theme.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/vendor_service.dart';
import '../services/vendor_supplier_service.dart';
import '../services/supplier_report_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickLanguage(BuildContext context, bool isEn) async {
    final choice = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.sheetTopRadius),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEn ? 'App Language' : 'Wika ng App',
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            _languageOption(context, 'English', AppLanguage.english),
            _languageOption(context, 'Filipino', AppLanguage.filipino),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null) {
      await SettingsService.setLanguage(choice);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, bool isEn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEn ? 'Delete your account?' : 'Burahin ang iyong account?'),
        content: Text(
          isEn
              ? "Your account will be deactivated immediately. You have 30 days to restore it by simply logging back in — after that, it's permanently deleted and can't be recovered."
              : 'Agad na mai-deactivate ang iyong account. May 30 araw ka para maibalik ito sa pamamagitan lang ng muling pag-login — pagkatapos noon, permanenteng mabubura ito at hindi na maibabalik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isEn ? 'Cancel' : 'Kanselahin'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isEn ? 'Delete Account' : 'Burahin ang Account',
              style: TextStyle(color: AppTheme.spoiledRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final authService = AuthService();
    try {
      await authService.requestAccountDeletion();
    } on AuthServiceException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(isEn
              ? "We couldn't start account deletion. Please try again."
              : 'Hindi namin nasimulan ang pagbura ng account. Pakisubukang muli.'),
        ));
      return;
    }

    if (!context.mounted) return;
    // Navigate away first, before actually signing out — same reasoning as
    // profile_screen.dart's sign-out handler: signOut() below triggers an
    // async auth-state listener that clears session state out from under
    // whatever screen is still visible, so route away before touching it.
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );

    try {
      await authService.signOut();
    } catch (e, st) {
      debugPrint('Delete account: failed to end the Supabase session: $e\n$st');
    }

    SessionService.signOut();
    UserService.clear();
    VendorService.clear();
    VendorSupplierService.clear();
    SupplierReportService.clear();
    HistoryService.items.value = [];
    ReportService.items.value = [];
    NotificationService.items.value = [];
  }

  Widget _languageOption(BuildContext context, String label, AppLanguage value) {
    final selected = SettingsService.language.value == value;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => Navigator.of(context).pop(value),
        title: Text(label, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14.5)),
        trailing: selected ? Icon(Icons.check_rounded, color: AppTheme.roleAccent) : null,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
                      ),
                      Text(
                        isEn ? 'Settings' : 'Mga Setting',
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      AppTheme.fieldLabel(isEn ? 'PREFERENCES' : 'MGA KAGUSTUHAN'),
                      const SizedBox(height: 8),
                      ProfileTheme.settingsGroup([
                        ProfileTheme.settingsRow(
                          icon: Icons.translate_rounded,
                          label: isEn ? 'App Language' : 'Wika ng App',
                          onTap: () => _pickLanguage(context, isEn),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEn ? 'English' : 'Filipino',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textFaint),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: SettingsService.darkMode,
                          builder: (context, darkMode, _) => ProfileTheme.settingsRow(
                            icon: Icons.dark_mode_outlined,
                            label: isEn ? 'Dark Theme' : 'Madilim na Tema',
                            trailing: Switch(
                              value: darkMode,
                              onChanged: (v) => SettingsService.setDarkMode(v),
                              activeColor: AppTheme.roleAccent,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: SettingsService.notificationsEnabled,
                          builder: (context, notificationsEnabled, _) => ProfileTheme.settingsRow(
                            icon: Icons.notifications_none_rounded,
                            label: isEn ? 'Notifications' : 'Mga Abiso',
                            trailing: Switch(
                              value: notificationsEnabled,
                              onChanged: (v) => SettingsService.setNotificationsEnabled(v),
                              activeColor: AppTheme.roleAccent,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Text(
                        isEn
                            ? 'These preferences are saved on this device and apply across the whole app.'
                            : 'Naka-save ang mga kagustuhang ito sa device na ito at ginagamit sa buong app.',
                        style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      AppTheme.fieldLabel(isEn ? 'ACCOUNT' : 'ACCOUNT'),
                      const SizedBox(height: 8),
                      AppTheme.dangerOutlinedButton(
                        label: isEn ? 'Delete Account' : 'Burahin ang Account',
                        icon: Icons.delete_outline_rounded,
                        onPressed: () => _confirmDeleteAccount(context, isEn),
                      ),
                    ],
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
