// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsFileNotificationTest);
  });
}

@reflectiveTest
class AnalysisOptionsFileNotificationTest extends PubPackageAnalysisServerTest {
  late File optionsFile;
  Map<File, List<AnalysisError>> filesErrors = {};

  final testSource = '''
void f() {
  var x = '';
  int y = x; // Not assignable in strong-mode
  print(y);
}''';

  List<AnalysisError> get testFileErrors => filesErrors[testFile]!;

  void addOptionsFile(String contents) {
    optionsFile = newAnalysisOptionsYamlFile(testPackageRootPath, contents);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[getFile(decoded.file)] = decoded.errors;
    }
  }

  @override
  Future<void> setUp() async {
    registerLintRules();
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_error_filter() async {
    addOptionsFile('''
analyzer:
  errors:
    unused_local_variable: ignore
''');

    addTestFile('''
void f() {
  String unused = "";
}
''');

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
void f() {
  String unused = "";
}
''');

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

    await waitForTasksFinished();

    // TODO(brianwilkerson) Implement options file analysis in the new driver.
//    expect(optionsFileErrors, hasLength(1));
//    expect(optionsFileErrors.first.severity, AnalysisErrorSeverity.WARNING);
//    expect(optionsFileErrors.first.type, AnalysisErrorType.STATIC_WARNING);
  }

  Future<void> test_options_file_added() async {
    addTestFile(testSource);

    await waitForTasksFinished();

    // Verify that lints are disabled.
    expect(testFileAnalysisOptions.lint, false);

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

    await waitForTasksFinished();

    verifyLintsEnabled(['camel_case_types']);

    deleteFile(optionsFile.path);

    await pumpEventQueue();
    await waitForTasksFinished();

    expect(testFileAnalysisOptions.lint, false);
  }

  void verifyLintsEnabled(List<String> lints) {
    var options = testFileAnalysisOptions;
    expect(options.lint, true);
    var rules = options.lintRules.map((rule) => rule.name);
    expect(rules, unorderedEquals(lints));
  }
}
