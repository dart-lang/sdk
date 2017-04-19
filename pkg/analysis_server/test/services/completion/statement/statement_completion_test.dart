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
    defineReflectiveTests(_DoCompletionTest);
    defineReflectiveTests(_ForCompletionTest);
    defineReflectiveTests(_ForEachCompletionTest);
    defineReflectiveTests(_IfCompletionTest);
    defineReflectiveTests(_SimpleCompletionTest);
    defineReflectiveTests(_SwitchCompletionTest);
    defineReflectiveTests(_WhileCompletionTest);
  });
}

class StatementCompletionTest extends AbstractSingleUnitTest {
  SourceChange change;

  bool get enableNewAnalysisDriver => true;

  int _after(String source, String match) =>
      source.indexOf(match) + match.length;

  int _afterLast(String source, String match) =>
      source.lastIndexOf(match) + match.length;

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

@reflectiveTest
class _DoCompletionTest extends StatementCompletionTest {
  test_emptyCondition() async {
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
        (s) => _after(s, 'while ('));
  }

  test_keywordOnly() async {
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
        (s) => _after(s, 'while ('));
  }

  test_noBody() async {
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
        (s) => _after(s, 'while ('));
  }

  test_noCondition() async {
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
        (s) => _after(s, 'while ('));
  }

  test_noWhile() async {
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
        (s) => _after(s, 'while ('));
  }
}

@reflectiveTest
class _ForCompletionTest extends StatementCompletionTest {
  test_emptyCondition() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  for (int i = 0;) {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (int i = 0; ) {
  }
}
''',
        (s) => _after(s, '0; '));
  }

  test_emptyInitializers() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  for () {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for () {
  }
}
''',
        (s) => _after(s, 'for ('));
  }

  test_emptyInitializersEmptyCondition() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  for (;/**/) {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (;/**/) {
  }
}
''',
        (s) => _after(s, '/**/'));
  }

  test_emptyParts() async {
    await _prepareCompletion(
        ';)',
        '''
main() {
  for (;;)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (;;) {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_emptyUpdaters() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  for (int i = 0; i < 10 /**/) {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (int i = 0; i < 10 /**/; ) {
  }
}
''',
        (s) => _after(s, '10 /**/; '));
  }

  test_keywordOnly() async {
    await _prepareCompletion(
        'for',
        '''
main() {
  for
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for () {
    ////
  }
}
''',
        (s) => _after(s, 'for ('));
  }

  test_missingLeftSeparator() async {
    await _prepareCompletion(
        '}',
        '''
main() {
  for (int i = 0) {
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (int i = 0; ) {
  }
}
''',
        (s) => _after(s, '0; '));
  }
}

@reflectiveTest
class _ForEachCompletionTest extends StatementCompletionTest {
  test_emptyIdentifier() async {
    await _prepareCompletion(
        'in xs)',
        '''
main() {
  for (in xs)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-each-statement',
        '''
main() {
  for ( in xs) {
    ////
  }
}
''',
        (s) => _after(s, 'for ('));
  }

  test_emptyIdentifierAndIterable() async {
    await _prepareCompletion(
        'in)',
        '''
main() {
  for (in)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-each-statement',
        '''
main() {
  for ( in ) {
    ////
  }
}
''',
        (s) => _after(s, 'for ('));
  }

  test_emptyIterable() async {
    await _prepareCompletion(
        'in)',
        '''
main() {
  for (var x in)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-each-statement',
        '''
main() {
  for (var x in ) {
    ////
  }
}
''',
        (s) => _after(s, 'in '));
  }
}

@reflectiveTest
class _IfCompletionTest extends StatementCompletionTest {
  test_afterCondition_BAD() async {
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
        (s) => _after(s, 'if (true) '));
  }

  test_emptyCondition() async {
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
        (s) => _after(s, 'if ('));
  }

  test_keywordOnly() async {
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
        (s) => _after(s, 'if ('));
  }

  test_withCondition() async {
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
        (s) => _after(s, '    '));
  }

  test_withElse_BAD() async {
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
        (s) => _after(s, 'if ()'));
  }

  test_withinEmptyCondition() async {
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
        (s) => _after(s, 'if ('));
  }
}

@reflectiveTest
class _SimpleCompletionTest extends StatementCompletionTest {
  test_enter() async {
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

  test_semicolon() async {
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
        (s) => _afterLast(s, '  '));
  }
}

@reflectiveTest
class _SwitchCompletionTest extends StatementCompletionTest {
  test_emptyCondition() async {
    await _prepareCompletion(
        'switch',
        '''
main() {
  switch ()
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete switch-statement',
        '''
main() {
  switch () {
    ////
  }
}
''',
        (s) => _after(s, 'switch ('));
  }

  test_keywordOnly() async {
    await _prepareCompletion(
        'switch',
        '''
main() {
  switch////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete switch-statement',
        '''
main() {
  switch () {
    ////
  }
}
''',
        (s) => _after(s, 'switch ('));
  }

  test_keywordSpace() async {
    await _prepareCompletion(
        'switch',
        '''
main() {
  switch ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete switch-statement',
        '''
main() {
  switch () {
    ////
  }
}
''',
        (s) => _after(s, 'switch ('));
  }
}

@reflectiveTest
class _WhileCompletionTest extends StatementCompletionTest {
  /*
     The implementation of completion for while-statements is shared with
     if-statements. Here we check that the wrapper for while-statements
     functions as expected. The individual test cases are covered by the
     _IfCompletionTest tests. If the implementation changes then the same
     set of tests defined for if-statements should be duplicated here.
   */
  test_keywordOnly() async {
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
        (s) => _after(s, 'while ('));
  }
}
