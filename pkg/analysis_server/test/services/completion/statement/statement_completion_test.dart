// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/statement/statement_completion.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_ControlFlowCompletionTest);
    defineReflectiveTests(_DeclarationCompletionTest);
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
  late SourceChange change;

  void _assertHasChange(String message, String expected) {
    if (change.message != message) {
      fail('Expected to find |$message| but got: ${change.message}');
    }
    var parsedExpected = TestCode.parseNormalized(expected);
    var resultCode = change.edits.isNotEmpty
        ? SourceEdit.applySequence(testCode, change.edits[0].edits)
        : testCode;
    expect(resultCode, parsedExpected.code);
    if (parsedExpected.positions.isNotEmpty) {
      expect(change.selection!.offset, parsedExpected.position.offset);
    }
  }

  Future<void> _computeCompletion(int offset) async {
    var context = StatementCompletionContext(testAnalysisResult, offset);
    var processor = StatementCompletionProcessor(context);
    var completion = await processor.compute();
    change = completion.change;
  }

  Future<void> _prepareCompletion(String code) async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode(code);
    await _computeCompletion(parsedTestCode.position.offset);
  }
}

@reflectiveTest
class _ControlFlowCompletionTest extends StatementCompletionTest {
  Future<void> test_doReturnExprLineComment() async {
    await _prepareCompletion('''
ex(e) {
  do {
    return 3^//
  } while (true);
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  do {
    return 3;//
  } while (true);
  ^
}
''');
  }

  Future<void> test_doReturnUnterminated() async {
    await _prepareCompletion('''
ex(e) {
  do {
    return^
  } while (true);
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  do {
    return;
  } while (true);
  ^
}
''');
  }

  Future<void> test_forEachReturn() async {
    await _prepareCompletion('''
ex(e) {
  for (var x in e) {
    return;^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  for (var x in e) {
    return;
  }
  ^
}
''');
  }

  Future<void> test_forThrowUnterminated() async {
    await _prepareCompletion('''
ex(e) {
  for (int i = 0; i < 3; i++) {
    throw e^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  for (int i = 0; i < 3; i++) {
    throw e;
  }
  ^
}
''');
  }

  Future<void> test_ifNoBlock() async {
    await _prepareCompletion('''
ex(e) {
  if (true) return 0^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
ex(e) {
  if (true) return 0;
  ^
}
''');
  }

  Future<void> test_ifThrow() async {
    await _prepareCompletion('''
ex(e) {
  if (true) {
    throw e;^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  if (true) {
    throw e;
  }
  ^
}
''');
  }

  Future<void> test_ifThrowUnterminated() async {
    await _prepareCompletion('''
ex(e) {
  if (true) {
    throw e^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  if (true) {
    throw e;
  }
  ^
}
''');
  }

  Future<void> test_whileReturnExpr() async {
    await _prepareCompletion('''
ex(e) {
  while (true) {
    return 3 + 4^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
ex(e) {
  while (true) {
    return 3 + 4;
  }
  ^
}
''');
  }
}

@reflectiveTest
class _DeclarationCompletionTest extends StatementCompletionTest {
  Future<void> test_classNameNoBody() async {
    await _prepareCompletion('''
class Sample^
''');
    _assertHasChange('Complete class declaration', '''
class Sample {
  ^
}
''');
  }

  Future<void> test_extendsNoBody() async {
    await _prepareCompletion('''
class Sample^ extends Object
''');
    _assertHasChange('Complete class declaration', '''
class Sample extends Object {
  ^
}
''');
  }

  Future<void> test_functionDeclNoBody() async {
    await _prepareCompletion('''
String source()^
''');
    _assertHasChange('Complete function declaration', '''
String source() {
  ^
}
''');
  }

  Future<void> test_functionDeclNoParen() async {
    await _prepareCompletion('''
String source(^
''');
    _assertHasChange('Complete function declaration', '''
String source() {
  ^
}
''');
  }

  Future<void> test_implementsNoBody() async {
    await _prepareCompletion('''
class Interface {}
class Sample^ implements Interface
''');
    _assertHasChange('Complete class declaration', '''
class Interface {}
class Sample implements Interface {
  ^
}
''');
  }

