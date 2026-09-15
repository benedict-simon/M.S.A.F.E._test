// lib\screens\reports_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/report_service.dart';
import '../services/supplier_report_service.dart';
import '../services/user_service.dart';
import '../services/settings_service.dart';
import '../widgets/guest_gate.dart';
import 'receipt_screen.dart';
import 'summary_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  bool get _isVendor => UserService.profile.value?.isVendor ?? false;

  void _openReceipt(BuildContext context, ReportRecord r) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: r.meatType,
          scanReference: r.scanReference,
          scanTimestamp: r.scanTimestamp,
          placeOfPurchase: r.placeOfPurchase,
          locationAddress: r.formattedAddress,
          purchaseDate: r.purchaseDate,
          purchaseTime: r.purchaseTime,
          additionalDetails: r.additionalDetails,
          isPreview: false,
          isReviewed: r.isReviewed,
        ),
      ),
    );
  }

  void _openSupplierReceipt(BuildContext context, SupplierReport r, bool isEn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: r.meatType,
          scanReference: r.scanReference,
          scanTimestamp: r.scanTimestamp,
          placeOfPurchase: r.supplierName,
          purchaseDate: r.deliveryDate,
          additionalDetails: r.additionalDetails,
          locationLabel: 'SUPPLIER',
          dateLabel: isEn ? 'DELIVERY DATE' : 'PETSA NG DELIVERY',
          showTime: false,
          isPreview: false,
          isReviewed: r.isReviewed,
        ),
      ),
    );
  }

  void _openSummary(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode, UserService.profile]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final isVendor = _isVendor;
        return Scaffold(
          backgroundColor: AppTheme.bgColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppTheme.screenHeader(
                    context,
                    isVendor
                        ? (isEn ? 'Supplier Reports' : 'Ulat sa Supplier')
                        : (isEn ? 'My Reports' : 'Aking mga Report'),
                    trailing: _summaryButton(context),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GuestGate(
                    title: isEn ? 'No Reports Yet' : 'Wala Pang Report',
                    message: isVendor
                        ? (isEn
                            ? 'Log in as a vendor to submit and track supplier reports.'
                            : 'Mag-login bilang vendor para magsumite at subaybayan ang mga supplier report.')
                        : (isEn
                            ? 'Log in or create an account to submit and track NMIS reports.'
                            : 'Mag-login o gumawa ng account para magsumite at subaybayan ang mga NMIS report.'),
                    icon: Icons.flag_outlined,
                    child: isVendor ? _buildSupplierReportsContent(isEn) : _buildReportsContent(isEn),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsContent(bool isEn) {
    return ValueListenableBuilder<List<ReportRecord>>(
      valueListenable: ReportService.items,
      builder: (context, reports, _) {
        if (reports.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.flag_outlined,
            title: isEn ? 'No reports yet' : 'Wala Pang Report',
            subtitle: isEn ? 'Reports you submit to NMIS will\nshow up here.' : 'Ang mga report na isinumite mo sa NMIS ay\nlalabas dito.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (final r in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(record: r, isEn: isEn, onTap: () => _openReceipt(context, r)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierReportsContent(bool isEn) {
    return ValueListenableBuilder<List<SupplierReport>>(
      valueListenable: SupplierReportService.items,
      builder: (context, reports, _) {
        if (reports.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.local_shipping_outlined,
            color: AppTheme.vendorBlue,
            title: isEn ? 'No supplier reports yet' : 'Wala Pang Supplier Report',
            subtitle: isEn
                ? 'Reports you submit about your suppliers\nwill show up here.'
                : 'Ang mga report tungkol sa iyong supplier ay\nlalabas dito.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (final r in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SupplierReportCard(record: r, isEn: isEn, onTap: () => _openSupplierReceipt(context, r, isEn)),
              ),
          ],
        );
      },
    );
  }

  Widget _summaryButton(BuildContext context) => InkWell(
        onTap: () => _openSummary(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: AppTheme.backButtonDecoration,
          child: Icon(Icons.bar_chart_rounded, color: AppTheme.textDark, size: 19),
        ),
      );
}

class _ReportCard extends StatelessWidget {
  final ReportRecord record;
  final bool isEn;
  final VoidCallback onTap;

  const _ReportCard({required this.record, required this.isEn, required this.onTap});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return isEn ? '${diff.inMinutes} min ago' : '${diff.inMinutes} min ang nakalipas';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      if (isEn) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
      return '${diff.inHours} oras ang nakalipas';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, $hour12:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReviewed = record.isReviewed;
    final statusColor = isReviewed ? AppTheme.freshGreen : AppTheme.accentGold;
    final statusLabel = isReviewed ? (isEn ? 'REVIEWED' : 'NA-REVIEW NA') : (isEn ? 'PENDING REVIEW' : 'HINIHINTAY ANG REVIEW');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardWithShadow,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: AppTheme.iconBadgeBg(AppTheme.primaryRedDark),
              child: Icon(Icons.flag_rounded, color: AppTheme.primaryRedDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.meatType, style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${record.scanReference} · ${_formatTimestamp(record.submittedAt)}',
                    style: AppTheme.cardSubtitle.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: AppTheme.statusPillBg(statusColor),
                    child: Text(statusLabel, style: AppTheme.statusPillText(statusColor)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }
}

class _SupplierReportCard extends StatelessWidget {
  final SupplierReport record;
  final bool isEn;
  final VoidCallback onTap;

  const _SupplierReportCard({required this.record, required this.isEn, required this.onTap});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return isEn ? '${diff.inMinutes} min ago' : '${diff.inMinutes} min ang nakalipas';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      if (isEn) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
      return '${diff.inHours} oras ang nakalipas';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, $hour12:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReviewed = record.isReviewed;
    final statusColor = isReviewed ? AppTheme.freshGreen : AppTheme.accentGold;
    final statusLabel = isReviewed ? (isEn ? 'REVIEWED' : 'NA-REVIEW NA') : (isEn ? 'PENDING REVIEW' : 'HINIHINTAY ANG REVIEW');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardWithShadow,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: AppTheme.iconBadgeBg(AppTheme.vendorBlue),
              child: Icon(Icons.local_shipping_rounded, color: AppTheme.vendorBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.supplierName.isEmpty ? record.meatType : record.supplierName,
                      style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${record.meatType} · ${record.scanReference} · ${_formatTimestamp(record.submittedAt)}',
                    style: AppTheme.cardSubtitle.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: AppTheme.statusPillBg(statusColor),
                    child: Text(statusLabel, style: AppTheme.statusPillText(statusColor)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }
}
