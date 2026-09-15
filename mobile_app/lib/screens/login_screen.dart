import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/login_theme.dart';
import '../theme/wave_clipper.dart';
import '../services/auth_service.dart';
import '../services/login_attempt_service.dart';
import '../services/session_service.dart';
import '../services/user_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/vendor_service.dart';
import '../services/supplier_report_service.dart';
import '../services/settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();
  final _loginAttemptService = LoginAttemptService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGuestLoading = false;
  bool get _anyLoading => _isLoading || _isGuestLoading;

  bool _submitted = false;

  bool _awaitingGoogleSignIn = false;
  VoidCallback? _googleSessionListener;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingGoogleSignIn) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_awaitingGoogleSignIn || SessionService.isLoggedIn) return;
      _cancelGoogleSignIn();
    });
  }

  void _cancelGoogleSignIn() {
    if (_googleSessionListener != null) {
      SessionService.status.removeListener(_googleSessionListener!);
      _googleSessionListener = null;
    }
    _awaitingGoogleSignIn = false;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_googleSessionListener != null) {
      SessionService.status.removeListener(_googleSessionListener!);
    }
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _isEn ? 'Please enter your username' : 'Pakilagay ang iyong username';
    if (v.length < 3) return _isEn ? 'Username must be at least 3 characters' : 'Dapat hindi bababa sa 3 characters ang username';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return _isEn ? 'Please enter your password' : 'Pakilagay ang iyong password';
    return value.length < 6 ? (_isEn ? 'Password must be at least 6 characters' : 'Dapat hindi bababa sa 6 characters ang password') : null;
  }

  Future<void> _run(
    void Function(bool) setLoading,
    Future<void> Function() action,
    String fallbackErrorMsg, {
    Future<void> Function()? onSuccess,
  }) async {
    setState(() => setLoading(true));
    try {
      await action();

      await onSuccess?.call();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthServiceException catch (e) {

      _showError(e.message);
    } catch (e, st) {
      debugPrint('Login screen caught unexpected error: $e\n$st');
      _showError(fallbackErrorMsg);
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  String _lockoutMessage(int? retryAfterSeconds) {
    final minutes = ((retryAfterSeconds ?? 300) / 60).ceil().clamp(1, 999);
    return _isEn
        ? 'Too many failed attempts. Please try again in $minutes minute${minutes == 1 ? '' : 's'}.'
        : 'Sobrang dami ng maling pagtatangka. Pakisubukang muli pagkalipas ng $minutes minuto.';
  }

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();

    final lockStatus = await _loginAttemptService.checkLock(username);
    if (lockStatus.locked) {
      _showError(_lockoutMessage(lockStatus.retryAfterSeconds));
      return;
    }

    await _run(
      (v) => _isLoading = v,
      () async {
        try {
          await _authService.signIn(username: username, password: _passwordController.text);
        } on AuthServiceException catch (e) {
          final failure = await _loginAttemptService.recordFailure(username);
          if (failure.locked) {
            throw AuthServiceException(_lockoutMessage(failure.retryAfterSeconds));
          }
          if (failure.attemptsRemaining != null) {
            final n = failure.attemptsRemaining!;
            throw AuthServiceException(
              '${e.message} ${_isEn ? '($n attempt${n == 1 ? '' : 's'} remaining)' : '($n na pagtatangka na lang)'}',
            );
          }
          rethrow;
        }
      },
      _isEn
          ? "We couldn't sign you in. Check your username and password and try again."
          : 'Hindi ka namin ma-sign in. Suriin ang iyong username at password at subukan muli.',

      onSuccess: () async {
        await _loginAttemptService.recordSuccess(username);
        SessionService.markLoggedIn();
        await UserService.loadCurrentProfile();

        try {
          await Future.wait([
            HistoryService.fetchAll(),
            ReportService.fetchAll(),
            NotificationService.fetchAll(),
            VendorService.fetchCurrent(),
            SupplierReportService.fetchAll(),
          ]);
        } catch (e, st) {
          debugPrint('Post-login data fetch failed: $e\n$st');
        }
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(e.message);
      return;
    } catch (e, st) {
      debugPrint('Google sign-in launch failed: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
      _showError(_isEn ? 'Google sign-in failed. Please try again.' : 'Nabigo ang Google sign-in. Pakisubukang muli.');
      return;
    }

    // signInWithGoogle() only launches the OAuth browser — it resolves as
    // soon as that opens, not once the user actually finishes on Google's
    // side. Wait for the real signed-in event (fired by
    // supabase_service.dart's onAuthStateChange once the deep-link
    // redirect lands) before treating this as success; otherwise
    // cancelling/backing out of the browser would still drop the user
    // into Home with no real session. didChangeAppLifecycleState above
    // handles the cancel case.
    _awaitingGoogleSignIn = true;
    void onSessionChange() {
      if (!SessionService.isLoggedIn) return;
      SessionService.status.removeListener(onSessionChange);
      _googleSessionListener = null;
      _awaitingGoogleSignIn = false;
      _finishGoogleSignIn();
    }

    _googleSessionListener = onSessionChange;
    SessionService.status.addListener(onSessionChange);
  }

  Future<void> _finishGoogleSignIn() async {
    await UserService.loadCurrentProfile();
    try {
      await Future.wait([
        HistoryService.fetchAll(),
        ReportService.fetchAll(),
        NotificationService.fetchAll(),
        VendorService.fetchCurrent(),
        SupplierReportService.fetchAll(),
      ]);
    } catch (e, st) {
      debugPrint('Post-login data fetch failed: $e\n$st');
    }
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, UserService.postLoginRoute);
    }
  }

  Future<void> _handleGuestLogin() => _run(
        (v) => _isGuestLoading = v,
        () => _authService.signInAsGuest(),
        _isEn ? 'Unable to continue as guest right now. Please try again.' : 'Hindi makapagpatuloy bilang guest ngayon. Pakisubukang muli.',

        onSuccess: () async => SessionService.enterAsGuest(),
      );

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    bool sent = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.sheetTopRadius),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final isEn = _isEn;

          Future<void> handleSend() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() {
              sending = true;
              error = null;
            });
            try {
              await _authService.sendPasswordResetEmail(email: emailCtrl.text.trim());
              setSheetState(() {
                sending = false;
                sent = true;
              });
            } on AuthServiceException catch (e) {
              setSheetState(() {
                sending = false;
                error = e.message;
              });
            } catch (_) {
              setSheetState(() {
                sending = false;
                error = isEn
                    ? "We couldn't send the reset email. Please try again."
                    : 'Hindi namin naipadala ang reset email. Pakisubukang muli.';
              });
            }
          }

          Widget iconBadge(IconData icon) => Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: AppTheme.primaryRed, size: 26),
                ),
              );

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sent
                  ? [
                      Center(child: AppTheme.sheetHandle()),
                      const SizedBox(height: 18),
                      iconBadge(Icons.mark_email_read_outlined),
                      const SizedBox(height: 16),
                      Text(
                        isEn ? 'Check Your Email' : 'Tingnan ang Iyong Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? "If that email matches an account, we've sent a link to reset your password. It expires in 24 hours."
                            : 'Kung tumugma ang email na iyon sa isang account, nagpadala kami ng link para i-reset ang iyong password. Mag-e-expire ito sa loob ng 24 oras.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      AppTheme.gradientButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed]),
                        child: Text(isEn ? 'Done' : 'Tapos'),
                      ),
                    ]
                  : [
                      Center(child: AppTheme.sheetHandle()),
                      const SizedBox(height: 18),
                      iconBadge(Icons.lock_reset_rounded),
                      const SizedBox(height: 16),
                      Text(
                        isEn ? 'Reset Your Password' : 'I-reset ang Iyong Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? "Enter your email address and we'll send a reset link to it."
                            : 'Ilagay ang iyong email address at ipapadala namin ang reset link dito.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      AppTheme.fieldLabel(isEn ? 'EMAIL ADDRESS' : 'EMAIL ADDRESS'),
                      const SizedBox(height: 8),
                      Form(
                        key: formKey,
                        child: TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleSend(),
                          style: TextStyle(color: AppTheme.textDark, fontSize: 14),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return isEn ? 'Please enter your email' : 'Pakilagay ang iyong email';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                              return isEn ? 'Enter a valid email' : 'Maglagay ng wastong email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: isEn ? 'you@example.com' : 'ikaw@halimbawa.com',
                            hintStyle: TextStyle(color: AppTheme.textFaint, fontSize: 14),
                            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                            filled: true,
                            fillColor: AppTheme.bgColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.4),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.spoiledRed),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.spoiledRed, width: 1.4),
                            ),
                          ),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.error_outline, size: 14, color: AppTheme.spoiledRed),
                          const SizedBox(width: 6),
                          Expanded(child: Text(error!, style: TextStyle(color: AppTheme.spoiledRed, fontSize: 12.5))),
                        ]),
                      ],
                      const SizedBox(height: 22),
                      AppTheme.gradientButton(
                        onPressed: sending ? null : handleSend,
                        gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed]),
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text(isEn ? 'Send Reset Link' : 'Ipadala ang Reset Link'),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: sending ? null : () => Navigator.of(sheetContext).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(isEn ? 'Cancel' : 'Kanselahin', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                      ),
                    ],
            ),
          );
        },
      ),
    );
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
    final size = MediaQuery.of(context).size;
    final small = size.width < 360, tablet = size.width > 600;
    final hPad = tablet ? size.width * 0.12 : 24.0;

    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return Scaffold(
          backgroundColor: AppTheme.primaryRed,
          body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(children: [

                Positioned.fill(child: Container(decoration: LoginTheme.waveHeaderDecoration)),
                // Soft decorative circles over the red canvas.
                Positioned(top: -30, right: -20, child: LoginTheme.softCircle(110, opacity: 0.09)),
                Positioned(top: 100, left: -30, child: LoginTheme.softCircle(90, opacity: 0.07)),
                Positioned(top: 190, left: 30, child: LoginTheme.softCircle(46, opacity: 0.06)),
                Positioned(bottom: -50, right: -40, child: LoginTheme.softCircle(130, opacity: 0.06)),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _buildHeader(size, small, hPad, isEn),

                        PhysicalShape(
                          clipper: const CardWaveTopClipper(),
                          color: AppTheme.cardColor,
                          elevation: LoginTheme.cardElevation,
                          shadowColor: LoginTheme.cardShadowColor,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 20 + waveMaxCutDepth + 6, hPad, 36),
                            child: Theme(
                              data: Theme.of(context).copyWith(inputDecorationTheme: LoginTheme.inputDecorationTheme()),
                              child: _buildForm(small, isEn),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Size size, bool small, double hPad, bool isEn) {
    final logoSize = small ? 52.0 : 62.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, size.height * (small ? 0.055 : 0.075), hPad, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: EdgeInsets.all(logoSize * 0.04),
          clipBehavior: Clip.antiAlias,
          decoration: LoginTheme.logoBadgeDecoration(),
          child: Transform.scale(
            scale: 1.6,
            child: Image.asset(
              LoginTheme.logoAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.set_meal_outlined, color: Colors.white, size: logoSize * 0.47),
            ),
          ),
        ),
        SizedBox(height: small ? 12 : 16),
        Text('M.S.A.F.E.', textAlign: TextAlign.center, style: LoginTheme.headerTitle(fontSize: small ? 20 : 24, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          isEn ? 'Meat Spoilage & Freshness Evaluation' : 'Pagsusuri sa Pagkasira at Sariwa ng Karne',
          textAlign: TextAlign.center,
          style: LoginTheme.headerSubtitle(fontSize: small ? 11.5 : 13),
        ),
      ]),
    );
  }

  Widget _buildForm(bool small, bool isEn) {
    return Form(
      key: _formKey,
      // Silent until the first submit attempt, then live-corrects per field.
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(isEn ? 'WELCOME' : 'MALIGAYANG PAGDATING', style: LoginTheme.kickerLabel),
        const SizedBox(height: 6),
        Text(isEn ? 'Sign In to Your Account' : 'Mag-sign In sa Iyong Account', style: LoginTheme.welcomeTitle(fontSize: small ? 21 : 24)),
        const SizedBox(height: 6),
        Text(
          isEn ? 'Enter your credentials to access your dashboard' : 'Ilagay ang iyong credentials para ma-access ang iyong dashboard',
          style: LoginTheme.welcomeSubtitle(fontSize: small ? 12.5 : 13.5),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _usernameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          validator: _validateUsername,
          style: LoginTheme.fieldTextStyle,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
          decoration: InputDecoration(
            labelText: isEn ? 'Username' : 'Username',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: _validatePassword,
          style: LoginTheme.fieldTextStyle,
          onFieldSubmitted: (_) => _handleSignIn(),
          decoration: InputDecoration(
            labelText: isEn ? 'Password' : 'Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted, size: 20),
              tooltip: _obscurePassword ? (isEn ? 'Show password' : 'Ipakita ang password') : (isEn ? 'Hide password' : 'Itago ang password'),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value ?? true),
                  ),
                ),
                const SizedBox(width: 6),
                Text(isEn ? 'Remember me' : 'Tandaan ako', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ]),
            ),
          ),
          TextButton(
            onPressed: _anyLoading ? null : _showForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isEn ? 'Forgot password?' : 'Nakalimutan ang password?', style: const TextStyle(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 20),
        AppTheme.gradientButton(
          onPressed: _anyLoading ? null : _handleSignIn,
          gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed]),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(isEn ? 'Sign In' : 'Mag-sign In'),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: Divider(color: AppTheme.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(isEn ? 'OR CONTINUE WITH' : 'O IPAGPATULOY GAMIT', style: LoginTheme.dividerLabel),
          ),
          Expanded(child: Divider(color: AppTheme.borderColor)),
        ]),
        const SizedBox(height: 16),
      
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _anyLoading ? null : _handleGoogleSignIn,
              style: LoginTheme.compactSecondaryButtonStyle,
              icon: LoginTheme.iconGlyphBadge(color: const Color(0xFF4285F4), child: const _GoogleGlyph()),
              label: Text(isEn ? 'Google' : 'Google'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _anyLoading ? null : _handleGuestLogin,
              style: LoginTheme.compactSecondaryButtonStyle,
              icon: LoginTheme.iconGlyphBadge(
                child: _isGuestLoading
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed))
                    : Icon(Icons.person_outline, size: 16, color: AppTheme.primaryRed),
              ),
              label: Text(isEn ? 'Guest' : 'Guest'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: LoginTheme.noticeBoxBg(AppTheme.accentGold, opacity: 0.08),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: AppTheme.accentGold, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn
                    ? 'Guest access allows you to perform scans without registration; however, your scan history and NMIS reports will not be retained.'
                    : 'Sa pamamagitan ng guest access, makakapag-scan ka nang walang pagpaparehistro; gayunpaman, hindi mase-save ang iyong kasaysayan ng scan at mga NMIS report.',
                style: LoginTheme.noticeText(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Wrap(alignment: WrapAlignment.center, children: [
          Text(isEn ? "Don't have an account? " : 'Wala ka pang account? ', style: LoginTheme.promptText),
          GestureDetector(
            onTap: _anyLoading ? null : () => Navigator.pushNamed(context, '/signup'),
            child: Text(isEn ? 'Register Now' : 'Magparehistro Ngayon', style: LoginTheme.promptLink),
          ),
        ]),
      ]),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Text('G', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
      ),
    );
  }
}
