// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementCompletionTest);
  });
}

@reflectiveTest
class StatementCompletionTest extends PubPackageAnalysisServerTest {
  late SourceChange change;

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetStatementCompletionParams(
      'test.dart',
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetStatementCompletionParams(
      convertPath('/foo/../bar/test.dart'),
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_plainEnterFromStart() async {
    addTestFile('''
void f() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await _prepareCompletion('v = 1;', atStart: true);
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  int v = 1;
  ^
}
''');
  }

  Future<void> test_plainOleEnter() async {
    addTestFile('''
void f() {
  int v = 1;
}
''');
    await waitForTasksFinished();
    await _prepareCompletion('v = 1;', atEnd: true);
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  int v = 1;
  ^
}
''');
  }

  Future<void> test_plainOleEnterWithError() async {
    addTestFile('''
void f() {
  int v =
}
''');
    await waitForTasksFinished();
    var match = 'v =';
    await _prepareCompletion(match, atEnd: true);
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  int v =^
  x
}
''');
  }

  void _assertHasChange(String message, String expectedCode) {
    if (change.message == message) {
      if (change.edits.isNotEmpty) {
        var resultCode = SourceEdit.applySequence(
          testFileContent,
          change.edits[0].edits,
        );
        var parsedExpected = TestCode.parseNormalized(expectedCode);
        expect(resultCode, parsedExpected.code);
        if (parsedExpected.positions.isNotEmpty) {
          expect(change.selection!.offset, parsedExpected.position.offset);
        }
      }
      return;
    }
    fail('Expected to find |$message| but got: ${change.message}');
  }

  Future<void> _prepareCompletion(
    String search, {
    bool atStart = false,
    bool atEnd = false,
    int delta = 0,
  }) async {
    var offset = findOffset(search);
    if (atStart) {
      delta = 0;
    } else if (atEnd) {
      delta = search.length;
    }
    await _prepareCompletionAt(offset + delta);
  }

  Future<void> _prepareCompletionAt(int offset) async {
    var request = EditGetStatementCompletionParams(
      testFile.path,
      offset,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    var result = EditGetStatementCompletionResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
    change = result.change;
  }
}
