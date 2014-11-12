// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.error;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class AnalysisErrorIntegrationTest extends AbstractAnalysisServerIntegrationTest
    {
  test_detect_simple_error() {
    String pathname = sourcePath('test.dart');
    writeFile(pathname,
        '''
main() {
  print(null) // parse error: missing ';'
}''');
    standardAnalysisSetup();
    return analysisFinished.then((_) {
      expect(currentAnalysisErrors[pathname], isList);
      List<AnalysisError> errors = currentAnalysisErrors[pathname];
      expect(errors, hasLength(1));
      expect(errors[0].location.file, equals(pathname));
    });
  }
}

main() {
  runReflectiveTests(AnalysisErrorIntegrationTest);
}
