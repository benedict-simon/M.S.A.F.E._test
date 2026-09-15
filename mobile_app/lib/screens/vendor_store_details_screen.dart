import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/meat_type.dart';
import '../theme/app_theme.dart';
import '../services/vendor_service.dart';
import '../services/meat_type_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../widgets/nearby_report_banner.dart';
import 'stall_location_picker_screen.dart';
import '../utils/text_formatters.dart';

class VendorStoreDetailsScreen extends StatefulWidget {
  const VendorStoreDetailsScreen({super.key});

  @override
  State<VendorStoreDetailsScreen> createState() =>
      _VendorStoreDetailsScreenState();
}

class _VendorStoreDetailsScreenState extends State<VendorStoreDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _stallNumberController = TextEditingController();
  final _stallLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();

  LatLng? _pinnedLocation;
  bool _resolvingAddress = false;
  String? _stallHouseNumber;
  String? _stallStreet;
  String? _stallBarangay;
  String? _stallCity;
  String? _stallProvince;
  String? _stallPostalCode;
  String? _stallCountry;

  final Set<String> _selectedCategories = {};
  List<MeatType> _meatTypes = [];
  bool _loadingMeatTypes = true;
  bool _saving = false;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    final application = VendorService.currentApplication.value;
    _businessNameController.text = application?.businessName ?? '';
    _contactController.text = application?.contactNumber ?? '';
    _stallNumberController.text = application?.stallNumber ?? '';
    _stallLocationController.text = application?.stallLocation ?? '';
    _descriptionController.text = application?.storeDescription ?? '';
    _hoursController.text = application?.storeHours ?? '';
    _selectedCategories.addAll(application?.storeCategories ?? const []);

    _stallHouseNumber = application?.stallHouseNumber;
    _stallStreet = application?.stallStreet;
    _stallBarangay = application?.stallBarangay;
    _stallCity = application?.stallCity;
    _stallProvince = application?.stallProvince;
    _stallPostalCode = application?.stallPostalCode;
    _stallCountry = application?.stallCountry;
    if (application?.stallLat != null && application?.stallLng != null) {
      _pinnedLocation = LatLng(application!.stallLat!, application.stallLng!);
    }

    _loadMeatTypes();
  }

  Future<void> _loadMeatTypes() async {
    try {
      final types = await MeatTypeService.fetchAll();
      if (!mounted) return;
      setState(() {
        _meatTypes = types;
        _loadingMeatTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMeatTypes = false);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactController.dispose();
    _stallNumberController.dispose();
    _stallLocationController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickStallLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            StallLocationPickerScreen(initialLocation: _pinnedLocation),
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

    final address = await LocationService.reverseGeocodeDetailed(
      result.latitude,
      result.longitude,
    );
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _resolveTypedStallLocation();
      await VendorService.updateStoreDetails(
        businessName: _businessNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        stallNumber: _stallNumberController.text.trim(),
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
        storeDescription: _descriptionController.text.trim(),
        storeHours: _hoursController.text.trim(),
        storeCategories: _selectedCategories.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Store details saved.'
                : 'Nai-save ang detalye ng tindahan.',
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
                      ? "We couldn't save your store details. Please try again."
                      : 'Hindi namin nai-save ang detalye ng iyong tindahan. Pakisubukang muli.'),
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
      listenable: Listenable.merge([
        SettingsService.language,
        SettingsService.darkMode,
      ]),
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
                          isEn ? 'Store Details' : 'Detalye ng Tindahan',
                          titleFontSize: 18,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.tintedInfoBox(
                          icon: Icons.storefront_rounded,
                          color: AppTheme.vendorBlue,
                          text: isEn
                              ? 'Describe your own stall so buyers and NMIS know what you sell and when '
                                    "you're open."
                              : 'Ilarawan ang iyong sariling puwesto para malaman ng mga bumibili at NMIS '
                                    'kung ano ang binebenta mo at kung kailan ka bukas.',
                        ),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(
                          isEn ? 'STORE NAME' : 'PANGALAN NG TINDAHAN',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _businessNameController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn
                                ? "e.g. Aling Nena's Meat Shop"
                                : 'hal. Meat Shop ni Aling Nena',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isEn
                                    ? 'Please enter your store name.'
                                    : 'Pakilagay ang pangalan ng iyong tindahan.')
                              : null,
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'STORE CONTACT NUMBER'
                              : 'CONTACT NUMBER NG TINDAHAN',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. 09XX XXX XXXX'
                                : 'hal. 09XX XXX XXXX',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'STALL NUMBER (OPTIONAL)'
                              : 'NUMERO NG PUWESTO (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stallNumberController,
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. Stall 45'
                                : 'hal. Puwesto 45',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'STALL LOCATION (OPTIONAL)'
                              : 'LOKASYON NG PUWESTO (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stallLocationController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [TitleCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn
                                ? "e.g. Farmer's Market, Stall 12"
                                : 'hal. Palengke, Puwesto 12',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStallPinButton(isEn),
                        NearbyReportBanner(lat: _pinnedLocation?.latitude, lng: _pinnedLocation?.longitude),
                        const SizedBox(height: 24),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'STORE DESCRIPTION (OPTIONAL)'
                              : 'DESKRIPSYON NG TINDAHAN (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [SentenceCaseTextFormatter()],
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. Family-run stall selling fresh chicken and pork since 2015'
                                : 'hal. Family-run na puwesto na nagbebenta ng sariwang manok at baboy simula 2015',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'OPERATING HOURS (OPTIONAL)'
                              : 'ORAS NG PAGBUKAS (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hoursController,
                          decoration: InputDecoration(
                            hintText: isEn
                                ? 'e.g. 6:00 AM - 6:00 PM, Mon-Sat'
                                : 'hal. 6:00 AM - 6:00 PM, Lun-Sab',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTheme.fieldLabel(
                          isEn
                              ? 'MEAT CATEGORIES SOLD (OPTIONAL)'
                              : 'URI NG KARNENG BINEBENTA (OPTIONAL)',
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryChips(isEn),
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

  Widget _buildStallPinButton(bool isEn) {
    final pinned = _pinnedLocation;
    if (pinned == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickStallLocation,
          icon: Icon(
            Icons.add_location_alt_outlined,
            size: 18,
            color: AppTheme.vendorBlue,
          ),
          label: Text(
            isEn
                ? 'Pin Stall Location on Map'
                : 'I-pin ang Lokasyon ng Puwesto',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.vendorBlue,
            side: BorderSide(color: AppTheme.vendorBlue.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tintedCardDecoration(
        AppTheme.vendorBlue,
        opacity: 0.08,
        radius: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppTheme.iconBadgeBg(AppTheme.vendorBlue, radius: 10),
            child: Icon(
              Icons.location_on_rounded,
              size: 18,
              color: AppTheme.vendorBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Stall location pinned'
                      : 'Naka-pin ang lokasyon ng puwesto',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                if (_resolvingAddress)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: AppTheme.vendorBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEn ? 'Looking up address…' : 'Hinahanap ang address…',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
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
              child: Icon(
                Icons.edit_location_alt_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _pinnedLocation = null),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isEn) {
    if (_loadingMeatTypes) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_meatTypes.isEmpty) {
      return Text(
        isEn
            ? "Couldn't load meat categories right now."
            : 'Hindi mai-load ang mga uri ng karne ngayon.',
        style: TextStyle(color: AppTheme.textFaint, fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in _meatTypes)
          AppTheme.filterChip(
            label: type.label,
            selected: _selectedCategories.contains(type.name),
            onTap: () => setState(() {
              if (_selectedCategories.contains(type.name)) {
                _selectedCategories.remove(type.name);
              } else {
                _selectedCategories.add(type.name);
              }
            }),
          ),
      ],
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEn ? 'Save Changes' : 'I-save ang mga Pagbabago'),
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
