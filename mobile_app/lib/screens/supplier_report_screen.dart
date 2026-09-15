import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/supplier_report_service.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../services/location_service.dart';
import '../services/vendor_supplier_service.dart';
import '../services/settings_service.dart';
import '../utils/string_utils.dart';
import '../utils/text_formatters.dart';
import '../widgets/location_autocomplete_field.dart';
import 'receipt_screen.dart';
import 'stall_location_picker_screen.dart';

class SupplierReportScreen extends StatefulWidget {
  final String meatType;
  final String scanReference;
  final String scanId;
  final DateTime scanTimestamp;

  const SupplierReportScreen({
    super.key,
    required this.meatType,
    required this.scanReference,
    required this.scanId,
    required this.scanTimestamp,
  });

  @override
  State<SupplierReportScreen> createState() => _SupplierReportScreenState();
}

class _SupplierReportScreenState extends State<SupplierReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _supplierLocationController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();
  LatLng? _pinnedLocation;
  bool _resolvingAddress = false;
  String? _supplierHouseNumber;
  String? _supplierStreet;
  String? _supplierBarangay;
  String? _supplierCity;
  String? _supplierProvince;
  String? _supplierPostalCode;
  String? _supplierCountry;
  String? _selectedSavedSupplierId;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    VendorSupplierService.fetchAll();
  }

  void _applySavedSupplier(VendorSupplier? supplier) {
    setState(() {
      _selectedSavedSupplierId = supplier?.id;
      if (supplier == null) return;

      _supplierNameController.text = supplier.supplierName;
      _contactController.text = supplier.supplierContact ?? '';
      _supplierLocationController.text = supplier.supplierAddress ?? '';
      _supplierHouseNumber = supplier.supplierHouseNumber;
      _supplierStreet = supplier.supplierStreet;
      _supplierBarangay = supplier.supplierBarangay;
      _supplierCity = supplier.supplierCity;
      _supplierProvince = supplier.supplierProvince;
      _supplierPostalCode = supplier.supplierPostalCode;
      _supplierCountry = supplier.supplierCountry;
      _pinnedLocation = (supplier.supplierLat != null && supplier.supplierLng != null)
          ? LatLng(supplier.supplierLat!, supplier.supplierLng!)
          : null;
    });
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _contactController.dispose();
    _supplierLocationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickSupplierLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => StallLocationPickerScreen(initialLocation: _pinnedLocation),
      ),
    );
    if (result == null) return;

    setState(() {
      _pinnedLocation = result;
      _resolvingAddress = true;
      _supplierHouseNumber = null;
      _supplierStreet = null;
      _supplierBarangay = null;
      _supplierCity = null;
      _supplierProvince = null;
      _supplierPostalCode = null;
      _supplierCountry = null;
    });

    final address = await LocationService.reverseGeocodeDetailed(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _resolvingAddress = false;
      if (address != null) {
        _supplierLocationController.text = address.displayName;
        _supplierHouseNumber = address.houseNumber;
        _supplierStreet = address.street;
        _supplierBarangay = address.barangay;
        _supplierCity = address.city;
        _supplierProvince = address.province;
        _supplierPostalCode = address.postalCode;
        _supplierCountry = address.country;
      }
    });
  }

  /// Applies a location picked from the [LocationAutocompleteField]
  /// dropdown, capturing the same breakdown/coordinates a map pin would
  /// have produced so [_resolveTypedSupplierLocation] doesn't need to
  /// re-geocode it.
  void _applySuggestedSupplierLocation(GeocodedAddress address) {
    setState(() {
      _supplierHouseNumber = address.houseNumber;
      _supplierStreet = address.street;
      _supplierBarangay = address.barangay;
      _supplierCity = address.city;
      _supplierProvince = address.province;
      _supplierPostalCode = address.postalCode;
      _supplierCountry = address.country;
      if (address.lat != null && address.lng != null) {
        _pinnedLocation = LatLng(address.lat!, address.lng!);
      }
    });
  }

  String get _formattedScanTimestamp {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final t = widget.scanTimestamp;
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${months[t.month - 1]} ${t.day}, ${t.year}, $hour12:$minute $period';
  }

  String get _formattedDeliveryDate =>
      '${_deliveryDate.day.toString().padLeft(2, '0')}/${_deliveryDate.month.toString().padLeft(2, '0')}/${_deliveryDate.year}';

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.vendorBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEn = _isEn;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: widget.meatType,
          scanReference: widget.scanReference,
          scanTimestamp: widget.scanTimestamp,
          placeOfPurchase: _supplierNameController.text.trim().toTitleCase(),
          locationAddress: _supplierLocationController.text.trim().toTitleCase(),
          purchaseDate: _deliveryDate,
          additionalDetails: _detailsController.text.trim().capitalizeFirst(),
          locationLabel: isEn ? 'SUPPLIER' : 'SUPPLIER',
          dateLabel: isEn ? 'DELIVERY DATE' : 'PETSA NG DELIVERY',
          showTime: false,
          isPreview: true,
          onConfirm: () => _confirmSubmit(context),
        ),
      ),
    );
  }

  Future<void> _resolveTypedSupplierLocation() async {
    if (_pinnedLocation != null) return;
    final text = _supplierLocationController.text.trim();
    if (text.isEmpty) return;

    final address = await LocationService.forwardGeocodeDetailed(text);
    if (address == null) return;
    _supplierHouseNumber = address.houseNumber;
    _supplierStreet = address.street;
    _supplierBarangay = address.barangay;
    _supplierCity = address.city;
    _supplierProvince = address.province;
    _supplierPostalCode = address.postalCode;
    _supplierCountry = address.country;
  }

  Future<void> _confirmSubmit(BuildContext context) async {
    final isEn = SettingsService.isEnglish;

    await _resolveTypedSupplierLocation();

    final SupplierReport record;
    try {
      record = await SupplierReportService.submit(
        scanId: widget.scanId,
        supplierName: _supplierNameController.text.trim().toTitleCase(),
        supplierContact: _contactController.text.trim(),
        deliveryDate: _deliveryDate,
        additionalDetails: _detailsController.text.trim().capitalizeFirst(),
        supplierLocation: _supplierLocationController.text.trim().toTitleCase(),
        supplierHouseNumber: _supplierHouseNumber,
        supplierStreet: _supplierStreet,
        supplierBarangay: _supplierBarangay,
        supplierCity: _supplierCity,
        supplierProvince: _supplierProvince,
        supplierPostalCode: _supplierPostalCode,
        supplierCountry: _supplierCountry,
        supplierLat: _pinnedLocation?.latitude,
        supplierLng: _pinnedLocation?.longitude,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is SupplierReportServiceException
                ? e.message
                : (isEn ? "We couldn't submit your report. Please try again." : 'Hindi namin naisumite ang iyong report. Pakisubukang muli.')),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;

    HistoryService.markFlagged(widget.scanId);

    NotificationService.add(
      kind: NotificationKind.supplierReport,
      title: isEn ? 'Supplier report submitted' : 'Naisumite ang Supplier Report',
      body: isEn
          ? 'Your ${widget.meatType} supplier report was sent to NMIS for review.'
          : 'Ang iyong ${widget.meatType} supplier report ay naipadala sa NMIS para sa review.',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(
          meatType: widget.meatType,
          scanReference: widget.scanReference,
          scanTimestamp: widget.scanTimestamp,
          placeOfPurchase: record.supplierName,
          locationAddress: record.supplierLocation,
          purchaseDate: record.deliveryDate,
          additionalDetails: record.additionalDetails,
          locationLabel: isEn ? 'SUPPLIER' : 'SUPPLIER',
          dateLabel: isEn ? 'DELIVERY DATE' : 'PETSA NG DELIVERY',
          showTime: false,
          isPreview: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.language, SettingsService.darkMode, VendorSupplierService.suppliers]),
      builder: (context, _) {
        final isEn = SettingsService.isEnglish;
        final savedSuppliers = VendorSupplierService.suppliers.value;
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
                        AppTheme.screenHeader(context, isEn ? 'Report Supplier' : 'I-report ang Supplier', titleFontSize: 18),
                        const SizedBox(height: 20),
                        AppTheme.tintedInfoBox(
                          icon: Icons.local_shipping_rounded,
                          color: AppTheme.vendorBlue,
                          text: isEn
                              ? 'This flags your scan for review by a licensed NMIS meat inspector, '
                                  'pointing at the supplier this stock came from rather than a buyer.'
                              : 'Ito ay nag-fla-flag ng iyong scan para suriin ng lisensyadong NMIS meat '
                                  'inspector, na tumuturo sa supplier na pinagmulan ng stock na ito.',
                        ),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(isEn ? 'MEAT TYPE' : 'URI NG KARNE'),
                        const SizedBox(height: 8),
                        AppTheme.readOnlyField(value: widget.meatType, icon: Icons.set_meal_rounded),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SCAN REFERENCE' : 'REFERENCE NG SCAN'),
                        const SizedBox(height: 8),
                        AppTheme.readOnlyField(
                          value: '${widget.scanReference} · $_formattedScanTimestamp',
                          icon: Icons.qr_code_rounded,
                        ),
                        if (savedSuppliers.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          AppTheme.fieldLabel(isEn ? 'CHOOSE FROM SAVED SUPPLIERS (OPTIONAL)' : 'PUMILI SA NASAVE NA SUPPLIER (OPTIONAL)'),
                          const SizedBox(height: 8),
                          _buildSavedSupplierDropdown(isEn, savedSuppliers),
                        ],
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER NAME' : 'PANGALAN NG SUPPLIER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _supplierNameController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn ? "e.g. Del Rosario Meat Supply" : 'hal. Del Rosario Meat Supply',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isEn ? 'Please enter the supplier name.' : 'Pakilagay ang pangalan ng supplier.')
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER CONTACT NUMBER' : 'CONTACT NUMBER NG SUPPLIER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: isEn ? 'e.g. 09XX XXX XXXX' : 'hal. 09XX XXX XXXX',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isEn ? 'Please enter a contact number.' : 'Pakilagay ang contact number.')
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER LOCATION (OPTIONAL)' : 'LOKASYON NG SUPPLIER (OPTIONAL)'),
                        const SizedBox(height: 8),
                        LocationAutocompleteField(
                          controller: _supplierLocationController,
                          hintText: isEn ? "e.g. Aurora Blvd, Quezon City" : 'hal. Aurora Blvd, Quezon City',
                          onSelected: _applySuggestedSupplierLocation,
                          onManualEdit: () => setState(() => _pinnedLocation = null),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null;
                            if (_pinnedLocation == null) {
                              return isEn
                                  ? 'Please select a location from the suggestions or pin it on the map'
                                  : 'Pumili ng lokasyon mula sa mga suhestiyon o markahan ito sa mapa';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSupplierPinButton(isEn),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'DELIVERY DATE' : 'PETSA NG DELIVERY'),
                        const SizedBox(height: 8),
                        _buildDeliveryDateField(),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'ADDITIONAL DETAILS (OPTIONAL)' : 'KARAGDAGANG DETALYE (OPTIONAL)'),
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
                _buildBottomActions(isEn),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedSupplierDropdown(bool isEn, List<VendorSupplier> savedSuppliers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: AppTheme.outlinedCard(radius: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedSavedSupplierId,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600),
          hint: Text(
            isEn ? 'Type manually' : 'Mano-manong i-type',
            style: TextStyle(color: AppTheme.textFaint, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(isEn ? 'Type manually' : 'Mano-manong i-type'),
            ),
            for (final supplier in savedSuppliers)
              DropdownMenuItem<String?>(
                value: supplier.id,
                child: Text(supplier.supplierName, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (id) => _applySavedSupplier(
            id == null ? null : savedSuppliers.firstWhere((s) => s.id == id),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierPinButton(bool isEn) {
    final pinned = _pinnedLocation;
    if (pinned == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickSupplierLocation,
          icon: Icon(Icons.add_location_alt_outlined, size: 18, color: AppTheme.vendorBlue),
          label: Text(
            isEn ? 'Pin Supplier Location on Map' : 'I-pin ang Lokasyon ng Supplier',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.vendorBlue,
            side: BorderSide(color: AppTheme.vendorBlue.withOpacity(0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tintedCardDecoration(AppTheme.vendorBlue, opacity: 0.08, radius: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppTheme.iconBadgeBg(AppTheme.vendorBlue, radius: 10),
            child: Icon(Icons.location_on_rounded, size: 18, color: AppTheme.vendorBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Supplier location pinned' : 'Naka-pin ang lokasyon ng supplier',
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
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: AppTheme.vendorBlue),
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
            onTap: _pickSupplierLocation,
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

  Widget _buildDeliveryDateField() {
    return InkWell(
      onTap: _pickDeliveryDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: AppTheme.inputFieldDecoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formattedDeliveryDate,
                style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.event_rounded, size: 17, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          AppTheme.primaryButton(
            color: AppTheme.vendorBlue,
            onPressed: _submit,
            child: Text(isEn ? 'Submit Report' : 'Isumite ang Report'),
          ),
          const SizedBox(height: 10),
          AppTheme.secondaryActionButton(
            label: isEn ? 'Cancel' : 'Kanselahin',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
