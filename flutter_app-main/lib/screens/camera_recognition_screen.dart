import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hear_and_see_safe/services/voice_assistant_service.dart';
import 'package:hear_and_see_safe/utils/accessibility_utils.dart';
import 'package:hear_and_see_safe/utils/platform_utils.dart';
import 'package:hear_and_see_safe/utils/vibration_utils.dart';

class CameraRecognitionScreen extends StatefulWidget {
  const CameraRecognitionScreen({super.key});

  @override
  State<CameraRecognitionScreen> createState() =>
      _CameraRecognitionScreenState();
}

class _CameraRecognitionScreenState
    extends State<CameraRecognitionScreen> {
  late VoiceAssistantService _voiceAssistant;
  dynamic _cameraController;
  List<dynamic>? _cameras;
  bool _isInitialized = false;
  String _recognitionMode = 'currency';

  @override
  void initState() {
    super.initState();
    _voiceAssistant =
        Provider.of<VoiceAssistantService>(context, listen: false);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (PlatformUtils.isWeb) {
      setState(() {
        _isInitialized = true;
      });
      await _voiceAssistant.speak('camera.web_not_available'.tr());
      return;
    }

    try {
      final camera = await _tryGetCamera();
      if (camera != null) {
        _cameras = await camera.availableCameras();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _cameraController =
          await _createCameraController(_cameras![0]);
          if (_cameraController != null) {
            await _cameraController.initialize();
            setState(() {
              _isInitialized = true;
            });
            await _voiceAssistant.speak('camera.ready'.tr());
          }
        }
      }
    } catch (e) {
      await _voiceAssistant.speak('camera.error'.tr());
    }
  }

  Future<dynamic> _tryGetCamera() async {
    if (PlatformUtils.isWeb) return null;
    return null;
  }

  Future<dynamic> _createCameraController(dynamic camera) async {
    if (PlatformUtils.isWeb) return null;
    return null;
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _voiceAssistant.speak('camera.analyzing'.tr());

      if (await VibrationUtils.hasVibrator()) {
        await VibrationUtils.vibrate(duration: 300);
      }

      await Future.delayed(const Duration(seconds: 2));

      String result = '';
      if (_recognitionMode == 'currency') {
        result = _recognizeCurrency();
      } else if (_recognitionMode == 'color') {
        result = _recognizeColor();
      } else {
        result = _recognizeObject();
      }

      await _voiceAssistant.speak(result);
      AccessibilityUtils.provideFeedback(context: context);
    } catch (e) {
      await _voiceAssistant.speak('camera.error'.tr());
    }
  }

  String _recognizeCurrency() {
    final currencies = [
      'camera.currency_10'.tr(),
      'camera.currency_50'.tr(),
      'camera.currency_100'.tr(),
      'camera.currency_500'.tr(),
    ];
    return currencies[DateTime.now().millisecond % currencies.length];
  }

  String _recognizeColor() {
    final colors = [
      'camera.color_red'.tr(),
      'camera.color_blue'.tr(),
      'camera.color_green'.tr(),
      'camera.color_yellow'.tr(),
      'camera.color_black'.tr(),
      'camera.color_white'.tr(),
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  String _recognizeObject() {
    final objects = [
      'camera.object_shirt'.tr(),
      'camera.object_pants'.tr(),
      'camera.object_shoe'.tr(),
      'camera.object_book'.tr(),
      'camera.object_bottle'.tr(),
    ];
    return objects[DateTime.now().millisecond % objects.length];
  }

  Widget _buildCameraPreview() {
    if (PlatformUtils.isWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt,
                size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'camera.web_placeholder'.tr(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    if (_cameraController != null &&
        !PlatformUtils.isWeb) {
      try {
        _cameraController.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
    AccessibilityUtils.getBackgroundColor(context);
    final contrastColor =
    AccessibilityUtils.getContrastColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'features.camera_recognition'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: contrastColor,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                        context,
                        'currency',
                        'camera.currency'.tr()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                        context,
                        'color',
                        'camera.color'.tr()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                        context,
                        'object',
                        'camera.object'.tr()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: contrastColor,
                    width: 4,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isInitialized &&
                      _cameraController != null &&
                      !PlatformUtils.isWeb
                      ? _buildCameraPreview()
                      : Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'camera.initializing'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            color: contrastColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: _captureAndRecognize,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  'camera.capture'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                  const Size(double.infinity, 60),
                  backgroundColor:
                  const Color(0xFF2196F3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context, String mode, String label) {
    final isActive = _recognitionMode == mode;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _recognitionMode = mode;
        });
        AccessibilityUtils.provideFeedback(context: context);
        _voiceAssistant.speak(
            'camera.mode_changed'.tr(args: [label]));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? const Color(0xFF2196F3)
            : Colors.grey,
        foregroundColor: Colors.white,
        padding:
        const EdgeInsets.symmetric(vertical: 12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
