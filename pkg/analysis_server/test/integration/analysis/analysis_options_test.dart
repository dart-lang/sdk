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

  Future<void> test_option_warning_optionFile() async {
    var options = sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    writeFile(options, '''
linter:
  rules:
    - camel_case_typo # :)
''');

    optionsAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[options], isList);
    var errors = currentAnalysisErrors[options];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, options);
    expect(error.severity, AnalysisErrorSeverity.WARNING);
    expect(error.type, AnalysisErrorType.STATIC_WARNING);
    expect(error.location.offset, 23);
    expect(error.location.length, 'camel_case_typo'.length);
    expect(error.location.startLine, 3);
    expect(error.location.startColumn, 7);
  }
}
