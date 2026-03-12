import 'package:flutter/material.dart';
import 'package:inter_knot/components/zzz_desktop_action_button.dart';

class CreateDiscussionDesktopFooter extends StatelessWidget {
  const CreateDiscussionDesktopFooter({
    super.key,
    required this.isSavingDraft,
    required this.isPublishing,
    required this.onSubmit,
    this.submitEnabled = true,
    this.showCompressionToggle = false,
    this.compressBeforeUpload = true,
    this.onCompressionChanged,
  });

  final bool isSavingDraft;
  final bool isPublishing;
  final VoidCallback onSubmit;
  final bool submitEnabled;
  final bool showCompressionToggle;
  final bool compressBeforeUpload;
  final ValueChanged<bool>? onCompressionChanged;

  @override
  Widget build(BuildContext context) {
    final isBusy = isSavingDraft || isPublishing;
    final buttonEnabled = submitEnabled && !isBusy;
    final buttonLabel = isPublishing
        ? '发布中'
        : isSavingDraft
            ? '保存草稿中'
            : '发布';
    final buttonIcon = isSavingDraft ? Icons.save_outlined : Icons.add;

    return Container(
      margin: const EdgeInsets.only(
        left: 8,
        right: 16,
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff070707),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showCompressionToggle)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xff121212),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xff2A2A2A)),
                  ),
                  child: Row(
                    children: [
                      _CompressionOption(
                        label: '图片压缩',
                        selected: compressBeforeUpload,
                        onTap: isPublishing
                            ? null
                            : () => onCompressionChanged
                                ?.call(!compressBeforeUpload),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          ZzzDesktopActionButton(
            icon: buttonIcon,
            label: buttonLabel,
            width: 188,
            enabled: buttonEnabled,
            isLoading: isPublishing,
            onTap: buttonEnabled ? () => onSubmit() : null,
          ),
        ],
      ),
    );
  }
}

class _CompressionOption extends StatelessWidget {
  const _CompressionOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xffD7FF00) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
