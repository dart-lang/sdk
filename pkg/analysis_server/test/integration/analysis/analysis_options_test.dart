// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsIntegrationTest);
    defineReflectiveTests(OptionsIntegrationTest_PreviewDart2);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class OptionsIntegrationTest extends AbstractAnalysisServerIntegrationTest {
  @failingTest
  test_option_warning_newOptionFile() async {
    // TimeoutException after 0:00:30.000000: Test timed out after 30 seconds
    // (#28868).

    _fail('test timeout expected - #28868');

    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    writeFile(options, '''
linter:
  rules:
    - camel_case_typo # :)
''');

    standardAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[options], isList);
    List<AnalysisError> errors = currentAnalysisErrors[options];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, options);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    expect(error.location.offset, 23);
    expect(error.location.length, 'camel_case_typo'.length);
    expect(error.location.startLine, 3);
    expect(error.location.startColumn, 7);
  }

  @failingTest
  test_option_warning_oldOptionFile() async {
    // TimeoutException after 0:00:30.000000: Test timed out after 30 seconds
    // (#28868).

    _fail('test timeout expected - #28868');

    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    writeFile(options, '''
linter:
  rules:
    - camel_case_typo # :)
''');

    standardAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[options], isList);
    List<AnalysisError> errors = currentAnalysisErrors[options];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, options);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    expect(error.location.offset, 23);
    expect(error.location.length, 'camel_case_typo'.length);
    expect(error.location.startLine, 3);
    expect(error.location.startColumn, 7);
  }
}

@reflectiveTest
class OptionsIntegrationTest_PreviewDart2 extends OptionsIntegrationTest {
  @override
  bool get usePreviewDart2 => true;
}
