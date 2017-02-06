// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.get.errors;

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsTest);
    defineReflectiveTests(GetErrorsTest_Driver);
  });
}

/**
 * Base class for testing the "analysis.getErrors" request.
 */
class AnalysisDomainGetErrorsTest
    extends AbstractAnalysisServerIntegrationTest {
  AnalysisDomainGetErrorsTest();

  test_getErrors() {
    String pathname = sourcePath('test.dart');
    String text = r'''
main() {
  var x // parse error: missing ';'
}''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    Future finishTest() {
      return sendAnalysisGetErrors(pathname).then((result) {
        expect(result.errors, equals(currentAnalysisErrors[pathname]));
      });
    }

    return analysisFinished.then((_) => finishTest());
  }
}

@reflectiveTest
class GetErrorsTest extends AnalysisDomainGetErrorsTest {}

@reflectiveTest
class GetErrorsTest_Driver extends AnalysisDomainGetErrorsTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
