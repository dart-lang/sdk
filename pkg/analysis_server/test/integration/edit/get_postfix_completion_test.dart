// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetPostfixCompletionTest);
  });
}

@reflectiveTest
class GetPostfixCompletionTest extends AbstractAnalysisServerIntegrationTest {
  test_postfix_completion() async {
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

    // expect a postfix completion result
    EditGetPostfixCompletionResult result =
        await sendEditGetPostfixCompletion(pathname, '.tryon', loc);
    expect(result.change.edits, isNotEmpty);

    // apply the edit, expect that the new code has no errors
    SourceChange change = result.change;
    expect(change.edits.first.edits, isNotEmpty);
    for (SourceEdit edit in change.edits.first.edits) {
      text = text.replaceRange(edit.offset, edit.end, edit.replacement);
    }
    await sendAnalysisUpdateContent({pathname: new AddContentOverlay(text)});

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);
  }
}
