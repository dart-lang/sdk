// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/postfix/postfix_completion.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
  late TestCode testCodeCode;
  late PostfixCompletionProcessor processor;
  late SourceChange change;

  void _assertHasChange(String message, String expected) {
    if (change.message != message) {
      fail('Expected to find |$message| but got: ${change.message}');
    }
    if (change.edits.isNotEmpty) {
      // We use a carat in the expected code to prevent lines containing only
      // whitespace from being made empty.
      var expectedCode = TestCode.parse(normalizeSource(expected));
      var resultCode = SourceEdit.applySequence(
        testCode,
        change.edits[0].edits,
      );
      expect(resultCode, expectedCode.code);
    }
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
    testCodeCode = TestCode.parse(normalizeSource(code));

    verifyNoTestUnitErrors = false;
    await resolveTestCode(testCodeCode.code);

    var context = PostfixCompletionContext(
      testAnalysisResult,
      testCodeCode.position.offset,
      key,
    );
    processor = PostfixCompletionProcessor(context);
  }
}

@reflectiveTest
class _AssertTest extends PostfixCompletionTest {
  Future<void> test_assert() async {
    await _prepareCompletion('.assert', '''
f(bool expr) {
  expr^
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
  () => true^
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
  () => null^
}
''');
  }

  Future<void> test_assertFuncCmp() async {
    await _prepareCompletion('.assert', '''
f(int x, int y) {
  () => x + 3 > y + 4^
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
  {}^
}
''');
  }

  Future<void> test_forEmptyDynamic() async {
    await _prepareCompletion('.for', '''
f() {
  []^
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in []) {
    ^
  }
}
''');
  }

  Future<void> test_forEmptyString() async {
    await _prepareCompletion('.for', '''
f() {
  <String>[]^
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in <String>[]) {
    ^
  }
}
''');
  }

  Future<void> test_fori() async {
    await _prepareCompletion('.fori', '''
f() {
  100^
}
''');
    _assertHasChange('Expand .fori', '''
f() {
  for (int i = 0; i < 100; i++) {
    ^
  }
}
''');
  }

  Future<void> test_fori_invalid() async {
    await _assertNotApplicable('.fori', '''
f() {
  []^
}
''');
  }

  Future<void> test_forIntList() async {
    await _prepareCompletion('.for', '''
f() {
  [1,2,3]^
}
''');
    _assertHasChange('Expand .for', '''
f() {
  for (var value in [1,2,3]) {
    ^
  }
}
''');
  }

  Future<void> test_foriVar() async {
    await _prepareCompletion('.fori', '''
f() {
  var n = 100;
  n^
}
''');
    _assertHasChange('Expand .fori', '''
f() {
  var n = 100;
  for (int i = 0; i < n; i++) {
    ^
  }
}
''');
  }

  Future<void> test_iter_List_dynamic() async {
    await _prepareCompletion('.iter', '''
f(List values) {
  values^
}
''');
    _assertHasChange('Expand .iter', '''
f(List values) {
  for (var value in values) {
    ^
  }
}
''');
  }

  Future<void> test_iter_List_int() async {
    await _prepareCompletion('.iter', '''
f(List<int> values) {
  values^
}
''');
    _assertHasChange('Expand .iter', '''
f(List<int> values) {
  for (var value in values) {
    ^
  }
}
''');
  }

  Future<void> test_iterList() async {
    await _prepareCompletion('.iter', '''
f() {
  [1,2,3]^
}
''');
    _assertHasChange('Expand .iter', '''
f() {
  for (var value in [1,2,3]) {
    ^
  }
}
''');
  }

  Future<void> test_iterName() async {
    await _prepareCompletion('.iter', '''
f() {
  var value = [1,2,3];
  value^
}
''');
    _assertHasChange('Expand .iter', '''
f() {
  var value = [1,2,3];
  for (var value1 in value) {
    ^
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
  val^
}
''');
    _assertHasChange('Expand .else', '''
f(bool val) {
  if (!val) {
    ^
  }
}
''');
  }

  Future<void> test_if() async {
    await _prepareCompletion('.if', '''
f() {
  3 < 4^
}
''');
    _assertHasChange('Expand .if', '''
f() {
  if (3 < 4) {
    ^
  }
}
''');
  }

  Future<void> test_if_invalid() async {
    await _assertNotApplicable('.if', '''
f(List expr) {
  expr^
}
''');
  }

  Future<void> test_if_invalid_importPrefix() async {
    await _assertNotApplicable('.if', '''
import 'dart:async' as p;
f() {
  p^
}
''');
  }

  Future<void> test_ifDynamic() async {
    await _assertNotApplicable('.if', '''
f(expr) {
  expr^
}
''');
  }
}

