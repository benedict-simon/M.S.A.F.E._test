// lib\screens\report_screen.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../theme/report_theme.dart';
import '../services/report_service.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../utils/string_utils.dart';
import '../utils/text_formatters.dart';
import '../widgets/location_autocomplete_field.dart';
import '../widgets/nearby_report_banner.dart';
import 'receipt_screen.dart';
import 'stall_location_picker_screen.dart';

class ReportScreen extends StatefulWidget {
  final String meatType;
  final String scanReference;

  final String? scanId;
  final DateTime scanTimestamp;
  final void Function(ReportSubmission submission)? onSubmit;
  final VoidCallback? onCancel;

  ReportScreen({
    super.key,
    this.meatType = 'Chicken — Breast',
    this.scanReference = 'SCN-00483',
    this.scanId,
    DateTime? scanTimestamp,
    this.onSubmit,
    this.onCancel,
  }) : scanTimestamp = scanTimestamp ?? DateTime(2026, 7, 19, 8, 14);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  TimeOfDay? _purchaseTime;
  LatLng? _pinnedLocation;
  bool _resolvingAddress = false;
  String? _purchaseHouseNumber;
  String? _purchaseStreet;
  String? _purchaseBarangay;
  String? _purchaseCity;
  String? _purchaseProvince;
  String? _purchasePostalCode;
  String? _purchaseCountry;

  DateTime get _purchaseDate => DateTime(
        widget.scanTimestamp.year,
        widget.scanTimestamp.month,
        widget.scanTimestamp.day,
      );

  @override
  void dispose() {
    _placeController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String get _formattedScanTimestamp {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final t = widget.scanTimestamp;
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${months[t.month - 1]} ${t.day}, ${t.year}, $hour12:$minute $period';
  }

  String get _formattedPurchaseDate {
    final d = _purchaseDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  String get _formattedPurchaseTime =>
      _purchaseTime == null ? '' : _formatTimeOfDay(_purchaseTime!);

  Future<void> _pickStallLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => StallLocationPickerScreen(initialLocation: _pinnedLocation),
      ),
    );
    if (result == null) return;

    setState(() {
      _pinnedLocation = result;
      _resolvingAddress = true;
      _purchaseHouseNumber = null;
      _purchaseStreet = null;
      _purchaseBarangay = null;
      _purchaseCity = null;
      _purchaseProvince = null;
      _purchasePostalCode = null;
      _purchaseCountry = null;
    });

