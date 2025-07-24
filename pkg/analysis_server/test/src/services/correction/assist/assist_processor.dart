// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/src/correction/assist_processor.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test/test.dart';

import '../../../../abstract_single_unit.dart';
import '../../../../selection_mixin.dart';
import '../../../../utils/test_instrumentation_service.dart';

/// A base class defining support for writing assist processor tests.
abstract class AssistProcessorTest extends AbstractSingleUnitTest
    with SelectionMixin {
  late SourceChange _change;
  late String _resultCode;

  /// Return the kind of assist expected by this class.
  AssistKind get kind;

  /// The workspace in which fixes contributor operates.
  Future<ChangeWorkspace> get workspace async {
    return DartChangeWorkspace([await session]);
  }

  @override
  void addTestSource(String code) {
    super.addTestSource(code);
    setPositionOrRange(0);
  }

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
  /// produces the [expected] code when applied to [testCode]. The map of
  /// [additionallyChangedFiles] can be used to test assists that can modify
  /// more than the test file. The keys are expected to be the paths to the
  /// files that are modified (other than the test file) and the values are
  /// pairs of source code: the states of the code before and after the edits
  /// have been applied.
  ///
  /// Returns the [SourceChange] for the matching assist.
  Future<SourceChange> assertHasAssist(
    String expected, {
    Map<String, List<String>>? additionallyChangedFiles,
    int index = 0,
  }) async {
    setPositionOrRange(index);

    expected = normalizeNewlinesForPlatform(expected);
    additionallyChangedFiles = additionallyChangedFiles?.map(
      (key, value) =>
          MapEntry(key, value.map(normalizeNewlinesForPlatform).toList()),
    );

    // Remove any marker in the expected code. We allow markers to prevent an
    // otherwise empty line from having the leading whitespace be removed.
    expected = TestCode.parse(expected).code;
    var assist = await _assertHasAssist();
    _change = assist.change;
    expect(_change.id, kind.id);
    // apply to "file"
    var fileEdits = _change.edits;
    if (additionallyChangedFiles == null) {
      expect(fileEdits, hasLength(1));
      expect(_change.edits[0].file, testFile.path);
      _resultCode = SourceEdit.applySequence(testCode, _change.edits[0].edits);
      expect(_resultCode, expected);
    } else {
      expect(fileEdits, hasLength(additionallyChangedFiles.length + 1));
      var fileEdit = _change.getFileEdit(testFile.path)!;
      _resultCode = SourceEdit.applySequence(testCode, fileEdit.edits);
      expect(_resultCode, expected);
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

  /// Asserts that there is no [Assist] of the given [kind] at [offset].
  Future<void> assertNoAssist([int index = 0]) async {
    setPositionOrRange(index);
    var assists = await _computeAssists();
    for (var assist in assists) {
      if (assist.kind == kind) {
        fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
  }

  List<LinkedEditSuggestion> expectedSuggestions(
    LinkedEditSuggestionKind kind,
    List<String> values,
  ) {
    return values.map((value) {
      return LinkedEditSuggestion(value, kind);
    }).toList();
  }

  /// Computes assists and verifies that there is an assist of the given kind.
  Future<Assist> _assertHasAssist() async {
    var assists = await _computeAssists();
    for (var assist in assists) {
      if (assist.kind == kind) {
        return assist;
      }
    }
    fail('Expected to find assist $kind in\n${assists.join('\n')}');
  }

  Future<List<Assist>> _computeAssists() async {
    var libraryResult = testLibraryResult;
    if (libraryResult == null) {
      return const [];
    }
    var context = DartAssistContext(
      TestInstrumentationService(),
      await workspace,
      libraryResult,
      testAnalysisResult,
      offset,
      length,
    );
    return await computeAssists(context);
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    var positions = <Position>[];
    for (var search in searchStrings) {
      var offset = _resultCode.indexOf(search);
      positions.add(Position(testFile.path, offset));
    }
    return positions;
  }
}
