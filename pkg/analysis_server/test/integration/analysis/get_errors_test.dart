// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetErrorsTest);
  });
}

@reflectiveTest
class GetErrorsTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_getErrors() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
main() {
  var x // parse error: missing ';'
}''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    await analysisFinished;
    AnalysisGetErrorsResult result = await sendAnalysisGetErrors(pathname);
    expect(result.errors, equals(currentAnalysisErrors[pathname]));
  }
}
