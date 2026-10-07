// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_testing/correction/assist_processor.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

/// A base class defining support for writing assist processor tests for
/// built-in assist processors.
abstract class BuiltInAssistProcessorTest extends AssistProcessorTest {
  late SourceChange _change;
  late String _resultCode;

  void assertExitPosition({String? before, String? after}) {
    var exitPosition = _change.selection!;
    expect(exitPosition.file, testFile.path);
    if (before != null) {
      expect(exitPosition.offset, _resultCode.indexOf(before));
    } else if (after != null) {
      expect(exitPosition.offset, _resultCode.indexOf(after) + after.length);
    } else {
      fail("One of 'before' or 'after' expected.");
    }
  }

  /// Asserts that there is an assist of the given [kind] at [offset] which
  /// produces the [expected] code when applied to [testCode].
  ///
  /// The map of [additionallyChangedFiles] can be used to test assists that can
  /// modify more than the test file. The keys are expected to be the paths to
  /// the files that are modified (other than the test file) and the values are
  /// pairs of source code: the states of the code before and after the edits
  /// have been applied.
  ///
  /// Returns the [SourceChange] for the matching assist.
  @override
  Future<SourceChange> assertHasAssist(
    String expected, {
    Map<String, List<String>>? additionallyChangedFiles,
    int index = 0,
  }) async {
    _change = await super.assertHasAssist(expected, index: index);
    var fileEdit = _change.getFileEdit(testFile.path)!;
    _resultCode = SourceEdit.applySequence(testCode, fileEdit.edits);
    var fileEdits = _change.edits;
    if (additionallyChangedFiles == null) {
      expect(fileEdits, hasLength(1));
    } else {
      additionallyChangedFiles = additionallyChangedFiles.map(
        (key, value) =>
            MapEntry(key, value.map(normalizeNewlinesForPlatform).toList()),
      );
      expect(fileEdits, hasLength(additionallyChangedFiles.length + 1));
      for (var additionalEntry in additionallyChangedFiles.entries) {
        var filePath = additionalEntry.key;
        var pair = additionalEntry.value;
        var fileEdit = _change.getFileEdit(filePath)!;
        var resultCode = SourceEdit.applySequence(pair[0], fileEdit.edits);
        expect(resultCode, pair[1]);
      }
    }
    return _change;
  }

  void assertLinkedGroup(
    int groupIndex,
    List<String> expectedStrings, [
    List<LinkedEditSuggestion>? expectedSuggestions,
  ]) {
    var group = _change.linkedEditGroups[groupIndex];
    var expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Creates a list of [LinkedEditSuggestion]s of the given [kind] for each
  /// string in [values].
  List<LinkedEditSuggestion> expectedSuggestions(
    LinkedEditSuggestionKind kind,
    List<String> values,
  ) {
    return values.map((value) {
      return LinkedEditSuggestion(value, kind);
    }).toList();
  }

  @override
  void setUp() {
    registerLintRules();
    registerBuiltInAssistGenerators();
    registerBuiltInFixGenerators();
    super.setUp();
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    return [
      for (var search in searchStrings)
        Position(testFile.path, _resultCode.indexOf(search)),
    ];
  }
}
