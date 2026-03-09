import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

final _markdownDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubWeb,
);

bool looksLikeMarkdown(String text) {
  final input = text.trim();
  if (input.isEmpty) return false;

  const inlinePatterns = [
    r'(^|[\s(])\*\*[^*\n]+?\*\*(?=$|[\s).,!?])',
    r'(^|[\s(])\*[^*\n]+?\*(?=$|[\s).,!?])',
    r'(^|[\s(])~~[^~\n]+?~~(?=$|[\s).,!?])',
    r'`[^`\n]+`',
    r'!\[[^\]]*]\([^)]+\)',
    r'\[[^\]]+]\([^)]+\)',
  ];

  const blockPatterns = [
    r'^\s{0,3}#{1,6}\s+\S',
    r'^\s{0,3}>\s+\S',
    r'^\s{0,3}[-*+]\s+\[[ xX]\]\s+\S',
    r'^\s{0,3}[-*+]\s+\S',
    r'^\s{0,3}\d+\.\s+\S',
    r'^\s{0,3}```',
    r'^\s{0,3}(?:---|\*\*\*|___)\s*$',
  ];

  for (final pattern in blockPatterns) {
    if (RegExp(pattern, multiLine: true).hasMatch(input)) {
      return true;
    }
  }

  var inlineMatches = 0;
  for (final pattern in inlinePatterns) {
    if (RegExp(pattern, multiLine: true).hasMatch(input)) {
      inlineMatches++;
      if (inlineMatches >= 2 || input.contains('\n')) {
        return true;
      }
    }
  }

  return false;
}

Delta markdownToDocumentDelta(String markdown) {
  final delta = MarkdownToDelta(markdownDocument: _markdownDocument)
      .convert(markdown);
  return delta;
}
