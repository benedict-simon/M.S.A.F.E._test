// lib/screens/account_restore_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

class AccountRestoreScreen extends StatefulWidget {
  const AccountRestoreScreen({super.key});

  @override
  State<AccountRestoreScreen> createState() => _AccountRestoreScreenState();
}

class _AccountRestoreScreenState extends State<AccountRestoreScreen> {
  final _auth = AuthService();
  bool _loading = false;

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _handleRestore() async {
    setState(() => _loading = true);
    try {
      await _auth.restoreAccount();
      await UserService.loadCurrentProfile();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("We couldn't restore your account. Please try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignOut() async {
    if (mounted) {
      // Navigate away first — see the matching comment in
      // profile_screen.dart's sign-out handler for why.
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
    try {
      await _auth.signOut();
    } catch (_) {}
    SessionService.signOut();
    UserService.clear();
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

  @override
  Widget build(BuildContext context) {
    final deadline = UserService.profile.value?.permanentDeletionDate;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppTheme.spoiledRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.restore_from_trash_outlined, color: AppTheme.spoiledRed, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                'Your Account Is Scheduled for Deletion',
                style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                deadline != null
                    ? "You requested to delete your account. It will be permanently deleted on ${_formatDate(deadline)} unless you restore it now."
                    : 'You requested to delete your account. Restore it now to keep using M.S.A.F.E.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleRestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.roleAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Restore My Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _handleSignOut,
                child: Text('Not Now — Sign Out', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
