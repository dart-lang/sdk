// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol.dart';
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
      tokens.add(SemanticTokenInfo(
        region.offset,
        region.length,
        highlightRegionTokenTypes[region.type]!,
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
        semanticTokenLegend.bitmaskForModifiers(token.modifiers)
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

  /// Splits overlapping/nested tokens into discrete ranges for the "top-most"
  /// token.
  ///
  /// Tokens must be pre-sorted by offset, with tokens having the same offset
  /// sorted with the longest first.
  Iterable<SemanticTokenInfo> splitOverlappingTokens(
      Iterable<SemanticTokenInfo> sortedTokens) sync* {
    if (sortedTokens.isEmpty) {
      return;
    }

    final stack = ListQueue<SemanticTokenInfo>();

    /// Yields tokens for anything on the stack from between [fromOffset]
    /// and [toOffset].
    Iterable<SemanticTokenInfo> processStack(
        int fromOffset, int toOffset) sync* {
      // Process each item on the stack to figure out if we need to send
      // a token for it, and pop it off the stack if we've passed the end of it.
      while (stack.isNotEmpty) {
        final last = stack.last;
        final lastEnd = last.offset + last.length;
        final end = math.min(lastEnd, toOffset);
        final length = end - fromOffset;
        if (length > 0) {
          yield SemanticTokenInfo(
              fromOffset, length, last.type, last.modifiers);
          fromOffset = end;
        }

        // If this token is completely done with, remove it and continue
        // through the stack. Otherwise, if this token remains then we're done
        // for now.
        if (lastEnd <= toOffset) {
          stack.removeLast();
        } else {
          return;
        }
      }
    }

    var lastPos = sortedTokens.first.offset;
    for (final current in sortedTokens) {
      // Before processing each token, process the stack as there may be tokens
      // on it that need filling in the gap up until this point.
      yield* processStack(lastPos, current.offset);

      // Add this token to the stack but don't process it, it will be done by
      // the next iteration processing the stack since we don't know where this
      // one should end until we see the start of the next one.
      stack.addLast(current);
      lastPos = current.offset;
    }

    // Process any remaining stack after the last region.
    if (stack.isNotEmpty) {
      yield* processStack(lastPos, stack.first.offset + stack.first.length);
    }
  }
}

class SemanticTokenInfo {
  final int offset;
  final int length;
  final SemanticTokenTypes type;
  final Set<SemanticTokenModifiers>? modifiers;

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
    if (t1.length != t2.length) {
      return -t1.length.compareTo(t2.length);
    }

    // Next sort by priority (if different).
    final priority1 = priorities[t1.type] ?? 0;
    final priority2 = priorities[t2.type] ?? 0;
    if (priority1 != priority2) {
      return priority1.compareTo(priority2);
    }

    // The code below ensures consistent results for users, but ideally we don't
    // get here, so use an assert to fail any tests/debug builds if we failed
    // to sort based on the offset/length/priorities above.
    assert(
      false,
      'Failed to resolve semantic token ordering by offset/length/priority:\n'
      '${t1.offset}:${t1.length} ($priority1) - ${t1.type} / ${t1.modifiers?.join(', ')}\n'
      '${t2.offset}:${t2.length} ($priority2) - ${t2.type} / ${t2.modifiers?.join(', ')}\n'
      'Perhaps an explicit priority needs to be added?',
    );

    // If the tokens had the same offset and length, sort by name. This
    // is completely arbitrary but it's only important that it is consistent
    // between tokens and the sort is stable.
    return t1.type.toString().compareTo(t2.type.toString());
  }
}
