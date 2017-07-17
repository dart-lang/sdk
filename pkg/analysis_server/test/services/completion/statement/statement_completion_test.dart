// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_DeclarationCompletionTest);
    defineReflectiveTests(_ControlFlowCompletionTest);
    defineReflectiveTests(_DoCompletionTest);
    defineReflectiveTests(_ExpressionCompletionTest);
    defineReflectiveTests(_ForCompletionTest);
    defineReflectiveTests(_ForEachCompletionTest);
    defineReflectiveTests(_IfCompletionTest);
    defineReflectiveTests(_SimpleCompletionTest);
    defineReflectiveTests(_SwitchCompletionTest);
    defineReflectiveTests(_TryCompletionTest);
    defineReflectiveTests(_WhileCompletionTest);
  });
}

class StatementCompletionTest extends AbstractSingleUnitTest {
  SourceChange change;

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
        expect(testCode, expectedCode.replaceAll('////', ''));
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
class _ControlFlowCompletionTest extends StatementCompletionTest {
  test_doReturnExprLineComment() async {
    await _prepareCompletion(
        'return 3',
        '''
ex(e) {
  do {
    return 3//
  } while (true);
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  do {
    return 3;//
  } while (true);
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_doReturnUnterminated() async {
    await _prepareCompletion(
        'return',
        '''
ex(e) {
  do {
    return
  } while (true);
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  do {
    return;
  } while (true);
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_forEachReturn() async {
    await _prepareCompletion(
        'return;',
        '''
ex(e) {
  for (var x in e) {
    return;
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  for (var x in e) {
    return;
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_forThrowUnterminated() async {
    await _prepareCompletion(
        'throw e',
        '''
ex(e) {
  for (int i = 0; i < 3; i++) {
    throw e
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  for (int i = 0; i < 3; i++) {
    throw e;
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_ifNoBlock() async {
    await _prepareCompletion(
        'return',
        '''
ex(e) {
  if (true) return 0
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
ex(e) {
  if (true) return 0;
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_ifThrow() async {
    await _prepareCompletion(
        'throw e;',
        '''
ex(e) {
  if (true) {
    throw e;
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  if (true) {
    throw e;
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_ifThrowUnterminated() async {
    await _prepareCompletion(
        'throw e',
        '''
ex(e) {
  if (true) {
    throw e
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  if (true) {
    throw e;
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_whileReturnExpr() async {
    await _prepareCompletion(
        '+ 4',
        '''
ex(e) {
  while (true) {
    return 3 + 4
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
ex(e) {
  while (true) {
    return 3 + 4;
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }
}

@reflectiveTest
class _DeclarationCompletionTest extends StatementCompletionTest {
  test_classNameNoBody() async {
    await _prepareCompletion(
        'Sample',
        '''
class Sample
''',
        atEnd: true);
    _assertHasChange(
        'Complete class declaration',
        '''
class Sample {
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_extendsNoBody() async {
    await _prepareCompletion(
        'Sample',
        '''
class Sample extends Object
''',
        atEnd: true);
    _assertHasChange(
        'Complete class declaration',
        '''
class Sample extends Object {
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_functionDeclNoBody() async {
    await _prepareCompletion(
        'source()',
        '''
String source()
''',
        atEnd: true);
    _assertHasChange(
        'Complete function declaration',
        '''
String source() {
  ////
}
''',
        (s) => _after(s, '  '));
  }

  test_functionDeclNoParen() async {
    await _prepareCompletion(
        'source(',
        '''
String source(
''',
        atEnd: true);
    _assertHasChange(
        'Complete function declaration',
        '''
String source() {
  ////
}
''',
        (s) => _after(s, '  '));
  }

  test_implementsNoBody() async {
    await _prepareCompletion(
        'Sample',
        '''
class Interface {}
class Sample implements Interface
''',
        atEnd: true);
    _assertHasChange(
        'Complete class declaration',
        '''
class Interface {}
class Sample implements Interface {
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_methodDeclNoBody() async {
    await _prepareCompletion(
        'source()',
        '''
class Sample {
  String source()
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete function declaration',
        '''
class Sample {
  String source() {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_methodDeclNoParen() async {
    await _prepareCompletion(
        'source(',
        '''
class Sample {
  String source(
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete function declaration',
        '''
class Sample {
  String source() {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_variableDeclNoBody() async {
    await _prepareCompletion(
        'source',
        '''
String source
''',
        atEnd: true);
    _assertHasChange(
        'Complete variable declaration',
        '''
String source;
////
''',
        (s) => _after(s, ';\n'));
  }

  test_withNoBody() async {
    await _prepareCompletion(
        'Sample',
        '''
class M {}
class Sample extends Object with M
''',
        atEnd: true);
    _assertHasChange(
        'Complete class declaration',
        '''
class M {}
class Sample extends Object with M {
  ////
}
''',
        (s) => _afterLast(s, '  '));
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

  test_keywordStatement() async {
    await _prepareCompletion(
        'do',
        '''
main() {
  do ////
  return;
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
  return;
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
class _ExpressionCompletionTest extends StatementCompletionTest {
  test_listAssign() async {
    await _prepareCompletion(
        '= ',
        '''
main() {
  var x = [1, 2, 3
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  var x = [1, 2, 3];
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_listAssignMultiLine() async {
    // The indent of the final line is incorrect.
    await _prepareCompletion(
        '3',
        '''
main() {
  var x = [
    1,
    2,
    3
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  var x = [
    1,
    2,
    3,
  ];
    ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  @failingTest
  test_mapAssign() async {
    await _prepareCompletion(
        '3: 3',
        '''
main() {
  var x = {1: 1, 2: 2, 3: 3
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  var x = {1: 1, 2: 2, 3: 3};
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  @failingTest
  test_mapAssignMissingColon() async {
    await _prepareCompletion(
        '3',
        '''
main() {
  var x = {1: 1, 2: 2, 3
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  var x = {1: 1, 2: 2, 3: };
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_returnString() async {
    await _prepareCompletion(
        'text',
        '''
main() {
  if (done()) {
    return 'text
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete control flow block',
        '''
main() {
  if (done()) {
    return 'text';
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_stringAssign() async {
    await _prepareCompletion(
        '= ',
        '''
main() {
  var x = '
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  var x = '';
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_stringSingle() async {
    await _prepareCompletion(
        'text',
        '''
main() {
  print("text
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  print("text");
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_stringSingleRaw() async {
    await _prepareCompletion(
        'text',
        '''
main() {
  print(r"text
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  print(r"text");
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_stringTriple() async {
    await _prepareCompletion(
        'text',
        '''
main() {
  print(\'\'\'text
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  print(\'\'\'text\'\'\');
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_stringTripleRaw() async {
    await _prepareCompletion(
        'text',
        r"""
main() {
  print(r'''text
}
""",
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        r"""
main() {
  print(r'''text''');
  ////
}
""",
        (s) => _afterLast(s, '  '));
  }
}

@reflectiveTest
class _ForCompletionTest extends StatementCompletionTest {
  test_emptyCondition() async {
    await _prepareCompletion(
        '0;',
        '''
main() {
  for (int i = 0;)      /**/  ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (int i = 0; ; ) /**/ {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_emptyConditionWithBody() async {
    await _prepareCompletion(
        '0;',
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
  for (int i = 0; ; ) {
  }
}
''',
        (s) => _after(s, '0; '));
  }

  test_emptyInitializers() async {
    // This does nothing, same as for Java.
    await _prepareCompletion(
        'r (',
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
        (s) => _after(s, 'r ('));
  }

  test_emptyInitializersAfterBody() async {
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
        'Insert a newline at the end of the current line',
        '''
main() {
  for () {
  }
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_emptyInitializersEmptyCondition() async {
    await _prepareCompletion(
        '/**/',
        '''
main() {
  for (;/**/)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (; /**/; ) {
    ////
  }
}
''',
        (s) => _after(s, '    '));
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
        '/**/',
        '''
main() {
  for (int i = 0; i < 10 /**/)
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-statement',
        '''
main() {
  for (int i = 0; i < 10 /**/; ) {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_emptyUpdatersWithBody() async {
    await _prepareCompletion(
        '/**/',
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
        (s) => _after(s, '*/; '));
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
        '= 0',
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
  for (int i = 0; ; ) {
  }
}
''',
        (s) => _after(s, '0; '));
  }

  test_noError() async {
    await _prepareCompletion(
        ';)',
        '''
main() {
  for (;;)
  return;
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
  return;
}
''',
        (s) => _after(s, '    '));
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

  test_noError() async {
    await _prepareCompletion(
        '])',
        '''
main() {
  for (var x in [1,2])
  return;
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete for-each-statement',
        '''
main() {
  for (var x in [1,2]) {
    ////
  }
  return;
}
''',
        (s) => _after(s, '    '));
  }
}

@reflectiveTest
class _IfCompletionTest extends StatementCompletionTest {
  test_afterCondition() async {
    await _prepareCompletion(
        'if (true) ', // Trigger completion after space.
        '''
main() {
  if (true) ////
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

  test_noError() async {
    await _prepareCompletion(
        'if (true)',
        '''
main() {
  if (true)
  return;
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
  return;
}
''',
        (s) => _after(s, '    '));
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

  test_withElse() async {
    await _prepareCompletion(
        'else',
        '''
main() {
  if () {
  } else
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if () {
  } else {
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
''',
        (s) => _after(s, 'if ()'));
  }

  test_withElseNoThen() async {
    await _prepareCompletion(
        'else',
        '''
main() {
  if ()
  else
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete if-statement',
        '''
main() {
  if ()
  else {
    ////
  }
}
''',
        (s) => _after(s, '    '));
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
    _assertHasChange('Insert a newline at the end of the current line', '''
main() {
  int v = 1;
  ////
}
''');
  }

  test_noCloseParen() async {
    await _prepareCompletion(
        'ing(3',
        '''
main() {
  var s = 'sample'.substring(3
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  var s = 'sample'.substring(3);
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_noCloseParenWithSemicolon() async {
    String before = '''
main() {
  var s = 'sample'.substring(3;
}
''';
    String after = '''
main() {
  var s = 'sample'.substring(3);
  ////
}
''';
    // Check completion both before and after the semicolon.
    await _prepareCompletion('ing(3', before, atEnd: true);
    _assertHasChange('Insert a newline at the end of the current line', after,
        (s) => _afterLast(s, '  '));
    await _prepareCompletion('ing(3;', before, atEnd: true);
    _assertHasChange('Insert a newline at the end of the current line', after,
        (s) => _afterLast(s, '  '));
  }

  test_semicolonFn() async {
    await _prepareCompletion(
        '=> 3',
        '''
main() {
  int f() => 3
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  int f() => 3;
  ////
}
''',
        (s) => _afterLast(s, '  '));
  }

  test_semicolonFnBody() async {
    // It would be reasonable to add braces in this case. Unfortunately,
    // the incomplete line parses as two statements ['int;', 'f();'], not one.
    await _prepareCompletion(
        'f()',
        '''
main() {
  int f()
}
''',
        atEnd: true);
    _assertHasChange(
        'Insert a newline at the end of the current line',
        '''
main() {
  int f()
}
''',
        (s) => _afterLast(s, '()'));
  }

  test_semicolonFnBodyWithDef() async {
    // This ought to be the same as test_semicolonFnBody() but the definition
    // of f() removes an error and it appears to be a different case.
    // Suggestions for unifying the two are welcome.
    await _prepareCompletion(
        'f()',
        '''
main() {
  int f()
}
f() {}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  int f();
  ////
}
f() {}
''',
        (s) => _afterLast(s, '  '));
  }

  test_semicolonFnExpr() async {
    await _prepareCompletion(
        '=>',
        '''
main() {
  int f() =>
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  int f() => ;
  ////
}
''',
        (s) => _afterLast(s, '=> '));
  }

  test_semicolonFnSpaceExpr() async {
    await _prepareCompletion(
        '=>',
        '''
main() {
  int f() => ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Add a semicolon and newline',
        '''
main() {
  int f() => ;
  ////
}
''',
        (s) => _afterLast(s, '=> '));
  }

  test_semicolonVar() async {
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
  test_caseNoColon() async {
    await _prepareCompletion(
        'label',
        '''
main(x) {
  switch (x) {
    case label
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete switch-statement',
        '''
main(x) {
  switch (x) {
    case label: ////
  }
}
''',
        (s) => _after(s, 'label: '));
  }

  test_defaultNoColon() async {
    await _prepareCompletion(
        'default',
        '''
main(x) {
  switch (x) {
    default
  }
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete switch-statement',
        '''
main(x) {
  switch (x) {
    default: ////
  }
}
''',
        (s) => _after(s, 'default: '));
  }

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
class _TryCompletionTest extends StatementCompletionTest {
  test_catchOnly() async {
    await _prepareCompletion(
        '{} catch',
        '''
main() {
  try {
  } catch(e){} catch ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } catch(e){} catch () {
    ////
  }
}
''',
        (s) => _after(s, 'catch ('));
  }

  test_catchSecond() async {
    await _prepareCompletion(
        '} catch ',
        '''
main() {
  try {
  } catch() {
  } catch(e){} catch ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } catch() {
  } catch(e){} catch () {
    ////
  }
}
''',
        (s) => _afterLast(s, 'catch ('));
  }

  test_finallyOnly() async {
    await _prepareCompletion(
        'finally',
        '''
main() {
  try {
  } finally
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } finally {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_keywordOnly() async {
    await _prepareCompletion(
        'try',
        '''
main() {
  try////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_keywordSpace() async {
    await _prepareCompletion(
        'try',
        '''
main() {
  try ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
    ////
  }
}
''',
        (s) => _after(s, '    '));
  }

  test_onCatch() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on catch
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on catch () {
    ////
  }
}
''',
        (s) => _after(s, 'catch ('));
  }

  test_onCatchComment() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on catch
  //
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on catch () {
    ////
  }
  //
}
''',
        (s) => _after(s, 'catch ('));
  }

  test_onOnly() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on  {
    ////
  }
}
''',
        (s) => _after(s, ' on '));
  }

  test_onSpace() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on  {
    ////
  }
}
''',
        (s) => _after(s, ' on '));
  }

  test_onSpaces() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on  ////
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on  {
    ////
  }
}
''',
        (s) => _after(s, ' on '));
  }

  test_onType() async {
    await _prepareCompletion(
        'on',
        '''
main() {
  try {
  } on Exception
}
''',
        atEnd: true);
    _assertHasChange(
        'Complete try-statement',
        '''
main() {
  try {
  } on Exception {
    ////
  }
}
''',
        (s) => _after(s, '    '));
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
