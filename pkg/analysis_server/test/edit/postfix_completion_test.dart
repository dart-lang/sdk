// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixCompletionTest);
  });
}

@reflectiveTest
class PostfixCompletionTest extends AbstractAnalysisTest {
  SourceChange change;

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = EditDomainHandler(server);
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
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetPostfixCompletionParams(
            convertPath('/foo/../bar/test.dart'), '.for', 0)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  void _assertHasChange(String message, String expectedCode, [Function cmp]) {
    if (change.message == message) {
      if (change.edits.isNotEmpty) {
        var resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode.replaceAll('/*caret*/', ''));
        if (cmp != null) {
          int offset = cmp(resultCode);
          expect(change.selection.offset, offset);
        }
      } else {
        if (cmp != null) {
          int offset = cmp(testCode);
          expect(change.selection.offset, offset);
        }
      }
      return;
    }
    fail('Expected to find |$message| but got: ' + change.message);
  }

  Future<void> _prepareCompletion(String key) async {
    var offset = findOffset(key);
    var src = testCode.replaceFirst(key, '', offset);
    modifyTestFile(src);
    await _prepareCompletionAt(offset, key);
  }

  Future<void> _prepareCompletionAt(int offset, String key) async {
    var params = EditGetPostfixCompletionParams(testFile, key, offset);
    var request =
        Request('0', 'edit.isPostfixCompletionApplicable', params.toJson());
    var response = await waitResponse(request, throwOnError: false);
    var isApplicable =
        EditIsPostfixCompletionApplicableResult.fromResponse(response);
    if (!isApplicable.value) {
      fail('Postfix completion not applicable at given location');
    }
    request =
        EditGetPostfixCompletionParams(testFile, key, offset).toRequest('1');
    response = await waitResponse(request, throwOnError: false);
    var result = EditGetPostfixCompletionResult.fromResponse(response);
    change = result.change;
  }
}
