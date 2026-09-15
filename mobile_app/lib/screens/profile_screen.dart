import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/profile_theme.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/feedback_service.dart';
import '../services/settings_service.dart';
import '../services/vendor_service.dart';
import '../services/vendor_supplier_service.dart';
import '../services/supplier_report_service.dart';
import '../widgets/guest_gate.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'contact_us_screen.dart';
import 'settings_screen.dart';
import 'developers_screen.dart';
import 'about_screen.dart';
import 'vendor_application_screen.dart';
import 'vendor_store_details_screen.dart';
import 'vendor_supplier_details_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? name;
  final String? username;
  final String? email;
  final int? scansCount;
  final int? reportsCount;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onOpenEducation;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    this.name,
    this.username,
    this.email,
    this.scansCount,
    this.reportsCount,
    this.onEditProfile,
    this.onChangePassword,
    this.onOpenEducation,
    this.onOpenHistory,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  late String _name = widget.name ?? (UserService.profile.value?.fullName ?? '');
  late String _username = widget.username ?? (UserService.profile.value?.username ?? '');
  late String _email = widget.email ?? (UserService.profile.value?.email ?? '');
  late String _phone = UserService.profile.value?.phone ?? '';
  late String _middleInitial = UserService.profile.value?.middleInitial ?? '';

  final _authService = AuthService();

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    VendorService.fetchCurrent();
  }

  (String, String) get _splitName {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppTheme.screenHeader(context, isEn ? 'Profile' : 'Profile'),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GuestGate(
                    title: isEn ? 'No Profile Yet' : 'Wala Pang Profile',
                    message: isEn
                        ? 'Log in or create an account to manage your profile and settings.'
                        : 'Mag-login o gumawa ng account para mapamahalaan ang iyong profile at mga setting.',
                    icon: Icons.person_outline_rounded,
                    child: _buildProfileContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildStatsRow(),
        const SizedBox(height: 24),
        AppTheme.fieldLabel(_isEn ? 'ACCOUNT' : 'ACCOUNT'),
        const SizedBox(height: 8),
        ProfileTheme.settingsGroup([
          ProfileTheme.settingsRow(
            icon: Icons.person_outline_rounded,
            label: _isEn ? 'Edit Profile' : 'I-edit ang Profile',
            onTap: _openEditProfile,
          ),
          ProfileTheme.settingsRow(
            icon: Icons.lock_outline_rounded,
            label: _isEn ? 'Change Password' : 'Palitan ang Password',
            onTap: _openChangePassword,
          ),
          ProfileTheme.settingsRow(
            icon: Icons.history_rounded,
            label: _isEn ? 'Scan History' : 'Kasaysayan ng Scan',
            onTap: _openScanHistory,
          ),
        ]),
        const SizedBox(height: 20),
        AppTheme.fieldLabel(_isEn ? 'VENDOR' : 'VENDOR'),
        const SizedBox(height: 8),
        _buildVendorSection(),
        const SizedBox(height: 20),
        AppTheme.fieldLabel(_isEn ? 'PREFERENCES' : 'MGA KAGUSTUHAN'),
        const SizedBox(height: 8),
        ProfileTheme.settingsGroup([
          ProfileTheme.settingsRow(
            icon: Icons.settings_outlined,
            label: _isEn ? 'App Settings' : 'Mga Setting ng App',
            onTap: _openSettings,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEn ? 'English' : 'Filipino',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textFaint),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
        AppTheme.fieldLabel(_isEn ? 'SUPPORT' : 'SUPORTA'),
        const SizedBox(height: 8),
        ProfileTheme.settingsGroup([
          ProfileTheme.settingsRow(
            icon: Icons.menu_book_rounded,
            label: _isEn ? 'Food Safety Education' : 'Edukasyon sa Kaligtasan',
            onTap: _openEducation,
          ),
          ProfileTheme.settingsRow(
            icon: Icons.info_outline_rounded,
            label: _isEn ? 'About M.S.A.F.E.' : 'Tungkol sa M.S.A.F.E.',
            onTap: _openAbout,
          ),
          ProfileTheme.settingsRow(
            icon: Icons.groups_outlined,
            label: _isEn ? 'About the Developers' : 'Tungkol sa mga Developer',
            onTap: _openDevelopers,
          ),
          ProfileTheme.settingsRow(
            icon: Icons.help_outline_rounded,
            label: _isEn ? 'Help & Support' : 'Tulong at Suporta',
            onTap: _openContactUs,
          ),
        ]),
        const SizedBox(height: 24),
        AppTheme.dangerOutlinedButton(
          label: _isEn ? 'Sign Out' : 'Mag-sign Out',
          icon: Icons.logout_rounded,
          onPressed: () => _confirmSignOut(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('M.S.A.F.E. v1.0.0', style: TextStyle(color: AppTheme.textFaint, fontSize: 12)),
        ),
      ],
    );
  }

  // ---------- Profile card ----------

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardWithShadowRadius(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppTheme.roleAccent, shape: BoxShape.circle),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _name,
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (UserService.profile.value?.isVendor ?? false) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: AppTheme.statusPillBg(AppTheme.vendorBlue),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_rounded, size: 11, color: AppTheme.vendorBlue),
                            const SizedBox(width: 3),
                            Text(_isEn ? 'VENDOR' : 'VENDOR', style: AppTheme.statusPillText(AppTheme.vendorBlue)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@$_username',
                  style: TextStyle(color: AppTheme.roleAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _email,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _openEditProfile,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Stats ----------

  Widget _buildStatsRow() {
    return ValueListenableBuilder<List<HistoryItem>>(
      valueListenable: HistoryService.items,
      builder: (context, scans, _) => ValueListenableBuilder<List<ReportRecord>>(
        valueListenable: ReportService.items,
        builder: (context, reports, _) => Row(
          children: [
            Expanded(
              child: AppTheme.statCard(
                icon: Icons.qr_code_scanner_rounded,
                value: (widget.scansCount ?? scans.length).toString(),
                label: _isEn ? 'Scans Done' : 'Na-scan',
                color: AppTheme.roleAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTheme.statCard(
                icon: Icons.flag_rounded,
                value: (widget.reportsCount ?? reports.length).toString(),
                label: _isEn ? 'Reports Filed' : 'Nai-report',
                color: AppTheme.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Vendor ----------

  Widget _buildVendorSection() {
    return ValueListenableBuilder<VendorApplication?>(
      valueListenable: VendorService.currentApplication,
      builder: (context, application, _) {
        if (UserService.profile.value?.isVendor ?? false) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTheme.tintedInfoBox(
                icon: Icons.verified_rounded,
                color: AppTheme.vendorBlue,
                text: _isEn
                    ? "You're an approved vendor."
                    : 'Ikaw ay isang approved na vendor.',
              ),
              const SizedBox(height: 12),
              ProfileTheme.settingsGroup([
                ProfileTheme.settingsRow(
                  icon: Icons.storefront_outlined,
                  label: _isEn ? 'Store Details' : 'Detalye ng Tindahan',
                  onTap: _openVendorStoreDetails,
                ),
                ProfileTheme.settingsRow(
                  icon: Icons.local_shipping_outlined,
                  label: _isEn ? 'Supplier Details' : 'Detalye ng Supplier',
                  onTap: _openVendorSupplierDetails,
                ),
              ]),
            ],
          );
        }

        if (application != null && application.status == VendorApplicationStatus.pending) {
          return AppTheme.tintedInfoBox(
            icon: Icons.hourglass_top_rounded,
            color: AppTheme.accentGold,
            text: _isEn
                ? 'Your vendor application for "${application.businessName}" is under review. We\'ll notify you once the admin decides.'
                : 'Ang iyong vendor application para sa "${application.businessName}" ay sinusuri pa. Aabisuhan ka namin pagkatapos itong mapagpasyahan.',
          );
        }

        if (application != null && application.status == VendorApplicationStatus.rejected) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.tintedCardDecoration(AppTheme.spoiledRed, opacity: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 18, color: AppTheme.spoiledRed),
                    const SizedBox(width: 8),
                    Text(
                      _isEn ? 'Vendor application not approved' : 'Hindi naaprubahan ang vendor application',
                      style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                if (application.rejectionReason != null && application.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    application.rejectionReason!,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                  ),
                ],
                const SizedBox(height: 10),
                AppTheme.textActionButton(
                  _isEn ? 'Apply Again' : 'Mag-apply Ulit',
                  _openVendorApplication,
                ),
              ],
            ),
          );
        }

        return ProfileTheme.settingsGroup([
          ProfileTheme.settingsRow(
            icon: Icons.storefront_outlined,
            label: _isEn ? 'Apply for Vendor Account' : 'Mag-apply bilang Vendor',
            onTap: _openVendorApplication,
          ),
        ]);
      },
    );
  }

  Future<void> _openVendorStoreDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorStoreDetailsScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openVendorSupplierDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorSupplierDetailsScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openVendorApplication() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorApplicationScreen()),
    );
    await VendorService.fetchCurrent();
    if (mounted) setState(() {});
  }

  // ---------- Navigation ----------

  Future<void> _openEditProfile() async {
    if (widget.onEditProfile != null) {
      widget.onEditProfile!();
      return;
    }
    final (firstName, lastName) = _splitName;
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          firstName: firstName,
          middleInitial: _middleInitial,
          lastName: lastName,
          username: _username,
          email: _email,
          phone: _phone,
          onSave: (firstName, middleInitial, lastName, username, email, phone) async {
            await _authService.updateProfile(
              firstName: firstName,
              middleInitial: middleInitial,
              lastName: lastName,
              username: username,
              email: email,
              phoneNumber: phone,
            );

            await UserService.loadCurrentProfile();
          },
        ),
      ),
    );
    if (result != null && mounted) {
      final updatedFirst = result['firstName'] ?? firstName;
      final updatedLast = result['lastName'] ?? lastName;
      setState(() {
        _name = [updatedFirst, updatedLast].where((s) => s.isNotEmpty).join(' ');
        _username = result['username'] ?? _username;
        _email = result['email'] ?? _email;
        _phone = result['phone'] ?? _phone;
        _middleInitial = result['middleInitial'] ?? _middleInitial;
      });
    }
  }

  void _openChangePassword() {
    if (widget.onChangePassword != null) {
      widget.onChangePassword!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          onChangePassword: (currentPassword, newPassword) => _authService.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ),
        ),
      ),
    );
  }

  void _openScanHistory() {
    if (widget.onOpenHistory != null) {
      widget.onOpenHistory!();
      return;
    }
    Navigator.of(context).pushNamed('/history');
  }

  void _openEducation() {
    if (widget.onOpenEducation != null) {
      widget.onOpenEducation!();
      return;
    }
    Navigator.of(context).pushNamed('/education');
  }

  void _openSettings() {

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _openDevelopers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DevelopersScreen()),
    );
  }

  void _openContactUs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactUsScreen(
          prefillEmail: _email,
          onSubmit: (category, subject, message, email, rating, attachments) async {
            if (!SessionService.isLoggedIn) {
              showLoginRequiredSheet(
                context,
                title: _isEn ? 'Login Required' : 'Kailangan Mag-login',
                message: _isEn
                    ? 'Log in or create an account to send us feedback.'
                    : 'Mag-login o gumawa ng account para magpadala ng feedback.',
                icon: Icons.chat_bubble_outline_rounded,
              );
              return;
            }
            await FeedbackService.submit(
              subject: subject,
              message: message,
              email: email,
              rating: rating,
            );

            if (category == ContactCategory.bug) {
              await NotificationService.add(
                kind: NotificationKind.bugReportSubmitted,
                title: _isEn ? 'Bug report received' : 'Natanggap ang Bug Report',
                body: _isEn
                    ? "Thanks for the report — we've logged it and our team will look into it."
                    : 'Salamat sa report — na-log na namin ito at titingnan ito ng aming team.',
              );
            }
          },
        ),
      ),
    );
  }

  // ---------- Sign out ----------

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_isEn ? 'Sign out?' : 'Mag-sign out?'),
        content: Text(
          _isEn
              ? "You'll need to sign in again to scan or view your history."
              : 'Kailangan mong mag-sign in ulit para mag-scan o tingnan ang history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_isEn ? 'Cancel' : 'Kanselahin'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              _isEn ? 'Sign Out' : 'Mag-sign Out',
              style: TextStyle(color: AppTheme.spoiledRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (widget.onSignOut != null) {
        widget.onSignOut!();
      } else {
        if (!context.mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const LoginScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (route) => false,
        );

        try {
          await _authService.signOut();
        } catch (e, st) {
          debugPrint('Sign out: failed to end the Supabase session: $e\n$st');
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
    }
  }

}