//contact_us_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_form_widgets.dart' show AppFormField, PrimaryButton;
import '../services/settings_service.dart';

enum ContactCategory { bug, accuracy, suggestion, account, general, other }

class ContactUsScreen extends StatefulWidget {
  final String prefillEmail;

  final Future<void> Function(
    ContactCategory category,
    String subject,
    String message,
    String email,
    int? rating,
    List<XFile> attachments,
  )? onSubmit;

  const ContactUsScreen({super.key, this.prefillEmail = '', this.onSubmit});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _messageCtrl = TextEditingController();
  final _customSubjectCtrl = TextEditingController();
  final _picker = ImagePicker();

  ContactCategory _category = ContactCategory.general;
  int _rating = 0;
  bool _ratingTouched = false;
  bool _sending = false;

  static const int _maxAttachments = 3;
  final List<XFile> _attachments = [];

  bool get _isEn => SettingsService.isEnglish;

  bool get _showRating => _category == ContactCategory.general;

  List<(String, String)> get _faqs => _isEn
      ? const [
          (
            'Why does the app say "Caution" instead of a clear answer?',
            'M.S.A.F.E. gives a confidence-based read from the photo. When the '
                'model isn\'t confident enough for a clear Fresh/Spoiled call, it '
                'flags Caution so you can double-check manually before deciding.',
          ),
          (
            'Is a scan a substitute for official inspection?',
            'No. Scans are a screening aid only. For official findings, always '
                'defer to your local NMIS inspector or food safety authority.',
          ),
          (
            'Which meats are supported?',
            'Raw pork, beef, and chicken. Cooked, cured, or processed meats are '
                'not currently supported and may give unreliable results.',
          ),
        ]
      : const [
          (
            'Bakit "Caution" ang sagot ng app sa halip na malinaw na sagot?',
            'Nagbibigay ang M.S.A.F.E. ng confidence-based na pagbasa mula sa '
                'larawan. Kapag hindi sapat ang kumpiyansa ng modelo para sa '
                'malinaw na Fresh/Spoiled, nilalagyan ito ng Caution para '
                'ma-double-check mo muna nang manu-mano bago magdesisyon.',
          ),
          (
            'Kapalit ba ng opisyal na inspeksyon ang isang scan?',
            'Hindi. Tulong sa pag-screen lamang ang mga scan. Para sa opisyal '
                'na findings, laging sumangguni sa iyong lokal na NMIS inspector '
                'o awtoridad sa food safety.',
          ),
          (
            'Anong mga karne ang suportado?',
            'Hilaw na baboy, baka, at manok. Ang niluto, in-cure, o processed '
                'na karne ay hindi pa suportado at maaaring magbigay ng hindi '
                'maaasahang resulta.',
          ),
        ];

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    _customSubjectCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(ContactCategory c) {
    if (_isEn) {
      switch (c) {
        case ContactCategory.bug:
          return 'Report a bug';
        case ContactCategory.accuracy:
          return 'Scan result seems wrong';
        case ContactCategory.suggestion:
          return 'Suggest a feature';
        case ContactCategory.account:
          return 'Account or login issue';
        case ContactCategory.general:
          return 'General feedback';
        case ContactCategory.other:
          return 'Other';
      }
    }
    switch (c) {
      case ContactCategory.bug:
        return 'Mag-report ng bug';
      case ContactCategory.accuracy:
        return 'Mali ang resulta ng scan';
      case ContactCategory.suggestion:
        return 'Magmungkahi ng feature';
      case ContactCategory.account:
        return 'Isyu sa account o login';
      case ContactCategory.general:
        return 'Pangkalahatang feedback';
      case ContactCategory.other:
        return 'Iba pa';
    }
  }

