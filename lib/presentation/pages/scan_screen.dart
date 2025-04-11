import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smart_lock/presentation/pages/beacon_scanner_page.dart';

import '../../data/face_scan_repo_impl.dart';
import '../../domain/face_scan_usecase.dart';

class FaceScan extends StatefulWidget {
  final String lockUuid;

  const FaceScan({super.key, required this.lockUuid});

  @override
  State<FaceScan> createState() => _FaceScanState();
}

class _FaceScanState extends State<FaceScan> with TickerProviderStateMixin {
  late CameraController _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _showLockAnimation = false;
  bool _showAccessDenied = false; // New flag for access denied state
  String _status = 'Position your face within the frame';

  // Animation controllers
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  late final Animation<double> _scanAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

  // Lock animation controller
  late final AnimationController _lockAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _lockAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _lockAnimationController,
      curve: Curves.easeInOut,
    ),
  );

  // Access denied animation controller
  late final AnimationController _accessDeniedController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _accessDeniedAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _accessDeniedController,
      curve: Curves.easeInOut,
    ),
  );

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

    // Add listener for lock animation completion
    _lockAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a moment before navigating to BeaconScanScreen
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BeaconScannerPage()),
          );
        });
      }
    });

    // Add listener for access denied animation completion
    _accessDeniedController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait a moment before navigating to BeaconScanScreen
        Future.delayed(const Duration(milliseconds: 1000), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BeaconScannerPage()),
          );
        });
      }
    });
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

      // Check if we need to simulate a 300 status response
      // In a real implementation, you would get this from the API response
      // For now, we'll use a mock approach to determine access status
      bool hasAccess = await _checkAccessStatus(widget.lockUuid);

      if (!hasAccess) {
        // Simulate 300 status code
        setState(() {
          _status =
              'Access denied. You do not have permission to open this lock.';
          _isLoading = false;
          _showAccessDenied = true;
        });

        // Start the access denied animation
        _accessDeniedController.forward();
      } else {
        setState(() {
          _status = 'Face scan successful!';
          _isLoading = false;
          _showLockAnimation = true;
        });

        // Start the lock opening animation
        _lockAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _status = 'Face scan failed: $e';
        print(e);
        _isScanning = false;
        _isLoading = false;
      });
    }
  }

  // Mock method to check if user has access
  // In real implementation, this would extract status from API response
  Future<bool> _checkAccessStatus(String lockUuid) async {
    // This is a mock implementation - replace with actual logic
    // If lockUuid ends with '300', simulate no access
    return !lockUuid.endsWith('300');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lockAnimationController.dispose();
    _accessDeniedController.dispose();
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
      body: Stack(
        children: [
          // Main content
          _isCameraInitialized
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
                      Text(
                        _status,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
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
                          : _showLockAnimation || _showAccessDenied
                              ? const SizedBox() // Hide button during animation
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
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          // Lock animation overlay
          if (_showLockAnimation)
            AnimatedBuilder(
              animation: _lockAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.7),
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: LockAnimation(animation: _lockAnimation),
                  ),
                );
              },
            ),

          // Access Denied overlay
          if (_showAccessDenied)
            AnimatedBuilder(
              animation: _accessDeniedAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.7),
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: AccessDeniedAnimation(
                        animation: _accessDeniedAnimation),
                  ),
                );
              },
            ),
        ],
      ),
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

// Lock animation widget
class LockAnimation extends StatelessWidget {
  final Animation<double> animation;

  const LockAnimation({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.4;

    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lock body
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),

          // Lock shackle (the U-shaped part)
          Positioned(
            top: 0,
            child: CustomPaint(
              size: Size(size * 0.6, size * 0.6),
              painter: LockShacklePainter(
                animation.value,
                Colors.blue.shade700,
              ),
            ),
          ),

          // Success check mark
          Opacity(
            opacity: animation.value > 0.7 ? (animation.value - 0.7) * 3.3 : 0,
            child: Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.greenAccent,
                size: size * 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the lock shackle
class LockShacklePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  LockShacklePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    // Calculate opening angle (0 to 90 degrees)
    final angle = (animationValue * 90) * (3.14159 / 180); // Convert to radians

    final path = Path();

    // Start from bottom left anchor point
    path.moveTo(size.width * 0.2, size.height * 0.9);

    // Draw up to top left
    path.lineTo(size.width * 0.2, size.height * 0.3);

    // Draw top curved part - this is the part that rotates
    if (animationValue < 0.01) {
      // When closed, it's just a U shape
      path.arcToPoint(
        Offset(size.width * 0.8, size.height * 0.3),
        radius: Radius.circular(size.width * 0.3),
        clockwise: true,
      );
    } else {
      // When opening, we need to rotate the right part
      final pivotPoint = Offset(size.width * 0.2, size.height * 0.3);
      final rightPoint = Offset(
        pivotPoint.dx + size.width * 0.6 * cos(angle),
        pivotPoint.dy + size.width * 0.6 * sin(angle),
      );

      path.lineTo(rightPoint.dx, rightPoint.dy);
    }

    // Draw right side down if not fully open
    if (animationValue < 1.0) {
      final factor = 1.0 - animationValue;
      final rightX = size.width * 0.8;
      final startY = size.height * 0.3 + size.height * 0.6 * (1 - factor);
      final endY = size.height * 0.9;

      path.moveTo(rightX, startY);
      path.lineTo(rightX, endY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LockShacklePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Access Denied animation widget
class AccessDeniedAnimation extends StatelessWidget {
  final Animation<double> animation;

  const AccessDeniedAnimation({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.4;

    return SizedBox(
      width: size,
      height: size * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lock body
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),

          // Lock shackle (the U-shaped part - doesn't move for denied access)
          Positioned(
            top: 0,
            child: CustomPaint(
              size: Size(size * 0.6, size * 0.6),
              painter: LockShacklePainter(
                0.0, // Animation value 0 means lock stays closed
                Colors.red.shade700,
              ),
            ),
          ),

          // Access denied X mark
          Opacity(
            opacity: animation.value > 0.5 ? (animation.value - 0.5) * 2.0 : 0,
            child: Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.red.shade300,
                size: size * 1.0,
              ),
            ),
          ),

          // Text showing access denied
          Positioned(
            bottom: -size * 0.5,
            child: Opacity(
              opacity: animation.value,
              child: Column(
                children: [
                  Text(
                    "Access Denied",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You don't have permission",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
