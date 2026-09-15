import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meat_type.dart';
import '../theme/app_theme.dart';
import '../theme/scan_theme.dart';
import '../services/bug_report_service.dart';
import '../services/scan_service.dart';
import '../services/settings_service.dart';
import '../utils/scan_explanation.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  final MeatType meatType;

  const ScanScreen({super.key, required this.meatType});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static const Color _scanBg = ScanTheme.scaffoldBackground;

  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = const [];

  bool _flashOn = false;
  bool _isCapturing = false;
  String? _cameraError;

  // Serializes dispose/init so a resume never opens a new CameraController
  // before the previous one has actually finished releasing the camera —
  // see didChangeAppLifecycleState.
  Future<void> _cameraOpQueue = Future<void>.value();

  bool get _isEn => SettingsService.isEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _queueCameraOp(_disposeCameraController);
    } else if (state == AppLifecycleState.resumed) {
      _queueCameraOp(_initCamera);
    }
  }

  /// Chains camera ops onto a single queue so a resume's re-init can never
  /// start opening a new CameraController before an in-flight dispose (from
  /// the inactive state right before it, e.g. opening the gallery picker)
  /// has actually finished releasing the camera — starting one too early
  /// fails with "camera already in use" and leaves _cameraError set, which
  /// is what showed up as a permanently black, uncapturable viewfinder.
  void _queueCameraOp(Future<void> Function() op) {
    _cameraOpQueue = _cameraOpQueue.then((_) => op());
  }

  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    _cameraController = null;
    _initializeControllerFuture = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = _isEn ? 'No camera found on this device.' : 'Walang nahanap na camera sa device na ito.');
        return;
      }

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;
      if (!mounted) return;
      setState(() => _cameraError = null);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = e.description ?? (_isEn ? 'Could not start the camera.' : 'Hindi masimulan ang camera.'));
    }
  }

  Future<void> _handleCapture() async {
    final controller = _cameraController;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();
    try {
      final XFile shot = await controller.takePicture();
      await _handleCapturedImage(shot);
    } on CameraException catch (e) {
      if (mounted) _showCaptureError(e.description ?? (_isEn ? 'Failed to capture photo.' : 'Hindi nakuha ang larawan.'));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _handlePickFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return; // user cancelled
      await _handleCapturedImage(picked);
    } catch (_) {
      if (mounted) _showCaptureError(_isEn ? 'Could not open the gallery.' : 'Hindi mabuksan ang gallery.');
    }
  }

  /// Sends the real classification request — the backend uploads the photo
  /// to Supabase and returns the Fresh/Spoiled result (see
  /// app/routers/scan.py). Returns null when the caller should show an
  /// error and stop.
  Future<ScanResult?> _classify(XFile file) async {
    try {
      return await ScanService().classify(file, meatType: widget.meatType);
    } catch (e, st) {
      // "The scan didn't work" is exactly the kind of failure that should
      // always reach the admin automatically, not just literal unhandled
      // crashes — except MeatNotRecognizedException, which means the gate
      // correctly rejected a bad photo (wrong framing, not meat, etc.).
      // That's expected, working-as-intended user feedback, not a bug.
      if (e is! MeatNotRecognizedException) {
        BugReportService.reportError(e, st, context: 'Cannot capture or scan meat (${widget.meatType.label})');
      }

      final isEn = _isEn;
      if (mounted) {
        _showScanRejectedDialog(e is ScanServiceException
            ? e.message
            : (isEn ? "Couldn't process the scan. Please try again." : 'Hindi naproseso ang scan. Pakisubukang muli.'));
      }
      return null;
    }
  }

  Future<void> _handleCapturedImage(XFile file) async {
    setState(() => _isCapturing = true);
    try {
      final result = await _classify(file);
      if (result == null) return;
      if (!mounted) return;

      final explanation = buildScanExplanation(
        meatType: widget.meatType.label,
        isFresh: result.isFresh,
        confidence: result.confidence,
        hueDeg: result.hueDeg,
        saturationPct: result.saturationPct,
        brightnessPct: result.brightnessPct,
        uniformityPct: result.uniformityPct,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            meatTypeInfo: widget.meatType,
            meatType: widget.meatType.label,
            isFresh: result.isFresh,
            confidence: result.confidence,
            findings: explanation.findings,
            recommendation: explanation.recommendation,
            storageTips: explanation.storageTips,
            scanTimestamp: DateTime.now(),
            scanId: result.scanId,
            imageFile: file,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showCaptureError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showScanRejectedDialog(String message) {
    final isEn = _isEn;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppTheme.spoiledRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(isEn ? 'Scan Not Recognized' : 'Hindi Nakilala ang Scan'),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(color: AppTheme.textMuted, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEn ? 'Try Again' : 'Subukang Muli'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_flashOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _flashOn = next);
    } on CameraException catch (_) {
    }
  }

  void _showFramingTips() {
    final isEn = _isEn;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.sheetTopRadius),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTheme.sheetHandle(),
            Text(
              isEn ? 'Tips for an accurate scan' : 'Mga tip para sa tumpak na scan',
              style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            AppTheme.checkTipRow(isEn
                ? 'Use natural or white light — avoid yellow indoor lighting.'
                : 'Gumamit ng natural o white light — iwasan ang dilaw na ilaw sa loob ng bahay.'),
            AppTheme.checkTipRow(isEn
                ? 'Fill the frame with the meat surface, no packaging or plate.'
                : 'Punuin ang frame ng ibabaw ng karne, walang packaging o plato.'),
            AppTheme.checkTipRow(isEn
                ? 'Hold the camera steady, about 15–20 cm from the surface.'
                : 'Panatilihing steady ang camera, mga 15–20 cm mula sa ibabaw.'),
            AppTheme.checkTipRow(isEn ? 'Avoid shadows or glare across the meat.' : 'Iwasan ang anino o glare sa ibabaw ng karne.'),
          ],
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: _scanBg,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, isEn),
                  Expanded(child: _buildViewfinder(context, isEn)),
                  _buildBottomControls(context, isEn),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundIconButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                isEn ? 'FRAME THE ${widget.meatType.label.toUpperCase()}' : 'I-FRAME ANG ${widget.meatType.label.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          _RoundIconButton(
            icon: Icons.info_outline_rounded,
            onPressed: _showFramingTips,
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          color: ScanTheme.viewfinderBackground,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraFeed(),

              // Framing guide corners.
              const Positioned(
                  top: 18, left: 18, child: _CornerBracket(corner: _Corner.topLeft)),
              const Positioned(
                  top: 18, right: 18, child: _CornerBracket(corner: _Corner.topRight)),
              const Positioned(
                  bottom: 18, left: 18, child: _CornerBracket(corner: _Corner.bottomLeft)),
              const Positioned(
                  bottom: 18, right: 18, child: _CornerBracket(corner: _Corner.bottomRight)),

              // Center focus reticle.
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 1.4),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white38, size: 26),
                ),
              ),

              // Bottom instructional hint.
              Positioned(
                left: 24,
                right: 24,
                bottom: 26,
                child: Text(
                  _cameraError ?? (isEn ? 'Keep the camera steady and use good lighting' : 'Panatilihing steady ang camera at gumamit ng magandang liwanag'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFeed() {
    if (_cameraError != null) {
      return const _CameraPlaceholder();
    }

    final controller = _cameraController;
    final initFuture = _initializeControllerFuture;
    if (controller == null || initFuture == null) {
      return const _CameraPlaceholder();
    }

    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return const _CameraPlaceholder();
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.photo_library_outlined,
                onPressed: _handlePickFromGallery,
              ),
              _ShutterButton(
                isBusy: _isCapturing,
                onPressed: _handleCapture,
              ),
              _RoundIconButton(
                icon: _flashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                isActive: _flashOn,
                onPressed: _toggleFlash,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0C0A),
      child: Center(
        child: Icon(
          Icons.videocam_off_outlined,
          color: Colors.white.withOpacity(0.06),
          size: 72,
        ),
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  final _Corner corner;

  const _CornerBracket({required this.corner});

  @override
  Widget build(BuildContext context) {
    final isTop = corner == _Corner.topLeft || corner == _Corner.topRight;
    final isLeft = corner == _Corner.topLeft || corner == _Corner.bottomLeft;
    const size = ScanTheme.cornerBracketSize;
    const thickness = ScanTheme.cornerBracketThickness;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: size, height: thickness, color: ScanTheme.cornerBracketColor),
          ),
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: thickness, height: size, color: ScanTheme.cornerBracketColor),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ScanTheme.roundIconBg(isActive),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: ScanTheme.roundIconColor(isActive), size: 20),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isBusy;

  const _ShutterButton({required this.onPressed, this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: ScanTheme.shutterOuterDecoration,
      child: Material(
        color: AppTheme.accentGold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isBusy ? null : onPressed,
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppTheme.roleAccentDark,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}