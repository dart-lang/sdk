// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// Collects information about Semantic Tokens using absolute line/columns and
/// token types/modifiers and encodes them into a [List<int>] in a
/// [SemanticTokens] (a [List<int>]) as described by the LSP spec .
class SemanticTokenEncoder {
  // LSP is zero-based but server is 1-based.
  static const _serverToLspLineOffset = -1;

  /// Converts [regions]s into LSP [SemanticTokenInfo].
  List<SemanticTokenInfo> convertHighlightToTokens(
      List<HighlightRegion> regions) {
    final tokens = <SemanticTokenInfo>[];

    Iterable<HighlightRegion> translatedRegions = regions;

    // Remove any tokens that will not be mapped as there's no point further processing
    // them (eg. splitting multiline/overlaps) if they will be dropped.
    translatedRegions = translatedRegions
        .where((region) => highlightRegionTokenTypes.containsKey(region.type));

    for (final region in translatedRegions) {
      final tokenType = highlightRegionTokenTypes[region.type];

      tokens.add(SemanticTokenInfo(
        region.offset,
        region.length,
        tokenType,
        highlightRegionTokenModifiers[region.type],
      ));
    }

    return tokens;
  }

  /// Encodes tokens according to the LSP spec.
  ///
  /// Tokens must be pre-sorted by offset so that relative line/columns are accurate.
  SemanticTokens encodeTokens(
      List<SemanticTokenInfo> sortedTokens, LineInfo lineInfo) {
    final encodedTokens = <int>[];
    var lastLine = 0;
    var lastColumn = 0;

    for (final token in sortedTokens) {
      final location = lineInfo.getLocation(token.offset);
      final tokenLine = location.lineNumber + _serverToLspLineOffset;
      final tokenColumn = location.columnNumber + _serverToLspLineOffset;

      final relativeLine = tokenLine - lastLine;
      // Column is relative to last only if on the same line.
      final relativeColumn =
          relativeLine == 0 ? tokenColumn - lastColumn : tokenColumn;

      // The resulting array is groups of 5 items as described in the LSP spec:
      // https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/specification-3-16.md#textDocument_semanticTokens
      encodedTokens.addAll([
        relativeLine,
        relativeColumn,
        token.length,
        semanticTokenLegend.indexForType(token.type),
        semanticTokenLegend.bitmaskForModifiers(token.modifiers) ?? 0
      ]);

      lastLine = tokenLine;
      lastColumn = tokenColumn;
    }

    return SemanticTokens(data: encodedTokens);
  }

  /// Splits multiline regions into multiple regions for clients that do not support
  /// multiline tokens. Multiline tokens will be split at the end of the line and
  /// line endings and indenting will be included in the tokens.
  Iterable<SemanticTokenInfo> splitMultilineTokens(
      SemanticTokenInfo token, LineInfo lineInfo) sync* {
    final start = lineInfo.getLocation(token.offset);
    final end = lineInfo.getLocation(token.offset + token.length);

    // Create a region for each line in the original region.
    for (var lineNumber = start.lineNumber;
        lineNumber <= end.lineNumber;
        lineNumber++) {
      final isFirstLine = lineNumber == start.lineNumber;
      final isLastLine = lineNumber == end.lineNumber;
      final lineOffset = lineInfo.getOffsetOfLine(lineNumber - 1);

      final startOffset = isFirstLine ? start.columnNumber - 1 : 0;
      final endOffset = isLastLine
          ? end.columnNumber - 1
          : lineInfo.getOffsetOfLine(lineNumber) - lineOffset;
      final length = endOffset - startOffset;

      yield SemanticTokenInfo(
          lineOffset + startOffset, length, token.type, token.modifiers);
    }
  }

  /// Splits overlapping/nested tokens into descrete ranges for the "top-most"
  /// token.
  ///
  /// Tokens must be pre-sorted by offset, with tokens having the same offset sorted
  /// with the longest first.
  Iterable<SemanticTokenInfo> splitOverlappingTokens(
      Iterable<SemanticTokenInfo> sortedTokens) sync* {
    if (sortedTokens.isEmpty) {
      return;
    }

    final firstToken = sortedTokens.first;
    final stack = ListQueue<SemanticTokenInfo>()..add(firstToken);
    var pos = firstToken.offset;

    for (final current in sortedTokens.skip(1)) {
      if (stack.last != null) {
        final last = stack.last;
        final newPos = current.offset;
        if (newPos - pos > 0) {
          // The previous region ends at either its original end or
          // the position of this next region, whichever is shorter.
          final end = math.min(last.offset + last.length, newPos);
          final length = end - pos;
          yield SemanticTokenInfo(pos, length, last.type, last.modifiers);
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
        yield SemanticTokenInfo(pos, length, last.type, last.modifiers);
        pos = newPos;
      }
    }
  }
}

class SemanticTokenInfo {
  final int offset;
  final int length;
  final SemanticTokenTypes type;
  final Set<SemanticTokenModifiers> modifiers;

  SemanticTokenInfo(this.offset, this.length, this.type, this.modifiers);

  /// Sorter for semantic tokens that ensures tokens are sorted in offset order
  /// then longest first, then by priority, and finally by name. This ensures
  /// the order is always stable.
  static int offsetLengthPrioritySort(
      SemanticTokenInfo t1, SemanticTokenInfo t2) {
    final priorities = {
      // Ensure boolean comes above keyword.
      CustomSemanticTokenTypes.boolean: 1,
    };

    // First sort by offset.
    if (t1.offset != t2.offset) {
      return t1.offset.compareTo(t2.offset);
    }

    // Then length (so longest are first).
    if (t1.length != t1.length) {
      return -t1.length.compareTo(t2.length);
    }

    // Next sort by priority (if different).
    final priority1 = priorities[t1.type] ?? 0;
    final priority2 = priorities[t2.type] ?? 0;
    if (priority1 != priority2) {
      return priority1.compareTo(priority2);
    }

    // If the tokens had the same offset and length, sort by name. This
    // is completely arbitrary but it's only important that it is consistent
    // between tokens and the sort is stable.
    return t1.type.toString().compareTo(t2.type.toString());
  }
}
