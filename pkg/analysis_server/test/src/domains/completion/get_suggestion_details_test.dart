// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionDetailsTest);
  });
}

@reflectiveTest
class GetSuggestionDetailsTest extends AvailableSuggestionsBase {
  test_dart_existingImport() async {
    addTestFile(r'''
import 'dart:math';

main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      id: mathSet.id,
      label: 'sin',
      offset: testCode.indexOf('} // ref'),
    );

    expect(result.completion, 'sin');
    _assertEmptyChange(result.change);
  }

  test_dart_existingImport_prefixed() async {
    addTestFile(r'''
import 'dart:math' as math;

main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      id: mathSet.id,
      label: 'sin',
      offset: testCode.indexOf('} // ref'),
    );

    expect(result.completion, 'math.sin');
    _assertEmptyChange(result.change);
  }

  test_dart_newImport() async {
    addTestFile(r'''
main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      id: mathSet.id,
      label: 'sin',
      offset: testCode.indexOf('} // ref'),
    );

    expect(result.completion, 'sin');
    _assertTestFileChange(result.change, r'''
import 'dart:math';

main() {} // ref
''');
  }

  void _assertEmptyChange(SourceChange change) {
    expect(change.edits, isEmpty);
  }

  void _assertTestFileChange(SourceChange change, String expected) {
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileEdit = fileEdits[0];
    expect(fileEdit.file, testFile);

    var edits = fileEdit.edits;
    expect(SourceEdit.applySequence(testCode, edits), expected);
  }

  Future<CompletionGetSuggestionDetailsResult> _getSuggestionDetails({
    String file,
    @required int id,
    @required String label,
    @required int offset,
  }) async {
    file ??= testFile;
    var response = await waitResponse(
      CompletionGetSuggestionDetailsParams(
        file,
        id,
        label,
        offset,
      ).toRequest('0'),
    );
    return CompletionGetSuggestionDetailsResult.fromResponse(response);
  }
}
