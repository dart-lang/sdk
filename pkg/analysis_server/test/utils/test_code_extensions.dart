// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show Position, Range;
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart' show expect;

extension ListTestCodePositionExtension on List<TestCodePosition> {
  /// Return the LSP [Position]s of the markers.
  ///
  /// Positions are based on [TestCode.code], with all parsed markers removed.
  List<Position> get positions => map((position) => position.position).toList();
}

extension ListTestCodeRangeExtension on List<TestCodeRange> {
  /// The LSP [Range]s indicated by the markers.
  ///
  /// Ranges are based on [TestCode.code], with all parsed markers removed.
  List<Range> get ranges => map((range) => range.range).toList();
}

extension TestCodeExtension on TestCode {
  /// Return the offsets of all [positions].
  List<int> get positionOffsets => positions.map((p) => p.offset).toList();

  /// Verifies that [actualRanges] match with the marked ranges in [code].
  ///
  /// This is done by taking the resulting code (without markers) and then
  /// inserting the range markers from [actualRanges] and performing a string
  /// comparison.
  ///
  /// This can result in a simpler failure message/diff than having the JSON of
  /// a large [List<Range>] dumped.
  void verifyRanges(Iterable<Range> actualRanges) {
    // First rewrite the marked code to have only ranges, and using the indexed
    // markers. This removes any `^` we won't be verifing and changes any
    // range shorthand to indexed tokens.
    var expected = _withRanges(ranges.map((range) => range.range));

    // Now build the same with the actual result ranges.
    var actual = _withRanges(actualRanges);

    expect(actual, expected);
  }

  /// Replaces all marked positions and ranges with [ranges].
  String _withRanges(Iterable<Range> newRanges) {
    var insertedCharacters = 0;
    var rangeIndex = 0;
    var newContent = code; // Start from the unmarked code.
    var lineInfo = LineInfo.fromContent(newContent);

    /// Helper to insert the markers for [range] into the content.
    void markRange(Range range) {
      /// Helper to insert [text] at [offset] in the content.
      void insertText(int offset, String text) {
        var adjustedOffset = insertedCharacters + offset;
        newContent = newContent.replaceRange(
          adjustedOffset,
          adjustedOffset,
          text,
        );
        insertedCharacters += text.length;
      }

      var startOffset = toOffset(lineInfo, range.start).result;
      var endOffset = toOffset(lineInfo, range.end).result;
      insertText(startOffset, '/*[$rangeIndex*/');
      insertText(endOffset, '/*$rangeIndex]*/');
      rangeIndex++;
    }

    var sortedRanges = newRanges.sortedBy(
      (range) => toOffset(lineInfo, range.start).result,
    );
    sortedRanges.forEach(markRange);

    return newContent;
  }
}

extension TestCodePositionExtension on TestCodePosition {
  /// Return the LSP [Position] of the marker.
  ///
  /// Positions are based on [TestCode.code], with all parsed markers removed.
  Position get position => toPosition(lineInfo.getLocation(offset));
}

extension TestCodeRangeExtension on TestCodeRange {
  /// The LSP [Range] indicated by the markers.
  ///
  /// Ranges are based on [TestCode.code], with all parsed markers removed.
  Range get range => toRange(lineInfo, sourceRange.offset, sourceRange.length);
}
