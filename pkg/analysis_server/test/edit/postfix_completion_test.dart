// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixCompletionTest);
  });
}

@reflectiveTest
class PostfixCompletionTest extends PubPackageAnalysisServerTest {
  late SourceChange change;

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_for() async {
    addTestFile('''
main() {
  [].for
}
''');
    await waitForTasksFinished();
    await _prepareCompletion('.for');
    _assertHasChange('Expand .for', '''
main() {
  for (var value in []) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request =
        EditGetPostfixCompletionParams('test.dart', '.for', 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetPostfixCompletionParams(
            convertPath('/foo/../bar/test.dart'), '.for', 0)
        .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  void _assertHasChange(String message, String expectedCode) {
    if (change.message == message) {
      if (change.edits.isNotEmpty) {
        var resultCode =
            SourceEdit.applySequence(testFileContent, change.edits[0].edits);
        expect(resultCode, expectedCode.replaceAll('/*caret*/', ''));
      }
      return;
    }
    fail('Expected to find |$message| but got: ' + change.message);
  }

  Future<void> _prepareCompletion(String key) async {
    var offset = findOffset(key);
    var src = testFileContent.replaceFirst(key, '', offset);
    modifyTestFile(src);
    await _prepareCompletionAt(offset, key);
  }

  Future<void> _prepareCompletionAt(int offset, String key) async {
    var params = EditGetPostfixCompletionParams(testFile.path, key, offset);
    var request =
        Request('0', 'edit.isPostfixCompletionApplicable', params.toJson());
    var response = await handleSuccessfulRequest(request);
    var isApplicable =
        EditIsPostfixCompletionApplicableResult.fromResponse(response);
    if (!isApplicable.value) {
      fail('Postfix completion not applicable at given location');
    }
    request = EditGetPostfixCompletionParams(testFile.path, key, offset)
        .toRequest('1');
    response = await handleSuccessfulRequest(request);
    var result = EditGetPostfixCompletionResult.fromResponse(response);
    change = result.change;
  }
}
