// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification_errors;

import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/constants.dart';
import 'package:analysis_testing/reflective_tests.dart';
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
      String file = notification.getParameter(FILE);
      List<Map<String, Object>> errorMaps = notification.getParameter(ERRORS);
      filesErrors[file] = errorMaps.map(AnalysisError.fromJson).toList();
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
      expect(error.severity, 'ERROR');
      expect(error.type, 'SYNTACTIC_ERROR');
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
      expect(error.severity, 'WARNING');
      expect(error.type, 'STATIC_WARNING');
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
