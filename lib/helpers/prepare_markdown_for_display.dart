String prepareMarkdownForDisplay(String input) {
  const blankLinePlaceholder = '\u200B';
  final lines = input.replaceAll('\r\n', '\n').split('\n');
  final output = <String>[];
  var blankLineCount = 0;
  var inFence = false;

  void flushBlankLines() {
    if (blankLineCount == 0) return;
    output.add('');
    for (var i = 1; i < blankLineCount; i++) {
      output.add(blankLinePlaceholder);
      output.add('');
    }
    blankLineCount = 0;
  }

  for (final line in lines) {
    final trimmed = line.trimLeft();
    final isFenceDelimiter =
        trimmed.startsWith('```') || trimmed.startsWith('~~~');

    if (!inFence && line.isEmpty) {
      blankLineCount++;
      continue;
    }

    if (!inFence) {
      flushBlankLines();
    }

    output.add(line);

    if (isFenceDelimiter) {
      inFence = !inFence;
    }
  }

  if (!inFence) {
    flushBlankLines();
  }

  return output.join('\n');
}
