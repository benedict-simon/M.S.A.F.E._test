import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';


class StallLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const StallLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<StallLocationPickerScreen> createState() => _StallLocationPickerScreenState();
}

class _StallLocationPickerScreenState extends State<StallLocationPickerScreen> {
  static const _defaultCenter = LatLng(14.5995, 120.9842); // Manila fallback

  final _mapController = MapController();
  late LatLng _pinned;
  bool _locating = false;
  String? _locationError;

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    _pinned = widget.initialLocation ?? _defaultCenter;
    if (widget.initialLocation == null) _useCurrentLocation();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _pinned = here);
      _mapController.move(here, 17);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = _isEn
            ? "Couldn't get your current location. Drag the map to pin the stall manually."
            : 'Hindi nakuha ang iyong kasalukuyang lokasyon. I-drag ang mapa para manu-manong i-pin ang puwesto.';
      });
    } finally {
      if (mounted) setState(() => _locating = false);
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: AppTheme.screenHeader(context, isEn ? 'Pin Stall Location' : 'I-pin ang Puwesto', titleFontSize: 18),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isEn
                        ? 'Drag the map so the pin sits over the stall — useful when there\'s no signage or the seller won\'t share a stall number.'
                        : 'I-drag ang mapa para nasa ibabaw ng puwesto ang pin — kapaki-pakinabang kapag walang signage o ayaw sabihin ng seller ang numero ng puwesto.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _pinned,
                            initialZoom: 16,
                            onPositionChanged: (camera, hasGesture) {
                              if (hasGesture) _pinned = camera.center;
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.mobile_app',
                            ),
                          ],
                        ),
                      ),
                      // Pin fixed at the screen's center; the map pans underneath it.
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36),
                          child: Icon(Icons.location_on_rounded, size: 44, color: AppTheme.spoiledRed),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter',
                          backgroundColor: AppTheme.cardColor,
                          onPressed: _locating ? null : _useCurrentLocation,
                          child: _locating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.my_location_rounded, color: AppTheme.roleAccent),
                        ),
                      ),
                      if (_locationError != null)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              _locationError!,
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: [
                      AppTheme.primaryButton(
                        onPressed: () => Navigator.of(context).pop(_pinned),
                        child: Text(isEn ? 'Confirm Pin' : 'Kumpirmahin ang Pin'),
                      ),
                      const SizedBox(height: 10),
                      AppTheme.secondaryActionButton(
                        label: isEn ? 'Cancel' : 'Kanselahin',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationUnavailable implements Exception {
  final String message;
  const _LocationUnavailable(this.message);
}
