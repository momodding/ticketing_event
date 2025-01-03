import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TabletQRScannerPage extends StatefulWidget {
  const TabletQRScannerPage({Key? key}) : super(key: key);

  @override
  State<TabletQRScannerPage> createState() => _TabletQRScannerPageState();
}

class _TabletQRScannerPageState extends State<TabletQRScannerPage> with WidgetsBindingObserver {
  late MobileScannerController cameraController;
  ValueNotifier<bool> hasTorchStatus = ValueNotifier<bool>(true);
  bool isScanning = true;
  String? lastScanned;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();

    // Enable all orientations for rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> initializeCamera() async {
    try {
      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back, // Start with back camera
        returnImage: true,
        torchEnabled: false,
      );
      setState(() => isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() => isCameraInitialized = false);
    }
  }

  Future<void> switchCamera() async {
    try {
      await cameraController.switchCamera();
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching camera: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('QR Scanner'),
            actions: [
              // Torch toggle button
              ValueListenableBuilder(
                valueListenable: hasTorchStatus,
                builder: (context, hasTorch, child) {
                  if (hasTorch) {
                    return IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: ValueNotifier<bool>(cameraController.torchEnabled),
                        builder: (context, state, child) {
                          return Icon(
                            state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                          );
                        },
                      ),
                      onPressed: () => cameraController.toggleTorch(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Camera switch button
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: ValueNotifier<bool>(cameraController.facing == CameraFacing.back),
                  builder: (context, state, child) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return RotationTransition(
                          turns: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        state == CameraFacing.front
                          ? Icons.camera_front
                          : Icons.camera_rear,
                        key: ValueKey(state),
                      ),
                    );
                  },
                ),
                onPressed: switchCamera,
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                if (!isCameraInitialized)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  MobileScanner(
                    controller: cameraController,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Camera Error: ${error.errorCode}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                initializeCamera();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (isScanning && barcode.rawValue != null) {
                          // Prevent duplicate scans
                          if (lastScanned != barcode.rawValue) {
                            setState(() {
                              isScanning = false;
                              lastScanned = barcode.rawValue;
                            });

                            showQRResultDialog(context, barcode);
                          }
                        }
                      }
                    },
                  ),

                // Scanner overlay with animation
                CustomPaint(
                  painter: ScannerOverlayPainter(
                    orientation: orientation,
                    borderColor: Theme.of(context).primaryColor,
                    scanLinePosition: _getScanLinePosition(),
                  ),
                  child: const SizedBox.expand(),
                ),

                // Camera facing indicator
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: ValueNotifier<bool>(cameraController.facing == CameraFacing.front),
                      builder: (context, state, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state == CameraFacing.front
                                ? Icons.camera_front
                                : Icons.camera_rear,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state == CameraFacing.front ? 'Front' : 'Back',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Instructions
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Position QR code within the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap camera icon to switch cameras',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getScanLinePosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now % 2000) / 2000; // 2-second animation cycle
  }

  void showQRResultDialog(BuildContext context, Barcode barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Detected'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Type: ${barcode.type.name}'),
                const SizedBox(height: 8),
                Text('Value: ${barcode.rawValue}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: barcode.rawValue ?? ''),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  isScanning = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void showQRResultModal(BuildContext context, Barcode barcode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR Code Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                barcode.rawValue ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Implement check-in logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checked in successfully!')),
                      );
                      Navigator.pop(context);
                      setState(() {
                        isScanning = true;
                      });
                    },
                    child: const Text('Check In'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        isScanning = true;
                      });
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    // Reset to default orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Orientation orientation;
  final Color borderColor;
  final double scanLinePosition; // 0.0 to 1.0

  ScannerOverlayPainter({
    required this.orientation,
    required this.borderColor,
    required this.scanLinePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final double scannerSize = orientation == Orientation.portrait
        ? size.width * 0.8
        : size.height * 0.8;

    final Rect scannerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scannerSize,
      height: scannerSize,
    );

    // Draw semi-transparent overlay
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scannerRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw scanner border
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(scannerRect, borderPaint);

    // Draw animated scan line
    final Paint scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          borderColor.withOpacity(0),
          borderColor.withOpacity(0.8),
          borderColor.withOpacity(0),
        ],
      ).createShader(scannerRect);

    final double scanLineY = scannerRect.top +
        (scannerRect.height * scanLinePosition);
    canvas.drawLine(
      Offset(scannerRect.left, scanLineY),
      Offset(scannerRect.right, scanLineY),
      scanLinePaint..strokeWidth = 2,
    );

    // Draw corner markers
    final double cornerSize = scannerSize * 0.1;
    final Paint cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Draw corners
    void drawCorner(Offset start, Offset end) {
      canvas.drawLine(start, end, cornerPaint);
    }

    // Top left
    drawCorner(
      Offset(scannerRect.left, scannerRect.top + cornerSize),
      scannerRect.topLeft,
    );
    drawCorner(
      scannerRect.topLeft,
      Offset(scannerRect.left + cornerSize, scannerRect.top),
    );

    // Top right
    drawCorner(
      Offset(scannerRect.right - cornerSize, scannerRect.top),
      scannerRect.topRight,
    );
    drawCorner(
      scannerRect.topRight,
      Offset(scannerRect.right, scannerRect.top + cornerSize),
    );

    // Bottom left
    drawCorner(
      Offset(scannerRect.left, scannerRect.bottom - cornerSize),
      scannerRect.bottomLeft,
    );
    drawCorner(
      scannerRect.bottomLeft,
      Offset(scannerRect.left + cornerSize, scannerRect.bottom),
    );

    // Bottom right
    drawCorner(
      Offset(scannerRect.right - cornerSize, scannerRect.bottom),
      scannerRect.bottomRight,
    );
    drawCorner(
      scannerRect.bottomRight,
      Offset(scannerRect.right, scannerRect.bottom - cornerSize),
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLinePosition != scanLinePosition;
  }
}