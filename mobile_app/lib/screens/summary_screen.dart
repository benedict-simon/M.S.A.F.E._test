import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/report_service.dart';
import '../services/settings_service.dart';
import '../widgets/guest_gate.dart';

enum _RangePreset { last7, last30, last90, allTime, custom }

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  _RangePreset _preset = _RangePreset.last30;
  DateTimeRange? _customRange;

  DateTimeRange _resolveRange(List<HistoryItem> scans, List<ReportRecord> reports) {
    final now = DateTime.now();
    switch (_preset) {
      case _RangePreset.last7:
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case _RangePreset.last30:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case _RangePreset.last90:
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case _RangePreset.allTime:
        final timestamps = [
          ...scans.map((s) => s.timestamp),
          ...reports.map((r) => r.submittedAt),
        ];
        final earliest =
            timestamps.isEmpty ? now.subtract(const Duration(days: 30)) : timestamps.reduce((a, b) => a.isBefore(b) ? a : b);
        return DateTimeRange(start: earliest, end: now);
      case _RangePreset.custom:
        return _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.roleAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _preset = _RangePreset.custom;
      });
    }
  }

  String _formatRangeLabel(DateTimeRange range) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String fmt(DateTime d) => '${months[d.month - 1]} ${d.day}, ${d.year}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }

  bool _inRange(DateTime dt, DateTimeRange range) => !dt.isBefore(range.start) && !dt.isAfter(range.end);

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
                  child: AppTheme.screenHeader(context, isEn ? 'Summary Reports' : 'Buod ng Ulat'),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GuestGate(
                    title: isEn ? 'Login Required' : 'Kailangan Mag-login',
                    message: isEn
                        ? 'Log in or create an account to view your summary reports.'
                        : 'Mag-login o gumawa ng account para makita ang iyong buod ng ulat.',
                    icon: Icons.bar_chart_rounded,
                    child: _buildSummaryContent(isEn),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryContent(bool isEn) {
    return ValueListenableBuilder<List<HistoryItem>>(
      valueListenable: HistoryService.items,
      builder: (context, allScans, _) {
        return ValueListenableBuilder<List<ReportRecord>>(
          valueListenable: ReportService.items,
          builder: (context, allReports, _) {
            final range = _resolveRange(allScans, allReports);
            final scans = allScans.where((s) => _inRange(s.timestamp, range)).toList();
            final reports = allReports.where((r) => _inRange(r.submittedAt, range)).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                _rangeSelector(isEn),
                const SizedBox(height: 12),
                _rangeSummaryBanner(scans, reports, range, isEn),
                const SizedBox(height: 20),
                if (scans.isEmpty && reports.isEmpty)
                  _emptyState(isEn)
                else ...[
                  _statsCard(
                    icon: Icons.photo_camera_back_outlined,
                    title: isEn ? 'Scan Activity' : 'Aktibidad ng Scan',
                    color: AppTheme.freshGreen,
                    child: _scanStatsRow(scans, isEn),
                  ),
                  const SizedBox(height: 16),
                  _statsCard(
                    icon: Icons.flag_outlined,
                    title: isEn ? 'NMIS Reports' : 'Ulat sa NMIS',
                    color: AppTheme.roleAccentDark,
                    child: _reportStatsRow(reports, isEn),
                  ),
                  if (scans.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _meatTypeBreakdown(scans, isEn),
                    const SizedBox(height: 16),
                    _trendChart(scans, range, isEn),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _rangeSelector(bool isEn) {
    Widget segment(String label, _RangePreset preset) {
      final selected = _preset == preset;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _preset = preset),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppTheme.roleAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      );
    }

    final isCustom = _preset == _RangePreset.custom;

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: AppTheme.pillContainerDecoration,
          child: Row(children: [
            segment('7D', _RangePreset.last7),
            segment('30D', _RangePreset.last30),
            segment('90D', _RangePreset.last90),
            segment(isEn ? 'All' : 'Lahat', _RangePreset.allTime),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Semantics(
        button: true,
        label: isEn ? 'Pick a custom date range' : 'Pumili ng custom na saklaw ng petsa',
        child: InkWell(
          onTap: _pickCustomRange,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCustom ? AppTheme.roleAccent : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isCustom ? AppTheme.roleAccent : AppTheme.borderColor),
            ),
            child: Icon(Icons.calendar_month_rounded, size: 19, color: isCustom ? Colors.white : AppTheme.textMuted),
          ),
        ),
      ),
    ]);
  }

  Widget _rangeSummaryBanner(List<HistoryItem> scans, List<ReportRecord> reports, DateTimeRange range, bool isEn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: AppTheme.roleGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.roleAccent.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.event_rounded, size: 13, color: Colors.white70),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _formatRangeLabel(range),
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              isEn ? '${scans.length + reports.length} total activities' : '${scans.length + reports.length} kabuuang aktibidad',
              style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        _bannerFigure(value: '${scans.length}', label: isEn ? 'Scans' : 'Scan'),
        const SizedBox(width: 10),
        Container(width: 1, height: 34, color: Colors.white.withOpacity(0.22)),
        const SizedBox(width: 10),
        _bannerFigure(value: '${reports.length}', label: isEn ? 'Reports' : 'Report'),
      ]),
    );
  }

  Widget _bannerFigure({required String value, required String label}) => Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
      ]);

  Widget _emptyState(bool isEn) => AppTheme.emptyState(
        icon: Icons.bar_chart_rounded,
        title: isEn ? 'Nothing in this range' : 'Walang Laman sa Saklaw na Ito',
        subtitle: isEn
            ? 'Try a wider date range, or scan and\nreport something first.'
            : 'Subukan ang mas malawak na saklaw ng petsa, o\nmag-scan at mag-report muna.',
      );


  Widget _sectionHeader(IconData icon, String label, Color color) => Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: AppTheme.iconBadgeBg(color, radius: 9),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTheme.sectionTitle.copyWith(fontSize: 15)),
      ]);

  Widget _statsCard({required IconData icon, required String title, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardWithShadow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(icon, title, color),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _scanStatsRow(List<HistoryItem> scans, bool isEn) {
    final fresh = scans.where((s) => s.isFresh).length;
    final spoiled = scans.length - fresh;
    return Row(children: [
      Expanded(child: _StatTile(icon: Icons.photo_camera_back_outlined, color: AppTheme.textDark, value: '${scans.length}', label: isEn ? 'Total' : 'Kabuuan')),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(icon: Icons.check_circle_outline, color: AppTheme.freshGreen, value: '$fresh', label: isEn ? 'Fresh' : 'Sariwa')),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(icon: Icons.warning_amber_rounded, color: AppTheme.spoiledRed, value: '$spoiled', label: isEn ? 'Spoiled' : 'Sira')),
    ]);
  }

  Widget _reportStatsRow(List<ReportRecord> reports, bool isEn) {
    final reviewed = reports.where((r) => r.isReviewed).length;
    final pending = reports.length - reviewed;
    return Row(children: [
      Expanded(child: _StatTile(icon: Icons.flag_outlined, color: AppTheme.roleAccentDark, value: '${reports.length}', label: isEn ? 'Submitted' : 'Naisumite')),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(icon: Icons.forum_outlined, color: AppTheme.freshGreen, value: '$reviewed', label: isEn ? 'Reviewed' : 'Na-review')),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(icon: Icons.hourglass_empty_rounded, color: AppTheme.accentGold, value: '$pending', label: isEn ? 'Pending' : 'Naghihintay')),
    ]);
  }

  Widget _meatTypeBreakdown(List<HistoryItem> scans, bool isEn) {
    final counts = <String, int>{};
    for (final s in scans) {
      counts[s.meatType] = (counts[s.meatType] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    const colors = {'Chicken': AppTheme.accentGold, 'Pork': AppTheme.spoiledRed, 'Beef': AppTheme.primaryRedDark};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardWithShadow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.pie_chart_rounded, isEn ? 'Meat Type Breakdown' : 'Breakdown ng Uri ng Karne', AppTheme.accentGold),
        const SizedBox(height: 16),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MeatTypeBar(
              label: e.key,
              count: e.value,
              fraction: scans.isEmpty ? 0 : e.value / scans.length,
              color: colors[e.key] ?? AppTheme.textMuted,
              isEn: isEn,
            ),
          ),
      ]),
    );
  }

  Widget _trendChart(List<HistoryItem> scans, DateTimeRange range, bool isEn) {
    final buckets = _buildBuckets(range, scans);
    final maxTotal = buckets.fold<int>(1, (m, b) => b.total > m ? b.total : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardWithShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.show_chart_rounded, isEn ? 'Scan Trend' : 'Uso ng Scan', AppTheme.roleAccentDark),
          const SizedBox(height: 18),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in buckets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (b.spoiledCount > 0)
                            Container(
                              height: 100 * (b.spoiledCount / maxTotal),
                              decoration: const BoxDecoration(
                                color: AppTheme.spoiledRed,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          if (b.freshCount > 0)
                            Container(
                              height: 100 * (b.freshCount / maxTotal),
                              decoration: BoxDecoration(
                                color: AppTheme.freshGreen,
                                borderRadius: b.spoiledCount > 0
                                    ? const BorderRadius.vertical(bottom: Radius.circular(3))
                                    : BorderRadius.circular(3),
                              ),
                            ),
                          if (b.total == 0) Container(height: 2, color: AppTheme.borderColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final b in buckets)
                Expanded(
                  child: Text(
                    _bucketLabel(b.start),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textFaint, fontSize: 9.5, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(AppTheme.freshGreen, isEn ? 'Fresh' : 'Sariwa'),
            const SizedBox(width: 16),
            _legendDot(AppTheme.spoiledRed, isEn ? 'Spoiled' : 'Sira'),
          ]),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
      ]);

  String _bucketLabel(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  List<_Bucket> _buildBuckets(DateTimeRange range, List<HistoryItem> scans) {
    const maxBuckets = 10;

    final totalMs = math.max(1, range.end.difference(range.start).inMilliseconds);
    final days = math.max(1, (totalMs / (1000 * 60 * 60 * 24)).ceil());
    final bucketCount = days < maxBuckets ? days : maxBuckets;
    final bucketMs = (totalMs / bucketCount).ceil();

    final buckets = List.generate(bucketCount, (i) {
      final start = range.start.add(Duration(milliseconds: bucketMs * i));
      final isLast = i == bucketCount - 1;
      final end = isLast ? range.end.add(const Duration(seconds: 1)) : range.start.add(Duration(milliseconds: bucketMs * (i + 1)));
      return _Bucket(start: start, end: end);
    });

    for (final scan in scans) {
      for (final b in buckets) {
        if (!scan.timestamp.isBefore(b.start) && scan.timestamp.isBefore(b.end)) {
          if (scan.isFresh) {
            b.freshCount++;
          } else {
            b.spoiledCount++;
          }
          break;
        }
      }
    }

    return buckets;
  }
}

class _Bucket {
  final DateTime start;
  final DateTime end;
  int freshCount = 0;
  int spoiledCount = 0;
  _Bucket({required this.start, required this.end});
  int get total => freshCount + spoiledCount;
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Container(width: 30, height: 30, decoration: AppTheme.iconBadgeBg(color), child: Icon(icon, color: color, size: 15)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppTheme.textFaint, fontSize: 10.5, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      );
}

class _MeatTypeBar extends StatelessWidget {
  final String label;
  final int count;
  final double fraction;
  final Color color;
  final bool isEn;
  const _MeatTypeBar({required this.label, required this.count, required this.fraction, required this.color, required this.isEn});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              AppTheme.meatIconImage(label, size: 15, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            Text(
              isEn ? (count == 1 ? '1 scan' : '$count scans') : '$count scan',
              style: TextStyle(color: AppTheme.textFaint, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(children: [
                Container(height: 8, width: constraints.maxWidth, color: AppTheme.bgColor),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: 8,
                  width: constraints.maxWidth * fraction,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                ),
              ]);
            }),
          ),
        ],
      );
}
