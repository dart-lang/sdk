// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsTest);
    // TODO(scheglov): Restore similar test coverage when the front-end API
    // allows it.  See https://github.com/dart-lang/sdk/issues/32258.
    // defineReflectiveTests(GetErrorsTest_UseCFE);
  });
}

@reflectiveTest
class GetErrorsTest extends AbstractAnalysisServerIntegrationTest {
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
class GetErrorsTest_UseCFE extends GetErrorsTest {
  @override
  bool get useCFE => true;
}
