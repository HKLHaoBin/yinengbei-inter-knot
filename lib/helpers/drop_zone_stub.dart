import 'dart:typed_data';

typedef OnDropImageCallback = void Function(String filename, Uint8List bytes, String mimeType);
typedef OnDragStatusCallback = void Function(bool isDragging);

/// 空实现（非 Web 平台）
void setupDropZone({
  required OnDropImageCallback onDropImage,
  OnDragStatusCallback? onDragStatusChanged,
}) {}

/// 空实现（非 Web 平台）
void removeDropZone() {}
