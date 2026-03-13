import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageDimensions {
  const ImageDimensions({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

class ImageDimensionHelper {
  ImageDimensionHelper._();

  static Future<ImageDimensions?> decode(Uint8List bytes) async {
    ui.Codec? codec;
    ui.FrameInfo? frameInfo;

    try {
      codec = await ui.instantiateImageCodec(bytes);
      frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final width = image.width;
      final height = image.height;

      if (width <= 0 || height <= 0) {
        return null;
      }

      return ImageDimensions(width: width, height: height);
    } catch (_) {
      return null;
    } finally {
      frameInfo?.image.dispose();
      codec?.dispose();
    }
  }
}
