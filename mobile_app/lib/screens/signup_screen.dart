import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/signup_theme.dart';
import '../theme/wave_clipper.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart';
import '../services/session_service.dart';
import '../services/signup_otp_service.dart';
import '../services/user_service.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/vendor_service.dart';
import '../services/supplier_report_service.dart';
import '../services/settings_service.dart';
import '../utils/text_formatters.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

enum _PwStrength { empty, weak, fair, strong }

class _SignupScreenState extends State<SignupScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleInitial = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _auth = AuthService();
  final _signupOtp = SignupOtpService();

  final _firstNameFN = FocusNode();
  final _middleInitialFN = FocusNode();
  final _lastNameFN = FocusNode();
  final _usernameFN = FocusNode();
  final _phoneFN = FocusNode();
  final _emailFN = FocusNode();
  final _passwordFN = FocusNode();
  final _confirmPasswordFN = FocusNode();

  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  bool _obscurePw = true, _obscureConfirmPw = true;
  bool _agreed = false, _loading = false, _googleLoading = false;
  _PwStrength _pwStrength = _PwStrength.empty;

  bool _submitted = false;

  bool _awaitingGoogleSignIn = false;
  VoidCallback? _googleSessionListener;

  bool get _anyLoading => _loading || _googleLoading;
  bool get _confirmMatches => _confirmPassword.text.isNotEmpty && _confirmPassword.text == _password.text;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _termsTap.onTap = _showTermsOfService;
    _privacyTap.onTap = _showPrivacyPolicy;
    _password.addListener(_updatePwStrength);
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
    if (mounted) setState(() => _googleLoading = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_googleSessionListener != null) {
      SessionService.status.removeListener(_googleSessionListener!);
    }
    _password.removeListener(_updatePwStrength);
    for (final c in [_firstName, _middleInitial, _lastName, _username, _phone, _email, _password, _confirmPassword]) {
      c.dispose();
    }
    for (final f in [_firstNameFN, _middleInitialFN, _lastNameFN, _usernameFN, _phoneFN, _emailFN, _passwordFN, _confirmPasswordFN]) {
      f.dispose();
    }
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  // ---------- Strength meter ----------

  void _updatePwStrength() {
    final v = _password.text;
    _PwStrength s;
    if (v.isEmpty) {
      s = _PwStrength.empty;
    } else {
      var score = 0;
      if (v.length >= 6) score++;
      if (v.length >= 10) score++;
      if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[0-9]').hasMatch(v)) score++;
      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) score++;
      s = score <= 1 ? _PwStrength.weak : score <= 2 ? _PwStrength.fair : _PwStrength.strong;
    }
    if (s != _pwStrength) setState(() => _pwStrength = s);
  }

  // ---------- Validators ----------

  static final _nameChars = RegExp(r"^[A-Za-zÀ-ſ\s\-']+$");
  static final _usernameChars = RegExp(r'^[A-Za-z0-9_.]+$');
  static final _phoneChars = RegExp(r'^\+?[0-9\s\-]{7,15}$');

  static final _emailChars = RegExp(
    r'^[A-Za-z0-9](?:[A-Za-z0-9._%+-]*[A-Za-z0-9])?@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}$',
  );

  String? _validateFirstName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please enter your first name' : 'Pakilagay ang iyong pangalan';
    if (t.length < 2) return _isEn ? 'First name is too short' : 'Masyadong maikli ang pangalan';
    if (!_nameChars.hasMatch(t)) return _isEn ? 'Letters only, please' : 'Letra lamang, pakisuyo';
    return null;
  }

  String? _validateMiddleInitial(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!_nameChars.hasMatch(t)) return _isEn ? 'Letters only, please' : 'Letra lamang, pakisuyo';
    return null;
  }

  String? _validateLastName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please enter your last name' : 'Pakilagay ang iyong apelyido';
    if (t.length < 2) return _isEn ? 'Last name is too short' : 'Masyadong maikli ang apelyido';
    if (!_nameChars.hasMatch(t)) return _isEn ? 'Letters only, please' : 'Letra lamang, pakisuyo';
    return null;
  }

  String? _validateUsername(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please choose a username' : 'Pumili ng username';
    if (t.length < 3) return _isEn ? 'Username must be at least 3 characters' : 'Dapat hindi bababa sa 3 characters ang username';
    if (t.length > 20) return _isEn ? 'Username must be 20 characters or fewer' : 'Dapat 20 characters o mas kaunti ang username';
    if (!_usernameChars.hasMatch(t)) return _isEn ? 'Letters, numbers, "_" and "." only' : 'Letra, numero, "_" at "." lamang';
    return null;
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please enter your contact number' : 'Pakilagay ang iyong numero ng telepono';
    if (!_phoneChars.hasMatch(t)) return _isEn ? 'Please enter a valid contact number' : 'Pakilagay ang wastong numero ng telepono';
    return null;
  }

  static const _disposableDomains = {
    'mailinator.com', 'guerrillamail.com', 'guerrillamail.info', '10minutemail.com',
    '10minutemail.net', 'tempmail.com', 'temp-mail.org', 'throwawaymail.com',
    'yopmail.com', 'trashmail.com', 'getnada.com', 'dispostable.com',
    'fakeinbox.com', 'sharklasers.com', 'maildrop.cc', 'mintemail.com',
    'moakt.com', 'mailnesia.com', 'discard.email', 'spamgourmet.com',
  };

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please enter your email address' : 'Pakilagay ang iyong email address';
    if (t.contains('..') || !_emailChars.hasMatch(t)) {
      return _isEn ? 'Please enter a real, valid email address' : 'Pakilagay ang totoo at wastong email address';
    }
    final domain = t.split('@').last.toLowerCase();
    if (_disposableDomains.contains(domain)) {
      return _isEn
          ? 'Temporary/disposable email addresses are not allowed. Please use a real email account.'
          : 'Hindi pinapayagan ang pansamantalang email. Gumamit ng totoong email account.';
    }
    return null;
  }

  String? _validatePassword(String? v) => (v == null || v.isEmpty)
      ? (_isEn ? 'Please create a password' : 'Gumawa ng password')
      : (v.length < 6 ? (_isEn ? 'Use at least 6 characters' : 'Gumamit ng hindi bababa sa 6 characters') : null);

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return _isEn ? 'Please confirm your password' : 'Kumpirmahin ang iyong password';
    return v != _password.text ? (_isEn ? 'Passwords do not match' : 'Hindi magkatugma ang mga password') : null;
  }

  // ---------- Actions ----------

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() => _submitted = true);

    final formOk = _formKey.currentState!.validate();
    if (!formOk) {
      _showError(_isEn ? 'Please fill in all required fields correctly.' : 'Pakikumpleto ang lahat ng kinakailangang field nang wasto.');
      return;
    }
    if (!_agreed) {
      _showError(_isEn ? 'Please agree to the Terms and Privacy Policy to continue.' : 'Pakisang-ayunan ang Mga Tuntunin at Patakaran sa Privacy para magpatuloy.');
      return;
    }

    final email = _email.text.trim();

    setState(() => _loading = true);

    final emailIsReal = await EmailVerificationService.isEmailReal(email);
    if (!emailIsReal) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(_isEn
          ? "We couldn't verify that email address is real and deliverable. Please check for typos or use a different email."
          : 'Hindi namin na-verify na totoo at deliverable ang email address na iyon. Pakisuri ang typo o gumamit ng ibang email.');
      return;
    }

    try {

      await _signupOtp.requestOtp(email);
      if (!mounted) return;
      _showEmailConfirmationSheet(email);
    } on SignupOtpServiceException catch (e) {
      _showError(e.message);
    } catch (e, st) {
      debugPrint('Signup screen caught unexpected error: $e\n$st');
      _showError(_isEn ? "We couldn't send a verification code. Please try again." : 'Hindi namin naipadala ang verification code. Pakisubukang muli.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEmailConfirmationSheet(String email) {
    bool resending = false;
    bool resent = false;
    bool verifying = false;
    String? otpError;
    final otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> handleVerify() async {
            final code = otpController.text.trim();
            if (code.isEmpty) {
              setSheetState(() => otpError = _isEn ? 'Enter the code from your email.' : 'Ilagay ang code mula sa iyong email.');
              return;
            }
            setSheetState(() {
              verifying = true;
              otpError = null;
            });
            try {
              // Only now does the account actually get created — see
              // backend/app/routers/auth.py's /auth/signup/verify.
              await _signupOtp.verify(
                email: email,
                otp: code,
                firstName: _firstName.text.trim(),
                middleInitial: _middleInitial.text.trim(),
                lastName: _lastName.text.trim(),
                username: _username.text.trim(),
                phoneNumber: _phone.text.trim(),
                password: _password.text,
              );

              await _auth.signInWithPassword(email: email, password: _password.text);

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
                debugPrint('Post-OTP-verify data fetch failed: $e\n$st');
              }

              if (!sheetContext.mounted || !mounted) return;
              Navigator.of(sheetContext).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            } on SignupOtpServiceException catch (e) {
              setSheetState(() {
                verifying = false;
                otpError = e.message;
              });
            } on AuthServiceException catch (e) {
              setSheetState(() {
                verifying = false;
                otpError = e.message;
              });
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppTheme.freshGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.mark_email_read_outlined, color: AppTheme.freshGreen, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEn ? 'Enter Verification Code' : 'Ilagay ang Verification Code',
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, height: 1.5),
                    children: [
                      TextSpan(
                        text: _isEn ? "We've sent a 6-digit code to " : 'Nagpadala kami ng 6-digit code sa ',
                      ),
                      TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryRed)),
                      TextSpan(
                        text: _isEn
                            ? '. Enter it below to activate your account.'
                            : '. Ilagay ito sa ibaba para i-activate ang iyong account.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
                  onChanged: (_) {
                    if (otpError != null) setSheetState(() => otpError = null);
                  },
                  onSubmitted: (_) => handleVerify(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(color: AppTheme.textFaint, letterSpacing: 8),
                    filled: true,
                    fillColor: AppTheme.bgColor,
                    errorText: otpError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (resent) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _isEn ? 'Code resent.' : 'Naipadala muli ang code.',
                        style: TextStyle(color: AppTheme.freshGreen, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                AppTheme.primaryButton(
                  onPressed: verifying ? null : handleVerify,
                  child: verifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEn ? 'Verify' : 'I-verify'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: resending
                      ? null
                      : () async {
                          setSheetState(() => resending = true);
                          try {
                            await _signupOtp.requestOtp(email);
                            setSheetState(() {
                              resending = false;
                              resent = true;
                            });
                          } on SignupOtpServiceException catch (e) {
                            setSheetState(() => resending = false);
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          }
                        },
                  child: resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                        )
                      : Text(_isEn ? "Didn't get it? Resend code" : 'Hindi natanggap? Ipadala muli'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(_isEn ? 'Back to Sign In' : 'Bumalik sa Sign In'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _googleLoading = true);
    try {
      await _auth.signInWithGoogle();
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _googleLoading = false);
      _showError(e.message);
      return;
    } catch (e, st) {
      debugPrint('Google sign-up launch failed: $e\n$st');
      if (mounted) setState(() => _googleLoading = false);
      _showError(_isEn ? 'Google sign-up failed. Please try again.' : 'Nabigo ang Google sign-up. Pakisubukang muli.');
      return;
    }

    _awaitingGoogleSignIn = true;
    void onSessionChange() {
      if (!SessionService.isLoggedIn) return;
      SessionService.status.removeListener(onSessionChange);
      _googleSessionListener = null;
      _awaitingGoogleSignIn = false;
      _finishGoogleSignUp();
    }

    _googleSessionListener = onSessionChange;
    SessionService.status.addListener(onSessionChange);
  }

  Future<void> _finishGoogleSignUp() async {
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
      debugPrint('Post-signup data fetch failed: $e\n$st');
    }
    if (mounted) {
      setState(() => _googleLoading = false);
      Navigator.pushReplacementNamed(context, UserService.postLoginRoute);
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

  void _showTermsOfService() => _showLegalSheet(
        title: _isEn ? 'Terms of Service' : 'Mga Tuntunin ng Serbisyo',
        body: _isEn
            ? 'By creating an account, you agree to use M.S.A.F.E. responsibly '
                'as a preliminary screening tool. Scan results are based on visual '
                'indicators only and are not a substitute for official NMIS '
                'inspection or laboratory testing.'
            : 'Sa paggawa ng account, sumasang-ayon kang gamitin ang M.S.A.F.E. '
                'nang responsable bilang paunang tool sa pag-screen. Ang mga '
                'resulta ng scan ay batay lamang sa visual na palatandaan at '
                'hindi kapalit ng opisyal na inspeksyon ng NMIS o laboratory testing.',
      );

  void _showPrivacyPolicy() => _showLegalSheet(
        title: _isEn ? 'Privacy Policy' : 'Patakaran sa Privacy',
        body: _isEn
            ? 'Your scan history, account details, and any reports you submit '
                "are stored securely via Supabase. Reports you flag for review are "
                "shared only with NMIS inspectors through the Chick N' Meat portal."
            : 'Ang iyong kasaysayan ng scan, detalye ng account, at anumang '
                'report na isinumite mo ay maiimbak nang secure sa Supabase. Ang '
                'mga report na i-flag mo para sa review ay ibinabahagi lamang sa '
                "mga inspector ng NMIS sa pamamagitan ng Chick N' Meat portal.",
      );

  void _showLegalSheet({required String title, required String body}) => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.cardColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
              ),
              Text(title, style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(body, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      );

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final small = size.width < 360, tablet = size.width > 600;
    final hPad = tablet ? size.width * 0.12 : 24.0;

    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        return PopScope(
          canPop: !_anyLoading,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _anyLoading) {
              _showError(isEn ? 'Please wait for the current request to finish.' : 'Pakihintay munang matapos ang kasalukuyang request.');
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.primaryRed,
            body: SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(children: [

                  Positioned.fill(child: Container(decoration: SignupTheme.waveHeaderDecoration)),
                  // Soft decorative circles over the red canvas.
                  Positioned(top: -26, left: -24, child: SignupTheme.softCircle(100, opacity: 0.08)),
                  Positioned(top: 110, right: -20, child: SignupTheme.softCircle(90, opacity: 0.06)),
                  Positioned(top: 200, right: 30, child: SignupTheme.softCircle(40, opacity: 0.06)),
                  Positioned(bottom: -50, left: -40, child: SignupTheme.softCircle(130, opacity: 0.06)),
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
                            elevation: SignupTheme.cardElevation,
                            shadowColor: SignupTheme.cardShadowColor,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16 + waveMaxCutDepth + 6, hPad, 30),
                              child: Theme(
                                data: Theme.of(context).copyWith(inputDecorationTheme: SignupTheme.inputDecorationTheme()),
                                child: _buildForm(small, isEn),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _anyLoading ? null : () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: SignupTheme.backButtonDecoration,
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Size size, bool small, double hPad, bool isEn) {
    final logoSize = small ? 48.0 : 56.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, size.height * (small ? 0.04 : 0.055) + 44, hPad, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: EdgeInsets.all(logoSize * 0.04),
          clipBehavior: Clip.antiAlias,
          decoration: SignupTheme.logoBadgeDecoration(),
          child: Transform.scale(
            scale: 1.6,
            child: Image.asset(
              SignupTheme.logoAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.set_meal_outlined, color: Colors.white, size: logoSize * 0.45),
            ),
          ),
        ),
        SizedBox(height: small ? 10 : 14),
        Text(isEn ? 'Register for an Account' : 'Magparehistro ng Account', textAlign: TextAlign.center, style: SignupTheme.headerTitle(fontSize: small ? 18 : 21)),
        const SizedBox(height: 6),
        Text(
          isEn ? 'Complete the form below to begin monitoring meat freshness' : 'Kumpletuhin ang form sa ibaba para simulan ang pagmonitor sa sariwa ng karne',
          textAlign: TextAlign.center,
          style: SignupTheme.headerSubtitle(fontSize: small ? 11.5 : 13),
        ),
      ]),
    );
  }

  Widget _buildForm(bool small, bool isEn) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(isEn ? 'GET STARTED' : 'MAGSIMULA', style: SignupTheme.kickerLabel),
        const SizedBox(height: 6),
        Text(
          isEn ? 'Create Your Account' : 'Gumawa ng Iyong Account',
          style: SignupTheme.headerTitle(fontSize: small ? 19 : 21).copyWith(color: AppTheme.textDark),
        ),
        const SizedBox(height: 22),
        Text(isEn ? 'PERSONAL INFO' : 'PERSONAL NA IMPORMASYON', style: SignupTheme.sectionLabel),
        const SizedBox(height: 12),
        _buildNameFields(small, isEn),
        const SizedBox(height: 22),
        Text(isEn ? 'ACCOUNT DETAILS' : 'DETALYE NG ACCOUNT', style: SignupTheme.sectionLabel),
        const SizedBox(height: 12),
        TextFormField(
          controller: _username,
          focusNode: _usernameFN,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername],
          validator: _validateUsername,
          style: SignupTheme.fieldTextStyle,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFN),
          decoration: InputDecoration(
            labelText: isEn ? 'Username' : 'Username',
            prefixIcon: Icon(Icons.alternate_email, color: AppTheme.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          focusNode: _phoneFN,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: _validatePhone,
          style: SignupTheme.fieldTextStyle,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFN),
          decoration: InputDecoration(
            labelText: isEn ? 'Contact Number' : 'Numero ng Telepono',
            hintText: 'e.g. 0917 123 4567',
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _email,
          focusNode: _emailFN,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: _validateEmail,
          style: SignupTheme.fieldTextStyle,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFN),
          decoration: InputDecoration(
            labelText: isEn ? 'Email Address' : 'Email Address',
            prefixIcon: Icon(Icons.mail_outline, color: AppTheme.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 22),
        Text(isEn ? 'SECURITY' : 'SEGURIDAD', style: SignupTheme.sectionLabel),
        const SizedBox(height: 12),
        TextFormField(
          controller: _password,
          focusNode: _passwordFN,
          obscureText: _obscurePw,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: _validatePassword,
          style: SignupTheme.fieldTextStyle,
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFN),
          decoration: InputDecoration(
            labelText: isEn ? 'Password' : 'Password',
            helperText: isEn ? 'At least 6 characters' : 'Hindi bababa sa 6 characters',
            helperStyle: SignupTheme.fieldHelperStyle,
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted, size: 20),
              tooltip: _obscurePw ? (isEn ? 'Show password' : 'Ipakita ang password') : (isEn ? 'Hide password' : 'Itago ang password'),
              onPressed: () => setState(() => _obscurePw = !_obscurePw),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _PwStrengthIndicator(strength: _pwStrength, isEn: isEn),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPassword,
          focusNode: _confirmPasswordFN,
          obscureText: _obscureConfirmPw,
          textInputAction: TextInputAction.done,
          validator: _validateConfirmPassword,
          style: SignupTheme.fieldTextStyle,
          onFieldSubmitted: (_) => _handleSignUp(),
          decoration: InputDecoration(
            labelText: isEn ? 'Confirm Password' : 'Kumpirmahin ang Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_confirmMatches)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.check_circle_rounded, color: AppTheme.freshGreen, size: 18),
                ),
              IconButton(
                icon: Icon(_obscureConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textMuted, size: 20),
                tooltip: _obscureConfirmPw ? (isEn ? 'Show password' : 'Ipakita ang password') : (isEn ? 'Hide password' : 'Itago ang password'),
                onPressed: () => setState(() => _obscureConfirmPw = !_obscureConfirmPw),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                    children: [
                      TextSpan(text: isEn ? 'I agree to the ' : 'Sumasang-ayon ako sa '),
                      TextSpan(
                        text: isEn ? 'Terms of Service' : 'Mga Tuntunin ng Serbisyo',
                        recognizer: _termsTap,
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryRed,
                        ),
                      ),
                      TextSpan(text: isEn ? ' and ' : ' at '),
                      TextSpan(
                        text: isEn ? 'Privacy Policy' : 'Patakaran sa Privacy',
                        recognizer: _privacyTap,
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
        if (_submitted && !_agreed) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              isEn ? 'Please agree to the Terms and Privacy Policy' : 'Pakisang-ayunan ang Mga Tuntunin at Patakaran sa Privacy',
              style: TextStyle(color: AppTheme.spoiledRed, fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        const SizedBox(height: 24),

        AppTheme.gradientButton(
          onPressed: _anyLoading ? null : _handleSignUp,
          gradient: const LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed]),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
              : Text(isEn ? 'Create Account' : 'Gumawa ng Account'),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: Divider(color: AppTheme.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(isEn ? 'OR SIGN UP WITH' : 'O MAG-SIGN UP GAMIT', style: SignupTheme.dividerLabel),
          ),
          Expanded(child: Divider(color: AppTheme.borderColor)),
        ]),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _anyLoading ? null : _handleGoogleSignUp,
          style: SignupTheme.secondaryButtonStyle,
          icon: SignupTheme.iconGlyphBadge(
            color: const Color(0xFF4285F4),
            child: _googleLoading
                ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textDark))
                : const _GoogleGlyph(),
          ),
          label: Text(isEn ? 'Continue with Google' : 'Ipagpatuloy gamit ang Google'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: SignupTheme.noticeBoxBg(AppTheme.freshGreen, opacity: 0.08),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_outlined, color: AppTheme.freshGreen, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn
                    ? 'Your scan history remains private unless you choose to submit a report for NMIS review.'
                    : 'Ang iyong kasaysayan ng scan ay pribado maliban kung magpasya kang magsumite ng report para sa NMIS review.',
                style: SignupTheme.noticeText(fontSize: 11.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Wrap(alignment: WrapAlignment.center, children: [
          Text(isEn ? 'Already have an account? ' : 'May account ka na? ', style: SignupTheme.promptText),
          GestureDetector(
            onTap: _anyLoading ? null : () => Navigator.pop(context),
            child: Text(isEn ? 'Sign In' : 'Mag-sign In', style: SignupTheme.promptLink),
          ),
        ]),
      ]),
    );
  }

  Widget _buildNameFields(bool small, bool isEn) {
    final firstNameField = TextFormField(
      controller: _firstName,
      focusNode: _firstNameFN,
      autofocus: true,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [TitleCaseTextFormatter()],
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.givenName],
      validator: _validateFirstName,
      style: SignupTheme.fieldTextStyle,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_middleInitialFN),
      decoration: InputDecoration(
        labelText: isEn ? 'First Name' : 'Pangalan',
        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
      ),
    );

    final middleInitialField = TextFormField(
      controller: _middleInitial,
      focusNode: _middleInitialFN,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [TitleCaseTextFormatter()],
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.middleName],
      validator: _validateMiddleInitial,
      style: SignupTheme.fieldTextStyle,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_lastNameFN),
      decoration: InputDecoration(
        labelText: isEn ? 'M.I.' : 'G.T.',
        helperText: isEn ? 'Optional' : 'Opsyonal',
        helperStyle: SignupTheme.fieldHelperStyle,
        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
      ),
    );

    final lastNameField = TextFormField(
      controller: _lastName,
      focusNode: _lastNameFN,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [TitleCaseTextFormatter()],
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.familyName],
      validator: _validateLastName,
      style: SignupTheme.fieldTextStyle,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_usernameFN),
      decoration: InputDecoration(
        labelText: isEn ? 'Last Name' : 'Apelyido',
        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textMuted, size: 20),
      ),
    );

    return Column(children: [
      firstNameField,
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 1, child: middleInitialField),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: lastNameField),
      ]),
    ]);
  }
}

class _PwStrengthIndicator extends StatelessWidget {
  final _PwStrength strength;
  final bool isEn;
  const _PwStrengthIndicator({required this.strength, required this.isEn});

  @override
  Widget build(BuildContext context) {
    if (strength == _PwStrength.empty) return const SizedBox(height: 2);

    final (label, color, filledBars) = switch (strength) {
      _PwStrength.weak => (isEn ? 'Weak — add more characters' : 'Mahina — magdagdag ng mas maraming character', AppTheme.spoiledRed, 1),
      _PwStrength.fair => (isEn ? 'Fair — add a number or symbol' : 'Puwede na — magdagdag ng numero o simbolo', AppTheme.accentGold, 2),
      _PwStrength.strong => (isEn ? 'Strong password' : 'Malakas na password', AppTheme.freshGreen, 3),
      _PwStrength.empty => ('', AppTheme.borderColor, 0),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: List.generate(3, (i) {
          final filled = i < filledBars;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(color: filled ? color : AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
          );
        }),
      ),
      const SizedBox(height: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 18,
        height: 18,
        child: Center(
          child: Text('G', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
        ),
      );
}
