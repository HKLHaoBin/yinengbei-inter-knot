import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 压缩格式选项
enum CompressFormatOption {
  /// 标准 JPEG（默认）
  jpeg,
  /// 无损 WebP（实验性）
  losslessWebp,
  /// 高质量 AVIF（实验性）
  highQualityAvif,
}

/// 压缩结果
class CompressionResult {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const CompressionResult({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

/// 上传前自动压缩图片，减少传输体积，提升上传速度。
/// 支持 Web / Android / iOS / macOS。
class ImageCompressHelper {
  ImageCompressHelper._();

  /// 最大边长（像素），超过此值会等比缩放
  static const int _maxDimension = 1920;

  /// JPEG 压缩质量 (0-100)
  static const int _quality = 82;

  /// 低于此大小不压缩（200KB）
  static const int _skipThreshold = 200 * 1024;

  /// AVIF 编码量化器参数 (0-63, 值越小质量越高)
  /// 设置量化器值以达到约 85% 质量
  static const int _avifMaxQuantizer = 20;
  static const int _avifMinQuantizer = 10;

  /// 压缩图片字节数据
  ///
  /// [bytes] 原始图片二进制
  /// [filename] 文件名，用于判断格式
  /// [mimeType] MIME 类型
  /// [formatOption] 压缩格式选项（默认 JPEG）
  ///
  /// 返回压缩结果，包含字节数据、更新后的文件名和 MIME 类型
  static Future<CompressionResult> compress({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'image/jpeg',
    CompressFormatOption formatOption = CompressFormatOption.jpeg,
  }) async {
    // GIF 不压缩（会丢失动画）
    if (_isGif(filename, mimeType)) {
      return CompressionResult(bytes: bytes, filename: filename, mimeType: mimeType);
    }

    // 小图不压缩
    if (bytes.length <= _skipThreshold) {
      return CompressionResult(bytes: bytes, filename: filename, mimeType: mimeType);
    }

    try {
      // AVIF 格式使用 flutter_avif 库编码（Web 平台不支持，降级为 JPEG）
      if (formatOption == CompressFormatOption.highQualityAvif) {
        if (!kIsWeb) {
          final avifBytes = await _compressToAvif(bytes);
          // 更新文件名后缀为 .avif
          final newFilename = _changeExtension(filename, 'avif');
          return CompressionResult(
            bytes: avifBytes,
            filename: newFilename,
            mimeType: 'image/avif',
          );
        } else {
          // Web 平台降级为高质量 JPEG
          debugPrint('[ImageCompress] AVIF not supported on Web, using high quality JPEG instead');
        }
      }

      final CompressFormat format;
      final int quality;
      final String newExtension;
      final String newMimeType;

      switch (formatOption) {
        case CompressFormatOption.losslessWebp:
          format = CompressFormat.webp;
          quality = 100; // 无损 WebP
          newExtension = 'webp';
          newMimeType = 'image/webp';
        case CompressFormatOption.highQualityAvif:
          // Web 平台：降级为高质量 JPEG (quality 90)
          format = CompressFormat.jpeg;
          quality = 90;
          newExtension = 'jpg';
          newMimeType = 'image/jpeg';
        case CompressFormatOption.jpeg:
        default:
          format = _isWebp(filename, mimeType)
              ? CompressFormat.webp
              : _isPng(filename, mimeType)
                  ? CompressFormat.png
                  : CompressFormat.jpeg;
          quality = _quality;
          newExtension = format == CompressFormat.webp
              ? 'webp'
              : format == CompressFormat.png
                  ? 'png'
                  : 'jpg';
          newMimeType = format == CompressFormat.webp
              ? 'image/webp'
              : format == CompressFormat.png
                  ? 'image/png'
                  : 'image/jpeg';
      }

      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: quality,
        format: format,
      );

      // 如果压缩后反而变大，使用原图
      if (result.length >= bytes.length) {
        debugPrint(
            '[ImageCompress] Skipped: compressed ${result.length} >= original ${bytes.length}');
        return CompressionResult(bytes: bytes, filename: filename, mimeType: mimeType);
      }

      final formatName = formatOption == CompressFormatOption.losslessWebp
          ? 'WebP(无损)'
          : 'JPEG';
      debugPrint(
          '[ImageCompress] $formatName: ${bytes.length} -> ${result.length} bytes '
          '(${(100 - result.length * 100 ~/ bytes.length)}% saved)');

      final newFilename = _changeExtension(filename, newExtension);
      return CompressionResult(
        bytes: Uint8List.fromList(result),
        filename: newFilename,
        mimeType: newMimeType,
      );
    } catch (e) {
      debugPrint('[ImageCompress] Failed: $e, using original');
      return CompressionResult(bytes: bytes, filename: filename, mimeType: mimeType);
    }
  }

  /// 使用 flutter_avif 编码为 AVIF 格式
  static Future<Uint8List> _compressToAvif(Uint8List bytes) async {
    try {
      // 使用 flutter_avif 编码为 AVIF
      // 量化器参数：0-63，值越小质量越高
      final avifBytes = await encodeAvif(
        bytes,
        maxQuantizer: _avifMaxQuantizer,
        minQuantizer: _avifMinQuantizer,
        speed: 6, // 编码速度 (0-10)，6 是质量和速度的折中
      );

      // 如果压缩后反而变大，使用原图
      if (avifBytes.length >= bytes.length) {
        debugPrint(
            '[ImageCompress] AVIF Skipped: compressed ${avifBytes.length} >= original ${bytes.length}');
        return bytes;
      }

      debugPrint(
          '[ImageCompress] AVIF(高质量): ${bytes.length} -> ${avifBytes.length} bytes '
          '(${(100 - avifBytes.length * 100 ~/ bytes.length)}% saved)');
      return avifBytes;
    } catch (e) {
      debugPrint('[ImageCompress] AVIF encoding failed: $e, fallback to original');
      return bytes;
    }
  }

  static bool _isGif(String filename, String mimeType) =>
      mimeType.contains('gif') ||
      filename.toLowerCase().endsWith('.gif');

  static bool _isPng(String filename, String mimeType) =>
      mimeType.contains('png') ||
      filename.toLowerCase().endsWith('.png');

  static bool _isWebp(String filename, String mimeType) =>
      mimeType.contains('webp') ||
      filename.toLowerCase().endsWith('.webp');

  /// 更改文件扩展名
  static String _changeExtension(String filename, String newExtension) {
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex == -1) {
      return '$filename.$newExtension';
    }
    return '${filename.substring(0, lastDotIndex + 1)}$newExtension';
  }
}
