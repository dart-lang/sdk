// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AssertTest);
    defineReflectiveTests(_ForTest);
    defineReflectiveTests(_NegateTest);
    defineReflectiveTests(_IfTest);
    defineReflectiveTests(_NotNullTest);
    defineReflectiveTests(_ParenTest);
    defineReflectiveTests(_ReturnTest);
    defineReflectiveTests(_SwitchTest);
    defineReflectiveTests(_TryTest);
    defineReflectiveTests(_WhileTest);
  });
}

class PostfixCompletionTest extends AbstractSingleUnitTest {
  SourceChange change;

  void _assertHasChange(String message, String expectedCode, [Function cmp]) {
    if (change.message == message) {
      if (!change.edits.isEmpty) {
        String resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode.replaceAll('/*caret*/', ''));
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

  _computeCompletion(int offset, String key) async {
    driver.changeFile(testFile);
    AnalysisResult result = await driver.getResult(testFile);
    PostfixCompletionContext context = new PostfixCompletionContext(
        testFile,
        result.lineInfo,
        offset,
        key,
        result.driver,
        testUnit,
        testUnitElement,
        result.errors);
    PostfixCompletionProcessor processor =
        new PostfixCompletionProcessor(context);
    bool isApplicable = await processor.isApplicable();
    if (!isApplicable) {
      fail("Postfix completion not applicable at given location");
    }
    PostfixCompletion completion = await processor.compute();
    change = completion.change;
  }

  _prepareCompletion(String key, String sourceCode) async {
    testCode = sourceCode.replaceAll('////', '');
    int offset = findOffset(key);
    testCode = testCode.replaceFirst(key, '', offset);
    await _prepareCompletionAt(offset, key, testCode);
  }

  _prepareCompletionAt(int offset, String key, String sourceCode) async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit(sourceCode);
    await _computeCompletion(offset, key);
  }
}

@reflectiveTest
class _AssertTest extends PostfixCompletionTest {
  test_assert() async {
    await _prepareCompletion('.assert', '''
f(bool expr) {
  expr.assert
}
''');
    _assertHasChange('Expand .assert', '''
f(bool expr) {
  assert(expr);
}
''');
  }

  test_assertFunc() async {
    await _prepareCompletion('.assert', '''
f() {
  () => true.assert
}
''');
    _assertHasChange('Expand .assert', '''
f() {
  assert(() => true);
}
''');
  }

  @failingTest
  test_assertFunc_invalid() async {
    await _prepareCompletion('.assert', '''
f() {
  () => null.assert
}
''');
  }

  test_assertFuncCmp() async {
    await _prepareCompletion('.assert', '''
f(int x, int y) {
  () => x + 3 > y + 4.assert
}
''');
    _assertHasChange('Expand .assert', '''
f(int x, int y) {
  assert(() => x + 3 > y + 4);
}
''');
  }
}

@reflectiveTest
class _ForTest extends PostfixCompletionTest {
  @failingTest
  test_for_invalid() async {
    await _prepareCompletion('.for', '''
f() {
  {}.for
}
''');
  }

  test_forEmptyDynamic() async {
    await _prepareCompletion('.for', '''
f() {
  [].for
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in []) {
    /*caret*/
  }
}
''');
  }

  test_forEmptyString() async {
    await _prepareCompletion('.for', '''
f() {
  <String>[].for
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in <String>[]) {
    /*caret*/
  }
}
''');
  }

  test_fori() async {
    await _prepareCompletion('.fori', '''
f() {
  100.fori
}
''');
    _assertHasChange('Expand .fori', '''
f() {
  for (int i = 0; i < 100; i++) {
    /*caret*/
  }
}
''');
  }

  @failingTest
  test_fori_invalid() async {
    await _prepareCompletion('.fori', '''
f() {
  [].fori
}
''');
  }

  test_forIntList() async {
    await _prepareCompletion('.for', '''
f() {
  [1,2,3].for
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in [1,2,3]) {
    /*caret*/
  }
}
''');
  }

