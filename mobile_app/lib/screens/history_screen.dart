import 'package:flutter/material.dart';
import '../models/meat_type.dart';
import '../theme/app_theme.dart';
import '../theme/history_theme.dart';
import '../services/history_service.dart';
import '../services/meat_type_service.dart';
import '../services/settings_service.dart';
import '../widgets/guest_gate.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'scan_result_screen.dart';

enum _HistoryFilter { all, fresh, spoiled }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  final _searchController = TextEditingController();
  final Set<String> _selectedMeatTypes = {};
  List<MeatType> _meatTypes = [];

  @override
  void initState() {
    super.initState();
    MeatTypeService.fetchAll().then((types) {
      if (mounted) setState(() => _meatTypes = types);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryItem> _filtered(List<HistoryItem> all) {
    var list = all;

    switch (_filter) {
      case _HistoryFilter.all:
        break;
      case _HistoryFilter.fresh:
        list = list.where((e) => e.isFresh).toList();
        break;
      case _HistoryFilter.spoiled:
        list = list.where((e) => !e.isFresh).toList();
        break;
    }

    if (_selectedMeatTypes.isNotEmpty) {
      list = list.where((e) => _selectedMeatTypes.contains(e.meatType)).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((e) => e.meatType.toLowerCase().contains(query)).toList();
    }

    return list;
  }

  Map<String, List<HistoryItem>> _grouped(List<HistoryItem> filtered, bool isEn) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final todayLabel = isEn ? 'Today' : 'Ngayon';
    final yesterdayLabel = isEn ? 'Yesterday' : 'Kahapon';
    final thisWeekLabel = isEn ? 'This Week' : 'Ngayong Linggo';
    final earlierLabel = isEn ? 'Earlier' : 'Mas Nauna';

    final groups = <String, List<HistoryItem>>{
      todayLabel: [],
      yesterdayLabel: [],
      thisWeekLabel: [],
      earlierLabel: [],
    };

    for (final item in filtered) {
      final day = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
      if (day == today) {
        groups[todayLabel]!.add(item);
      } else if (day == yesterday) {
        groups[yesterdayLabel]!.add(item);
      } else if (day.isAfter(weekAgo)) {
        groups[thisWeekLabel]!.add(item);
      } else {
        groups[earlierLabel]!.add(item);
      }
    }

    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  void _openResult(HistoryItem item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            meatType: item.meatType,
            isFresh: item.isFresh,
            confidence: item.confidence,
            findings: item.findings,
            recommendation: item.recommendation,
            storageTips: item.storageTips,
            scanReference: item.scanReference,
            scanTimestamp: item.timestamp,
            readOnly: true,
            scanId: item.scanId,
            flagged: item.flagged,
          ),
        ),
      );

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
                  child: AppTheme.screenHeader(context, isEn ? 'Scan History' : 'Kasaysayan ng Scan'),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GuestGate(
                    title: isEn ? 'No Scan History' : 'Walang Kasaysayan ng Scan',
                    message: isEn
                        ? 'Log in or create an account to keep and view your scan history.'
                        : 'Mag-login o gumawa ng account para i-save at makita ang iyong kasaysayan ng scan.',
                    icon: Icons.history_rounded,
                    child: _buildHistoryContent(isEn),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 1,
            onTap: (i) => AppBottomNavBar.navigateTo(context, 1, i),
          ),
        );
      },
    );
  }

  Widget _buildHistoryContent(bool isEn) {
    return ValueListenableBuilder<List<HistoryItem>>(
      valueListenable: HistoryService.items,
      builder: (context, all, _) {
        final filtered = _filtered(all);
        final grouped = _grouped(filtered, isEn);

        if (all.isEmpty) return _emptyState(isEn);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isEn ? 'Search by meat type' : 'Maghanap ayon sa uri ng karne',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final type in _meatTypes)
                  AppTheme.filterChip(
                    label: type.label,
                    selected: _selectedMeatTypes.contains(type.name),
                    onTap: () => setState(() {
                      if (_selectedMeatTypes.contains(type.name)) {
                        _selectedMeatTypes.remove(type.name);
                      } else {
                        _selectedMeatTypes.add(type.name);
                      }
                    }),
                  ),
                _statusDropdown(isEn),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isEn ? '${filtered.length} scan${filtered.length == 1 ? '' : 's'}' : '${filtered.length} scan',
                style: HistoryTheme.countLabel,
              ),
            ),
            const SizedBox(height: 18),
            if (grouped.isEmpty)
              _noMatchesState(isEn)
            else
              for (final entry in grouped.entries) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(entry.key.toUpperCase(), style: HistoryTheme.groupLabel),
                  Text('${entry.value.length}', style: HistoryTheme.countLabel),
                ]),
                const SizedBox(height: 10),
                for (final item in entry.value) ...[
                  _ScanHistoryCard(item: item, isEn: isEn, onTap: () => _openResult(item)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Widget _statusDropdown(bool isEn) {
    return Container(
      width: 100,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_HistoryFilter>(
          value: _filter,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 16),
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
          items: [
            DropdownMenuItem(value: _HistoryFilter.all, child: Text(isEn ? 'All' : 'Lahat')),
            DropdownMenuItem(value: _HistoryFilter.fresh, child: Text(isEn ? 'Fresh' : 'Sariwa')),
            DropdownMenuItem(value: _HistoryFilter.spoiled, child: Text(isEn ? 'Spoiled' : 'Sira')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _filter = v);
          },
        ),
      ),
    );
  }

  Widget _emptyState(bool isEn) => AppTheme.emptyState(
        icon: Icons.history_rounded,
        title: isEn ? 'No scans yet' : 'Wala Pang Scan',
        subtitle: isEn
            ? 'Your scanned meat photos and their\nfreshness results will show up here.'
            : 'Ang iyong mga na-scan na larawan ng karne\nat resulta ng freshness ay lalabas dito.',
      );

  Widget _noMatchesState(bool isEn) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.filter_alt_off_outlined, color: AppTheme.textFaint, size: 32),
          const SizedBox(height: 10),
          Text(
            isEn ? 'No scans match this filter' : 'Walang tumutugmang scan sa filter na ito',
            style: AppTheme.emptySubtitle,
            textAlign: TextAlign.center,
          ),
        ]),
      );
}

class _ScanHistoryCard extends StatelessWidget {
  final HistoryItem item;
  final bool isEn;
  final VoidCallback onTap;

  const _ScanHistoryCard({required this.item, required this.isEn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = item.isFresh ? AppTheme.freshGreen : AppTheme.spoiledRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardWithShadow,
        child: Row(
          children: [
            AppTheme.meatThumbnail(item.meatType, size: 56, radius: 12, color: AppTheme.textFaint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.meatType, style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                      if (item.flagged) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.flag_rounded, size: 14, color: AppTheme.accentGold),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_formatTimestamp(item.timestamp, isEn), style: AppTheme.cardSubtitle.copyWith(fontSize: 12.5)),
                  const SizedBox(height: 8),
                  HistoryTheme.smallBadge(item.isFresh ? (isEn ? 'Fresh' : 'Sariwa') : (isEn ? 'Spoiled' : 'Sira'), statusColor),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt, bool isEn) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return isEn ? '${diff.inMinutes} min ago' : '${diff.inMinutes} min ang nakalipas';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      if (isEn) {
        return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
      }
      return '${diff.inHours} oras ang nakalipas';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, $hour12:$minute $period';
    }
  }
}
