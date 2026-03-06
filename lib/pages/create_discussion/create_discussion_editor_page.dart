import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inter_knot/components/image_viewer.dart';
import 'package:inter_knot/helpers/upload_task.dart';

class CreateDiscussionEditorPage extends StatelessWidget {
  const CreateDiscussionEditorPage({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.onPickAndUploadImage,
    this.isMobile = false,
    this.mobileUploadTasks,
    this.onRemoveMobileImage,
    this.onRetryMobileImage,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final VoidCallback onPickAndUploadImage;

  // Mobile-only
  final bool isMobile;
  final RxList<UploadTask>? mobileUploadTasks;
  final void Function(int index)? onRemoveMobileImage;
  final void Function(UploadTask task)? onRetryMobileImage;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return _MobileEditorBody(
        titleController: titleController,
        bodyController: bodyController,
        uploadTasks: mobileUploadTasks!,
        onRemoveImage: onRemoveMobileImage!,
        onRetryImage: onRetryMobileImage!,
      );
    }

    return _DesktopEditorBody(
      titleController: titleController,
      bodyController: bodyController,
      onPickAndUploadImage: onPickAndUploadImage,
    );
  }
}

class _DesktopEditorBody extends StatefulWidget {
  const _DesktopEditorBody({
    required this.titleController,
    required this.bodyController,
    required this.onPickAndUploadImage,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final VoidCallback onPickAndUploadImage;

  @override
  State<_DesktopEditorBody> createState() => _DesktopEditorBodyState();
}

class _DesktopEditorBodyState extends State<_DesktopEditorBody> {
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();

  @override
  void dispose() {
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.titleController,
          focusNode: _titleFocus,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            hintText: '请输入标题',
            hintStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff505050),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
        const Divider(height: 1, color: Color(0xff2A2A2A)),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: widget.onPickAndUploadImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('插入图片'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '正文按 Markdown 原文保存，换行和空行会按输入保留。',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff2A2A2A)),
            ),
            child: TextField(
              controller: widget.bodyController,
              focusNode: _bodyFocus,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xffE0E0E0),
                height: 1.7,
              ),
              decoration: const InputDecoration(
                hintText: '说点什么吧...\n\n支持 Markdown，例如：\n# 标题\n- 列表\n![图片](url)',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Color(0xff505050),
                  height: 1.6,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileEditorBody extends StatefulWidget {
  const _MobileEditorBody({
    required this.titleController,
    required this.bodyController,
    required this.uploadTasks,
    required this.onRemoveImage,
    required this.onRetryImage,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final RxList<UploadTask> uploadTasks;
  final void Function(int index) onRemoveImage;
  final void Function(UploadTask task) onRetryImage;

  @override
  State<_MobileEditorBody> createState() => _MobileEditorBodyState();
}

class _MobileEditorBodyState extends State<_MobileEditorBody> {
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();

  @override
  void dispose() {
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        TextField(
          controller: widget.titleController,
          focusNode: _titleFocus,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            hintText: '请输入标题',
            hintStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff505050),
            ),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const Divider(height: 1, color: Color(0xff2A2A2A)),
        // Body text field
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: widget.bodyController,
                  focusNode: _bodyFocus,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xffE0E0E0),
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText: '说点什么吧...',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Color(0xff505050),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                // Inline image thumbnails with upload status
                Obx(() {
                  if (widget.uploadTasks.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(widget.uploadTasks.length, (i) {
                        final task = widget.uploadTasks[i];
                        return _MobileImageTile(
                          task: task,
                          allTasks: widget.uploadTasks,
                          onRemove: () => widget.onRemoveImage(i),
                          onRetry: () => widget.onRetryImage(task),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileImageTile extends StatelessWidget {
  const _MobileImageTile({
    required this.task,
    required this.allTasks,
    required this.onRemove,
    required this.onRetry,
  });

  final UploadTask task;
  final List<UploadTask> allTasks;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = task.status.value;
      final progress = task.progress.value;

      return SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          children: [
            // Preview image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildPreview(context, status),
            ),
            // Overlay for non-done states
            if (status != UploadStatus.done)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: _buildIndicator(status, progress),
                    ),
                  ),
                ),
              ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
            // Retry button for errors
            if (status == UploadStatus.error)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffD7FF00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '重试',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _openImageViewer(BuildContext context) {
    final doneTasks = allTasks
        .where((t) => t.status.value == UploadStatus.done && t.serverUrl != null)
        .toList();
    final doneUrls = doneTasks.map((t) => t.serverUrl!).toList();
    final doneIndex = doneTasks.indexWhere((t) => t.localId == task.localId);

    if (doneUrls.isEmpty) return;

    ImageViewer.show(
      context,
      imageUrls: doneUrls,
      initialIndex: doneIndex >= 0 ? doneIndex : 0,
    );
  }

  Widget _buildPreview(BuildContext context, UploadStatus status) {
    if (status == UploadStatus.done && task.serverUrl != null) {
      return GestureDetector(
        onTap: () => _openImageViewer(context),
        child: Image.network(
          task.serverUrl!,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 90,
            height: 90,
            color: const Color(0xff2A2A2A),
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    if (task.localPreviewBytes != null) {
      return Image.memory(
        task.localPreviewBytes!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          height: 90,
          color: const Color(0xff2A2A2A),
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      );
    }
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xff2A2A2A),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Widget _buildIndicator(UploadStatus status, int progress) {
    switch (status) {
      case UploadStatus.pending:
      case UploadStatus.compressing:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: status == UploadStatus.compressing
                ? const Color(0xffFBC02D)
                : const Color(0xffD7FF00),
          ),
        );
      case UploadStatus.uploading:
        return SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 2.5,
                backgroundColor: Colors.white24,
                color: const Color(0xffD7FF00),
              ),
              Center(
                child: Text(
                  '$progress%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      case UploadStatus.error:
        return const Icon(Icons.error_outline, color: Colors.redAccent, size: 24);
      case UploadStatus.done:
        return const SizedBox.shrink();
    }
  }
}
