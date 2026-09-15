import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/education_theme.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../services/education_service.dart';
import '../services/settings_service.dart';
import 'education_category_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late Future<List<EducationNode>> _treeFuture;

  String? _pendingFocusSection;
  bool _handledInitialFocus = false;

  @override
  void initState() {
    super.initState();
    _treeFuture = EducationService.fetchTree();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final focusSection = ModalRoute.of(context)?.settings.arguments as String?;
    if (focusSection != null) _pendingFocusSection = focusSection;
  }

  void _retry() => setState(() => _treeFuture = EducationService.fetchTree());

  EducationNode? _firstMatch(List<EducationNode> nodes, bool Function(String) predicate) {
    for (final n in nodes) {
      if (predicate(n.title)) return n;
    }
    return null;
  }

  void _openCategory(EducationNode category) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EducationCategoryScreen(category: category)));
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                AppTheme.screenHeader(context, isEn ? 'Food Safety Education' : 'Edukasyon sa Kaligtasan sa Pagkain'),
                const SizedBox(height: 20),
                FutureBuilder<List<EducationNode>>(
                  future: _treeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.roleAccent)),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return _buildErrorState(isEn);
                    }
                    return _buildCategoryList(snapshot.data!, isEn);
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 3,
            onTap: (i) => AppBottomNavBar.navigateTo(context, 3, i),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(children: [
        Icon(Icons.wifi_off_rounded, color: AppTheme.textFaint, size: 34),
        const SizedBox(height: 10),
        Text(isEn ? 'Could not load content' : 'Hindi Na-load ang Content', style: AppTheme.emptyTitle),
        const SizedBox(height: 4),
        Text(isEn ? 'Check your connection and try again.' : 'Suriin ang iyong koneksyon at subukan muli.', style: AppTheme.emptySubtitle, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh_rounded, size: 16), label: Text(isEn ? 'Try Again' : 'Subukan Muli')),
      ]),
    );
  }

  String _subtitleFor(EducationNode category, bool isEn) {
    if (category.plainBody.isNotEmpty) return category.plainBody;
    final n = category.children.length;
    return isEn ? '$n item${n == 1 ? '' : 's'}' : '$n item';
  }

  Widget _buildCategoryList(List<EducationNode> roots, bool isEn) {
    final categories = roots.where((r) => r.nodeType == 'category').toList();

    if (categories.isEmpty) {
      return AppTheme.emptyState(
        icon: Icons.menu_book_outlined,
        title: isEn ? 'No content yet' : 'Wala Pang Content',
        subtitle: isEn ? 'Check back soon for food safety guidance.' : 'Bumalik sa lalong madaling panahon para sa gabay sa kaligtasan sa pagkain.',
      );
    }

    if (!_handledInitialFocus) {
      _handledInitialFocus = true;
      final focusSection = _pendingFocusSection;
      if (focusSection != null) {
        EducationNode? target;
        if (focusSection == 'spoilage') {
          target = _firstMatch(categories, EducationTheme.isFreshnessFolder);
        } else if (focusSection == 'storage') {
          target = _firstMatch(categories, EducationTheme.isHandlingFolder);
        }
        if (target != null) {
          final resolvedTarget = target;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openCategory(resolvedTarget);
          });
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          EducationTheme.navCard(
            icon: EducationTheme.iconForFolder(categories[i].title),
            color: EducationTheme.colorForFolder(categories[i].title),
            title: categories[i].title,
            subtitle: _subtitleFor(categories[i], isEn),
            onTap: () => _openCategory(categories[i]),
          ),
          if (i != categories.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
