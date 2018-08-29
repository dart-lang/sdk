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
    defineReflectiveTests(GetRefactoringTest);
  });
}

@reflectiveTest
class GetRefactoringTest extends AbstractAnalysisServerIntegrationTest {
  test_rename() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
void foo() { }

void bar() {
  foo();
  foo();
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isEmpty);

    // expect no edits if no rename options specified
    EditGetRefactoringResult result = await sendEditGetRefactoring(
        RefactoringKind.RENAME, pathname, text.indexOf('foo('), 0, false);
    expect(result.initialProblems, isEmpty);
    expect(result.optionsProblems, isEmpty);
    expect(result.finalProblems, isEmpty);
    expect(result.potentialEdits, isNull);
    expect(result.change, isNull);

    // expect a valid rename refactoring
    result = await sendEditGetRefactoring(
        RefactoringKind.RENAME, pathname, text.indexOf('foo('), 0, false,
        options: new RenameOptions('baz'));
    expect(result.initialProblems, isEmpty);
    expect(result.optionsProblems, isEmpty);
    expect(result.finalProblems, isEmpty);
    expect(result.potentialEdits, isNull);
    expect(result.change.edits, isNotEmpty);

    // apply the refactoring, expect that the new code has no errors
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
