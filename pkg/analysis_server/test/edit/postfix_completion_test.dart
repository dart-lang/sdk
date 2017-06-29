// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
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
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins([server.serverPlugin]);
    handler = new EditDomainHandler(server);
  }

  test_for() async {
    addTestFile('''
main() {
  [].for
}
''');
    await waitForTasksFinished();
    await _prepareCompletion('.for', atStart: true);
    _assertHasChange(
        'Expand .for',
        '''
main() {
  for (var value in []) {
    /*caret*/
  }
}
''');
  }

  void _assertHasChange(String message, String expectedCode, [Function cmp]) {
    if (change.message == message) {
      if (!change.edits.isEmpty) {
        String resultCode =
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
    fail("Expected to find |$message| but got: " + change.message);
  }

  _prepareCompletion(String key,
      {bool atStart: false, bool atEnd: false, int delta: 0}) async {
    int offset = findOffset(key);
    String src = testCode.replaceFirst(key, '', offset);
    modifyTestFile(src);
    await _prepareCompletionAt(offset, key);
  }

  _prepareCompletionAt(int offset, String key) async {
    var params = new EditGetPostfixCompletionParams(testFile, key, offset);
    var request =
        new Request('0', "edit.isPostfixCompletionApplicable", params.toJson());
    Response response = await waitResponse(request);
    var isApplicable =
        new EditIsPostfixCompletionApplicableResult.fromResponse(response);
    if (!isApplicable.value) {
      fail("Postfix completion not applicable at given location");
    }
    request = new EditGetPostfixCompletionParams(testFile, key, offset)
        .toRequest('1');
    response = await waitResponse(request);
    var result = new EditGetPostfixCompletionResult.fromResponse(response);
    change = result.change;
  }
}
