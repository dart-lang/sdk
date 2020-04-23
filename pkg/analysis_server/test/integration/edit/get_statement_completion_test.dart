// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetStatementCompletionTest);
  });
}

@reflectiveTest
class GetStatementCompletionTest extends AbstractAnalysisServerIntegrationTest {
  @TestTimeout(Timeout.factor(2))
  Future<void> test_statement_completion() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
void bar() { foo() } // missing semi-colon
void foo() { }''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isNotEmpty);

    // expect a statement completion result
    var result =
        await sendEditGetStatementCompletion(pathname, text.indexOf('foo('));
    expect(result.change.edits, isNotEmpty);

    // apply the edit, expect that the new code has no errors
    var change = result.change;
    expect(change.edits.first.edits, isNotEmpty);
    for (var edit in change.edits.first.edits) {
      text = text.replaceRange(edit.offset, edit.end, edit.replacement);
    }
    expect(text, r'''
void bar() { foo(); } // missing semi-colon

void foo() { }''');

    await sendAnalysisUpdateContent({pathname: AddContentOverlay(text)});

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);
  }
}
