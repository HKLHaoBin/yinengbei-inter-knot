import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class CreateDiscussionEditorPage extends StatelessWidget {
  const CreateDiscussionEditorPage({
    super.key,
    required this.titleController,
    required this.quillController,
    required this.onPickAndUploadImage,
  });

  final TextEditingController titleController;
  final quill.QuillController quillController;
  final VoidCallback onPickAndUploadImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: '标题',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        quill.QuillSimpleToolbar(
          controller: quillController,
          config: quill.QuillSimpleToolbarConfig(
            showFontFamily: false,
            showFontSize: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            toolbarIconAlignment: WrapAlignment.start,
            multiRowsDisplay: false,
            customButtons: [
              quill.QuillToolbarCustomButtonOptions(
                icon: const Icon(Icons.image),
                onPressed: onPickAndUploadImage,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: quill.QuillEditor.basic(
              controller: quillController,
              config: quill.QuillEditorConfig(
                placeholder: '请输入文本',
                padding: const EdgeInsets.all(16),
                embedBuilders: [
                  ...FlutterQuillEmbeds.editorBuilders(
                    imageEmbedConfig: QuillEditorImageEmbedConfig(
                      onImageClicked: (url) {},
                    ),
                  ),
                  const _DividerEmbedBuilder(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerEmbedBuilder extends quill.EmbedBuilder {
  const _DividerEmbedBuilder();

  @override
  String get key => 'divider';

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xff313132),
      ),
    );
  }
}
