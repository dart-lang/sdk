// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsFileNotificationTest);
  });
}

@reflectiveTest
class AnalysisOptionsFileNotificationTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  final testSource = '''
main() {
  var x = '';
  int y = x; // Not assignable in strong-mode
  print(y);
}''';

  List<AnalysisError> get errors => filesErrors[testFile];

  List<AnalysisError> get optionsFileErrors => filesErrors[optionsFilePath];

  String get optionsFilePath => '$projectPath/analysis_options.yaml';

  List<AnalysisError> get testFileErrors => filesErrors[testFile];

  void addOptionsFile(String contents) {
    newFile(optionsFilePath, content: contents);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  void setAnalysisRoot() {
    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  @override
  void setUp() {
    registerLintRules();
    super.setUp();
    server.handlers = [AnalysisDomainHandler(server)];
  }

  @override
  void tearDown() {
    filesErrors[optionsFilePath] = [];
    filesErrors[testFile] = [];
    super.tearDown();
  }

  Future<void> test_error_filter() async {
    addOptionsFile('''
analyzer:
  errors:
    unused_local_variable: ignore
''');

    addTestFile('''
main() {
  String unused = "";
}
''');

    setAnalysisRoot();

    await waitForTasksFinished();

    // Verify options file.
    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, isNotNull);
//    expect(optionsFileErrors, isEmpty);

    // Verify test file.
    expect(testFileErrors, isNotNull);
    expect(testFileErrors, isEmpty);
  }

  Future<void> test_error_filter_removed() async {
    addOptionsFile('''
analyzer:
  errors:
    unused_local_variable: ignore
''');

    addTestFile('''
main() {
  String unused = "";
}
''');

    setAnalysisRoot();

    await waitForTasksFinished();

    // Verify options file.
    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, isNotNull);
//    expect(optionsFileErrors, isEmpty);

    // Verify test file.
    expect(testFileErrors, isNotNull);
    expect(testFileErrors, isEmpty);

    addOptionsFile('''
analyzer:
  errors:
  #  unused_local_variable: ignore
''');

    await pumpEventQueue();
    await waitForTasksFinished();

    // Verify options file.
    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, isEmpty);

    // Verify test file.
    expect(testFileErrors, hasLength(1));
  }

  Future<void> test_lint_options_changes() async {
    addOptionsFile('''
linter:
  rules:
    - camel_case_types
    - constant_identifier_names
''');

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    verifyLintsEnabled(['camel_case_types', 'constant_identifier_names']);

    addOptionsFile('''
linter:
  rules:
    - camel_case_types
''');

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyLintsEnabled(['camel_case_types']);
  }

  Future<void> test_lint_options_unsupported() async {
    addOptionsFile('''
linter:
  rules:
    - unsupported
''');

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, hasLength(1));
//    expect(optionsFileErrors.first.severity, AnalysisErrorSeverity.WARNING);
//    expect(optionsFileErrors.first.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_options_file_added() async {
    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    // Verify that lints are disabled.
    expect(analysisOptions.lint, false);

    // Clear errors.
    filesErrors[testFile] = [];

    // Add options file with a lint enabled.
    addOptionsFile('''
linter:
  rules:
    - camel_case_types
''');

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyLintsEnabled(['camel_case_types']);
  }

  Future<void> test_options_file_parse_error() async {
    addOptionsFile('''
; #bang
''');
    setAnalysisRoot();

    await waitForTasksFinished();

    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, hasLength(1));
//    expect(optionsFileErrors.first.severity, AnalysisErrorSeverity.ERROR);
//    expect(optionsFileErrors.first.type, AnalysisErrorType.COMPILE_TIME_ERROR);
  }

  Future<void> test_options_file_removed() async {
    addOptionsFile('''
linter:
  rules:
    - camel_case_types
''');

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    verifyLintsEnabled(['camel_case_types']);

    // Clear errors.
    filesErrors[testFile] = [];

    deleteFile(optionsFilePath);

    await pumpEventQueue();
    await waitForTasksFinished();

    expect(analysisOptions.lint, false);
  }

  void verifyLintsEnabled(List<String> lints) {
    var options = analysisOptions;
    expect(options.lint, true);
    var rules = options.lintRules.map((rule) => rule.name);
    expect(rules, unorderedEquals(lints));
  }
}
