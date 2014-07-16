// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.error;

import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';

@ReflectiveTestCase()
class AnalysisErrorIntegrationTest extends AbstractAnalysisServerIntegrationTest
    {
  test_detect_simple_error() {
    createFile('test.dart',
        '''
main() {
  var x // parse error: missing ';'
}''');
    setAnalysisRoots(['']);
    return analysisFinished.then((_) {
      String filePath = normalizePath('test.dart');
      expect(currentAnalysisErrors[filePath], isList);
      List errors = currentAnalysisErrors[filePath];
      expect(errors, hasLength(1));
      expect(errors[0], isAnalysisError);
      expect(errors[0]['location']['file'], equals(filePath));
    });
  }
}

main() {
  runReflectiveTests(AnalysisErrorIntegrationTest);
}
