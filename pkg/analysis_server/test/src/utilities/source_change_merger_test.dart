// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/utilities/source_change_merger.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceChangeMergerTest);
  });
}

@reflectiveTest
class SourceChangeMergerTest {
  void test_multipleFiles_mergeIndividually() {
    var original = [
      SourceFileEdit('fileA', -1, edits: [SourceEdit(4, 1, '4')]),
      SourceFileEdit('fileB', -1, edits: [SourceEdit(3, 1, '3')]),
      SourceFileEdit('fileA', -1, edits: [SourceEdit(3, 1, '3')]),
      SourceFileEdit('fileB', -1, edits: [SourceEdit(2, 1, '2')]),
    ];
    var expected = [
      SourceFileEdit('fileA', -1, edits: [SourceEdit(3, 2, '34')]),
      SourceFileEdit('fileB', -1, edits: [SourceEdit(2, 2, '23')]),
    ];
    var merged = SourceChangeMerger().merge(original);
    expect(merged, expected);
  }

  void test_multipleFiles_noMerge() {
    var original = [
      SourceFileEdit('fileA', -1, edits: [SourceEdit(2, 1, '2')]),
      SourceFileEdit('fileB', -1, edits: [SourceEdit(1, 1, '1')]),
    ];
    var merged = SourceChangeMerger().merge(original);
    // The resulting edits should be the same with no merging because they
    // are different files.
    expect(merged, original);
  }

  void test_notTouching_singlePass() {
    verifyMerge(
      start: '0123456789',
      expected: '0-12-34-56789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'),
            SourceEdit(3, 1, '-3'),
            SourceEdit(1, 1, '-1'),
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_andLeading() {
    verifyMerge(
      start: '0123456789',
      expected: '01236789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(4, 3, ''), // Delete 4-5
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_andLeadingAndTrailing() {
    verifyMerge(
      start: '0123456789',
      expected: '0123789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(4, 4, ''), // Delete 4-56
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_andTrailing() {
    verifyMerge(
      start: '0123456789',
      expected: '01234789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 3, ''), // Delete -56
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_end() {
    verifyMerge(
      start: '0123456789',
      expected: '01234-6789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(6, 1, ''), // Delete 5
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_exactly() {
    verifyMerge(
      start: '0123456789',
      expected: '012346789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 2, ''), // Delete -5
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_inner() {
    verifyMerge(
      start: '0123456789',
      expected: '01234556789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '5-5'), // Replace 5 with 5-5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(6, 1, ''), // Delete -
          ],
        ),
      ],
    );
  }

  void test_overlap_secondDeletesFirst_start() {
    verifyMerge(
      start: '0123456789',
      expected: '0123456789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, ''), // Delete -
          ],
        ),
      ],
    );
  }

  void test_overlap_secondInsertsIntoFirst() {
    verifyMerge(
      start: '0123456789',
      expected: '01234-056789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(6, 0, '0'), // Insert 0 between - and 5
          ],
        ),
      ],
    );
  }

  void test_overlap_secondInsertsIntoFirst2() {
    verifyMerge(
      start: 'AAAAAAAAAABBBBBBBBBB',
      expected:
          'AAAAAAAAAACCCCCCCCCCEEEEEEEEEEGGGGGGGGGGHHHHHHHHHHFFFFFFFFFFDDDDDDDDDDBBBBBBBBBB',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Insert CD between AB
            SourceEdit(10, 0, 'CCCCCCCCCCDDDDDDDDDD'),
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Insert EF between CD
            SourceEdit(20, 0, 'EEEEEEEEEEFFFFFFFFFF'),
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Insert GH between EF
            SourceEdit(30, 0, 'GGGGGGGGGGHHHHHHHHHH'),
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_andLeading() {
    verifyMerge(
      start: '0123456789',
      expected: '012306789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(4, 3, '0'), // Replace 4-5 with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_andLeadingAndTrailing() {
    verifyMerge(
      start: '0123456789',
      expected: '01230789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(4, 4, '0'), // Replace 4-56 with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_andTrailing() {
    verifyMerge(
      start: '0123456789',
      expected: '012340789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 3, '0'), // Replace -56 with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_end() {
    verifyMerge(
      start: '0123456789',
      expected: '01234-06789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(6, 1, '0'), // Replace 5 with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_exactly() {
    verifyMerge(
      start: '0123456789',
      expected: '0123406789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 2, '0'), // Replace -5 with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_inner() {
    verifyMerge(
      start: '0123456789',
      expected: '012345056789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '5-5'), // Replace 5 with 5-5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(6, 1, '0'), // Replace - with 0
          ],
        ),
      ],
    );
  }

  void test_overlap_secondReplacesFirst_start() {
    verifyMerge(
      start: '0123456789',
      expected: '01234056789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '0'), // Replace - with 0
          ],
        ),
      ],
    );
  }

  void test_touching_deletes() {
    verifyMerge(
      start: '0123456789',
      expected: '06789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Delete 5, 3, 1
            SourceEdit(5, 1, ''),
            SourceEdit(3, 1, ''),
            SourceEdit(1, 1, ''),
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Delete 4, 2
            SourceEdit(2, 1, ''),
            SourceEdit(1, 1, ''),
          ],
        ),
      ],
    );
  }

