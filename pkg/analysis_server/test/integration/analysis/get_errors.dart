// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.get.errors;

import 'dart:async';

import 'package:unittest/unittest.dart';

import '../integration_tests.dart';

/**
 * Base class for testing the "analysis.getErrors" request.
 */
class AnalysisDomainGetErrorsTest extends AbstractAnalysisServerIntegrationTest
    {
  /**
   * True if the "analysis.getErrors" request should be made after analysis is
   * complete.
   */
  final bool afterAnalysis;

  AnalysisDomainGetErrorsTest(this.afterAnalysis);

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
        expect(
            result.errors.map((error) => error.toJson()),
            equals(currentAnalysisErrors[pathname]));
      });
    }
    if (afterAnalysis) {
      return analysisFinished.then((_) => finishTest());
    } else {
      return finishTest();
    }
  }
}