  test_foriVar() async {
    await _prepareCompletion('.fori', '''
f() {
  var n = 100;
  n.fori
}
''');
    _assertHasChange('Expand .fori', '''
f() {
  var n = 100;
  for (int i = 0; i < n; i++) {
    /*caret*/
  }
}
''');
  }

  test_iterList() async {
    await _prepareCompletion('.iter', '''
f() {
  [1,2,3].iter
}
''');
    _assertHasChange('Expand .iter', '''
f() {
  for (var value in [1,2,3]) {
    /*caret*/
  }
}
''');
  }

  test_iterName() async {
    await _prepareCompletion('.iter', '''
f() {
  var value = [1,2,3];
  value.iter
}
''');
    _assertHasChange('Expand .iter', '''
f() {
  var value = [1,2,3];
  for (var value1 in value) {
    /*caret*/
  }
}
''');
  }
}

@reflectiveTest
class _IfTest extends PostfixCompletionTest {
  test_Else() async {
    await _prepareCompletion('.else', '''
f(bool val) {
  val.else
}
''');
    _assertHasChange('Expand .else', '''
f(bool val) {
  if (!val) {
    /*caret*/
  }
}
''');
  }

  test_if() async {
    await _prepareCompletion('.if', '''
f() {
  3 < 4.if
}
''');
    _assertHasChange('Expand .if', '''
f() {
  if (3 < 4) {
    /*caret*/
  }
}
''');
  }

  @failingTest
  test_if_invalid() async {
    await _prepareCompletion('.if', '''
f(List expr) {
  expr.if
}
''');
  }

  test_ifDynamic() async {
    await _prepareCompletion('.if', '''
f(expr) {
  expr.if
}
''');
    _assertHasChange('Expand .if', '''
f(expr) {
  if (expr) {
    /*caret*/
  }
}
''');
  }
}

@reflectiveTest
class _NegateTest extends PostfixCompletionTest {
  test_negate() async {
    await _prepareCompletion('.not', '''
f(expr) {
  if (expr.not)
}
''');
    _assertHasChange('Expand .not', '''
f(expr) {
  if (!expr)
}
''');
  }

  @failingTest
  test_negate_invalid() async {
    await _prepareCompletion('.not', '''
f(int expr) {
  if (expr.not)
}
''');
  }

  test_negateCascade() async {
    await _prepareCompletion('.not', '''
f(expr) {
  if (expr..a..b..c.not)
}
''');
    _assertHasChange('Expand .not', '''
f(expr) {
  if (!expr..a..b..c)
}
''');
  }

  test_negateExpr() async {
    await _prepareCompletion('.not', '''
f(int i, int j) {
  if (i + 3 < j - 4.not)
}
''');
    _assertHasChange('Expand .not', '''
f(int i, int j) {
  if (i + 3 >= j - 4)
}
''');
  }

  test_negateProperty() async {
    await _prepareCompletion('.not', '''
f(expr) {
  if (expr.a.b.c.not)
}
''');
    _assertHasChange('Expand .not', '''
f(expr) {
  if (!expr.a.b.c)
}
''');
  }

  test_notFalse() async {
    await _prepareCompletion('!', '''
f() {
  if (false!)
}
''');
    _assertHasChange('Expand !', '''
f() {
  if (true)
}
''');
  }

  test_notFunc() async {
    await _prepareCompletion('.not', '''
bool f() {
  if (f().not)
}
''');
    _assertHasChange('Expand .not', '''
bool f() {
  if (!f())
}
''');
  }

  test_notTrue() async {
    await _prepareCompletion('.not', '''
f() {
  if (true.not)
}
''');
    _assertHasChange('Expand .not', '''
f() {
  if (false)
}
''');
  }
}

@reflectiveTest
class _NotNullTest extends PostfixCompletionTest {
  test_nn() async {
    await _prepareCompletion('.nn', '''
f(expr) {
  var list = [1,2,3];
  list.nn
}
''');
    _assertHasChange('Expand .nn', '''
f(expr) {
  var list = [1,2,3];
  if (list != null) {
    /*caret*/
  }
}
''');
  }

  @failingTest
  test_nn_invalid() async {
    await _prepareCompletion('.nn', '''
f(expr) {
  var list = [1,2,3];
}.nn
''');
  }

