import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 显示通用 Toast 提示
///
/// [message] 提示内容
/// [isError] 是否为错误提示（红色背景）
/// [duration] 显示时长，默认 3 秒
void showToast(
  String message, {
  bool isError = false,
  Duration? duration,
}) {
  final context = Get.context;
  if (context == null) return;

  final width = context.width;
  // 简单的桌面端判断，宽度大于 800 视为桌面/平板宽屏模式
  final isDesktop = width >= 800;

  // 桌面端 Toast 宽度
  const toastWidth = 360.0;
  // 桌面端右侧边距
  const rightMargin = 24.0;
  // 计算左侧边距以实现靠右对齐
  final leftMargin = width - toastWidth - rightMargin;

  Get.rawSnackbar(
    messageText: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    snackPosition: SnackPosition.TOP,
    // 如果是桌面端，通过 margin 控制位置和宽度
    // 如果是移动端，自适应宽度
    margin: isDesktop
        ? EdgeInsets.only(
            top: 78,
            right: rightMargin,
            left: leftMargin > 0 ? leftMargin : rightMargin,
          )
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    borderRadius: 12,
    backgroundColor: isError
        ? Colors.red.withValues(alpha: 0.9)
        : const Color(0xff333333).withValues(alpha: 0.95),
    duration: duration ?? const Duration(seconds: 3),
    animationDuration: const Duration(milliseconds: 300),
    snackStyle: SnackStyle.FLOATING,
  );
}
