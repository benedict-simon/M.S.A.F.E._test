import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/education_theme.dart';
import '../services/education_service.dart';
import '../services/settings_service.dart';

class EducationCategoryScreen extends StatefulWidget {
  final EducationNode category;

  const EducationCategoryScreen({super.key, required this.category});

  @override
  State<EducationCategoryScreen> createState() => _EducationCategoryScreenState();
}

class _EducationCategoryScreenState extends State<EducationCategoryScreen> {
  int _selectedMeatIndex = 0;
  final Map<String, bool> _expandedFolders = {};
  final Set<String> _expandedLessons = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final category = widget.category;
        final color = EducationTheme.colorForFolder(category.title);
        final isFreshness = EducationTheme.isFreshnessFolder(category.title);
        final meatFolders = category.children.where((c) => c.nodeType == 'subcategory').toList();

        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                AppTheme.screenHeader(context, category.title),
                const SizedBox(height: 20),
                if (isFreshness && meatFolders.isNotEmpty)
                  _buildFreshnessContent(meatFolders, color, isEn)
                else
                  _buildGenericContent(category, color, isEn, isTopLevel: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreshnessContent(List<EducationNode> meatFolders, Color color, bool isEn) {
    if (_selectedMeatIndex >= meatFolders.length) _selectedMeatIndex = 0;

    final selected = meatFolders[_selectedMeatIndex];
    final cards = selected.children.where((c) => c.nodeType == 'card').toList();
    final lessons = selected.children.where((c) => c.nodeType == 'dropdown').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn ? 'Compare color, texture, and smell for each meat type' : 'Ihambing ang kulay, texture, at amoy ng bawat uri ng karne',
          style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < meatFolders.length; i++) ...[
              AppTheme.filterChip(
                label: meatFolders[i].title,
                selected: i == _selectedMeatIndex,
                onTap: () => setState(() => _selectedMeatIndex = i),
              ),
              if (i != meatFolders.length - 1) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        if (cards.isEmpty && lessons.isEmpty)
          Text(
            isEn ? 'No content yet for ${selected.title}.' : 'Wala pang content para sa ${selected.title}.',
            style: TextStyle(color: AppTheme.textFaint, fontSize: 12.5),
          ),
        if (cards.isNotEmpty)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: _cardTile(cards[i], isEn)),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ]),
        if (lessons.isNotEmpty) ...[
          if (cards.isNotEmpty) const SizedBox(height: 12),
          for (var i = 0; i < lessons.length; i++) ...[
            _lessonTile(lessons[i], color: color, isEn: isEn),
            if (i != lessons.length - 1) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _cardTile(EducationNode card, bool isEn) {
    final color = card.color ?? AppTheme.textMuted;
    final icon = card.title.toLowerCase().contains('spoil') ? Icons.cancel_rounded : Icons.check_circle_rounded;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(card.title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15))),
        ]),
        const SizedBox(height: 12),
        if (card.items.isEmpty)
          Text(isEn ? 'No details yet.' : 'Wala pang detalye.', style: TextStyle(color: color.withOpacity(0.7), fontSize: 12.5, fontStyle: FontStyle.italic))
        else
          for (final item in card.items) ...[
            AppTheme.bulletItem(text: item, color: color, fontSize: 13),
            const SizedBox(height: 6),
          ],
      ]),
    );
  }

  Widget _buildGenericContent(EducationNode folder, Color color, bool isEn, {bool isTopLevel = false}) {
    final isLegal = EducationTheme.isLegalFolder(folder.title);
    final body = folder.plainBody;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTopLevel && body.isNotEmpty) ...[
          Text(body, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.45)),
          const SizedBox(height: 16),
        ],
        if (folder.children.isEmpty)
          Text(isEn ? 'No content yet.' : 'Wala pang content.', style: TextStyle(color: AppTheme.textFaint, fontSize: 12.5))
        else
          for (var i = 0; i < folder.children.length; i++) ...[
            _renderChild(folder.children[i], color, isEn),
            const SizedBox(height: 10),
          ],
        if (isTopLevel && isLegal) ...[
          AppTheme.tintedInfoBox(
            icon: Icons.info_outline_rounded,
            color: AppTheme.borderColor,
            opacity: 0.4,
            iconSize: 16,
            fontSize: 11.5,
            italic: true,
            padding: const EdgeInsets.all(14),
            text: isEn
                ? 'The content provided by M.S.A.F.E. is based on official NMIS legal '
                    'references. It is intended for informational purposes only and does '
                    'not replace official NMIS inspection.'
                : 'Ang content na ibinigay ng M.S.A.F.E. ay batay sa opisyal na legal na '
                    'reperensya ng NMIS. Ito ay para sa layuning pang-impormasyon lamang '
                    'at hindi kapalit ng opisyal na inspeksyon ng NMIS.',
          ),
        ],
      ],
    );

    if (isTopLevel) return content;

    final subtitle = body.isNotEmpty
        ? body
        : (isEn
            ? '${folder.children.length} item${folder.children.length == 1 ? '' : 's'}'
            : '${folder.children.length} item');

    return _dropdownSection(
      icon: EducationTheme.iconForFolder(folder.title),
      color: color,
      title: folder.title,
      subtitle: subtitle,
      expanded: _expandedFolders[folder.id] ?? false,
      onToggle: () => setState(() => _expandedFolders[folder.id] = !(_expandedFolders[folder.id] ?? false)),
      content: content,
    );
  }

  Widget _renderChild(EducationNode node, Color parentColor, bool isEn) {
    switch (node.nodeType) {
      case 'dropdown':
        return _lessonTile(node, color: parentColor, isEn: isEn);
      case 'card':
        return _cardTile(node, isEn);
      case 'subcategory':
        return _buildGenericContent(node, parentColor, isEn);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _dropdownSection({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget content,
  }) =>
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppTheme.cardWithShadow,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: AppTheme.iconBadgeBg(color, radius: 12),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      const SizedBox(height: 3),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ]),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textFaint),
                  ),
                ]),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: content,
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      );

  String _lessonPreview(EducationNode lesson, bool isEn) =>
      lesson.plainBody.isEmpty ? (isEn ? 'No details yet.' : 'Wala pang detalye.') : lesson.plainBody;

  Widget _lessonTile(EducationNode lesson, {required Color color, required bool isEn}) {
    final hasLaw = lesson.lawReference != null && lesson.lawReference!.trim().isNotEmpty;
    final preview = _lessonPreview(lesson, isEn);
    return _lessonDropdown(
      id: lesson.id,
      icon: hasLaw ? Icons.gavel_rounded : Icons.description_outlined,
      color: color,
      title: lesson.title,
      preview: preview,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLaw) ...[
            Text(lesson.lawReference!.trim(), style: TextStyle(color: AppTheme.textFaint, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
          ],
          Text(preview, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }

  Widget _lessonDropdown({
    required String id,
    required IconData icon,
    required Color color,
    required String title,
    required String preview,
    required Widget body,
  }) {
    final isOpen = _expandedLessons.contains(id);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              isOpen ? _expandedLessons.remove(id) : _expandedLessons.add(id);
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(icon, size: 17, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(preview,
                        maxLines: isOpen ? null : 1,
                        overflow: isOpen ? null : TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                  ]),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color.withOpacity(0.7)),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: body,
            ),
            crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}