  test_nnDynamic() async {
    await _prepareCompletion('.nn', '''
f(expr) {
  expr.nn
}
''');
    _assertHasChange('Expand .nn', '''
f(expr) {
  if (expr != null) {
    /*caret*/
  }
}
''');
  }

  test_notnull() async {
    await _prepareCompletion('.notnull', '''
f(expr) {
  var list = [1,2,3];
  list.notnull
}
''');
    _assertHasChange('Expand .notnull', '''
f(expr) {
  var list = [1,2,3];
  if (list != null) {
    /*caret*/
  }
}
''');
  }

  test_null() async {
    await _prepareCompletion('.null', '''
f(expr) {
  var list = [1,2,3];
  list.null
}
''');
    _assertHasChange('Expand .null', '''
f(expr) {
  var list = [1,2,3];
  if (list == null) {
    /*caret*/
  }
}
''');
  }

  test_nullnn() async {
    await _prepareCompletion('.nn', '''
f() {
  null.nn
}
''');
    _assertHasChange('Expand .nn', '''
f() {
  if (false) {
    /*caret*/
  }
}
''');
  }

  test_nullnull() async {
    await _prepareCompletion('.null', '''
f() {
  null.null
}
''');
    _assertHasChange('Expand .null', '''
f() {
  if (true) {
    /*caret*/
  }
}
''');
  }
}

@reflectiveTest
class _ParenTest extends PostfixCompletionTest {
  test_paren() async {
    await _prepareCompletion('.par', '''
f(expr) {
  expr.par
}
''');
    _assertHasChange('Expand .par', '''
f(expr) {
  (expr)
}
''');
  }
}

@reflectiveTest
class _ReturnTest extends PostfixCompletionTest {
  test_return() async {
    await _prepareCompletion('.return', '''
f(expr) {
  expr.return
}
''');
    _assertHasChange('Expand .return', '''
f(expr) {
  return expr;
}
''');
  }
}

@reflectiveTest
class _SwitchTest extends PostfixCompletionTest {
  test_return() async {
    await _prepareCompletion('.switch', '''
f(expr) {
  expr.switch
}
''');
    _assertHasChange('Expand .switch', '''
f(expr) {
  switch (expr) {
    /*caret*/
  }
}
''');
  }
}

@reflectiveTest
class _TryTest extends PostfixCompletionTest {
  test_try() async {
    await _prepareCompletion('.try', '''
f() {
  var x = 1.try
}
''');
    _assertHasChange('Expand .try', '''
f() {
  try {
    var x = 1/*caret*/
  } catch (e, s) {
    print(s);
  }
}
''');
  }

  @failingTest
  test_try_invalid() async {
    // The semicolon is fine; this fails because of the do-statement.
    await _prepareCompletion('.try', '''
f() {
  do {} while (true);.try
}
''');
  }

  test_tryMultiline() async {
    await _prepareCompletion('.try', '''
f(arg) {
  arg
    ..first
    ..second
    ..third
    ..fourth.try
}
''');
    _assertHasChange('Expand .try', '''
f(arg) {
  try {
    arg
      ..first
      ..second
      ..third
      ..fourth/*caret*/
  } catch (e, s) {
    print(s);
  }
}
''');
  }

  test_tryon() async {
    await _prepareCompletion('.tryon', '''
f() {
  var x = 1.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    var x = 1/*caret*/
  } on Exception catch (e, s) {
    print(s);
  }
}
''');
  }

  test_tryonThrowStatement() async {
    await _prepareCompletion('.tryon', '''
f() {
  throw 'error';.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    throw 'error';/*caret*/
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  test_tryonThrowString() async {
    await _prepareCompletion('.tryon', '''
f() {
  throw 'error'.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    throw 'error'/*caret*/
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }
}

@reflectiveTest
class _WhileTest extends PostfixCompletionTest {
  test_while() async {
    await _prepareCompletion('.while', '''
f(expr) {
  expr.while
}
''');
    _assertHasChange('Expand .while', '''
f(expr) {
  while (expr) {
    /*caret*/
  }
}
''');
  }
}
