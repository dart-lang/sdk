// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.lint;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import '../integration_tests.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(LintIntegrationTest);
}

@reflectiveTest
class LintIntegrationTest extends AbstractAnalysisServerIntegrationTest {
  test_no_lints_when_not_specified() async {
    String source = sourcePath('test.dart');
    writeFile(
        source,
        '''
class abc { // lint: not CamelCase (should get ignored though)
}''');
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[source], isList);
    // Should be empty without .analysis_options.
    List<AnalysisError> errors = currentAnalysisErrors[source];
    expect(errors, hasLength(0));
  }

  test_simple_lint() async {
    writeFile(
        sourcePath('.analysis_options'),
        '''
linter:
  rules:
    - camel_case_types
''');

    String source = sourcePath('test.dart');
    writeFile(
        source,
        '''
class a { // lint: not CamelCase
}''');

    standardAnalysisSetup();

    await analysisFinished;

    expect(currentAnalysisErrors[source], isList);
    List<AnalysisError> errors = currentAnalysisErrors[source];
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.location.file, source);
    expect(error.severity, AnalysisErrorSeverity.INFO);
    expect(error.type, AnalysisErrorType.LINT);
  }
}