    final address = await LocationService.reverseGeocodeDetailed(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _resolvingAddress = false;
      if (address != null) {
        _addressController.text = address.displayName;
        _purchaseHouseNumber = address.houseNumber;
        _purchaseStreet = address.street;
        _purchaseBarangay = address.barangay;
        _purchaseCity = address.city;
        _purchaseProvince = address.province;
        _purchasePostalCode = address.postalCode;
        _purchaseCountry = address.country;
      }
    });
  }

  Future<void> _pickPurchaseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _purchaseTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryRed,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final submission = ReportSubmission(
      meatType: widget.meatType,
      scanReference: widget.scanReference,
      placeOfPurchase: _placeController.text.trim().toTitleCase(),
      address: _addressController.text.trim().toTitleCase(),
      purchaseDate: _purchaseDate,
      purchaseTime: _purchaseTime == null ? null : _formatTimeOfDay(_purchaseTime!),
      additionalDetails: _detailsController.text.trim().capitalizeFirst(),
      purchaseHouseNumber: _purchaseHouseNumber,
      purchaseStreet: _purchaseStreet,
      purchaseBarangay: _purchaseBarangay,
      purchaseCity: _purchaseCity,
      purchaseProvince: _purchaseProvince,
      purchasePostalCode: _purchasePostalCode,
      purchaseCountry: _purchaseCountry,
      purchaseLat: _pinnedLocation?.latitude,
      purchaseLng: _pinnedLocation?.longitude,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: widget.meatType,
          scanReference: widget.scanReference,
          scanTimestamp: widget.scanTimestamp,
          placeOfPurchase: submission.placeOfPurchase,
          locationAddress: submission.address,
          purchaseDate: submission.purchaseDate,
          purchaseTime: submission.purchaseTime,
          additionalDetails: submission.additionalDetails,
          isPreview: true,
          onConfirm: () => _confirmSubmit(context, submission),
        ),
      ),
    );
  }

  /// Applies an address picked from the [LocationAutocompleteField]
  /// dropdown, capturing the same breakdown/coordinates a map pin would
  /// have produced so [_resolveTypedAddress] doesn't need to re-geocode it.
  void _applySuggestedAddress(GeocodedAddress address) {
    setState(() {
      _purchaseHouseNumber = address.houseNumber;
      _purchaseStreet = address.street;
      _purchaseBarangay = address.barangay;
      _purchaseCity = address.city;
      _purchaseProvince = address.province;
      _purchasePostalCode = address.postalCode;
      _purchaseCountry = address.country;
      if (address.lat != null && address.lng != null) {
        _pinnedLocation = LatLng(address.lat!, address.lng!);
      }
    });
  }

  /// If the user typed the address instead of pinning it on the map,
  /// forward-geocode the typed text so it still gets split into house
  /// number/street/barangay/city/province/etc. Skipped when a pin was
  /// dropped, since those components already came from the reverse geocode
  /// of that pin.
  Future<void> _resolveTypedAddress() async {
    if (_pinnedLocation != null) return;
    final text = _addressController.text.trim();
    if (text.isEmpty) return;

    final address = await LocationService.forwardGeocodeDetailed(text);
    if (address == null) return;
    _purchaseHouseNumber = address.houseNumber;
    _purchaseStreet = address.street;
    _purchaseBarangay = address.barangay;
    _purchaseCity = address.city;
    _purchaseProvince = address.province;
    _purchasePostalCode = address.postalCode;
    _purchaseCountry = address.country;
  }

  Future<void> _confirmSubmit(BuildContext context, ReportSubmission submission) async {
    final isEn = SettingsService.isEnglish;
    final scanId = widget.scanId;
    if (scanId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Missing scan reference — this report cannot be submitted.' : 'Kulang ang scan reference — hindi maisusumite ang report na ito.')),
        );
      }
      return;
    }

    await _resolveTypedAddress();

    final ReportRecord record;
    try {
      record = await ReportService.submit(
        scanId: scanId,
        placeOfPurchase: submission.placeOfPurchase,
        purchaseDate: submission.purchaseDate,
        purchaseTime: submission.purchaseTime,
        additionalDetails: submission.additionalDetails,
        purchaseHouseNumber: _purchaseHouseNumber,
        purchaseStreet: _purchaseStreet,
        purchaseBarangay: _purchaseBarangay,
        purchaseCity: _purchaseCity,
        purchaseProvince: _purchaseProvince,
        purchasePostalCode: _purchasePostalCode,
        purchaseCountry: _purchaseCountry,
        purchaseLat: submission.purchaseLat,
        purchaseLng: submission.purchaseLng,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ReportServiceException ? e.message : (isEn ? "We couldn't submit your report. Please try again." : 'Hindi namin naisumite ang iyong report. Pakisubukang muli.'))),
        );
      }
      return;
    }
    if (!context.mounted) return;

    HistoryService.markFlagged(scanId);

    NotificationService.add(
      kind: NotificationKind.reportSubmitted,
      title: isEn ? 'Report submitted' : 'Naisumite ang Report',
      body: isEn
          ? 'Your ${submission.meatType} report was sent to NMIS for review.'
          : 'Ang iyong ${submission.meatType} report ay naipadala sa NMIS para sa review.',
      reportId: record.id,
    );

    if (widget.onSubmit != null) {
      widget.onSubmit!(submission);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: submission.meatType,
          scanReference: submission.scanReference,
          scanTimestamp: widget.scanTimestamp,
          placeOfPurchase: submission.placeOfPurchase,
          locationAddress: submission.address,
          purchaseDate: submission.purchaseDate,
          purchaseTime: submission.purchaseTime,
          additionalDetails: submission.additionalDetails,
          isPreview: false,
        ),
      ),
    );
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
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        AppTheme.screenHeader(context, isEn ? 'Report to NMIS' : 'I-report sa NMIS', titleFontSize: 18),
                        const SizedBox(height: 20),
                        ReportTheme.disclaimerBanner(
                          isEn
                              ? 'This flags your scan for review by a licensed NMIS meat inspector. '
                                  'Reporting is optional but recommended if this was recently purchased.'
                              : 'Ito ay nag-fla-flag ng iyong scan para suriin ng lisensyadong NMIS meat '
                                  'inspector. Opsyonal ang pag-report ngunit inirerekomenda kung kamakailan '
                                  'lang ito nabili.',
                        ),
                        const SizedBox(height: 24),
                        ReportTheme.fieldLabel(isEn ? 'MEAT TYPE' : 'URI NG KARNE'),
                        const SizedBox(height: 8),
                        ReportTheme.readOnlyField(value: widget.meatType, icon: Icons.set_meal_rounded),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'SCAN REFERENCE' : 'REFERENCE NG SCAN'),
                        const SizedBox(height: 8),
                        ReportTheme.readOnlyField(
                          value: '${widget.scanReference} · $_formattedScanTimestamp',
                          icon: Icons.qr_code_rounded,
                        ),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'STALL NAME / NUMBER' : 'PANGALAN/NUMERO NG PUWESTO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _placeController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn ? 'e.g. Stall 12' : 'hal. Puwesto 12',
                          ),
                        ),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'ADDRESS' : 'ADDRESS'),
                        const SizedBox(height: 8),
                        LocationAutocompleteField(
                          controller: _addressController,
                          hintText: isEn ? "e.g. Aurora Blvd, Quezon City" : 'hal. Aurora Blvd, Quezon City',
                          onSelected: _applySuggestedAddress,
                          onManualEdit: () => setState(() => _pinnedLocation = null),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return isEn ? 'Please enter the address' : 'Pakilagay ang address';
                            }
                            if (_pinnedLocation == null) {
                              return isEn
                                  ? 'Please select an address from the suggestions or pin it on the map'
                                  : 'Pumili ng address mula sa mga suhestiyon o markahan ito sa mapa';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStallPinButton(isEn),
                        NearbyReportBanner(lat: _pinnedLocation?.latitude, lng: _pinnedLocation?.longitude),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'WHEN DID YOU BUY IT?' : 'KAILAN MO ITO BINILI?'),
                        const SizedBox(height: 8),
                        ReportTheme.readOnlyField(
                          value: _formattedPurchaseDate,
                          icon: Icons.event_rounded,
                        ),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'WHAT TIME DID YOU BUY IT?' : 'ANONG ORAS MO ITO BINILI?'),
                        const SizedBox(height: 8),
                        _buildTimeField(),
                        const SizedBox(height: 20),
                        ReportTheme.fieldLabel(isEn ? 'ADDITIONAL DETAILS (OPTIONAL)' : 'KARAGDAGANG DETALYE (OPTIONAL)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _detailsController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [SentenceCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn ? 'Anything else the inspector should know' : 'Anumang iba pang dapat malaman ng inspector',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(context, isEn),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStallPinButton(bool isEn) {
    final pinned = _pinnedLocation;
    if (pinned == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickStallLocation,
          icon: Icon(Icons.add_location_alt_outlined, size: 18, color: AppTheme.primaryRed),
          label: Text(
            isEn ? 'Pin Stall Location on Map' : 'I-pin ang Lokasyon ng Puwesto',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryRed,
            side: BorderSide(color: AppTheme.primaryRed.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tintedCardDecoration(AppTheme.freshGreen, opacity: 0.08, radius: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppTheme.iconBadgeBg(AppTheme.freshGreen, radius: 10),
            child: Icon(Icons.location_on_rounded, size: 18, color: AppTheme.freshGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Stall location pinned' : 'Naka-pin ang lokasyon ng puwesto',
                  style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                if (_resolvingAddress)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: AppTheme.freshGreen),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEn ? 'Looking up address…' : 'Hinahanap ang address…',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                      ),
                    ],
                  )
                else
                  Text(
                    '${pinned.latitude.toStringAsFixed(5)}, ${pinned.longitude.toStringAsFixed(5)}',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: _pickStallLocation,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.edit_location_alt_outlined, size: 18, color: AppTheme.textMuted),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _pinnedLocation = null),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textFaint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _pickPurchaseTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: ReportTheme.inputFieldDecoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _purchaseTime == null ? '--:-- --' : _formattedPurchaseTime,
                style: TextStyle(
                  color: _purchaseTime == null ? AppTheme.textFaint : AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.access_time_rounded, size: 17, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          AppTheme.primaryButton(
            onPressed: _submit,
            child: Text(isEn ? 'Submit Report' : 'Isumite ang Report'),
          ),
          const SizedBox(height: 10),
          AppTheme.secondaryActionButton(
            label: isEn ? 'Cancel' : 'Kanselahin',
            onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class ReportSubmission {
  final String meatType;
  final String scanReference;
  final String placeOfPurchase;
  final String address;
  final DateTime? purchaseDate;
  final String? purchaseTime;
  final String additionalDetails;
  final String? purchaseHouseNumber;
  final String? purchaseStreet;
  final String? purchaseBarangay;
  final String? purchaseCity;
  final String? purchaseProvince;
  final String? purchasePostalCode;
  final String? purchaseCountry;
  final double? purchaseLat;
  final double? purchaseLng;

  const ReportSubmission({
    required this.meatType,
    required this.scanReference,
    required this.placeOfPurchase,
    required this.address,
    required this.purchaseDate,
    required this.purchaseTime,
    required this.additionalDetails,
    this.purchaseHouseNumber,
    this.purchaseStreet,
    this.purchaseBarangay,
    this.purchaseCity,
    this.purchaseProvince,
    this.purchasePostalCode,
    this.purchaseCountry,
    this.purchaseLat,
    this.purchaseLng,
  });
}