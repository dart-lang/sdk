// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification_errors;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import '../reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(NotificationErrorsTest);
}


@ReflectiveTestCase()
class NotificationErrorsTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  @override
  void setUp() {
    super.setUp();
    server.handlers = [new AnalysisDomainHandler(server),];
  }

  test_ParserError() {
    createProject();
    addTestFile('library lib');
    return waitForTasksFinished().then((_) {
      List<AnalysisError> errors = filesErrors[testFile];
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.location.file, '/project/bin/test.dart');
      expect(error.location.offset, isPositive);
      expect(error.location.length, isNonNegative);
      expect(error.severity, AnalysisErrorSeverity.ERROR);
      expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
      expect(error.message, isNotNull);
    });
  }

  test_StaticWarning() {
    createProject();
    addTestFile('''
main() {
  print(UNKNOWN);
}
''');
    return waitForTasksFinished().then((_) {
      List<AnalysisError> errors = filesErrors[testFile];
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.severity, AnalysisErrorSeverity.WARNING);
      expect(error.type, AnalysisErrorType.STATIC_WARNING);
    });
  }

  test_notInAnalysisRoot() {
    createProject();
    String otherFile = '/other.dart';
    addFile(otherFile, 'UnknownType V;');
    addTestFile('''
import '/other.dart';

main() {
  print(V);
}
''');
    return waitForTasksFinished().then((_) {
      expect(filesErrors[otherFile], isNull);
    });
  }
}
