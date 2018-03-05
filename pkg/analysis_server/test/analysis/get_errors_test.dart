// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsTest);
  });
}

@reflectiveTest
class GetErrorsTest extends AbstractAnalysisTest {
  static const String requestId = 'test-getError';

  @override
  void setUp() {
    super.setUp();
    server.handlers = [
      new AnalysisDomainHandler(server),
    ];
    createProject();
  }

  test_afterAnalysisComplete() async {
    addTestFile('''
main() {
  print(42)
}
''');
    await waitForTasksFinished();
    List<AnalysisError> errors = await _getErrors(testFile);
    expect(errors, hasLength(1));
  }

  test_errorInPart() async {
    String libPath = join(testFolder, 'main.dart');
    String partPath = join(testFolder, 'main_part.dart');
    newFile(libPath, content: r'''
library main;
part 'main_part.dart';
class A {}
''');
    newFile(partPath, content: r'''
part of main;
class A {}
''');
    await waitForTasksFinished();
    {
      List<AnalysisError> libErrors = await _getErrors(libPath);
      expect(libErrors, isEmpty);
    }
    {
      List<AnalysisError> partErrors = await _getErrors(partPath);
      expect(partErrors, hasLength(1));
    }
  }

  @failingTest
  test_fileDoesNotExist() {
    // Broken under the new driver.
    String file = convertPath('$projectPath/doesNotExist.dart');
    return _checkInvalid(file);
  }

  @failingTest
  test_fileWithoutContext() {
    // Broken under the new driver.
    String file = convertPath('/outside.dart');
    newFile(file, content: '''
main() {
  print(42);
}
''');
    return _checkInvalid(file);
  }

  test_hasErrors() async {
    addTestFile('''
main() {
  print(42)
}
''');
    List<AnalysisError> errors = await _getErrors(testFile);
    expect(errors, hasLength(1));
    {
      AnalysisError error = errors[0];
      expect(error.severity, AnalysisErrorSeverity.ERROR);
      expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
      expect(error.location.file, testFile);
      expect(error.location.startLine, 2);
    }
  }

  test_noErrors() async {
    addTestFile('''
main() {
  print(42);
}
''');
    List<AnalysisError> errors = await _getErrors(testFile);
    expect(errors, isEmpty);
  }

  @failingTest
  test_removeContextAfterRequest() async {
    // Broken under the new driver.
    addTestFile('''
main() {
  print(42)
}
''');
    // handle the request synchronously
    Request request = _createGetErrorsRequest(testFile);
    server.handleRequest(request);
    // remove context, causes sending an "invalid file" error
    deleteFolder(projectPath);
    // wait for an error response
    Response response = await serverChannel.waitForResponse(request);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.GET_ERRORS_INVALID_FILE);
  }

  Future _checkInvalid(String file) async {
    Request request = _createGetErrorsRequest(file);
    Response response = await serverChannel.sendRequest(request);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.GET_ERRORS_INVALID_FILE);
  }

  Request _createGetErrorsRequest(String file) {
    return new AnalysisGetErrorsParams(file).toRequest(requestId);
  }

  Future<List<AnalysisError>> _getErrors(String file) async {
    Request request = _createGetErrorsRequest(file);
    Response response = await serverChannel.sendRequest(request);
    return new AnalysisGetErrorsResult.fromResponse(response).errors;
  }
}
