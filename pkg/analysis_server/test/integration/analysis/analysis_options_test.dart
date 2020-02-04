// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsIntegrationTest);
  });
}

@reflectiveTest
class OptionsIntegrationTest extends AbstractAnalysisServerIntegrationTest {
  void optionsAnalysisSetup() {
    // Add an empty Dart file; required to trigger analysis (#35383).
    writeFile(sourcePath('test.dart'), '');
    standardAnalysisSetup();
  }

  Future<void> test_option_warning_newOptionFile() async {
    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    writeFile(options, '''
linter:
  rules:
    - camel_case_typo # :)
''');

    optionsAnalysisSetup();

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

  Future<void> test_option_warning_oldOptionFile() async {
    String options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    writeFile(options, '''
linter:
  rules:
    - camel_case_types
''');

    optionsAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[options], isList);
    List<AnalysisError> errors = currentAnalysisErrors[options];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, options);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.HINT);
    expect(error.location.offset, 0);
    expect(error.location.length, 1);
    expect(error.location.startLine, 1);
    expect(error.location.startColumn, 1);
    expect(error.message,
        'The name of the analysis options file .analysis_options is deprecated; consider renaming it to analysis_options.yaml.');
  }
}