  Future<void> test_methodDeclNoBody() async {
    await _prepareCompletion('''
class Sample {
  String source()^
}
''');
    _assertHasChange('Complete function declaration', '''
class Sample {
  String source() {
    ^
  }
}
''');
  }

  Future<void> test_methodDeclNoParen() async {
    await _prepareCompletion('''
class Sample {
  String source(^
}
''');
    _assertHasChange('Complete function declaration', '''
class Sample {
  String source() {
    ^
  }
}
''');
  }

  Future<void> test_variableDeclNoBody() async {
    await _prepareCompletion('''
String source^
''');
    _assertHasChange('Complete variable declaration', '''
String source;
^
''');
  }

  Future<void> test_withNoBody() async {
    await _prepareCompletion('''
mixin class M {}
class Sample^ extends Object with M
''');
    _assertHasChange('Complete class declaration', '''
mixin class M {}
class Sample extends Object with M {
  ^
}
''');
  }
}

@reflectiveTest
class _DoCompletionTest extends StatementCompletionTest {
  Future<void> test_emptyCondition() async {
    await _prepareCompletion('''
void f() {
  do {
  } while ()^
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
  } while (^);
}
''');
  }

  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  do^
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
    /**/
  } while (^);
}
''');
  }

  Future<void> test_keywordStatement() async {
    await _prepareCompletion('''
void f() {
  do^
  return;
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
    /**/
  } while (^);
  return;
}
''');
  }

  Future<void> test_noBody() async {
    await _prepareCompletion('''
void f() {
  do^;
  while
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
    /**/
  } while (^);
}
''');
  }

  Future<void> test_noCondition() async {
    await _prepareCompletion('''
void f() {
  do {
  } while^
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
  } while (^);
}
''');
  }

  Future<void> test_noWhile() async {
    await _prepareCompletion('''
void f() {
  do {
  }^
}
''');
    _assertHasChange('Complete do-statement', '''
void f() {
  do {
  } while (^);
}
''');
  }
}

@reflectiveTest
class _ExpressionCompletionTest extends StatementCompletionTest {
  Future<void> test_listAssign() async {
    await _prepareCompletion('''
