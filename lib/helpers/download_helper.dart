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
    try {
      // Try to download by creating an anchor element
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'image_${DateTime.now().millisecondsSinceEpoch}';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      // Fallback: just open in new tab
      html.window.open(url, '_blank');
    }
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
      if (url.contains('.png')) ext = 'png';
      else if (url.contains('.gif')) ext = 'gif';
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
