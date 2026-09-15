import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/meat_type_service.dart';
import '../services/settings_service.dart';
import '../services/vendor_directory_service.dart';
import '../models/meat_type.dart';

class VendorDirectoryScreen extends StatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  State<VendorDirectoryScreen> createState() => _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends State<VendorDirectoryScreen> {
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<VendorDirectoryEntry> _vendors = [];
  List<MeatType> _meatTypes = [];
  final Set<String> _selectedCategories = {};

  bool _sortingNearest = false;
  Position? _devicePosition;
  String? _locationError;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    _load();
    MeatTypeService.fetchAll().then((types) {
      if (mounted) setState(() => _meatTypes = types);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vendors = await VendorDirectoryService.fetchAll();
      if (mounted) setState(() => _vendors = vendors);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is VendorDirectoryServiceException
            ? e.message
            : (_isEn ? "We couldn't load the vendor directory." : 'Hindi na-load ang vendor directory.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSortByNearest() async {
    if (_sortingNearest) {
      setState(() {
        _sortingNearest = false;
        _devicePosition = null;
      });
      return;
    }

    setState(() {
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationUnavailable('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw const _LocationUnavailable('Location permission was denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _devicePosition = position;
        _sortingNearest = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = _isEn
            ? "Couldn't get your location. Check your device's location settings."
            : 'Hindi nakuha ang iyong lokasyon. Suriin ang location settings ng iyong device.';
      });
    }
  }

  double _distanceKm(double lat, double lng) {
    final position = _devicePosition!;
    return Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng) / 1000;
  }

  List<VendorDirectoryEntry> get _filtered {
    var list = _vendors;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((v) => v.businessName.toLowerCase().contains(query)).toList();
    }

    if (_selectedCategories.isNotEmpty) {
      list = list.where((v) => v.storeCategories.any(_selectedCategories.contains)).toList();
    }

    if (_sortingNearest && _devicePosition != null) {
      list = [...list];
      list.sort((a, b) {
        final da = (a.stallLat != null && a.stallLng != null) ? _distanceKm(a.stallLat!, a.stallLng!) : double.infinity;
        final db = (b.stallLat != null && b.stallLng != null) ? _distanceKm(b.stallLat!, b.stallLng!) : double.infinity;
        return da.compareTo(db);
      });
    }

    return list;
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppTheme.screenHeader(context, isEn ? 'Vendor Directory' : 'Direktoryo ng Vendor', titleFontSize: 18),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: isEn ? 'Search by store name' : 'Maghanap ayon sa pangalan ng tindahan',
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _toggleSortByNearest,
                            icon: Icon(
                              _sortingNearest ? Icons.near_me_rounded : Icons.near_me_outlined,
                              size: 16,
                              color: _sortingNearest ? Colors.white : AppTheme.roleAccent,
                            ),
                            label: Text(isEn ? 'Sort by Nearest' : 'Ayusin sa Pinakamalapit'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _sortingNearest ? AppTheme.roleAccent : null,
                              foregroundColor: _sortingNearest ? Colors.white : AppTheme.roleAccent,
                              side: BorderSide(color: AppTheme.roleAccent.withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ]),
                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Text(_locationError!, style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                      ],
                      if (_meatTypes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
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
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildContent(isEn)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isEn) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, color: AppTheme.textFaint, size: 34),
            const SizedBox(height: 10),
            Text(_error!, style: AppTheme.emptySubtitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 16), label: Text(isEn ? 'Try Again' : 'Subukan Muli')),
          ]),
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return AppTheme.emptyState(
        icon: Icons.storefront_outlined,
        title: isEn ? 'No vendors found' : 'Walang Nahanap na Vendor',
        subtitle: isEn ? 'Try a different search or filter.' : 'Subukan ang ibang paghahanap o filter.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final vendor = list[i];
        double? distanceKm;
        if (_sortingNearest && _devicePosition != null && vendor.stallLat != null && vendor.stallLng != null) {
          distanceKm = _distanceKm(vendor.stallLat!, vendor.stallLng!);
        }
        return _VendorCard(vendor: vendor, isEn: isEn, distanceKm: distanceKm);
      },
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorDirectoryEntry vendor;
  final bool isEn;
  final double? distanceKm;

  const _VendorCard({required this.vendor, required this.isEn, this.distanceKm});

  Future<void> _openDirections(BuildContext context) async {
    final lat = vendor.stallLat;
    final lng = vendor.stallLng;
    if (lat == null || lng == null) return;

    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn ? "Couldn't open Maps." : 'Hindi mabuksan ang Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardWithShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: AppTheme.iconBadgeBg(AppTheme.roleAccent, radius: 12),
                child: Icon(Icons.storefront_rounded, size: 20, color: AppTheme.roleAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.businessName, style: AppTheme.cardTitle.copyWith(fontSize: 15)),
                    if (vendor.formattedAddress.isNotEmpty)
                      Text(vendor.formattedAddress, style: AppTheme.cardSubtitle.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (distanceKm != null)
                Text(
                  '${distanceKm!.toStringAsFixed(1)} km',
                  style: TextStyle(color: AppTheme.roleAccent, fontWeight: FontWeight.w700, fontSize: 12),
                ),
            ],
          ),
          if (vendor.storeDescription != null && vendor.storeDescription!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(vendor.storeDescription!, style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4)),
          ],
          if (vendor.storeHours != null && vendor.storeHours!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textFaint),
              const SizedBox(width: 6),
              Text(vendor.storeHours!, style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
            ]),
          ],
          if (vendor.storeCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final category in vendor.storeCategories)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppTheme.tintedCardDecoration(AppTheme.roleAccent, opacity: 0.1, radius: 20),
                    child: Text(category, style: TextStyle(color: AppTheme.roleAccentDark, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
          if (vendor.stallLat != null && vendor.stallLng != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openDirections(context),
                icon: Icon(Icons.directions_rounded, size: 17, color: AppTheme.roleAccent),
                label: Text(isEn ? 'Get Directions' : 'Kumuha ng Direksyon', style: const TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.roleAccent,
                  side: BorderSide(color: AppTheme.roleAccent.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationUnavailable implements Exception {
  final String message;
  const _LocationUnavailable(this.message);
}
