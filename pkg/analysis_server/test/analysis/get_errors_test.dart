// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_errors;

import 'dart:async';

import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';


main() {
  group('notification.hover', () {
    runReflectiveTests(GetErrorsTest);
  });
}


@ReflectiveTestCase()
class GetErrorsTest extends AbstractAnalysisTest {
  Future<List<AnalysisError>> getErrors() {
    return getErrorsForFile(testFile);
  }

  Future<List<AnalysisError>> getErrorsForFile(String file) {
    return waitForTasksFinished().then((_) {
      String requestId = 'test-getError';
      // send the Request
      Request request = new Request(requestId, ANALYSIS_GET_ERRORS);
      request.setParameter(FILE, file);
      server.handleRequest(request);
      // wait for the Response
      waitForResponse() {
        for (Response response in serverChannel.responsesReceived) {
          if (response.id == requestId) {
            List errorsJsons = response.getResult(ERRORS);
            return errorsJsons.map(AnalysisError.fromJson).toList();
          }
        }
        return new Future(waitForResponse);
      }
      return new Future(waitForResponse);
    });
  }

  @override
  void setUp() {
    super.setUp();
    server.handlers = [new AnalysisDomainHandler(server),];
    createProject();
  }

  test_hasErrors() {
    addTestFile('''
main() {
  print(42)
}
''');
    return getErrors().then((List<AnalysisError> errors) {
      expect(errors, hasLength(1));
      {
        AnalysisError error = errors[0];
        expect(error.severity, 'ERROR');
        expect(error.type, 'SYNTACTIC_ERROR');
        expect(error.location.file, testFile);
        expect(error.location.startLine, 2);
      }
    });
  }

  test_noErrors() {
    addTestFile('''
main() {
  print(42);
}
''');
    return getErrors().then((List<AnalysisError> errors) {
      expect(errors, isEmpty);
    });
  }

  test_fileWithoutContext() {
    String file = '/outside.dart';
    addFile(file, '''
main() {
  print(42);
}
''');
    return getErrorsForFile(file).then((List<AnalysisError> errors) {
      expect(errors, isEmpty);
    });
  }
}
