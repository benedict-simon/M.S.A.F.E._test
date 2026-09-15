import 'package:flutter/material.dart';
import '../services/nearby_report_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Shows a "N prior reports near this location" warning once a lat/lng is
/// available — purely informational, never blocks submission. Shared by
/// report_screen.dart and vendor_store_details_screen.dart so a consumer
/// (or a vendor checking their own stall) gets the same pre-purchase signal.
class NearbyReportBanner extends StatefulWidget {
  final double? lat;
  final double? lng;
  const NearbyReportBanner({super.key, this.lat, this.lng});

  @override
  State<NearbyReportBanner> createState() => _NearbyReportBannerState();
}

class _NearbyReportBannerState extends State<NearbyReportBanner> {
  final _service = NearbyReportService();
  NearbySummary? _summary;
  double? _fetchedLat;
  double? _fetchedLng;

  @override
  void initState() {
    super.initState();
    _maybeFetch();
  }

  @override
  void didUpdateWidget(covariant NearbyReportBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFetch();
  }

  void _maybeFetch() {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) return;
    if (lat == _fetchedLat && lng == _fetchedLng) return;
    _fetchedLat = lat;
    _fetchedLng = lng;
    _service.summary(lat, lng).then((s) {
      if (mounted && lat == widget.lat && lng == widget.lng) {
        setState(() => _summary = s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (widget.lat == null || widget.lng == null || summary == null) return const SizedBox.shrink();
    if (summary.complaintCount == 0) return const SizedBox.shrink();

    final isEn = SettingsService.isEnglish;
    final text = isEn
        ? '${summary.complaintCount} prior report${summary.complaintCount == 1 ? '' : 's'} near this location.'
        : '${summary.complaintCount} nakaraang report malapit sa lokasyong ito.';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppTheme.tintedInfoBox(
        icon: Icons.warning_amber_rounded,
        text: text,
        contentColor: AppTheme.spoiledRed.withOpacity(0.85),
        color: AppTheme.spoiledRed,
        opacity: 0.08,
      ),
    );
  }
}
