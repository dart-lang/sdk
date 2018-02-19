// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotificationErrorsTest);
  });
}

@reflectiveTest
class NotificationErrorsTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  @override
  void setUp() {
    generateSummaryFiles = true;
    registerLintRules();
    super.setUp();
    server.handlers = [
      new AnalysisDomainHandler(server),
    ];
  }

  test_analysisOptionsFile() async {
    String filePath = join(projectPath, 'analysis_options.yaml');
    String analysisOptionsFile = newFile(filePath, content: '''
linter:
  rules:
    - invalid_lint_rule_name
''').path;

    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    List<AnalysisError> errors = filesErrors[analysisOptionsFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }

  test_importError() async {
    createProject();

    addTestFile('''
import 'does_not_exist.dart';
''');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    List<AnalysisError> errors = filesErrors[testFile];
    // Verify that we are generating only 1 error for the bad URI.
    // https://github.com/dart-lang/sdk/issues/23754
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.COMPILE_TIME_ERROR);
    expect(error.message, startsWith("Target of URI doesn't exist"));
  }

  test_lintError() async {
    var camelCaseTypesLintName = 'camel_case_types';

    newFile(join(projectPath, '.analysis_options'), content: '''
linter:
  rules:
    - $camelCaseTypesLintName
''');

    addTestFile('class a { }');

    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);

    await waitForTasksFinished();
    List<Linter> lints;
    AnalysisDriver testDriver = (server.contextManager as ContextManagerImpl)
        .getContextInfoFor(getFolder(projectPath))
        .analysisDriver;
    lints = testDriver.analysisOptions.lintRules;
    // Registry should only contain single lint rule.
    expect(lints, hasLength(1));
    LintRule lint = lints.first as LintRule;
    expect(lint.name, camelCaseTypesLintName);
    // Verify lint error result.
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, join(projectPath, 'bin', 'test.dart'));
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
    expect(error.message, lint.description);
  }

  test_notInAnalysisRoot() async {
    createProject();
    String otherFile = newFile('/other.dart', content: 'UnknownType V;').path;
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
    await pumpEventQueue(times: 5000);
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, join(projectPath, 'bin', 'test.dart'));
    expect(error.location.offset, isPositive);
    expect(error.location.length, isNonNegative);
    expect(error.severity, AnalysisErrorSeverity.ERROR);
    expect(error.type, AnalysisErrorType.SYNTACTIC_ERROR);
    expect(error.message, isNotNull);
  }

  test_pubspecFile() async {
    String filePath = join(projectPath, 'pubspec.yaml');
    String pubspecFile = newFile(filePath, content: '''
version: 1.3.2
''').path;

    Request setRootsRequest =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(setRootsRequest);
    await waitForTasksFinished();
    await pumpEventQueue();
    //
    // Verify the error result.
    //
    List<AnalysisError> errors = filesErrors[pubspecFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, filePath);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    //
    // Fix the error and verify the new results.
    //
    modifyFile(pubspecFile, '''
name: sample
version: 1.3.2
''');
    await waitForTasksFinished();
    await pumpEventQueue();

    errors = filesErrors[pubspecFile];
    expect(errors, hasLength(0));
  }

  test_StaticWarning() async {
    createProject();
    addTestFile('''
main() {
  print(UNKNOWN);
}
''');
    await waitForTasksFinished();
    await pumpEventQueue(times: 5000);
    List<AnalysisError> errors = filesErrors[testFile];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
  }
}
