// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsIntegrationTest);
    defineReflectiveTests(OptionsIntegrationTest_Driver);
  });
}

class AbstractOptionsIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  test_option_warning_newOptionFile() async {
    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    writeFile(
        options,
        '''
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

  test_option_warning_oldOptionFile() async {
    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    writeFile(
        options,
        '''
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
class OptionsIntegrationTest extends AbstractOptionsIntegrationTest {}

@reflectiveTest
class OptionsIntegrationTest_Driver extends AbstractOptionsIntegrationTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  test_option_warning_newOptionFile() async {
    // TimeoutException after 0:00:30.000000: Test timed out after 30 seconds
    // (#28868).
    //return super.test_option_warning_newOptionFile();
    fail('Test timed out');
  }

  @failingTest
  test_option_warning_oldOptionFile() async {
    // TimeoutException after 0:00:30.000000: Test timed out after 30 seconds
    // (#28868).
    //return super.test_option_warning_oldOptionFile();
    fail('Test timed out');
  }
}
