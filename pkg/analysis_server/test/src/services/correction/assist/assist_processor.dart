// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:test/test.dart';

import '../../../../abstract_single_unit.dart';
import '../../../../utils/test_instrumentation_service.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

/// A base class defining support for writing assist processor tests.
abstract class AssistProcessorTest extends AbstractSingleUnitTest {
  int _offset;
  int _length;

  SourceChange _change;
  String _resultCode;

  /// Return the kind of assist expected by this class.
  AssistKind get kind;

  /// The workspace in which fixes contributor operates.
  ChangeWorkspace get workspace {
    return DartChangeWorkspace([session]);
  }

  @override
  void addTestSource(String code) {
    if (useLineEndingsForPlatform) {
      code = normalizeNewlinesForPlatform(code);
    }
    final eol = code.contains('\r\n') ? '\r\n' : '\n';
    var offset = code.indexOf('/*caret*/');
    if (offset >= 0) {
      var endOffset = offset + '/*caret*/'.length;
      code = code.substring(0, offset) + code.substring(endOffset);
      _offset = offset;
      _length = 0;
    } else {
      var startOffset = code.indexOf('// start$eol');
      var endOffset = code.indexOf('// end$eol');
      if (startOffset >= 0 && endOffset >= 0) {
        var startLength = '// start$eol'.length;
        code = code.substring(0, startOffset) +
            code.substring(startOffset + startLength, endOffset) +
            code.substring(endOffset + '// end$eol'.length);
        _offset = startOffset;
        _length = endOffset - startLength - _offset;
      } else {
        _offset = 0;
        _length = 0;
      }
    }
    super.addTestSource(code);
  }

  void assertExitPosition({String before, String after}) {
    var exitPosition = _change.selection;
    expect(exitPosition, isNotNull);
    expect(exitPosition.file, testFile);
    if (before != null) {
      expect(exitPosition.offset, _resultCode.indexOf(before));
    } else if (after != null) {
      expect(exitPosition.offset, _resultCode.indexOf(after) + after.length);
    } else {
      fail("One of 'before' or 'after' expected.");
    }
  }

  /// Asserts that there is an assist of the given [kind] at [_offset] which
  /// produces the [expected] code when applied to [testCode]. The map of
  /// [additionallyChangedFiles] can be used to test assists that can modify
  /// more than the test file. The keys are expected to be the paths to the
  /// files that are modified (other than the test file) and the values are
  /// pairs of source code: the states of the code before and after the edits
  /// have been applied.
  Future<void> assertHasAssist(String expected,
      {Map<String, List<String>> additionallyChangedFiles}) async {
    if (useLineEndingsForPlatform) {
      expected = normalizeNewlinesForPlatform(expected);
      additionallyChangedFiles = additionallyChangedFiles?.map((key, value) =>
          MapEntry(key, value.map(normalizeNewlinesForPlatform).toList()));
    }
    var assist = await _assertHasAssist();
    _change = assist.change;
    expect(_change.id, kind.id);
    // apply to "file"
    var fileEdits = _change.edits;
    if (additionallyChangedFiles == null) {
      expect(fileEdits, hasLength(1));
      _resultCode = SourceEdit.applySequence(testCode, _change.edits[0].edits);
      expect(_resultCode, expected);
    } else {
      expect(fileEdits, hasLength(additionallyChangedFiles.length + 1));
      _resultCode = SourceEdit.applySequence(
          testCode, _change.getFileEdit(testFile).edits);
      expect(_resultCode, expected);
      for (var filePath in additionallyChangedFiles.keys) {
        var pair = additionallyChangedFiles[filePath];
        var resultCode = SourceEdit.applySequence(
            pair[0], _change.getFileEdit(filePath).edits);
        expect(resultCode, pair[1]);
      }
    }
  }

  /// Asserts that there is an [Assist] of the given [kind] at the offset of the
  /// given [snippet] which produces the [expected] code when applied to [testCode].
  Future<void> assertHasAssistAt(String snippet, String expected,
      {int length = 0}) async {
    if (useLineEndingsForPlatform) {
      expected = normalizeNewlinesForPlatform(expected);
    }
    _offset = findOffset(snippet);
    _length = length;
    var assist = await _assertHasAssist();
    _change = assist.change;
    expect(_change.id, kind.id);
    // apply to "file"
    var fileEdits = _change.edits;
    expect(fileEdits, hasLength(1));
    _resultCode = SourceEdit.applySequence(testCode, _change.edits[0].edits);
    expect(_resultCode, expected);
  }

  void assertLinkedGroup(int groupIndex, List<String> expectedStrings,
      [List<LinkedEditSuggestion> expectedSuggestions]) {
    var group = _change.linkedEditGroups[groupIndex];
    var expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /// Asserts that there is no [Assist] of the given [kind] at [_offset].
  Future<void> assertNoAssist() async {
    var assists = await _computeAssists();
    for (var assist in assists) {
      if (assist.kind == kind) {
        fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
  }

  /// Asserts that there is no [Assist] of the given [kind] at the offset of the
  /// given [snippet].
  Future<void> assertNoAssistAt(String snippet, {int length = 0}) async {
    _offset = findOffset(snippet);
    _length = length;
    var assists = await _computeAssists();
    for (var assist in assists) {
      if (assist.kind == kind) {
        fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
  }

  List<LinkedEditSuggestion> expectedSuggestions(
      LinkedEditSuggestionKind kind, List<String> values) {
    return values.map((value) {
      return LinkedEditSuggestion(value, kind);
    }).toList();
  }

  @override
  void setUp() {
    super.setUp();
    useLineEndingsForPlatform = true;
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
    var context = DartAssistContextImpl(
      TestInstrumentationService(),
      workspace,
      testAnalysisResult,
      _offset,
      _length,
    );
    var processor = AssistProcessor(context);
    return await processor.compute();
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    var positions = <Position>[];
    for (var search in searchStrings) {
      var offset = _resultCode.indexOf(search);
      positions.add(Position(testFile, offset));
    }
    return positions;
  }
}
