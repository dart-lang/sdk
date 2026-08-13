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
void f() {
  []^
}
''');

    await _prepareCompletionAt(parsedTestCode.position.offset, '.for');
    _assertHasChange('Expand .for', '''
void f() {
  for (var value in []) {
    ^
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
    addTestFile('''
void f() {
  () {
    // comment^
  };
}
''');

    var result = await _isApplicable(
      offset: parsedTestCode.position.offset,
      key: '.try',
    );
    expect(result, isFalse);
  }

  void _assertHasChange(String message, String expected) {
    var expectedCode = TestCode.parseNormalized(expected);
    if (change.message != message) {
      fail('Expected to find |$message| but got: ${change.message}');
    }
    if (change.edits.isNotEmpty) {
      var resultCode = SourceEdit.applySequence(
        testFileContent,
        change.edits[0].edits,
      );
      expect(resultCode, expectedCode.code);
    }
    expect(change.selection?.offset, expectedCode.position.offset);
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
