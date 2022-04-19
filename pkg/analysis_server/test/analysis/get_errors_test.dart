// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(GetErrorsTest);
  });
}

@reflectiveTest
class GetErrorsTest extends PubPackageAnalysisServerTest {
  static const String _requestId = 'test-getError';

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_afterAnalysisComplete() async {
    newFile(testFilePath, '''
main() {
  print(42)
}
''');

    await waitForTasksFinished();

    var errors = await _getErrors(testFile.path);
    expect(errors, hasLength(1));
  }

  Future<void> test_errorInPart() async {
    var libraryFile = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
class A {}
''');

    var partFile = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class A {}
''');

    {
      var libErrors = await _getErrors(libraryFile.path);
      expect(libErrors, isEmpty);
    }
    {
      var partErrors = await _getErrors(partFile.path);
      expect(partErrors, hasLength(1));
    }
  }

  Future<void> test_fileWithoutContext() async {
    await setRoots(included: [], excluded: []);

    var request = _createGetErrorsRequest(testFile.path);
    var response = await serverChannel.sendRequest(request);
    assertResponseFailure(
      response,
      requestId: _requestId,
      errorCode: RequestErrorCode.GET_ERRORS_INVALID_FILE,
    );
  }

  Future<void> test_hasErrors() async {
    newFile(testFilePath, '''
main() {
  print(42)
}
''');

    var errors = await _getErrors(testFile.path);
    expect(errors, hasLength(1));
    {
      var error = errors[0];
      expect(error.severity, AnalysisErrorSeverity.ERROR);
      expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
      expect(error.location.file, testFile.path);
      expect(error.location.startLine, 2);
    }
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = _createGetErrorsRequest('test.dart');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: _requestId,
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = _createGetErrorsRequest(convertPath('/foo/../bar/test.dart'));
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: _requestId,
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_noErrors() async {
    newFile(testFilePath, '''
main() {
  print(42);
}
''');

    var errors = await _getErrors(testFile.path);
    expect(errors, isEmpty);
  }

  Request _createGetErrorsRequest(String path) {
    return AnalysisGetErrorsParams(path).toRequest(_requestId);
  }

  Future<List<AnalysisError>> _getErrors(String path) async {
    var request = _createGetErrorsRequest(path);
    var response = await handleSuccessfulRequest(request);
    return AnalysisGetErrorsResult.fromResponse(response).errors;
  }
}
