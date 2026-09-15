import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/vendor_service.dart';
import '../services/settings_service.dart';
import '../services/location_service.dart';
import 'stall_location_picker_screen.dart';
import '../utils/text_formatters.dart';
import '../widgets/location_autocomplete_field.dart';

class VendorApplicationScreen extends StatefulWidget {
  const VendorApplicationScreen({super.key});

  @override
  State<VendorApplicationScreen> createState() => _VendorApplicationScreenState();
}

class _VendorApplicationScreenState extends State<VendorApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _stallLocationController = TextEditingController();
  final _picker = ImagePicker();
  LatLng? _pinnedLocation;
  bool _resolvingAddress = false;
  String? _stallHouseNumber;
  String? _stallStreet;
  String? _stallBarangay;
  String? _stallCity;
  String? _stallProvince;
  String? _stallPostalCode;
  String? _stallCountry;
  XFile? _validId;
  XFile? _vendorPermit;
  bool _submitting = false;
  bool _documentsTouched = false;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactController.dispose();
    _stallLocationController.dispose();
    super.dispose();
  }

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
      _stallHouseNumber = null;
      _stallStreet = null;
      _stallBarangay = null;
      _stallCity = null;
      _stallProvince = null;
      _stallPostalCode = null;
      _stallCountry = null;
    });

    final address = await LocationService.reverseGeocodeDetailed(result.latitude, result.longitude);
    if (!mounted) return;
    setState(() {
      _resolvingAddress = false;
      if (address != null) {
        _stallLocationController.text = address.displayName;
        _stallHouseNumber = address.houseNumber;
        _stallStreet = address.street;
        _stallBarangay = address.barangay;
        _stallCity = address.city;
        _stallProvince = address.province;
        _stallPostalCode = address.postalCode;
        _stallCountry = address.country;
      }
    });
  }

  void _applySuggestedStallLocation(GeocodedAddress address) {
    setState(() {
      _stallHouseNumber = address.houseNumber;
      _stallStreet = address.street;
      _stallBarangay = address.barangay;
      _stallCity = address.city;
      _stallProvince = address.province;
      _stallPostalCode = address.postalCode;
      _stallCountry = address.country;
      if (address.lat != null && address.lng != null) {
        _pinnedLocation = LatLng(address.lat!, address.lng!);
      }
    });
  }

  Future<void> _pickDocument(bool isValidId) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      if (!mounted) return;
      setState(() => isValidId ? _validId = file : _vendorPermit = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEn ? 'Could not add that file: $e' : 'Hindi maidagdag ang file na iyon: $e')),
      );
    }
  }

  Future<void> _resolveTypedStallLocation() async {
    if (_pinnedLocation != null) return;
    final text = _stallLocationController.text.trim();
    if (text.isEmpty) return;

    final address = await LocationService.forwardGeocodeDetailed(text);
    if (address == null) return;
    _stallHouseNumber = address.houseNumber;
    _stallStreet = address.street;
    _stallBarangay = address.barangay;
    _stallCity = address.city;
    _stallProvince = address.province;
    _stallPostalCode = address.postalCode;
    _stallCountry = address.country;
  }

  Future<void> _submit() async {
    setState(() => _documentsTouched = true);
    final formOk = _formKey.currentState!.validate();
    final validId = _validId;
    final vendorPermit = _vendorPermit;
    if (!formOk || validId == null || vendorPermit == null) return;

    setState(() => _submitting = true);
    try {
      await _resolveTypedStallLocation();
      await VendorService.submit(
        businessName: _businessNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        validIdFile: validId,
        vendorPermitFile: vendorPermit,
        stallLocation: _stallLocationController.text.trim(),
        stallHouseNumber: _stallHouseNumber,
        stallStreet: _stallStreet,
        stallBarangay: _stallBarangay,
        stallCity: _stallCity,
        stallProvince: _stallProvince,
        stallPostalCode: _stallPostalCode,
        stallCountry: _stallCountry,
        stallLat: _pinnedLocation?.latitude,
        stallLng: _pinnedLocation?.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Vendor application submitted. We\'ll notify you once it\'s reviewed.'
                : 'Naisumite ang vendor application. Aabisuhan ka namin pagkatapos itong ma-review.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is VendorServiceException
                ? e.message
                : (_isEn
                    ? "We couldn't submit your application. Please try again."
                    : 'Hindi namin naisumite ang iyong application. Pakisubukang muli.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                          isEn ? 'Apply for Vendor Account' : 'Mag-apply bilang Vendor',
                          titleFontSize: 18,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.tintedInfoBox(
                          icon: Icons.storefront_rounded,
                          color: AppTheme.vendorBlue,
                          text: isEn
                              ? 'Vendor accounts let you list your stall and report spoiled meat from '
                                  'your suppliers. Submit your details below — our admin team will '
                                  'review and approve your application.'
                              : 'Ang vendor account ay nagpapahintulot sa iyong i-list ang iyong puwesto '
                                  'at mag-report ng sirang karne mula sa iyong supplier. Isumite ang '
                                  'iyong detalye sa ibaba.',
                        ),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(isEn ? 'BUSINESS / STALL NAME' : 'PANGALAN NG NEGOSYO/PUWESTO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _businessNameController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn ? "e.g. Aling Nena's Meat Shop" : 'hal. Meat Shop ni Aling Nena',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isEn ? 'Please enter your business or stall name.' : 'Pakilagay ang pangalan ng iyong negosyo o puwesto.')
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(isEn ? 'CONTACT NUMBER' : 'CONTACT NUMBER'),
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
                        AppTheme.fieldLabel(isEn ? 'STALL LOCATION (OPTIONAL)' : 'LOKASYON NG PUWESTO (OPTIONAL)'),
                        const SizedBox(height: 8),
                        LocationAutocompleteField(
                          controller: _stallLocationController,
                          hintText: isEn
                              ? "e.g. Farmer's Market, Stall 12"
                              : 'hal. Palengke, Puwesto 12',
                          onSelected: _applySuggestedStallLocation,
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
                        _buildStallPinButton(isEn),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(isEn ? 'DOCUMENTS' : 'MGA DOKUMENTO'),
                        const SizedBox(height: 8),
                        Text(
                          isEn
                              ? 'Upload a clear photo of each document. Only NMIS admin reviewers can view these.'
                              : 'Mag-upload ng malinaw na larawan ng bawat dokumento. Tanging ang NMIS admin reviewer lang ang makakakita nito.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        _buildDocumentPicker(
                          isEn: isEn,
                          label: isEn ? 'Valid Government ID' : 'Valid na Government ID',
                          hint: isEn ? "e.g. UMID, driver's license, passport" : 'hal. UMID, driver\'s license, passport',
                          file: _validId,
                          onPick: () => _pickDocument(true),
                          onRemove: () => setState(() => _validId = null),
                        ),
                        const SizedBox(height: 12),
                        _buildDocumentPicker(
                          isEn: isEn,
                          label: isEn ? "Market Vendor's Permit" : 'Market Vendor\'s Permit',
                          hint: isEn
                              ? 'Or a Certificate of Stall Occupancy from your market admin'
                              : 'O Certificate of Stall Occupancy mula sa market admin',
                          file: _vendorPermit,
                          onPick: () => _pickDocument(false),
                          onRemove: () => setState(() => _vendorPermit = null),
                        ),
                        if (_documentsTouched && (_validId == null || _vendorPermit == null)) ...[
                          const SizedBox(height: 8),
                          Text(
                            isEn ? 'Both documents are required.' : 'Kailangan ang parehong dokumento.',
                            style: TextStyle(color: AppTheme.spoiledRed, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
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

  Widget _buildDocumentPicker({
    required bool isEn,
    required String label,
    required String hint,
    required XFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    if (file == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.iconBadgeBg(AppTheme.vendorBlue, radius: 10),
                child: Icon(Icons.add_photo_alternate_outlined, size: 19, color: AppTheme.vendorBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(hint, style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
            ],
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(width: 44, height: 44, color: AppTheme.borderColor.withValues(alpha: 0.3));
                }
                return Image.memory(snapshot.data!, width: 44, height: 44, fit: BoxFit.cover);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  isEn ? 'Uploaded' : 'Na-upload na',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
            ),
          ),
          InkWell(
            onTap: onRemove,
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

  Widget _buildStallPinButton(bool isEn) {
    final pinned = _pinnedLocation;
    if (pinned == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickStallLocation,
          icon: Icon(Icons.add_location_alt_outlined, size: 18, color: AppTheme.vendorBlue),
          label: Text(
            isEn ? 'Pin Stall Location on Map' : 'I-pin ang Lokasyon ng Puwesto',
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

  Widget _buildBottomActions(bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          AppTheme.primaryButton(
            color: AppTheme.vendorBlue,
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : Text(isEn ? 'Submit Application' : 'Isumite ang Application'),
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
