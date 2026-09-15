import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_form_widgets.dart' show AppFormField, PrimaryButton;
import '../services/settings_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final Future<void> Function(String firstName, String middleInitial, String lastName, String username, String email, String phone)? onSave;

  const EditProfileScreen({
    super.key,
    this.firstName = '',
    this.middleInitial = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.phone = '',
    this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleInitialCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _saving = false;

  static final _nameChars = RegExp(r"^[A-Za-zÀ-ſ\s\-']+$");
  static final _usernameChars = RegExp(r'^[A-Za-z0-9_.]+$');
  static final _phoneChars = RegExp(r'^\+?[0-9\s\-]{7,15}$');
  static final _emailChars = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  bool get _isEn => SettingsService.isEnglish;

  String get _initials {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    if (f.isEmpty && l.isEmpty) return '?';
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    return (a + b).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.firstName);
    _middleInitialCtrl = TextEditingController(text: widget.middleInitial);
    _lastNameCtrl = TextEditingController(text: widget.lastName);
    _usernameCtrl = TextEditingController(text: widget.username);
    _emailCtrl = TextEditingController(text: widget.email);
    _phoneCtrl = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleInitialCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

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

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEn ? 'Please enter your email address' : 'Pakilagay ang iyong email address';
    return _emailChars.hasMatch(t) ? null : (_isEn ? 'Please enter a valid email address' : 'Pakilagay ang wastong email address');
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null; // optional
    return _phoneChars.hasMatch(t) ? null : (_isEn ? 'Please enter a valid contact number' : 'Pakilagay ang wastong numero ng telepono');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.onSave != null) {
        await widget.onSave!(
          _firstNameCtrl.text.trim(),
          _middleInitialCtrl.text.trim(),
          _lastNameCtrl.text.trim(),
          _usernameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _phoneCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Profile updated successfully' : 'Matagumpay na na-update ang profile')),
      );
      Navigator.of(context).pop({
        'firstName': _firstNameCtrl.text.trim(),
        'middleInitial': _middleInitialCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Could not save your changes: $e' : 'Hindi na-save ang iyong mga pagbabago: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                _ScreenHeader(title: isEn ? 'Edit Profile' : 'I-edit ang Profile'),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Center(child: _AvatarPicker(initials: _initials, isEn: isEn)),
                        const SizedBox(height: 22),
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
                                      ? 'Changing your email may require you to verify it again before signing in.'
                                      : 'Kapag pinalitan ang iyong email, maaaring kailanganin mo itong i-verify muli bago mag-sign in.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        AppTheme.fieldLabel(isEn ? 'FIRST NAME' : 'PANGALAN'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _firstNameCtrl,
                          hint: isEn ? 'Enter first name' : 'Ilagay ang pangalan',
                          textCapitalization: TextCapitalization.words,
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          validator: _validateFirstName,
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'MIDDLE INITIAL (OPTIONAL)' : 'GITNANG TITIK (OPSYONAL)'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _middleInitialCtrl,
                          hint: isEn ? 'Enter middle initial' : 'Ilagay ang gitnang titik',
                          textCapitalization: TextCapitalization.words,
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          validator: _validateMiddleInitial,
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'LAST NAME' : 'APELYIDO'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _lastNameCtrl,
                          hint: isEn ? 'Enter last name' : 'Ilagay ang apelyido',
                          textCapitalization: TextCapitalization.words,
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.name,
                          validator: _validateLastName,
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'USERNAME' : 'USERNAME'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _usernameCtrl,
                          hint: isEn ? 'Choose a username' : 'Pumili ng username',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.text,
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'CONTACT NUMBER (OPTIONAL)' : 'NUMERO NG TELEPONO (OPTIONAL)'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _phoneCtrl,
                          hint: 'e.g. 0917 123 4567',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'EMAIL ADDRESS' : 'EMAIL ADDRESS'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _emailCtrl,
                          hint: isEn ? 'Enter email address' : 'Ilagay ang email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: isEn ? 'Save Changes' : 'I-save ang mga Pagbabago',
                          loading: _saving,
                          onPressed: _handleSave,
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

class _AvatarPicker extends StatelessWidget {
  final String initials;
  final bool isEn;
  const _AvatarPicker({required this.initials, required this.isEn});

  @override
  Widget build(BuildContext context) {
    const size = 76.0;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderColor, width: 1.4),
          ),
          child: Text(
            initials,
            style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 26),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEn ? 'Photo upload coming soon' : 'Malapit nang magamit ang pag-upload ng larawan')),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor, width: 1.2),
              ),
              child: Icon(Icons.camera_alt_outlined, size: 14, color: AppTheme.textMuted),
            ),
          ),
        ),
      ],
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
