// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsPostfixCompletionApplicableTest);
  });
}

@reflectiveTest
class IsPostfixCompletionApplicableTest
    extends AbstractAnalysisServerIntegrationTest {
  test_is_postfix_completion_applicable() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
void bar() {
  foo();.tryon
}
void foo() { }
''';
    int loc = text.indexOf('.tryon');
    text = text.replaceAll('.tryon', '');
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    // expect a postfix completion applicable result
    EditIsPostfixCompletionApplicableResult result =
        await sendEditIsPostfixCompletionApplicable(pathname, '.tryon', loc);
    expect(result.value, isTrue);
  }
}
