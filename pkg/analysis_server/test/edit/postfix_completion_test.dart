// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var key = '.for';
    var offset = _newFileForCompletion(key, '''
void f() {
  [].for
}
''');

    await _prepareCompletionAt(offset, key);
    _assertHasChange('Expand .for', '''
void f() {
  for (var value in []) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetPostfixCompletionParams(
      'test.dart',
      '.for',
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
    var request = EditGetPostfixCompletionParams(
      convertPath('/foo/../bar/test.dart'),
      '.for',
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_notApplicable_inComment_try() async {
    var key = '.try';
    var offset = _newFileForCompletion(key, '''
void f() {
  () {
    // comment.try
  };
}
''');

    var result = await _isApplicable(offset: offset, key: key);
    expect(result, isFalse);
  }

  void _assertHasChange(String message, String expectedCode) {
    if (change.message == message) {
      if (change.edits.isNotEmpty) {
        var resultCode = SourceEdit.applySequence(
          testFileContent,
          change.edits[0].edits,
        );
        expect(resultCode, expectedCode.replaceAll('/*caret*/', ''));
      }
      return;
    }
    fail('Expected to find |$message| but got: ${change.message}');
  }

  Future<bool> _isApplicable({required int offset, required String key}) async {
    var response = await handleSuccessfulRequest(
      EditIsPostfixCompletionApplicableParams(
        testFile.path,
        key,
        offset,
      ).toRequest('0', clientUriConverter: server.uriConverter),
    );
    var result = EditIsPostfixCompletionApplicableResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
    return result.value;
  }

  int _newFileForCompletion(String key, String content) {
    var keyOffset = content.indexOf(key);
    expect(keyOffset, isNot(equals(-1)), reason: 'missing "$key"');

    modifyFile2(
      testFile,
      content.substring(0, keyOffset) +
          content.substring(keyOffset + key.length),
    );

    return keyOffset;
  }

  Future<void> _prepareCompletionAt(int offset, String key) async {
    var isApplicable = await _isApplicable(offset: offset, key: key);

    if (!isApplicable) {
      fail('Postfix completion not applicable at given location');
    }

    var response = await handleSuccessfulRequest(
      EditGetPostfixCompletionParams(
        testFile.path,
        key,
        offset,
      ).toRequest('0', clientUriConverter: server.uriConverter),
    );

    var result = EditGetPostfixCompletionResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
    change = result.change;
  }
}
