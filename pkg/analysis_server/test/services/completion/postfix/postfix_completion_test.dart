// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';
import '../../../abstract_single_unit.dart';

void main() {
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
  PostfixCompletionProcessor processor;
  SourceChange change;

  void _assertHasChange(String message, String expectedCode, [Function cmp]) {
    if (change.message == message) {
      if (change.edits.isNotEmpty) {
        var resultCode =
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
    fail('Expected to find |$message| but got: ' + change.message);
  }

  Future<void> _assertNotApplicable(String key, String code) async {
    await _prepareProcessor(key, code);

    var isApplicable = await processor.isApplicable();
    expect(isApplicable, isFalse);
  }

  Future<void> _prepareCompletion(String key, String code) async {
    await _prepareProcessor(key, code);

    var isApplicable = await processor.isApplicable();
    if (!isApplicable) {
      fail('Postfix completion not applicable at given location');
    }

    if (isApplicable) {
      var completion = await processor.compute();
      change = completion.change;
    }
  }

  Future<void> _prepareProcessor(String key, String code) async {
    var offset = code.indexOf(key);
    code = code.replaceFirst(key, '', offset);

    verifyNoTestUnitErrors = false;
    await resolveTestCode(code);

    var context = PostfixCompletionContext(testAnalysisResult, offset, key);
    processor = PostfixCompletionProcessor(context);
  }
}

@reflectiveTest
class _AssertTest extends PostfixCompletionTest {
  Future<void> test_assert() async {
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

  Future<void> test_assertFunc() async {
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

  Future<void> test_assertFunc_invalid() async {
    await _assertNotApplicable('.assert', '''
f() {
  () => null.assert
}
''');
  }

  Future<void> test_assertFuncCmp() async {
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
  Future<void> test_for_invalid() async {
    await _assertNotApplicable('.for', '''
f() {
  {}.for
}
''');
  }

  Future<void> test_forEmptyDynamic() async {
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

  Future<void> test_forEmptyString() async {
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

  Future<void> test_fori() async {
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

  Future<void> test_fori_invalid() async {
    await _assertNotApplicable('.fori', '''
f() {
  [].fori
}
''');
  }

  Future<void> test_forIntList() async {
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

  Future<void> test_foriVar() async {
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

  Future<void> test_iter_List_dynamic() async {
    await _prepareCompletion('.iter', '''
f(List values) {
  values.iter
}
''');
    _assertHasChange('Expand .iter', '''
f(List values) {
  for (var value in values) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_iter_List_int() async {
    await _prepareCompletion('.iter', '''
f(List<int> values) {
  values.iter
}
''');
    _assertHasChange('Expand .iter', '''
f(List<int> values) {
  for (var value in values) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_iterList() async {
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

  Future<void> test_iterName() async {
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
  Future<void> test_Else() async {
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

  Future<void> test_if() async {
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

  Future<void> test_if_invalid() async {
    await _assertNotApplicable('.if', '''
f(List expr) {
  expr.if
}
''');
  }

  Future<void> test_if_invalid_importPrefix() async {
    await _assertNotApplicable('.if', '''
import 'dart:async' as p;
f() {
  p.if
}
''');
  }

  Future<void> test_ifDynamic() async {
    await _assertNotApplicable('.if', '''
f(expr) {
  expr.if
}
''');
  }
}

@reflectiveTest
class _NegateTest extends PostfixCompletionTest {
  Future<void> test_negate() async {
    await _prepareCompletion('.not', '''
f(bool expr) {
  if (expr.not)
}
''');
    _assertHasChange('Expand .not', '''
f(bool expr) {
  if (!expr)
}
''');
  }

  Future<void> test_negate_invalid() async {
    await _assertNotApplicable('.not', '''
f(int expr) {
  if (expr.not)
}
''');
  }

  Future<void> test_negateCascade() async {
    await _prepareCompletion('.not', '''
f(bool expr) {
  if (expr..a..b..c.not)
}
''');
    _assertHasChange('Expand .not', '''
f(bool expr) {
  if (!expr..a..b..c)
}
''');
  }

  Future<void> test_negateExpr() async {
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

  Future<void> test_negateProperty() async {
    await _prepareCompletion('.not', '''
f(B b) {
  if (b.a.f.not)
}

class A {
  bool f;
}
`
class B {
  A a;
}
''');
    _assertHasChange('Expand .not', '''
f(B b) {
  if (!b.a.f)
}

class A {
  bool f;
}
`
class B {
  A a;
}
''');
  }

  Future<void> test_notFalse() async {
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

  Future<void> test_notFunc() async {
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

  Future<void> test_notTrue() async {
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
  Future<void> test_nn() async {
    await _prepareCompletion('.nn', '''
f() {
  var list = [1,2,3];
  list.nn
}
''');
    _assertHasChange('Expand .nn', '''
f() {
  var list = [1,2,3];
  if (list != null) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_nn_invalid() async {
    await _assertNotApplicable('.nn', '''
f() {
  var list = [1,2,3];
}.nn
''');
  }

  Future<void> test_nnDynamic() async {
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

  Future<void> test_notnull() async {
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

  Future<void> test_null() async {
    await _prepareCompletion('.null', '''
f(expr) {
  expr.null
}
''');
    _assertHasChange('Expand .null', '''
f(expr) {
  if (expr == null) {
    /*caret*/
  }
}
''');
  }

  Future<void> test_nullnn() async {
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

  Future<void> test_nullnull() async {
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
  Future<void> test_paren() async {
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
  Future<void> test_return() async {
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
  Future<void> test_return() async {
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
class _TryTest extends PostfixCompletionTest with WithNullSafetyMixin {
  Future<void> test_try() async {
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

  Future<void> test_try_invalid() async {
    // The semicolon is fine; this fails because of the do-statement.
    await _assertNotApplicable('.try', '''
f() {
  do {} while (true);.try
}
''');
  }

  Future<void> test_tryMultiline() async {
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

  Future<void> test_tryon() async {
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

  Future<void> test_tryonThrowStatement() async {
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

  Future<void> test_tryonThrowStatement_nnbd() async {
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

  Future<void> test_tryonThrowStatement_nnbd_into_legacy() async {
    newFile('/home/test/lib/a.dart', content: r'''
String? x;
''');
    await _prepareCompletion('.tryon', '''
// @dart = 2.8
import 'a.dart';
f() {
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
// @dart = 2.8
import 'a.dart';
f() {
  try {
    throw x;/*caret*/
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_into_legacy_nested() async {
    newFile('/home/test/lib/a.dart', content: r'''
List<String?> x;
''');
    await _prepareCompletion('.tryon', '''
// @dart = 2.8
import 'a.dart';
f() {
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
// @dart = 2.8
import 'a.dart';
f() {
  try {
    throw x;/*caret*/
  } on List<String> catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_legacy() async {
    newFile('/home/test/lib/a.dart', content: r'''
// @dart = 2.8
String x;
''');
    await _prepareCompletion('.tryon', '''
import 'a.dart';
f() {
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
import 'a.dart';
f() {
  try {
    throw x;/*caret*/
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_legacy_nested() async {
    newFile('/home/test/lib/a.dart', content: r'''
// @dart = 2.8
List<String> x;
''');
    await _prepareCompletion('.tryon', '''
import 'a.dart';
f() {
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
import 'a.dart';
f() {
  try {
    throw x;/*caret*/
  } on List<String> catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_nullable() async {
    await _prepareCompletion('.tryon', '''
f() {
  String? x;
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  String? x;
  try {
    throw x;/*caret*/
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_nullable_nested() async {
    await _prepareCompletion('.tryon', '''
f() {
  List<String?>? x;
  throw x;.tryon
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  List<String?>? x;
  try {
    throw x;/*caret*/
  } on List<String?> catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowString() async {
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
  Future<void> test_while() async {
    await _prepareCompletion('.while', '''
f(bool expr) {
  expr.while
}
''');
    _assertHasChange('Expand .while', '''
f(bool expr) {
  while (expr) {
    /*caret*/
  }
}
''');
  }
}
