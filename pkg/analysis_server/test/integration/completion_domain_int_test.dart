// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.completion.domain;

import 'dart:async';

import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'integration_tests.dart';

@ReflectiveTestCase()
class CompletionDomainIntegrationTest extends
    AbstractAnalysisServerIntegrationTest {
  fail_test_getSuggestions_string_var() {
    // See dartbug.com/20188
    String pathname = sourcePath('test.dart');
    String text = r'''
var test = '';
main() {
  test.
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    return analysisFinished.then((_) {
      return sendCompletionGetSuggestions(pathname, text.indexOf('test.') +
          'test.'.length).then((result) {
        // Since the feature doesn't work yet, just pause for a second to
        // collect the output of the analysis server, and then stop the test.
        // TODO(paulberry): finish writing the integration test once the feature
        // it more complete.
        return new Future.delayed(new Duration(seconds: 1), () {
          fail('test not completed yet');
        });
      });
    });
  }

  test_placeholder() {
    // The unit test framework freaks out if there are no tests, so this is a
    // placeholder until we have a passing test.
    // TODO(paulberry): remove this.
  }
}

main() {
  runReflectiveTests(CompletionDomainIntegrationTest);
}
