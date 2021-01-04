// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Collects information about Semantic Tokens using absolute line/columns and
/// token types/modifiers and encodes them into a [List<int>] in a
/// [SemanticTokens] (a [List<int>]) as described by the LSP spec .
class SemanticTokenEncoder {
  /// Converts [regions]s into LSP [SemanticTokenInfo], splitting multiline tokens
  /// and nested tokens if required.
  List<SemanticTokenInfo> convertHighlights(
      List<HighlightRegion> regions, LineInfo lineInfo, String fileContent) {
    // LSP is zero-based but server is 1-based.
    const lspPositionOffset = -1;

    final tokens = <SemanticTokenInfo>[];

    // Capabilities exist for supporting multiline/overlapping tokens. These
    // could be used if any clients take it up (VS Code does not).
    // - clientCapabilities?.multilineTokenSupport
    // - clientCapabilities?.overlappingTokenSupport
    final allowMultilineTokens = false;
    final allowOverlappingTokens = false;

    Iterable<HighlightRegion> translatedRegions = regions;

    // Remove any tokens that will not be mapped as there's no point further processing
    // them (eg. splitting multiline/overlaps) if they will be dropped.
    translatedRegions = translatedRegions
        .where((region) => highlightRegionTokenTypes.containsKey(region.type));

    if (!allowMultilineTokens) {
      translatedRegions = translatedRegions.expand(
          (region) => _splitMultilineRegions(region, lineInfo, fileContent));
    }

    if (!allowOverlappingTokens) {
      translatedRegions = _splitOverlappingTokens(translatedRegions);
    }

    for (final region in translatedRegions) {
      final tokenType = highlightRegionTokenTypes[region.type];
      final start = lineInfo.getLocation(region.offset);

      tokens.add(SemanticTokenInfo(
        start.lineNumber + lspPositionOffset,
        start.columnNumber + lspPositionOffset,
        region.length,
        tokenType,
        highlightRegionTokenModifiers[region.type],
      ));
    }

    return tokens;
  }

  SemanticTokens encodeTokens(List<SemanticTokenInfo> tokens) {
    final encodedTokens = <int>[];
    var lastLine = 0;
    var lastColumn = 0;

    // Ensure tokens are all sorted by location in file regardless of the order
    // they were registered.
    tokens.sort(SemanticTokenInfo.offsetSort);

    for (final token in tokens) {
      var relativeLine = token.line - lastLine;
      // Column is relative to last only if on the same line.
      var relativeColumn =
          relativeLine == 0 ? token.column - lastColumn : token.column;

      // The resulting array is groups of 5 items as described in the LSP spec:
      // https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/specification-3-16.md#textDocument_semanticTokens
      encodedTokens.addAll([
        relativeLine,
        relativeColumn,
        token.length,
        semanticTokenLegend.indexForType(token.type),
        semanticTokenLegend.bitmaskForModifiers(token.modifiers) ?? 0
      ]);

      lastLine = token.line;
      lastColumn = token.column;
    }

    return SemanticTokens(data: encodedTokens);
  }

  /// Sorted for highlight regions that ensures tokens are sorted in offset order
  /// then longest first, then by priority, and finally by name. This ensures
  /// the order is always stable.
  int _regionOffsetLengthPrioritySorter(
      HighlightRegion r1, HighlightRegion r2) {
    const priorities = {
      // Ensure boolean comes above keyword.
      HighlightRegionType.LITERAL_BOOLEAN: 1,
    };

    // First sort by offset.
    if (r1.offset != r2.offset) {
      return r1.offset.compareTo(r2.offset);
    }

    // Then length (so longest are first).
    if (r1.length != r2.length) {
      return -r1.length.compareTo(r2.length);
    }

    // Next sort by priority (if different).
    final priority1 = priorities[r1.type] ?? 0;
    final priority2 = priorities[r2.type] ?? 0;
    if (priority1 != priority2) {
      return priority1.compareTo(priority2);
    }

    // If the tokens had the same offset and length, sort by name. This
    // is completely arbitrary but it's only important that it is consistent
    // between regions and the sort is stable.
    return r1.type.name.compareTo(r2.type.name);
  }

  /// Splits multiline regions into multiple regions for clients that do not support
  /// multiline tokens.
  Iterable<HighlightRegion> _splitMultilineRegions(
      HighlightRegion region, LineInfo lineInfo, String fileContent) sync* {
    final start = lineInfo.getLocation(region.offset);
    final end = lineInfo.getLocation(region.offset + region.length);

    // Create a region for each line in the original region.
    for (var lineNumber = start.lineNumber;
        lineNumber <= end.lineNumber;
        lineNumber++) {
      final isFirstLine = lineNumber == start.lineNumber;
      final isLastLine = lineNumber == end.lineNumber;
      final isSingleLine = start.lineNumber == end.lineNumber;
      final lineOffset = lineInfo.getOffsetOfLine(lineNumber - 1);

      var startOffset = isFirstLine ? start.columnNumber - 1 : 0;
      var endOffset = isLastLine
          ? end.columnNumber - 1
          : lineInfo.getOffsetOfLine(lineNumber) - lineOffset;
      var length = endOffset - startOffset;

      // When we split multiline tokens, we may end up with leading/trailing
      // whitespace which doesn't make sense to include in the token. Examine
      // the content to remove this.
      if (!isSingleLine) {
        final tokenContent = fileContent.substring(
            lineOffset + startOffset, lineOffset + endOffset);
        final leadingWhitespaceCount =
            tokenContent.length - tokenContent.trimLeft().length;
        final trailingWhitespaceCount =
            tokenContent.length - tokenContent.trimRight().length;

        startOffset += leadingWhitespaceCount;
        endOffset -= trailingWhitespaceCount;
        length = endOffset - startOffset;
      }

      yield HighlightRegion(region.type, lineOffset + startOffset, length);
    }
  }

  Iterable<HighlightRegion> _splitOverlappingTokens(
      Iterable<HighlightRegion> regions) sync* {
    if (regions.isEmpty) {
      return;
    }

    // Sort tokens so by offset, shortest length, priority then name to ensure
    // tne sort is always stable.
    final sortedRegions = regions.toList()
      ..sort(_regionOffsetLengthPrioritySorter);

    final firstRegion = sortedRegions.first;
    final stack = ListQueue<HighlightRegion>()..add(firstRegion);
    var pos = firstRegion.offset;

    for (final current in sortedRegions.skip(1)) {
      if (stack.last != null) {
        final last = stack.last;
        final newPos = current.offset;
        if (newPos - pos > 0) {
          // The previous region ends at either its original end or
          // the position of this next region, whichever is shorter.
          final end = math.min(last.offset + last.length, newPos);
          final length = end - pos;
          yield HighlightRegion(last.type, pos, length);
          pos = newPos;
        }
      }

      stack.addLast(current);
    }

    // Process any remaining stack after the last region.
    while (stack.isNotEmpty) {
      final last = stack.removeLast();
      final newPos = last.offset + last.length;
      final length = newPos - pos;
      if (length > 0) {
        yield HighlightRegion(last.type, pos, length);
        pos = newPos;
      }
    }
  }
}

class SemanticTokenInfo {
  final int line;
  final int column;
  final int length;
  final SemanticTokenTypes type;
  final Set<SemanticTokenModifiers> modifiers;

  SemanticTokenInfo(
      this.line, this.column, this.length, this.type, this.modifiers);

  static int offsetSort(SemanticTokenInfo t1, SemanticTokenInfo t2) =>
      t1.line == t2.line
          ? t1.column.compareTo(t2.column)
          : t1.line.compareTo(t2.line);
}
