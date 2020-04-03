// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LintIntegrationTest);
  });
}

@reflectiveTest
class LintIntegrationTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_no_lints_when_not_specified() async {
    var source = sourcePath('test.dart');
    writeFile(source, '''
class abc { // lint: not CamelCase (should get ignored though)
}''');
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[source], isList);
    // Should be empty without an analysis options file.
    var errors = currentAnalysisErrors[source];
    expect(errors, hasLength(0));
  }

  Future<void> test_simple_lint_optionsFile() async {
    writeFile(sourcePath(AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE), '''
linter:
  rules:
    - camel_case_types
''');

    var source = sourcePath('test.dart');
    writeFile(source, '''
class a { // lint: not CamelCase
}''');

    standardAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[source], isList);
    var errors = currentAnalysisErrors[source];
    expect(errors, hasLength(1));
    var error = errors[0];
    expect(error.location.file, source);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
  }
}
