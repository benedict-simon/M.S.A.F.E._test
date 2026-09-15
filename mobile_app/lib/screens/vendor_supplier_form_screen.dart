import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/vendor_supplier_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import 'stall_location_picker_screen.dart';
import '../utils/text_formatters.dart';

class VendorSupplierFormScreen extends StatefulWidget {
  final VendorSupplier? supplier;

  const VendorSupplierFormScreen({super.key, this.supplier});

  @override
  State<VendorSupplierFormScreen> createState() => _VendorSupplierFormScreenState();
}

class _VendorSupplierFormScreenState extends State<VendorSupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _accreditationController = TextEditingController();
  bool _saving = false;

  LatLng? _pinnedLocation;
  bool _resolvingAddress = false;
  String? _houseNumber;
  String? _street;
  String? _barangay;
  String? _city;
  String? _province;
  String? _postalCode;
  String? _country;

  bool get _isEn => SettingsService.isEnglish;
  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _nameController.text = supplier?.supplierName ?? '';
    _contactController.text = supplier?.supplierContact ?? '';
    _addressController.text = supplier?.supplierAddress ?? '';
    _accreditationController.text = supplier?.supplierAccreditationNo ?? '';

    _houseNumber = supplier?.supplierHouseNumber;
    _street = supplier?.supplierStreet;
    _barangay = supplier?.supplierBarangay;
    _city = supplier?.supplierCity;
    _province = supplier?.supplierProvince;
    _postalCode = supplier?.supplierPostalCode;
    _country = supplier?.supplierCountry;
    if (supplier?.supplierLat != null && supplier?.supplierLng != null) {
      _pinnedLocation = LatLng(supplier!.supplierLat!, supplier.supplierLng!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _accreditationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => StallLocationPickerScreen(initialLocation: _pinnedLocation),
      ),
    );
    if (result == null) return;

    setState(() {
      _pinnedLocation = result;
      _resolvingAddress = true;
      _houseNumber = null;
      _street = null;
      _barangay = null;
      _city = null;
      _province = null;
      _postalCode = null;
      _country = null;
    });

    final address = await LocationService.reverseGeocodeDetailed(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _resolvingAddress = false;
      if (address != null) {
        _addressController.text = address.displayName;
        _houseNumber = address.houseNumber;
        _street = address.street;
        _barangay = address.barangay;
        _city = address.city;
        _province = address.province;
        _postalCode = address.postalCode;
        _country = address.country;
      }
    });
  }

  Future<void> _resolveTypedAddress() async {
    if (_pinnedLocation != null) return;
    final text = _addressController.text.trim();
    if (text.isEmpty) return;

    final address = await LocationService.forwardGeocodeDetailed(text);
    if (address == null) return;
    _houseNumber = address.houseNumber;
    _street = address.street;
    _barangay = address.barangay;
    _city = address.city;
    _province = address.province;
    _postalCode = address.postalCode;
    _country = address.country;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _resolveTypedAddress();
      final existing = widget.supplier;
      if (existing != null) {
        await VendorSupplierService.update(
          existing.id,
          supplierName: _nameController.text.trim(),
          supplierContact: _contactController.text.trim(),
          supplierAddress: _addressController.text.trim(),
          supplierHouseNumber: _houseNumber,
          supplierStreet: _street,
          supplierBarangay: _barangay,
          supplierCity: _city,
          supplierProvince: _province,
          supplierPostalCode: _postalCode,
          supplierCountry: _country,
          supplierLat: _pinnedLocation?.latitude,
          supplierLng: _pinnedLocation?.longitude,
          supplierAccreditationNo: _accreditationController.text.trim(),
        );
      } else {
        await VendorSupplierService.add(
          supplierName: _nameController.text.trim(),
          supplierContact: _contactController.text.trim(),
          supplierAddress: _addressController.text.trim(),
          supplierHouseNumber: _houseNumber,
          supplierStreet: _street,
          supplierBarangay: _barangay,
          supplierCity: _city,
          supplierProvince: _province,
          supplierPostalCode: _postalCode,
          supplierCountry: _country,
          supplierLat: _pinnedLocation?.latitude,
          supplierLng: _pinnedLocation?.longitude,
          supplierAccreditationNo: _accreditationController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is VendorSupplierServiceException
                ? e.message
                : (_isEn
                    ? "We couldn't save that supplier. Please try again."
                    : 'Hindi namin nai-save ang supplier. Pakisubukang muli.'),
          ),
        ),
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
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        AppTheme.screenHeader(
                          context,
                          _isEditing
                              ? (isEn ? 'Edit Supplier' : 'I-edit ang Supplier')
                              : (isEn ? 'Add Supplier' : 'Magdagdag ng Supplier'),
                          titleFontSize: 18,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER NAME' : 'PANGALAN NG SUPPLIER'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
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
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER CONTACT NUMBER (OPTIONAL)' : 'CONTACT NUMBER NG SUPPLIER (OPTIONAL)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: isEn ? 'e.g. 09XX XXX XXXX' : 'hal. 09XX XXX XXXX',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'SUPPLIER ADDRESS (OPTIONAL)' : 'ADDRESS NG SUPPLIER (OPTIONAL)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. 123 Del Pan St, Divisoria, Manila'
                                : 'hal. 123 Del Pan St, Divisoria, Maynila',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPinButton(isEn),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'SUPPLIER ACCREDITATION / PERMIT NO. (OPTIONAL)'
                              : 'ACCREDITATION / PERMIT NO. NG SUPPLIER (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _accreditationController,
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. NMIS accreditation or LGU permit number'
                                : 'hal. numero ng NMIS accreditation o LGU permit',
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

  Widget _buildPinButton(bool isEn) {
    final pinned = _pinnedLocation;
    if (pinned == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickLocation,
          icon: Icon(Icons.add_location_alt_outlined, size: 18, color: AppTheme.vendorBlue),
          label: Text(
            isEn ? 'Pin Supplier Location on Map' : 'I-pin ang Lokasyon ng Supplier',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.vendorBlue,
            side: BorderSide(color: AppTheme.vendorBlue.withValues(alpha: 0.4)),
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
            onTap: _pickLocation,
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

  Widget _buildBottomActions(bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          AppTheme.primaryButton(
            color: AppTheme.vendorBlue,
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Text(isEn ? 'Save Supplier' : 'I-save ang Supplier'),
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
