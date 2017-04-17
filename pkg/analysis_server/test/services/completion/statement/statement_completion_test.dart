// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.statement;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementCompletionTest);
  });
}

@reflectiveTest
class StatementCompletionTest extends AbstractSingleUnitTest {
  SourceChange change;

  bool get enableNewAnalysisDriver => true;

  test_completeDoEmptyCondition() async {
    await _prepareCompletion(
        'while ()',
        '''
main() {
  do {
  } while ()
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete do-statement',
        '''
main() {
  do {
  } while ();
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_completeDoKeywordOnly() async {
    await _prepareCompletion(
        'do',
        '''
main() {
  do ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete do-statement',
        '''
main() {
  do {
    ////
  } while ();
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_completeDoNoBody() async {
    await _prepareCompletion(
        'do',
        '''
main() {
  do;
  while
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete do-statement',
        '''
main() {
  do {
    ////
  } while ();
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_completeDoNoCondition() async {
    await _prepareCompletion(
        'while',
        '''
main() {
  do {
  } while
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete do-statement',
        '''
main() {
  do {
  } while ();
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_completeDoNoWhile() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  do {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete do-statement',
        '''
main() {
  do {
  } while ();
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_completeIfAfterCondition_BAD() async {
    // TODO(messick): Fix the code to make this like test_completeIfWithCondition.
    // Recap: Finding the node at the selectionOffset returns the block, not the
    // if-statement. Need to understand if that only happens when the if-statement
    // is the only statement in the block, or perhaps first or last? And what
    // happens when it is in the middle of other statements?
    await _prepareCompletion(
        'if (true) ', // Trigger completion after space.
        '''
main() {
  if (true) ////
}
''',
        atEnd: true);
    _assertHasChange(
        // Note: This is not what we want.
        'Insert a newline at the end of the current line',
        '''
main() {
  if (true) ////
  }
}
''',
        (s) => s.indexOf('if (true) ') + 'if (true) '.length);
  }

  test_completeIfEmptyCondition() async {
    await _prepareCompletion(
        'if ()',
        '''
main() {
  if ()
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if () {
    ////
  }
}
''',
        (s) => s.indexOf('if (') + 'if ('.length);
  }

  test_completeIfKeywordOnly() async {
    await _prepareCompletion(
        'if',
        '''
main() {
  if ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if () {
    ////
  }
}
''',
        (s) => s.indexOf('if (') + 'if ('.length);
  }

  test_completeIfWithCondition() async {
    await _prepareCompletion(
        'if (tr', // Trigger completion from within expression.
        '''
main() {
  if (true)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if (true) {
    ////
  }
}
''',
        (s) => s.indexOf('    ') + '    '.length);
  }

  test_completeIfWithElse_BAD() async {
    await _prepareCompletion(
        'if ()',
        '''
main() {
  if ()
  else
}
''',
        atEnd: true);
    _assertHasChange(
        // Note: if-statement completion should not trigger.
        'Insert a newline at the end of the current line',
        '''
main() {
  if ()
  else
  }
}
''',
        (s) => s.indexOf('if ()') + 'if ()'.length);
  }

  test_completeIfWithinEmptyCondition() async {
    await _prepareCompletion(
        'if (',
        '''
main() {
  if ()
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if () {
    ////
  }
}
''',
        (s) => s.indexOf('if (') + 'if ('.length);
  }

  test_completeWhileKeywordOnly() async {
    await _prepareCompletion(
        'while',
        '''
main() {
  while ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete while-statement',
        '''
main() {
  while () {
    ////
  }
}
''',
        (s) => s.indexOf('while (') + 'while ('.length);
  }

  test_simpleEnter() async {
    await _prepareCompletion(
        'v = 1;',
        '''
main() {
  int v = 1;
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  int v = 1;
  ////
}
''');
  }

  test_simpleSemicolon() async {
    await _prepareCompletion(
        'v = 1',
        '''
main() {
  int v = 1
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  int v = 1;
  ////
}
''',
        (s) => s.lastIndexOf('  ') + '  '.length);
  }

  void _assertHasChange(String message, String expectedCode, [Function cmp]) {
    if (change.message == message) {
      if (!change.edits.isEmpty) {
        String resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode.replaceAll('////', ''));
        if (cmp != null) {
          int offset = cmp(resultCode);
          expect(change.selection.offset, offset);
        }
      } else {
        if (cmp != null) {
          int offset = cmp(testCode);
          expect(change.selection.offset, offset);
        }
      }
      return;
    }
    fail("Expected to find |$message| but got: " + change.message);
  }

  _computeCompletion(int offset) async {
    driver.changeFile(testFile);
    AnalysisResult result = await driver.getResult(testFile);
    StatementCompletionContext context = new StatementCompletionContext(
        testFile,
        result.lineInfo,
        offset,
        testUnit,
        testUnitElement,
        result.errors);
    StatementCompletionProcessor processor =
        new StatementCompletionProcessor(context);
    StatementCompletion completion = await processor.compute();
    change = completion.change;
  }

  _prepareCompletion(String search, String sourceCode,
      {bool atStart: false, bool atEnd: false, int delta: 0}) async {
    testCode = sourceCode.replaceAll('////', '');
    int offset = findOffset(search);
    if (atStart) {
      delta = 0;
    } else if (atEnd) {
      delta = search.length;
    }
    await _prepareCompletionAt(offset + delta, testCode);
  }

  _prepareCompletionAt(int offset, String sourceCode) async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit(sourceCode);
    await _computeCompletion(offset);
  }
}
