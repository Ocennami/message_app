import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Dialog crop avatar giong Facebook
class AvatarCropDialog extends StatefulWidget {
  final XFile imageFile;

  const AvatarCropDialog({super.key, required this.imageFile});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  static const double _viewportSize = 300.0;
  static const double _defaultZoom = 1.35;

  late ui.Image _image;
  bool _imageLoaded = false;

  // Transform values
  double _currentScale = 1.0;
  double _minScale = 1.0;
  double _maxScale = 3.0;
  Offset _offset = Offset.zero;

  // Drag state
  Offset _startOffset = Offset.zero;
  Offset _currentOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _image = frame.image;
      _imageLoaded = true;

      _currentScale = _defaultZoom;
      _minScale = _defaultZoom;
      _maxScale = _defaultZoom * 2.5;
      _offset = Offset.zero;
      _currentOffset = Offset.zero;
    });
  }

  double get _coverScale {
    if (!_imageLoaded) return 1.0;
    final width = _image.width.toDouble();
    final height = _image.height.toDouble();
    if (width <= 0 || height <= 0) return 1.0;
    return math.max(_viewportSize / width, _viewportSize / height);
  }

  double get _effectiveScale => _coverScale * _currentScale;

  void _clampOffset() {
    if (!_imageLoaded) return;

    final scaledWidth = _image.width * _effectiveScale;
    final scaledHeight = _image.height * _effectiveScale;

    final maxDx = math.max(0.0, (scaledWidth - _viewportSize) / 2);
    final maxDy = math.max(0.0, (scaledHeight - _viewportSize) / 2);

    final clampedDx = _offset.dx.clamp(-maxDx, maxDx);
    final clampedDy = _offset.dy.clamp(-maxDy, maxDy);
    _offset = Offset(clampedDx, clampedDy);
  }

  void _resetTransform() {
    setState(() {
      _currentScale = _defaultZoom;
      _offset = Offset.zero;
      _currentOffset = Offset.zero;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _startOffset = details.localPosition;
    _currentOffset = _offset;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final delta = details.localPosition - _startOffset;
      _offset = _currentOffset + delta;
      _clampOffset();
    });
  }

  void _onScaleUpdate(double value) {
    setState(() {
      _currentScale = value;
      _clampOffset();
    });
  }

  Future<Uint8List?> _cropImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Get original image dimensions
      final origWidth = originalImage.width.toDouble();

      // Get UI image dimensions (decoded for display)
      final uiWidth = _image.width.toDouble();
      final uiHeight = _image.height.toDouble();

      // Calculate how BoxFit.cover scales the image to fill the viewport
      final coverScale = _coverScale;
      final effectiveScale = coverScale * _currentScale;

      // Calculate displayed image size after scaling
      final displayedWidth = uiWidth * effectiveScale;
      final displayedHeight = uiHeight * effectiveScale;

      // Offset of the displayed image within the viewport
      final displayOffsetX = (displayedWidth - _viewportSize) / 2;
      final displayOffsetY = (displayedHeight - _viewportSize) / 2;

      // Convert viewport center to displayed image coordinates
      final viewportCenter = _viewportSize / 2;
      final imageCenterX =
          (displayOffsetX - _offset.dx + viewportCenter) / effectiveScale;
      final imageCenterY =
          (displayOffsetY - _offset.dy + viewportCenter) / effectiveScale;

      // Convert to original image coordinates
      final scaleToOriginal = origWidth / uiWidth;
      final origCenterX = imageCenterX * scaleToOriginal;
      final origCenterY = imageCenterY * scaleToOriginal;

      // Calculate crop radius in original image coordinates
      final cropRadiusInOrig =
          (_viewportSize / 2) / effectiveScale * scaleToOriginal;
      final cropSizeInOrig = (cropRadiusInOrig * 2).round();

      // Calculate crop position (top-left corner)
      final maxCropSize = originalImage.width < originalImage.height
          ? originalImage.width
          : originalImage.height;
      final cropSize = cropSizeInOrig > maxCropSize
          ? maxCropSize
          : math.max(1, cropSizeInOrig);
      final maxCropX = originalImage.width - cropSize;
      final maxCropY = originalImage.height - cropSize;
      final halfCropSize = cropSize / 2;
      final cropX = math.min(
        math.max(0, (origCenterX - halfCropSize).round()),
        math.max(0, maxCropX),
      );
      final cropY = math.min(
        math.max(0, (origCenterY - halfCropSize).round()),
        math.max(0, maxCropY),
      );

      // Crop to square
      final cropped = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropSize,
        height: cropSize,
      );

      // Make it circular with the original crop size
      final circular = img.copyCropCircle(cropped, radius: cropSize ~/ 2);

      // Encode to PNG to preserve transparency
      return Uint8List.fromList(img.encodePng(circular));
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF242526),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Chon anh dai dien',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Image area with circle overlay
              if (_imageLoaded)
                SizedBox(
                  width: 480,
                  height: 360,
                  child: Center(
                    child: SizedBox(
                      width: _viewportSize,
                      height: _viewportSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onDoubleTap: _resetTransform,
                            child: ClipRect(
                              child: SizedBox(
                                width: _viewportSize,
                                height: _viewportSize,
                                child: Transform.translate(
                                  offset: _offset,
                                  child: Transform.scale(
                                    scale: _effectiveScale,
                                    alignment: Alignment.center,
                                    child: RawImage(
                                      image: _image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(_viewportSize, _viewportSize),
                              painter: CircleCutoutPainter(),
                            ),
                          ),
                          Positioned(
                            top: (_viewportSize / 2) - 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_with,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Keo de dat lai vi tri',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (!_imageLoaded)
                const SizedBox(
                  width: 420,
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),

              const SizedBox(height: 32),

              // Zoom slider
              Row(
                children: [
                  const Icon(Icons.remove, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _currentScale,
                      min: _minScale,
                      max: _maxScale,
                      activeColor: const Color(0xFF0084FF),
                      inactiveColor: Colors.white24,
                      onChanged: _onScaleUpdate,
                    ),
                  ),
                  const Icon(Icons.add, color: Colors.white70),
                ],
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final croppedBytes = await _cropImage();
                      if (!mounted) return;
                      navigator.pop(croppedBytes);
                    },
                    icon: const Icon(Icons.crop),
                    label: const Text('Cat anh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      debugPrint('This feature is not supported yet.');
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.access_time),
                    label: const Text('De tam thoi'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anh dai dien cua ban hien thi cong khai.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circle cutout overlay
class CircleCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: 150,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
