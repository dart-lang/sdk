// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetAvailableRefactoringsTest);
  });
}

@reflectiveTest
class GetAvailableRefactoringsTest
    extends AbstractAnalysisServerIntegrationTest {
  test_has_refactorings() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
void foo() { }
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    // expect at least one refactoring
    EditGetAvailableRefactoringsResult result =
        await sendEditGetAvailableRefactorings(
            pathname, text.indexOf('foo('), 0);
    expect(result.kinds, isNotEmpty);
  }
}
