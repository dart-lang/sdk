// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewAnalysisOptionsFileNotificationTest);
    defineReflectiveTests(OldAnalysisOptionsFileNotificationTest);
  });
}

abstract class AnalysisOptionsFileNotificationTest
    extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  final testSource = '''
main() {
  var x = '';
  int y = x; // Not assignable in strong-mode
  print(y);
}''';

  List<AnalysisError> get errors => filesErrors[testFile];

  List<AnalysisError> get optionsFileErrors => filesErrors[optionsFilePath];

  String get optionsFilePath;

  List<AnalysisError> get testFileErrors => filesErrors[testFile];

  void addOptionsFile(String contents) {
    addFile(optionsFilePath, contents);
  }

  void deleteFile(String filePath) {
    resourceProvider.deleteFile(filePath);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  void setAnalysisRoot() {
    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  void setStrongMode(bool isSet) {
    addOptionsFile('''
analyzer:
  strong-mode: $isSet
''');
  }

  @override
  void setUp() {
    generateSummaryFiles = true;
    registerLintRules();
    super.setUp();
    server.handlers = [new AnalysisDomainHandler(server)];
  }

  @override
  void tearDown() {
    filesErrors[optionsFilePath] = [];
    filesErrors[testFile] = [];
    super.tearDown();
  }

  test_error_filter() async {
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
    if (!enableNewAnalysisDriver) {
      // TODO(brianwilkerson) Implement options file analysis in the new driver.
      expect(optionsFileErrors, isNotNull);
      expect(optionsFileErrors, isEmpty);
    }

    // Verify test file.
    expect(testFileErrors, isNotNull);
    expect(testFileErrors, isEmpty);
  }

  test_error_filter_removed() async {
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
    if (!enableNewAnalysisDriver) {
      // TODO(brianwilkerson) Implement options file analysis in the new driver.
      expect(optionsFileErrors, isNotNull);
      expect(optionsFileErrors, isEmpty);
    }

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
    if (!enableNewAnalysisDriver) {
      // TODO(brianwilkerson) Implement options file analysis in the new driver.
      expect(optionsFileErrors, isEmpty);
    }

    // Verify test file.
    expect(testFileErrors, hasLength(1));
  }

  test_lint_options_changes() async {
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

  test_lint_options_unsupported() async {
    addOptionsFile('''
linter:
  rules:
    - unsupported
''');

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    if (!enableNewAnalysisDriver) {
      // TODO(brianwilkerson) Implement options file analysis in the new driver.
      expect(optionsFileErrors, hasLength(1));
      expect(optionsFileErrors.first.severity, AnalysisErrorSeverity.WARNING);
      expect(optionsFileErrors.first.type, AnalysisErrorType.STATIC_WARNING);
    }
  }

  test_options_file_added() async {
    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    // Verify strong-mode disabled.
    verifyStrongMode(enabled: false);

    // Clear errors.
    filesErrors[testFile] = [];

    // Add options file with strong mode enabled.
    setStrongMode(true);

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyStrongMode(enabled: true);
  }

  test_options_file_parse_error() async {
    addOptionsFile('''
; #bang
''');
    setAnalysisRoot();

    await waitForTasksFinished();

    if (!enableNewAnalysisDriver) {
      // TODO(brianwilkerson) Implement options file analysis in the new driver.
      expect(optionsFileErrors, hasLength(1));
      expect(optionsFileErrors.first.severity, AnalysisErrorSeverity.ERROR);
      expect(
          optionsFileErrors.first.type, AnalysisErrorType.COMPILE_TIME_ERROR);
    }
  }

  test_options_file_removed() async {
    setStrongMode(true);

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    verifyStrongMode(enabled: true);

    // Clear errors.
    filesErrors[testFile] = [];

    deleteFile(optionsFilePath);

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyStrongMode(enabled: false);
  }

  test_strong_mode_changed_off() async {
    setStrongMode(true);

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    verifyStrongMode(enabled: true);

    // Clear errors.
    filesErrors[testFile] = [];

    setStrongMode(false);

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyStrongMode(enabled: false);
  }

  test_strong_mode_changed_on() async {
    setStrongMode(false);

    addTestFile(testSource);
    setAnalysisRoot();

    await waitForTasksFinished();

    verifyStrongMode(enabled: false);

    setStrongMode(true);

    await pumpEventQueue();
    await waitForTasksFinished();

    verifyStrongMode(enabled: true);
  }

  void verifyLintsEnabled(List<String> lints) {
    AnalysisOptions options = analysisOptions;
    expect(options.lint, true);
    var rules = options.lintRules.map((rule) => rule.name);
    expect(rules, unorderedEquals(lints));
  }

  verifyStrongMode({bool enabled}) {
    // Verify strong-mode enabled.
    expect(analysisOptions.strongMode, enabled);

    if (enabled) {
      // Should produce a type warning.
      expect(errors.map((error) => error.type),
          unorderedEquals([AnalysisErrorType.STATIC_TYPE_WARNING]));
    } else {
      // Should only produce a hint.
      expect(errors.map((error) => error.type),
          unorderedEquals([AnalysisErrorType.HINT]));
    }
  }
}

@reflectiveTest
class NewAnalysisOptionsFileNotificationTest
    extends AnalysisOptionsFileNotificationTest {
  @override
  String get optionsFilePath => '$projectPath/analysis_options.yaml';
}

@reflectiveTest
class OldAnalysisOptionsFileNotificationTest
    extends AnalysisOptionsFileNotificationTest {
  @override
  String get optionsFilePath => '$projectPath/.analysis_options';
}
