// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.analysis_options;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import '../integration_tests.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(OptionsIntegrationTest);
}

@reflectiveTest
class OptionsIntegrationTest extends AbstractAnalysisServerIntegrationTest {
  test_option_warning() async {
    String options = sourcePath('.analysis_options');
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