@reflectiveTest
class _NegateTest extends PostfixCompletionTest {
  Future<void> test_negate() async {
    await _prepareCompletion('.not', '''
f(bool expr) {
  if (expr^)
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
  if (expr^)
}
''');
  }

  Future<void> test_negateCascade() async {
    await _prepareCompletion('.not', '''
void f(bool expr) {
  if (expr..a..b..c^)
}

extension on bool {
  void a() {}
  void b() {}
  void c() {}
}
''');
    _assertHasChange('Expand .not', '''
void f(bool expr) {
  if (!expr..a..b..c)
}

extension on bool {
  void a() {}
  void b() {}
  void c() {}
}
''');
  }

  Future<void> test_negateExpr() async {
    await _prepareCompletion('.not', '''
f(int i, int j) {
  if (i + 3 < j - 4^)
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
  if (b.a.f^)
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
  if (false^)
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
  if (f()^)
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
  if (true^)
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
  list^
}
''');
    _assertHasChange('Expand .nn', '''
f() {
  var list = [1,2,3];
  if (list != null) {
    ^
  }
}
''');
  }

  Future<void> test_nn_invalid() async {
    await _assertNotApplicable('.nn', '''
f() {
  var list = [1,2,3];
}^
''');
  }

  Future<void> test_nnDynamic() async {
    await _prepareCompletion('.nn', '''
f(expr) {
  expr^
}
''');
    _assertHasChange('Expand .nn', '''
f(expr) {
  if (expr != null) {
    ^
  }
}
''');
  }

  Future<void> test_notnull() async {
    await _prepareCompletion('.notnull', '''
f(expr) {
  var list = [1,2,3];
  list^
}
''');
    _assertHasChange('Expand .notnull', '''
f(expr) {
  var list = [1,2,3];
  if (list != null) {
    ^
  }
}
''');
  }

  Future<void> test_null() async {
    await _prepareCompletion('.null', '''
f(expr) {
  expr^
}
''');
    _assertHasChange('Expand .null', '''
f(expr) {
  if (expr == null) {
    ^
  }
}
''');
  }

  Future<void> test_nullnn() async {
    await _prepareCompletion('.nn', '''
f() {
  null^
}
''');
    _assertHasChange('Expand .nn', '''
f() {
  if (false) {
    ^
  }
}
''');
  }

  Future<void> test_nullnull() async {
    await _prepareCompletion('.null', '''
f() {
  null^
}
''');
    _assertHasChange('Expand .null', '''
f() {
  if (true) {
    ^
  }
}
''');
  }
}

@reflectiveTest
class _ParenTest extends PostfixCompletionTest {
  @override
  String get testPackageLanguageVersion => '2.9';

  Future<void> test_paren() async {
    await _prepareCompletion('.par', '''
f(expr) {
  expr^
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
  @override
  String get testPackageLanguageVersion => '2.9';

  Future<void> test_return() async {
    await _prepareCompletion('.return', '''
f(expr) {
  expr^
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
  @override
  String get testPackageLanguageVersion => '2.9';

  Future<void> test_return() async {
    await _prepareCompletion('.switch', '''
f(expr) {
  expr^
}
''');
    _assertHasChange('Expand .switch', '''
f(expr) {
  switch (expr) {
    ^
  }
}
''');
  }
}

@reflectiveTest
class _TryTest extends PostfixCompletionTest {
  Future<void> test_try() async {
    await _prepareCompletion('.try', '''
f() {
  var x = 1^
}
''');
    _assertHasChange('Expand .try', '''
f() {
  try {
    var x = 1^
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
  do {} while (true);^
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
    ..fourth^
}
''');
    _assertHasChange('Expand .try', '''
f(arg) {
  try {
    arg
      ..first
      ..second
      ..third
      ..fourth^
  } catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryon() async {
    await _prepareCompletion('.tryon', '''
f() {
  var x = 1^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    var x = 1^
  } on Exception catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement() async {
    await _prepareCompletion('.tryon', '''
f() {
  throw 'error';^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    throw 'error';^
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd() async {
    await _prepareCompletion('.tryon', '''
f() {
  throw 'error';^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    throw 'error';^
  } on String catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowStatement_nnbd_nullable() async {
    await _prepareCompletion('.tryon', '''
f() {
  String? x;
  throw x;^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  String? x;
  try {
    throw x;^
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
  throw x;^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  List<String?>? x;
  try {
    throw x;^
  } on List<String?> catch (e, s) {
    print(s);
  }
}
''');
  }

  Future<void> test_tryonThrowString() async {
    await _prepareCompletion('.tryon', '''
f() {
  throw 'error'^
}
''');
    _assertHasChange('Expand .tryon', '''
f() {
  try {
    throw 'error'^
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
  expr^
}
''');
    _assertHasChange('Expand .while', '''
f(bool expr) {
  while (expr) {
    ^
  }
}
''');
  }
}
