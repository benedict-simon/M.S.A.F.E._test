// lib/screens/google_profile_finish_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/session_service.dart';
import '../utils/text_formatters.dart';
import 'login_screen.dart';

class GoogleProfileFinishScreen extends StatefulWidget {
  const GoogleProfileFinishScreen({super.key});

  @override
  State<GoogleProfileFinishScreen> createState() => _GoogleProfileFinishScreenState();
}

class _GoogleProfileFinishScreenState extends State<GoogleProfileFinishScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: UserService.profile.value?.firstName ?? '');
  late final _middleInitial = TextEditingController(text: UserService.profile.value?.middleInitial ?? '');
  late final _lastName = TextEditingController(text: UserService.profile.value?.lastName ?? '');
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _submitted = false;

  static final _nameChars = RegExp(r"^[A-Za-zÀ-ſ\s\-']+$");
  static final _usernameChars = RegExp(r'^[A-Za-z0-9_.]+$');
  static final _phoneChars = RegExp(r'^\+?[0-9\s\-]{7,15}$');

  @override
  void dispose() {
    _firstName.dispose();
    _middleInitial.dispose();
    _lastName.dispose();
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateFirstName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please enter your first name';
    if (t.length < 2) return 'First name is too short';
    if (!_nameChars.hasMatch(t)) return 'Letters only, please';
    return null;
  }

  String? _validateLastName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please enter your last name';
    if (t.length < 2) return 'Last name is too short';
    if (!_nameChars.hasMatch(t)) return 'Letters only, please';
    return null;
  }

  String? _validateMiddleInitial(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!_nameChars.hasMatch(t)) return 'Letters only, please';
    return null;
  }

  String? _validateUsername(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please choose a username';
    if (t.length < 3) return 'Username must be at least 3 characters';
    if (t.length > 20) return 'Username must be 20 characters or fewer';
    if (!_usernameChars.hasMatch(t)) return 'Letters, numbers, "_" and "." only';
    return null;
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Please enter your contact number';
    if (!_phoneChars.hasMatch(t)) return 'Please enter a valid contact number';
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final username = _username.text.trim();
      final available = await _auth.isUsernameAvailable(username);
      if (!available) {
        _showError('That username is already taken. Please choose another.');
        return;
      }

      await _auth.updateProfile(
        firstName: _firstName.text.trim(),
        middleInitial: _middleInitial.text.trim(),
        lastName: _lastName.text.trim(),
        username: username,
        email: UserService.profile.value?.email ?? '',
        phoneNumber: _phone.text.trim(),
      );
      await UserService.loadCurrentProfile();

      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on AuthServiceException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("We couldn't save your profile. Please check your connection and try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignOut() async {
    if (mounted) {
      // Navigate away first — see the matching comment in
      // profile_screen.dart's sign-out handler for why: signOut() below
      // triggers an async auth-state listener that clears session state
      // out from under whatever screen is still visible, so route away
      // before touching any of that state.
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_add_alt_rounded, color: AppTheme.primaryRed, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  'Finish Setting Up Your Account',
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  "You're almost done — a few more details are needed to finish creating your account.",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [TitleCaseTextFormatter()],
                  validator: _validateFirstName,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _middleInitial,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [TitleCaseTextFormatter()],
                  validator: _validateMiddleInitial,
                  decoration: const InputDecoration(
                    labelText: 'M.I.',
                    hintText: 'Optional',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [TitleCaseTextFormatter()],
                  validator: _validateLastName,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _username,
                  validator: _validateUsername,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: 'e.g. 0917 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 28),
                AppTheme.gradientButton(
                  onPressed: _loading ? null : _handleSubmit,
                  gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed]),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Continue'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _handleSignOut,
                    child: Text('Not you? Sign out', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}