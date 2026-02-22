import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

typedef OnDropImageCallback = void Function(String filename, Uint8List bytes, String mimeType);
typedef OnDragStatusCallback = void Function(bool isDragging);

web.EventListener? _dragOverListener;
web.EventListener? _dragLeaveListener;
web.EventListener? _dropListener;

/// 设置拖拽事件监听（Web 平台）
void setupDropZone({
  required OnDropImageCallback onDropImage,
  OnDragStatusCallback? onDragStatusChanged,
}) {
  // 阻止默认拖拽行为
  _dragOverListener = (web.Event event) {
    event.preventDefault();
    onDragStatusChanged?.call(true);
  }.toJS;

  _dragLeaveListener = (web.Event event) {
    event.preventDefault();
    onDragStatusChanged?.call(false);
  }.toJS;

  _dropListener = (web.Event event) {
    event.preventDefault();
    onDragStatusChanged?.call(false);

    final dropEvent = event as web.DragEvent;
    final dataTransfer = dropEvent.dataTransfer;
    if (dataTransfer == null) return;

    final files = dataTransfer.files;
    if (files.length == 0) return;

    final length = files.length;
    for (var i = 0; i < length; i++) {
      final file = files.item(i);
      if (file == null) continue;

      final mimeType = file.type;
      if (!mimeType.startsWith('image/')) continue;

      final reader = web.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onloadend = (web.Event _) {
        final result = reader.result;
        if (result != null) {
          final bytes = (result as JSArrayBuffer).toDart.asUint8List();
          onDropImage(file.name, bytes, mimeType);
        }
      }.toJS;
    }
  }.toJS;

  // 添加到 document 和 window
  web.document.addEventListener('dragover', _dragOverListener);
  web.document.addEventListener('dragleave', _dragLeaveListener);
  web.document.addEventListener('drop', _dropListener);
}

/// 移除拖拽事件监听
void removeDropZone() {
  if (_dragOverListener != null) {
    web.document.removeEventListener('dragover', _dragOverListener);
    _dragOverListener = null;
  }
  if (_dragLeaveListener != null) {
    web.document.removeEventListener('dragleave', _dragLeaveListener);
    _dragLeaveListener = null;
  }
  if (_dropListener != null) {
    web.document.removeEventListener('drop', _dropListener);
    _dropListener = null;
  }
}