  IconData _categoryIcon(ContactCategory c) {
    switch (c) {
      case ContactCategory.bug:
        return Icons.bug_report_outlined;
      case ContactCategory.accuracy:
        return Icons.rule_outlined;
      case ContactCategory.suggestion:
        return Icons.lightbulb_outline_rounded;
      case ContactCategory.account:
        return Icons.person_outline_rounded;
      case ContactCategory.general:
        return Icons.chat_bubble_outline_rounded;
      case ContactCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _ratingLabel(int r) {
    if (_isEn) {
      switch (r) {
        case 1:
          return 'Poor';
        case 2:
          return 'Fair';
        case 3:
          return 'Good';
        case 4:
          return 'Great';
        case 5:
          return 'Excellent';
        default:
          return 'Tap a star to rate the app';
      }
    }
    switch (r) {
      case 1:
        return 'Mahina';
      case 2:
        return 'Puwede Na';
      case 3:
        return 'Maganda';
      case 4:
        return 'Napakaganda';
      case 5:
        return 'Napakahusay';
      default:
        return 'Pindutin ang bituin para mag-rate ng app';
    }
  }

  void _onCategoryChanged(ContactCategory? c) {
    if (c == null) return;
    setState(() {
      _category = c;
      // A star rating only belongs to general feedback — drop it silently
      // if the user switches to something else.
      if (!_showRating) {
        _rating = 0;
        _ratingTouched = false;
      }
    });
  }

  Future<void> _addAttachment() async {
    if (_attachments.length >= _maxAttachments) return;

    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
      if (file == null) return;
      if (!mounted) return;
      setState(() => _attachments.add(file));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Could not add that file: $e' : 'Hindi maidagdag ang file na iyon: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  Future<void> _handleSend() async {
    setState(() => _ratingTouched = true);
    final formOk = _formKey.currentState!.validate();

    if (!formOk) return;
    if (_showRating && _rating == 0) return;

    final subjectText =
        _category == ContactCategory.other ? _customSubjectCtrl.text.trim() : _categoryLabel(_category);

    setState(() => _sending = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(
          _category,
          subjectText,
          _messageCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _showRating && _rating > 0 ? _rating : null,
          List.unmodifiable(_attachments),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Thanks for reaching out! Our team will get back to you soon.'
                : 'Salamat sa pagkontak! Makikipag-ugnayan ang aming team sa iyo sa lalong madaling panahon.',
          ),
        ),
      );
      setState(() {
        _messageCtrl.clear();
        _customSubjectCtrl.clear();
        _category = ContactCategory.general;
        _rating = 0;
        _ratingTouched = false;
        _attachments.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Could not send your message: $e' : 'Hindi naipadala ang iyong mensahe: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
                      ),
                      Text(
                        isEn ? 'Help & Support' : 'Tulong at Suporta',
                        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        AppTheme.fieldLabel(isEn ? 'FREQUENTLY ASKED' : 'MADALAS ITANONG'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: AppTheme.outlinedCard(radius: 16),
                          child: Column(
                            children: [
                              for (int i = 0; i < _faqs.length; i++) ...[
                                _FaqTile(question: _faqs[i].$1, answer: _faqs[i].$2),
                                if (i != _faqs.length - 1)
                                  Divider(height: 1, color: AppTheme.borderColor, indent: 16, endIndent: 16),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(isEn ? 'CONTACT US' : 'KONTAKIN KAMI'),
                        const SizedBox(height: 8),
                        Text(
                          isEn
                              ? 'Found a bug, have an idea, or think a scan got it wrong? '
                                  "Let us know and we'll get back to you at the email below. "
                                  '(Bugs the app detects on its own are also reported to us '
                                  "automatically — you'll still see a notification either way.)"
                              : 'May nakita kang bug, may ideya ka, o sa tingin mo mali ang '
                                  'resulta ng scan? Sabihin mo sa amin at sasagutin ka namin '
                                  'sa email sa ibaba. (Ang mga bug na na-detect mismo ng app ay '
                                  'awtomatiko ring nire-report sa amin — makakakuha ka pa rin '
                                  'ng notification sa alinmang paraan.)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUBJECT' : 'PAKSA'),
                        const SizedBox(height: 8),
                        _SubjectDropdown(
                          value: _category,
                          onChanged: _onCategoryChanged,
                          label: _categoryLabel,
                          icon: _categoryIcon,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _category == ContactCategory.other
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: AppFormField(
                                    controller: _customSubjectCtrl,
                                    hint: isEn ? 'Type your subject' : 'I-type ang iyong paksa',
                                    icon: Icons.edit_outlined,
                                    textCapitalization: TextCapitalization.words,
                                    validator: (v) {
                                      if (_category != ContactCategory.other) return null;
                                      if (v == null || v.trim().isEmpty) {
                                        return isEn ? 'Please tell us what this is about' : 'Pakisabi kung ano ang tungkol dito';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        // The star rating is only relevant — and only shown —
                        // for general feedback about the app itself.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _showRating
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppTheme.fieldLabel(isEn ? 'RATE YOUR EXPERIENCE' : 'I-RATE ANG IYONG KARANASAN'),
                                      const SizedBox(height: 8),
                                      _StarRating(
                                        value: _rating,
                                        onChanged: (v) => setState(() {
                                          _rating = v;
                                          _ratingTouched = true;
                                        }),
                                        label: _ratingLabel(_rating),
                                      ),
                                      if (_ratingTouched && _rating == 0) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          isEn ? 'Please tap a star to rate the app' : 'Pakipindot ang bituin para mag-rate ng app',
                                          style: TextStyle(
                                            color: AppTheme.spoiledRed,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'YOUR EMAIL' : 'IYONG EMAIL'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _emailCtrl,
                          hint: isEn ? 'Where should we reply?' : 'Saan namin dapat isagot?',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return isEn ? 'Email is required' : 'Kinakailangan ang email';
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                              return isEn ? 'Enter a valid email' : 'Maglagay ng wastong email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppTheme.fieldLabel(isEn ? 'MESSAGE' : 'MENSAHE'),
                        const SizedBox(height: 8),
                        AppFormField(
                          controller: _messageCtrl,
                          hint: isEn ? 'Tell us what happened...' : 'Sabihin sa amin ang nangyari...',
                          icon: Icons.chat_bubble_outline_rounded,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              (v == null || v.trim().length < 5) ? (isEn ? 'Please add a bit more detail' : 'Pakidagdagan ng kaunting detalye') : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            AppTheme.fieldLabel(isEn ? 'ATTACHMENTS (OPTIONAL)' : 'MGA ATTACHMENT (OPTIONAL)'),
                            const Spacer(),
                            Text(
                              '${_attachments.length}/$_maxAttachments',
                              style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEn
                              ? 'Attach a screenshot of the bug or the scan result to help us understand faster.'
                              : 'Mag-attach ng screenshot ng bug o resulta ng scan para mas mabilis naming maintindihan.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        _AttachmentsRow(
                          attachments: _attachments,
                          maxAttachments: _maxAttachments,
                          onAdd: _addAttachment,
                          onRemove: _removeAttachment,
                          isEn: isEn,
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: isEn ? 'Send Message' : 'Ipadala ang Mensahe',
                          loading: _sending,
                          onPressed: _handleSend,
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

class _SubjectDropdown extends StatelessWidget {
  final ContactCategory value;
  final ValueChanged<ContactCategory?> onChanged;
  final String Function(ContactCategory) label;
  final IconData Function(ContactCategory) icon;

  const _SubjectDropdown({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppTheme.outlinedCard(radius: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ContactCategory>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600),
          items: ContactCategory.values.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon(c), size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 10),
                  Text(label(c)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AttachmentsRow extends StatelessWidget {
  final List<XFile> attachments;
  final int maxAttachments;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool isEn;

  const _AttachmentsRow({
    required this.attachments,
    required this.maxAttachments,
    required this.onAdd,
    required this.onRemove,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    final canAddMore = attachments.length < maxAttachments;
    const tileSize = 76.0;

    return SizedBox(
      height: tileSize,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int i = 0; i < attachments.length; i++) ...[
            _AttachmentThumbnail(
              file: attachments[i],
              size: tileSize,
              onRemove: () => onRemove(i),
            ),
            const SizedBox(width: 10),
          ],
          if (canAddMore)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor, width: 1.4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textMuted, size: 22),
                    const SizedBox(height: 4),
                    Text(isEn ? 'Add' : 'Idagdag', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final XFile file;
  final double size;
  final VoidCallback onRemove;

  const _AttachmentThumbnail({required this.file, required this.size, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),

            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    width: size,
                    height: size,
                    color: AppTheme.borderColor.withValues(alpha: 0.3),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    width: size,
                    height: size,
                    color: AppTheme.borderColor.withValues(alpha: 0.3),
                    child: Icon(Icons.broken_image_outlined, color: AppTheme.textFaint),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: size,
                    height: size,
                    color: AppTheme.borderColor.withValues(alpha: 0.3),
                    child: Icon(Icons.broken_image_outlined, color: AppTheme.textFaint),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppTheme.spoiledRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int value; // 0-5
  final ValueChanged<int> onChanged;
  final String label;

  const _StarRating({required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: AppTheme.outlinedCard(radius: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final filled = starIndex <= value;
              return InkWell(
                onTap: () => onChanged(starIndex),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: filled ? AppTheme.accentGold : AppTheme.textFaint,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: value == 0 ? AppTheme.textFaint : AppTheme.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          question,
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        iconColor: AppTheme.textMuted,
        collapsedIconColor: AppTheme.textFaint,
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}
