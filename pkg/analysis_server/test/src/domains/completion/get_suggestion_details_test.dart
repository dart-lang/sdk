// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'available_suggestions_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionDetailsTest);
  });
}

@reflectiveTest
class GetSuggestionDetailsTest extends AvailableSuggestionsBase {
  Future<void> test_enum() async {
    newFile('/home/test/lib/a.dart', content: r'''
enum MyEnum {
  aaa, bbb
}
''');
    addTestFile(r'''
main() {} // ref
''');

    var set = await waitForSetWithUri('package:test/a.dart');
    var result = await _getSuggestionDetails(
      _buildRequest(
        id: set.id,
        label: 'MyEnum.aaa',
        offset: testCode.indexOf('} // ref'),
      ),
    );

    expect(result.completion, 'MyEnum.aaa');
    _assertTestFileChange(result.change, r'''
import 'package:test/a.dart';

main() {} // ref
''');
  }

  Future<void> test_existingImport() async {
    addTestFile(r'''
import 'dart:math';

main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      _buildRequest(
        id: mathSet.id,
        label: 'sin',
        offset: testCode.indexOf('} // ref'),
      ),
    );

    expect(result.completion, 'sin');
    _assertEmptyChange(result.change);
  }

  Future<void> test_existingImport_prefixed() async {
    addTestFile(r'''
import 'dart:math' as math;

main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      _buildRequest(
        id: mathSet.id,
        label: 'sin',
        offset: testCode.indexOf('} // ref'),
      ),
    );

    expect(result.completion, 'math.sin');
    _assertEmptyChange(result.change);
  }

  Future<void> test_invalid_library() async {
    addTestFile('');

    var response = await waitResponse(
      _buildRequest(id: -1, label: 'foo', offset: 0),
    );
    expect(response.error.code, RequestErrorCode.INVALID_PARAMETER);
  }

  Future<void> test_newImport() async {
    addTestFile(r'''
main() {} // ref
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      _buildRequest(
        id: mathSet.id,
        label: 'sin',
        offset: testCode.indexOf('} // ref'),
      ),
    );

    expect(result.completion, 'sin');
    _assertTestFileChange(result.change, r'''
import 'dart:math';

main() {} // ref
''');
  }

  Future<void> test_newImport_part() async {
    var partCode = r'''
part of 'test.dart';

main() {} // ref
''';
    var partPath = newFile('/home/test/lib/a.dart', content: partCode).path;
    addTestFile(r'''
part 'a.dart';
''');

    var mathSet = await waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(
      _buildRequest(
        file: partPath,
        id: mathSet.id,
        label: 'sin',
        offset: partCode.indexOf('} // ref'),
      ),
    );

    expect(result.completion, 'sin');
    _assertTestFileChange(result.change, r'''
import 'dart:math';

part 'a.dart';
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

  Request _buildRequest({
    String file,
    @required int id,
    @required String label,
    @required int offset,
  }) {
    return CompletionGetSuggestionDetailsParams(
      file ?? testFile,
      id,
      label,
      offset,
    ).toRequest('0');
  }

  Future<CompletionGetSuggestionDetailsResult> _getSuggestionDetails(
      Request request) async {
    var response = await waitResponse(request);
    return CompletionGetSuggestionDetailsResult.fromResponse(response);
  }
}