  void test_touching_inserts() {
    verifyMerge(
      start: '0123456789',
      expected: '0-1-2-3-4-56789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Insert - before 5, 3, 1
            SourceEdit(5, 0, '-'),
            SourceEdit(3, 0, '-'),
            SourceEdit(1, 0, '-'),
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            // Insert - before 4, 2
            SourceEdit(6, 0, '-'),
            SourceEdit(3, 0, '-'),
          ],
        ),
      ],
    );
  }

  void test_touching_mixed() {
    verifyMerge(
      start: '0123456789',
      expected: '01234-60789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, ''), // Delete 5
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-6'), // Change 6 to -6
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(7, 0, '0'), // Insert 0 between -6 and 7
          ],
        ),
      ],
    );
  }

  void test_touching_replacements() {
    verifyMerge(
      start: '0123456789',
      expected: '0-1-2-3-4-56789',
      edits: [
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(5, 1, '-5'), // Replace 5 with -5
            SourceEdit(3, 1, '-3'),
            SourceEdit(1, 1, '-1'),
          ],
        ),
        SourceFileEdit(
          '',
          -1,
          edits: [
            SourceEdit(
              6,
              1,
              '-4',
            ), // 4 is at 6 because of two minuses before it
            SourceEdit(3, 1, '-2'), // 2 is at 3...
          ],
        ),
      ],
    );
  }

  /// Verifies merged edits for a single file.
  void verifyMerge({
    required String start,
    required String expected,
    required List<SourceFileEdit> edits,
  }) {
    // First, apply edits sequentially to ensure the test is configured
    // correctly.
    _validateEdits(edits);
    _verifyAppliedEdits(
      start,
      edits,
      expected,
      'Applying edits sequentially did not produce expected results. '
      'This indicates a bug in the test.',
    );

    // Take a copy of the edits before merging to ensure they are not mutated.
    var originalJson = jsonEncode(edits);

    var debugBuffer = StringBuffer();
    var merged = SourceChangeMerger(debugBuffer: debugBuffer).merge(edits);

    // Ensure the merger didn't mutate the originals.
    expect(jsonEncode(edits), originalJson);

    try {
      _validateMergedEdits(merged);
      _verifyAppliedEdits(
        start,
        merged,
        expected,
        'Applying merged edits did not produce expected results. '
        'This indicates a bug in the merger.',
      );
    } catch (_) {
      print(debugBuffer);
      rethrow;
    }
  }

  /// Verifies that a [SourceFileEdit] meets some expected criteria:
  ///
  /// - Edits are all for the same file
  /// - Edits are ordered from latest offset to earliest
  /// - No edits intersect
  void _validateEdits(List<SourceFileEdit> edits) {
    expect(
      edits.map((edit) => edit.file).toSet(),
      hasLength(1),
      reason: 'All edits should be from the same file',
    );

    for (var fileEdit in edits) {
      var lastOffset = fileEdit.edits.first.offset;
      for (var edit in fileEdit.edits.skip(1)) {
        expect(
          edit.end,
          lessThanOrEqualTo(lastOffset),
          reason:
              'Edits within a SourceFileEdit should be ordered from '
              'last (highest offset) to first (lowest offset) and not overlap',
        );
        lastOffset = edit.offset;
      }
    }
  }

  /// Verifies that merged edits meet some expected criteria:
  ///
  /// - Each file appears only once.
  /// - Edits are ordered from latest offset to earliest
  /// - No edits intersect
  /// - No edits touch
  void _validateMergedEdits(List<SourceFileEdit> edits) {
    expect(
      edits.map((edit) => edit.file).toSet(),
      hasLength(edits.length),
      reason: 'Merged edits should only contain one SourceFileEdit per file',
    );

    for (var fileEdit in edits) {
      var lastOffset = fileEdit.edits.first.offset;
      for (var edit in fileEdit.edits.skip(1)) {
        expect(
          edit.end,
          lessThan(lastOffset),
          reason:
              'Edits within a SourceFileEdit should be ordered from '
              'last (highest offset) to first (lowest offset) and not touch or '
              'overlap',
        );
        lastOffset = edit.offset;
      }
    }
  }

  /// Verifies that [edits] applied to [content] produce [expected].
  void _verifyAppliedEdits(
    String content,
    List<SourceFileEdit> edits,
    String expected,
    String reason,
  ) {
    var result = edits.fold(
      content,
      (content, edit) => SourceEdit.applySequence(content, edit.edits),
    );

    expect(result, expected, reason: reason);
  }
}
