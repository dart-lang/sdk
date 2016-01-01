// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification_errors;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:linter/src/linter.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(NotificationErrorsTest);
}

@reflectiveTest
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

  test_importError() async {
    createProject();

    addTestFile('''
import 'does_not_exist.dart';
''');
    await waitForTasksFinished();
    List<AnalysisError> errors = filesErrors[testFile];
    // Verify that we are generating only 1 error for the bad URI.
    // https://github.com/dart-lang/sdk/issues/23754
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.COMPILE_TIME_ERROR);
    expect(error.message, startsWith('Target of URI does not exist'));
  }

  test_lintError() async {
    var camelCaseTypesLintName = 'camel_case_types';

    addFile(
        '$projectPath/.analysis_options',
        '''
linter:
  rules:
    - $camelCaseTypesLintName
''');

    addTestFile('class a { }');

    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);

    await waitForTasksFinished();
    AnalysisContext testContext = server.getContainingContext(testFile);
    List<Linter> lints = getLints(testContext);
    // Registry should only contain single lint rule.
    expect(lints, hasLength(1));
    LintRule lint = lints.first as LintRule;
    expect(lint.name, camelCaseTypesLintName);
    // Verify lint error result.
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, '/project/bin/test.dart');
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    expect(error.message, lint.description);
  }

  test_notInAnalysisRoot() async {
    createProject();
    String otherFile = '/other.dart';
    addFile(otherFile, 'UnknownType V;');
    addTestFile('''
import '/other.dart';
main() {
  print(V);
}
''');
    await waitForTasksFinished();
    expect(filesErrors[otherFile], isNull);
  }

  test_ParserError() async {
    createProject();
    addTestFile('library lib');
    await waitForTasksFinished();
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, '/project/bin/test.dart');
    expect(error.location.offset, isPositive);
    expect(error.location.length, isNonNegative);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(error.message, isNotNull);
  }

  test_StaticWarning() async {
    createProject();
    addTestFile('''
main() {
  print(UNKNOWN);
}
''');
    await waitForTasksFinished();
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }
}
