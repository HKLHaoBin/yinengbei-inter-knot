import 'package:flutter_test/flutter_test.dart';
import 'package:inter_knot/helpers/markdown_import.dart';

void main() {
  group('looksLikeMarkdown', () {
    test('detects block markdown', () {
      expect(looksLikeMarkdown('# Title\n\n- item'), isTrue);
    });

    test('detects link-heavy inline markdown', () {
      expect(
        looksLikeMarkdown('See **bold** and [link](https://example.com).'),
        isTrue,
      );
    });

    test('ignores regular plain text', () {
      expect(
        looksLikeMarkdown('This is a regular paragraph without markdown cues.'),
        isFalse,
      );
    });
  });

  group('markdownToDocumentDelta', () {
    test('converts heading markdown to structured delta', () {
      final delta = markdownToDocumentDelta('# Title');
      final ops = delta.toJson();

      expect(ops, isNotEmpty);
      expect(ops.first['insert'], 'Title');
      expect(ops.last['attributes'], containsPair('header', 1));
    });
  });
}
