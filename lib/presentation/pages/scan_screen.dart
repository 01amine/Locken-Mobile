import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../data/face_scan_repo_impl.dart';
import '../../domain/face_scan_usecase.dart';

class FaceScan extends StatefulWidget {
  final String lockUuid;

  const FaceScan({super.key, required this.lockUuid});

  @override
  State<FaceScan> createState() => _FaceScanState();
}

class _FaceScanState extends State<FaceScan>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isScanning = false;
  String _status = 'Position your face within the frame';

  // Animation controller and animation - initialize immediately to avoid late initialization errors
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  late final Animation<double> _scanAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

  late final FaceScanUseCase _faceScanUseCase;

  @override
  void initState() {
    super.initState();
    _faceScanUseCase = FaceScanUseCase(
      repository: FaceScanRepositoryImpl(),
    );

    // Setup animation to repeat
    _animationController.repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    // Retrieve the list of available cameras on the device.
    final cameras = await availableCameras();

    // Select the front camera. If not found, default to the first camera.
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);

    _initializeControllerFuture = _cameraController.initialize();
    _initializeControllerFuture!.then((_) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    });
  }

  Future<void> _captureFace() async {
    try {
      // Start the scanning animation
      setState(() {
        _isScanning = true;
        _status = 'Scanning face...';
      });

      // Wait for a moment to show the scanning animation
      await Future.delayed(const Duration(seconds: 2));

      // Ensure the camera is initialized.
      await _initializeControllerFuture;
      // Capture an image from the live camera preview.
      final image = await _cameraController.takePicture();

      setState(() {
        _isLoading = true;
        _isScanning = false;
        _status = 'Processing face scan...';
      });

      // Process the captured image.
      await _faceScanUseCase.scanAndSendFace(widget.lockUuid, image.path);
      setState(() {
        _status = 'Face scan successful!';
      });
    } catch (e) {
      setState(() {
        _status = 'Face scan failed: $e';
        _isScanning = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For a better layout, we can define a fixed height for the preview.
    // Here we use a 4:3 ratio based on the device width.
    final double previewHeight = MediaQuery.of(context).size.width * (4 / 3);

    return Scaffold(
      appBar: AppBar(title: const Text("Face Detection")),
      body: _isCameraInitialized
          ? SingleChildScrollView(
              child: Column(
                children: [
                  // Fixed camera preview container with face overlay
                  Stack(
                    children: [
                      // Camera preview
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: previewHeight,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CameraPreview(_cameraController),
                        ),
                      ),

                      // Face outline overlay
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.lightBlueAccent,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.35),
                            ),
                          ),
                        ),
                      ),

                      // Scanning animation
                      if (_isScanning)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: ScannerPainter(
                                  _scanAnimation.value,
                                  MediaQuery.of(context).size.width * 0.7,
                                ),
                              );
                            },
                          ),
                        ),

                      // Corners for visual alignment guide
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            child: CustomPaint(
                              painter: CornersPainter(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(_status, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  _isLoading || _isScanning
                      ? Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            _isScanning
                                ? const Text("Keep still while scanning...")
                                : const Text("Processing..."),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _captureFace,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            "Scan Face",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// Custom painter for scan line effect
class ScannerPainter extends CustomPainter {
  final double progress;
  final double size;

  ScannerPainter(this.progress, this.size);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2;

    // Create a gradient for the scan line
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.0),
          Colors.blue.withOpacity(0.5),
          Colors.blue.withOpacity(0.8),
          Colors.blue.withOpacity(0.5),
          Colors.blue.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
        center.dx - radius,
        center.dy - radius + (progress * size),
        size,
        20,
      ));

    // Draw the scan line
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - radius,
        center.dy - radius + (progress * size),
        size,
        4,
      ),
      paint,
    );

    // Draw a glow effect
    canvas.drawCircle(
      Offset(
        center.dx,
        center.dy - radius + (progress * size) + 2,
      ),
      radius,
      Paint()
        ..color = Colors.blue.withOpacity(0.05)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Custom painter for corner brackets
class CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double cornerSize = size.width * 0.15;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerSize),
      paint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerSize)
        ..lineTo(0, size.height)
        ..lineTo(cornerSize, size.height),
      paint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornersPainter oldDelegate) => false;
}
