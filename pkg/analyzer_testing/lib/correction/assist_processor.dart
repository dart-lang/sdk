// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/src/correction/assist_processor.dart'; // ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/change_workspace.dart'; // ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart'; // ignore: implementation_imports
import 'package:analyzer/src/test_utilities/platform.dart'; // ignore: implementation_imports
import 'package:analyzer/src/test_utilities/test_code_format.dart'; // ignore: implementation_imports
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_testing/src/selection_mixin.dart';
import 'package:analyzer_testing/src/single_unit.dart';
import 'package:analyzer_testing/src/test_instrumentation_service.dart';
import 'package:test/test.dart';

/// A base class defining support for writing assist processor tests.
abstract class AssistProcessorTest extends SingleUnitTest with SelectionMixin {
  /// The kind of assist expected by this test class.
  AssistKind get kind;

  /// The workspace in which the assist contributor operates.
  Future<ChangeWorkspace> get workspace async =>
      DartChangeWorkspace([await session]);

  @override
  void addTestSource(String code) {
    super.addTestSource(code);
    setPositionOrRange(0);
  }

  /// Asserts that there is an assist of the given [kind] at [offset] which
  /// produces the [expected] code when applied to [testCode].
  ///
  /// If [index] is provided, selects the position or range marker at [index] in
  /// [parsedTestCode] before computing assists.
  ///
  /// Returns the [SourceChange] for the matching assist.
  Future<SourceChange> assertHasAssist(String expected, {int index = 0}) async {
    setPositionOrRange(index);

    expected = normalizeNewlinesForPlatform(expected);

    // Remove any marker in the expected code. We allow markers to prevent an
    // otherwise empty line from having the leading whitespace be removed.
    expected = TestCode.parse(expected).code;
    var assist = await _assertHasAssist();
    var change = assist.change;
    expect(change.id, kind.id);
    // Apply to `testFile`.
    var fileEdit = change.getFileEdit(testFile.path);
    expect(fileEdit, isNotNull);
    var resultCode = SourceEdit.applySequence(testCode, fileEdit!.edits);
    expect(resultCode, expected);
    return change;
  }

  /// Asserts that there is no [Assist] of the given [kind] at the selection
  /// corresponding to the position or range marker at [index].
  Future<void> assertNoAssist([int index = 0]) async {
    setPositionOrRange(index);
    var assists = await _computeAssists();
    for (var assist in assists) {
      if (assist.kind == kind) {
        fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
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
}
