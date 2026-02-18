import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class DownloadHelper {
  static Future<void> downloadImage(String url) async {
    if (kIsWeb) {
      _downloadWeb(url);
    } else {
      await _downloadMobile(url);
    }
  }

  static void _downloadWeb(String url) {
    html.HttpRequest.request(
      url,
      responseType: 'blob',
    ).then((response) {
      final blob = response.response as html.Blob;
      final objectUrl = html.Url.createObjectUrlFromBlob(blob);
      final contentType = response.getResponseHeader('content-type');
      final disposition = response.getResponseHeader('content-disposition');
      final nameFromDisposition = _fileNameFromContentDisposition(disposition);
      final extFromType = _extensionFromContentType(contentType);
      final extFromUrl = _extensionFromUrl(url);
      final extension = extFromType ?? extFromUrl ?? 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = _ensureExtension(
        nameFromDisposition ?? 'image_$timestamp',
        extension,
      );
      final anchor = html.AnchorElement(href: objectUrl)..download = fileName;
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(objectUrl);
    }).catchError((_) {
      html.window.open(url, '_blank');
    });
  }

  static String? _fileNameFromContentDisposition(String? header) {
    if (header == null) {
      return null;
    }
    final utf8Match = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
        .firstMatch(header);
    if (utf8Match != null) {
      return Uri.decodeFull(utf8Match.group(1) ?? '');
    }
    final quotedMatch =
        RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(header);
    if (quotedMatch != null) {
      return quotedMatch.group(1);
    }
    final rawMatch =
        RegExp(r'filename=([^;]+)', caseSensitive: false).firstMatch(header);
    return rawMatch?.group(1)?.trim();
  }

  static String? _extensionFromContentType(String? contentType) {
    if (contentType == null) {
      return null;
    }
    final lower = contentType.toLowerCase();
    if (lower.contains('image/jpeg') || lower.contains('image/jpg')) {
      return 'jpg';
    }
    if (lower.contains('image/jfif')) {
      return 'jpg';
    }
    if (lower.contains('image/png')) {
      return 'png';
    }
    if (lower.contains('image/gif')) {
      return 'gif';
    }
    if (lower.contains('image/webp')) {
      return 'webp';
    }
    if (lower.contains('image/avif')) {
      return 'avif';
    }
    if (lower.contains('image/heic')) {
      return 'heic';
    }
    if (lower.contains('image/heif')) {
      return 'heif';
    }
    return null;
  }

  static String? _extensionFromUrl(String url) {
    final path = Uri.parse(url).path;
    final lastSegment = path.isEmpty ? '' : path.split('/').last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) {
      return null;
    }
    final ext = lastSegment.substring(dotIndex + 1).toLowerCase();
    if (ext.length > 5) {
      return null;
    }
    return ext;
  }

  static String _ensureExtension(String name, String extension) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'image.${extension.toLowerCase()}';
    }
    if (normalized.contains('.') && normalized.split('.').last.isNotEmpty) {
      return normalized;
    }
    return '$normalized.${extension.toLowerCase()}';
  }

  static Future<void> _downloadMobile(String url) async {
    try {
      // Check/Request permission
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // Get temp path
      final tempDir = await getTemporaryDirectory();
      // Try to guess extension
      String ext = 'jpg';
      if (url.contains('.png'))
        ext = 'png';
      else if (url.contains('.gif'))
        ext = 'gif';
      else if (url.contains('.webp')) ext = 'webp';

      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '${tempDir.path}/$fileName';

      // Download
      Get.rawSnackbar(message: '正在下载...', duration: const Duration(seconds: 1));
      await Dio().download(url, path);

      // Save to gallery
      await Gal.putImage(path);
      Get.rawSnackbar(message: '图片已保存到相册');
    } catch (e) {
      Get.rawSnackbar(message: '保存失败: $e');
    }
  }
}