void f() {
  var x = [1, 2, 3^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  var x = [1, 2, 3];
  ^
}
''');
  }

  Future<void> test_listAssignMultiLine() async {
    // The indent of the final line is incorrect.
    await _prepareCompletion('''
void f() {
  var x = [
    1,
    2,
    3^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  var x = [
    1,
    2,
    3,
  ];
    ^
}
''');
  }

  @failingTest
  Future<void> test_mapAssign() async {
    await _prepareCompletion('''
void f() {
  var x = {1: 1, 2: 2, 3: 3^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  var x = {1: 1, 2: 2, 3: 3};
  ^
}
''');
  }

  @failingTest
  Future<void> test_mapAssignMissingColon() async {
    await _prepareCompletion('''
void f() {
  var x = {1: 1, 2: 2, 3^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  var x = {1: 1, 2: 2, 3: };
  ^
}
''');
  }

  Future<void> test_returnString() async {
    await _prepareCompletion('''
void f() {
  if (done()) {
    return 'text^
  }
}
''');
    _assertHasChange('Complete control flow block', '''
void f() {
  if (done()) {
    return 'text';
  }
  ^
}
''');
  }

  Future<void> test_stringAssign() async {
    await _prepareCompletion('''
void f() {
  var x = '^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  var x = '';
  ^
}
''');
  }

  Future<void> test_stringSingle() async {
    await _prepareCompletion('''
void f() {
  print("text^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  print("text");
  ^
}
''');
  }

  Future<void> test_stringSingleRaw() async {
    await _prepareCompletion('''
void f() {
  print(r"text^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  print(r"text");
  ^
}
''');
  }

  Future<void> test_stringTriple() async {
    await _prepareCompletion('''
void f() {
  print(\'\'\'text^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  print(\'\'\'text\'\'\');
  ^
}
''');
  }

  Future<void> test_stringTripleRaw() async {
    await _prepareCompletion(r"""
void f() {
  print(r'''text^
}
""");
    _assertHasChange('Insert a newline at the end of the current line', r"""
void f() {
  print(r'''text''');
  ^
}
""");
  }
}

@reflectiveTest
class _ForCompletionTest extends StatementCompletionTest {
  Future<void> test_emptyCondition() async {
    await _prepareCompletion('''
void f() {
  for (int i = 0;^)      /* */
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (int i = 0; ; ) /* */ {
    ^
  }
}
''');
  }

  Future<void> test_emptyConditionWithBody() async {
    await _prepareCompletion('''
void f() {
  for (int i = 0;^) {
  }
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (int i = 0; ^; ) {
  }
}
''');
  }

  Future<void> test_emptyInitializers() async {
    // This does nothing, same as for Java.
    await _prepareCompletion('''
void f() {
  for (^) {
  }
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (^) {
  }
}
''');
  }

  Future<void> test_emptyInitializersAfterBody() async {
    await _prepareCompletion('''
void f() {
  for () {
  }^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  for () {
  }
  ^
}
''');
  }

  Future<void> test_emptyInitializersEmptyCondition() async {
    await _prepareCompletion('''
void f() {
  for (;/* */^)
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (; /* */; ) {
    ^
  }
}
''');
  }

  Future<void> test_emptyParts() async {
    await _prepareCompletion('''
void f() {
  for (;;^)
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (;;) {
    ^
  }
}
''');
  }

  Future<void> test_emptyUpdaters() async {
    await _prepareCompletion('''
void f() {
  for (int i = 0; i < 10 /* */^)
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (int i = 0; i < 10 /* */; ) {
    ^
  }
}
''');
  }

  Future<void> test_emptyUpdatersWithBody() async {
    await _prepareCompletion('''
void f() {
  for (int i = 0; i < 10 /* */^) {
  }
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (int i = 0; i < 10 /* */; ^) {
  }
}
''');
  }

  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  for^
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (^) {
    /**/
  }
}
''');
  }

  Future<void> test_missingLeftSeparator() async {
    await _prepareCompletion('''
void f() {
  for (int i = 0^) {
  }
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (int i = 0; ^; ) {
  }
}
''');
  }

  Future<void> test_noError() async {
    await _prepareCompletion('''
void f() {
  for (;;^)
  return;
}
''');
    _assertHasChange('Complete for-statement', '''
void f() {
  for (;;) {
    ^
  }
  return;
}
''');
  }
}

@reflectiveTest
class _ForEachCompletionTest extends StatementCompletionTest {
  Future<void> test_emptyIdentifier() async {
    await _prepareCompletion('''
void f() {
  for (in xs)^
}
''');
    _assertHasChange('Complete for-each-statement', '''
void f() {
  for (^ in xs) {
    /**/
  }
}
''');
  }

  Future<void> test_emptyIdentifierAndIterable() async {
    // Analyzer parser produces
    //    for (_s_ in _s_) ;
    // Fasta parser produces
    //    for (in; ;) ;
    await _prepareCompletion('''
void f() {
  for (in)^
}
''');
    _assertHasChange('Complete for-each-statement', '''
void f() {
  for (^ in ) {
    /**/
  }
}
''');
  }

  Future<void> test_emptyIterable() async {
    await _prepareCompletion('''
void f() {
  for (var x in)^
}
''');
    _assertHasChange('Complete for-each-statement', '''
void f() {
  for (var x in ^) {
    /**/
  }
}
''');
  }

  Future<void> test_noError() async {
    await _prepareCompletion('''
void f() {
  for (var x in [1,2])^
  return;
}
''');
    _assertHasChange('Complete for-each-statement', '''
void f() {
  for (var x in [1,2]) {
    ^
  }
  return;
}
''');
  }
}

@reflectiveTest
class _IfCompletionTest extends StatementCompletionTest {
  Future<void> test_afterCondition() async {
    await _prepareCompletion('''
void f() {
  if (true) ^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (true) {
    ^
  }
}
''');
  }

  Future<void> test_emptyCondition() async {
    await _prepareCompletion('''
void f() {
  if ()^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (^) {
    /**/
  }
}
''');
  }

  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  if^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (^) {
    /**/
  }
}
''');
  }

  Future<void> test_noError() async {
    await _prepareCompletion('''
void f() {
  if (true)^
  return;
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (true) {
    ^
  }
  return;
}
''');
  }

  Future<void> test_withCondition() async {
    await _prepareCompletion('''
void f() {
  if (tr^ue)
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (true) {
    ^
  }
}
''');
  }

  Future<void> test_withCondition_noRightParenthesis() async {
    await _prepareCompletion('''
void f() {
  if (true^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (true) {
    ^
  }
}
''');
  }

  Future<void> test_withElse() async {
    await _prepareCompletion('''
void f() {
  if () {
  } else^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if () {
  } else {
    ^
  }
}
''');
  }

  Future<void> test_withElse_BAD() async {
    await _prepareCompletion('''
void f() {
  if ()^
  else
}
''');
    _assertHasChange(
      // Note: if-statement completion should not trigger.
      'Insert a newline at the end of the current line',
      '''
void f() {
  if ()^
  else
}
''',
    );
  }

  Future<void> test_withElseNoThen() async {
    await _prepareCompletion('''
void f() {
  if ()
  else^
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if ()
  else {
    ^
  }
}
''');
  }

  Future<void> test_withinEmptyCondition() async {
    await _prepareCompletion('''
void f() {
  if (^)
}
''');
    _assertHasChange('Complete if-statement', '''
void f() {
  if (^) {
    /**/
  }
}
''');
  }
}

@reflectiveTest
class _SimpleCompletionTest extends StatementCompletionTest {
  Future<void> test_enter() async {
    await _prepareCompletion('''
void f() {
  int v = 1;^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  int v = 1;
  ^
}
''');
  }

  Future<void> test_expressionBody() async {
    await _prepareCompletion('''
class Thing extends Object {
  int foo() => 1^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
class Thing extends Object {
  int foo() => 1;
  ^
}
''');
  }

  Future<void> test_noCloseParen() async {
    await _prepareCompletion('''
void f() {
  var s = 'sample'.substring(3^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  var s = 'sample'.substring(3);
  ^
}
''');
  }

  Future<void> test_noCloseParenWithSemicolon1() async {
    await _prepareCompletion('''
void f() {
  var s = 'sample'.substring(3^;
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  var s = 'sample'.substring(3);
  ^
}
''');
  }

  Future<void> test_noCloseParenWithSemicolon2() async {
    await _prepareCompletion('''
void f() {
  var s = 'sample'.substring(3;^
}
''');
    _assertHasChange('Insert a newline at the end of the current line', '''
void f() {
  var s = 'sample'.substring(3);
  ^
}
''');
  }

  Future<void> test_semicolonFn() async {
    await _prepareCompletion('''
void f() {
  int f() => 3^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int f() => 3;
  ^
}
''');
  }

  Future<void> test_semicolonFnBody() async {
    // It would be reasonable to add braces in this case. Unfortunately,
    // the incomplete line parses as two statements ['int;', 'g();'], not one.
    await _prepareCompletion('''
void f() {
  int g()^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int g();
  ^
}
''');
  }

  Future<void> test_semicolonFnBodyWithDef() async {
    // This ought to be the same as test_semicolonFnBody() but the definition
    // of f() removes an error and it appears to be a different case.
    // Suggestions for unifying the two are welcome.

    // Analyzer parser produces
    //   int; f();
    // Fasta parser produces
    //   int f; ();
    // Neither of these is ideal.
    // TODO(danrubel): Improve parser recovery in this situation.
    await _prepareCompletion('''
void f() {
  int f()^
}
f() {}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int f();
  ^
}
f() {}
''');
  }

  Future<void> test_semicolonFnExpr() async {
    await _prepareCompletion('''
void f() {
  int f() =>^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int f() => ^;
  /**/
}
''');
  }

  Future<void> test_semicolonFnSpaceExpr() async {
    await _prepareCompletion('''
void f() {
  int f() => ^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int f() => ^;
  /**/
}
''');
  }

  Future<void> test_semicolonVar() async {
    await _prepareCompletion('''
void f() {
  int v = 1^
}
''');
    _assertHasChange('Add a semicolon and newline', '''
void f() {
  int v = 1;
  ^
}
''');
  }
}

@reflectiveTest
class _SwitchCompletionTest extends StatementCompletionTest {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_caseNoColon() async {
    await _prepareCompletion('''
void f(x) {
  switch (x) {
    case label^
  }
}
''');
    _assertHasChange('Complete switch-statement', '''
void f(x) {
  switch (x) {
    case label: ^
  }
}
''');
  }

  Future<void> test_caseNoColon_language219() async {
    await _prepareCompletion('''
// @dart=2.19
void f(x) {
  switch (x) {
    case label^
  }
}
''');
    _assertHasChange('Complete switch-statement', '''
// @dart=2.19
void f(x) {
  switch (x) {
    case label: ^
  }
}
''');
  }

  Future<void> test_defaultNoColon() async {
    await _prepareCompletion('''
void f(x) {
  switch (x) {
    default^
  }
}
''');
    _assertHasChange('Complete switch-statement', '''
void f(x) {
  switch (x) {
    default: ^
  }
}
''');
  }

  Future<void> test_emptyCondition() async {
    await _prepareCompletion('''
void f() {
  switch^ ()
}
''');
    _assertHasChange('Complete switch-statement', '''
void f() {
  switch (^) {
    /**/
  }
}
''');
  }

  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  switch^
}
''');
    _assertHasChange('Complete switch-statement', '''
void f() {
  switch (^) {
    /**/
  }
}
''');
  }

  Future<void> test_keywordSpace() async {
    await _prepareCompletion('''
void f() {
  switch ^
}
''');
    _assertHasChange('Complete switch-statement', '''
void f() {
  switch (^) {
    /**/
  }
}
''');
  }
}

@reflectiveTest
class _TryCompletionTest extends StatementCompletionTest {
  Future<void> test_catchOnly() async {
    await _prepareCompletion('''
void f() {
  try {
  } catch(e){} catch ^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } catch(e){} catch (^) {
    /**/
  }
}
''');
  }

  Future<void> test_catchSecond() async {
    await _prepareCompletion('''
void f() {
  try {
  } catch() {
  } catch(e){} catch ^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } catch() {
  } catch(e){} catch (^) {
    /**/
  }
}
''');
  }

  Future<void> test_finallyOnly() async {
    await _prepareCompletion('''
void f() {
  try {
  } finally^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } finally {
    ^
  }
}
''');
  }

  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  try^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
    ^
  }
}
''');
  }

  Future<void> test_keywordSpace() async {
    await _prepareCompletion('''
void f() {
  try ^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
    ^
  }
}
''');
  }

  Future<void> test_onCatch() async {
    await _prepareCompletion('''
void f() {
  try {
  } on catch^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on catch (^) {
    /**/
  }
}
''');
  }

  Future<void> test_onCatchComment() async {
    await _prepareCompletion('''
void f() {
  try {
  } on catch^
  //
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on catch (^) {
    /**/
  }
  //
}
''');
  }

  Future<void> test_onOnly() async {
    await _prepareCompletion('''
void f() {
  try {
  } on^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on ^ {
    /**/
  }
}
''');
  }

  Future<void> test_onSpace() async {
    await _prepareCompletion('''
void f() {
  try {
  } on ^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on ^ {
    /**/
  }
}
''');
  }

  Future<void> test_onSpaces() async {
    await _prepareCompletion('''
void f() {
  try {
  } on  ^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on ^ {
    /**/
  }
}
''');
  }

  Future<void> test_onType() async {
    await _prepareCompletion('''
void f() {
  try {
  } on Exception^
}
''');
    _assertHasChange('Complete try-statement', '''
void f() {
  try {
  } on Exception {
    ^
  }
}
''');
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
  Future<void> test_keywordOnly() async {
    await _prepareCompletion('''
void f() {
  while ^
}
''');
    _assertHasChange('Complete while-statement', '''
void f() {
  while (^) {
    /**/
  }
}
''');
  }
}
