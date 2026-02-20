import 'package:flutter/services.dart';
import 'package:inter_knot/helpers/logger.dart';
import 'package:inter_knot/helpers/toast.dart';

Future<bool> copyText(String text, {String? msg, String? title}) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    showToast(msg ?? '复制成功');
    return true;
  } catch (e, s) {
    logger.e('Copy failed', stackTrace: s, error: e);
    showToast('复制失败', isError: true);
    return false;
  }
}
