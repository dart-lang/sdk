// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNullAwareOperatorAfterShortCircuitTest);
    defineReflectiveTests(InvalidNullAwareOperatorTest);
  });
}

@reflectiveTest
class InvalidNullAwareOperatorAfterShortCircuitTest
    extends PubPackageResolutionTest {
  Future<void> test_getter_previousTarget() async {
    await assertErrorsInCode(
      '''
void f(String? s) {
  s?.length?.isEven;
}
''',
      [
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          31,
          2,
          contextMessages: [message(testFile, 23, 2)],
        ),
      ],
    );
  }

  Future<void> test_index_previousTarget() async {
    await assertErrorsInCode(
      '''
void f(String? s) {
  s?[4]?.length;
}
''',
      [
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          27,
          2,
          contextMessages: [message(testFile, 23, 1)],
        ),
      ],
    );
  }

  Future<void> test_methodInvocation_noTarget() async {
    await assertErrorsInCode(
      '''
class C {
  C? m1() => this;
  C m2() => this;
  void m3() {
    m1()?.m2()?.m2();
  }
}
''',
      [
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          75,
          2,
          contextMessages: [message(testFile, 69, 2)],
        ),
      ],
    );
  }

  Future<void> test_methodInvocation_previousTarget() async {
    await assertErrorsInCode(
      '''
void f(String? s) {
  s?.substring(0, 5)?.length;
}
''',
      [
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          40,
          2,
          contextMessages: [message(testFile, 23, 2)],
        ),
      ],
    );
  }

  Future<void> test_methodInvocation_previousTwoTargets() async {
    await assertErrorsInCode(
      '''
void f(String? s) {
  s?.substring(0, 5)?.toLowerCase()?.length;
}
''',
      [
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          40,
          2,
          contextMessages: [message(testFile, 23, 2)],
        ),
        error(
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
          55,
          2,
          contextMessages: [message(testFile, 23, 2)],
        ),
      ],
    );
  }
}

@reflectiveTest
class InvalidNullAwareOperatorTest extends PubPackageResolutionTest {
  test_extensionOverride_assignmentExpression_indexExpression() async {
    await assertErrorsInCode(
      '''
extension E on int {
  operator[]=(int index, bool _) {}
}

void f(int? a, int b) {
  E(a)?[0] = true;
  E(b)?[0] = true;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 109, 2)],
    );
  }

  test_extensionOverride_assignmentExpression_propertyAccess() async {
    await assertErrorsInCode(
      '''
extension E on int {
  set foo(bool _) {}
}

void f(int? a, int b) {
  E(a)?.foo = true;
  E(b)?.foo = true;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 95, 2)],
    );
  }

  test_extensionOverride_indexExpression() async {
    await assertErrorsInCode(
      '''
extension E on int {
  bool operator[](int index) => true;
}

void f(int? a, int b) {
  E(a)?[0];
  E(b)?[0];
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 104, 2)],
    );
    assertType(findNode.index('E(a)'), 'bool?');
    assertType(findNode.index('E(b)'), 'bool?');
  }

  test_extensionOverride_methodInvocation() async {
    await assertErrorsInCode(
      '''
extension E on int {
  bool foo() => true;
}

void f(int? a, int b) {
  E(a)?.foo();
  E(b)?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 91, 2)],
    );

    assertType(findNode.methodInvocation('E(a)'), 'bool?');
    assertType(findNode.methodInvocation('E(b)'), 'bool?');
  }

  test_extensionOverride_propertyAccess() async {
    await assertErrorsInCode(
      '''
extension E on int {
  bool get foo => true;
}

void f(int? a, int b) {
  E(a)?.foo;
  E(b)?.foo;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 91, 2)],
    );
    assertType(findNode.propertyAccess('E(a)'), 'bool?');
    assertType(findNode.propertyAccess('E(b)'), 'bool?');
  }

  test_getter_class() async {
    await assertErrorsInCode(
      '''
class C {
  static int x = 0;
}

f() {
  C?.x;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 42, 2)],
    );
  }

  test_getter_extension() async {
    await assertErrorsInCode(
      '''
extension E on int {
  static int x = 0;
}

f() {
  E?.x;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 53, 2)],
    );
  }

  test_getter_mixin() async {
    await assertErrorsInCode(
      '''
mixin M {
  static int x = 0;
}

f() {
  M?.x;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 42, 2)],
    );
  }

  test_getter_nonNullable() async {
    await assertErrorsInCode(
      '''
f(int x) {
  x?.isEven;
  x?..isEven;
}
''',
      [
        error(StaticWarningCode.invalidNullAwareOperator, 14, 2),
        error(StaticWarningCode.invalidNullAwareOperator, 27, 3),
      ],
    );
  }

  test_getter_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x?.isEven;
  x?..isEven;
}
''');
  }

  /// Here we test that analysis does not crash while checking whether to
  /// report [StaticWarningCode.invalidNullAwareOperator]. But we also
  /// report another error.
  test_getter_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertErrorsInCode(
      '''
import 'a.dart' as p;

f() {
  p?.x;
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 31, 1)],
    );
  }

  test_index_nonNullable() async {
    await assertErrorsInCode(
      '''
f(List<int> x) {
  x?[0];
  x?..[0];
}
''',
      [
        error(StaticWarningCode.invalidNullAwareOperator, 20, 2),
        error(StaticWarningCode.invalidNullAwareOperator, 29, 3),
      ],
    );
  }

  test_index_nullable() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  x?[0];
  x?..[0];
}
''');
  }

  test_invalid_nonNullable() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nonNull;
  i.isEven;
}
''',
      [
        error(CompileTimeErrorCode.undefinedClass, 2, 10),
        error(
          CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue,
          44,
          6,
        ),
      ],
    );
  }

  test_invalid_nullable() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nullable;
  i?.isEven;
}
''',
      [error(CompileTimeErrorCode.undefinedClass, 2, 10)],
    );
  }

  test_method_class() async {
    await assertErrorsInCode(
      '''
class C {
  static void foo() {}
}

f() {
  C?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 45, 2)],
    );
  }

  test_method_class_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static void foo() {}
}
''');

    await assertErrorsInCode(
      '''
import 'a.dart' as prefix;

void f() {
  prefix.C?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 49, 2)],
    );
  }

  test_method_extension() async {
    await assertErrorsInCode(
      '''
extension E on int {
  static void foo() {}
}

f() {
  E?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 56, 2)],
    );
  }

  test_method_extension_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static void foo() {}
}
''');

    await assertErrorsInCode(
      '''
import 'a.dart' as prefix;

f() {
  prefix.E?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 44, 2)],
    );
  }

  test_method_mixin() async {
    await assertErrorsInCode(
      '''
mixin M {
  static void foo() {}
}

f() {
  M?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 45, 2)],
    );
  }

  test_method_mixin_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M {
  static void foo() {}
}
''');

    await assertErrorsInCode(
      '''
import 'a.dart' as prefix;

f() {
  prefix.M?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 44, 2)],
    );
  }

  test_method_nonNullable() async {
    await assertErrorsInCode(
      '''
f(int x) {
  x?.round();
  x?..round();
}
''',
      [
        error(StaticWarningCode.invalidNullAwareOperator, 14, 2),
        error(StaticWarningCode.invalidNullAwareOperator, 28, 3),
      ],
    );
  }

  test_method_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x?.round();
  x?..round();
}
''');
  }

  test_method_typeAlias_class() async {
    await assertErrorsInCode(
      '''
class A {
  static void foo() {}
}

typedef B = A; 

f() {
  B?.foo();
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 62, 2)],
    );
  }

  test_nonNullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int> x) {
  [...x];
}
''');
  }

  test_nullableSpread_nonNullableType() async {
    await assertErrorsInCode(
      '''
f(List<int> x) {
  [...?x];
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 20, 4)],
    );
  }

  test_nullableSpread_nullableType() async {
    await assertNoErrorsInCode('''
f(List<int>? x) {
  [...?x];
}
''');
  }

  test_setter_class() async {
    await assertErrorsInCode(
      '''
class C {
  static int x = 0;
}

f() {
  C?.x = 0;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 42, 2)],
    );
  }

  test_setter_extension() async {
    await assertErrorsInCode(
      '''
extension E on int {
  static int x = 0;
}

f() {
  E?.x = 0;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 53, 2)],
    );
  }

  test_setter_mixin() async {
    await assertErrorsInCode(
      '''
mixin M {
  static int x = 0;
}

f() {
  M?.x = 0;
}
''',
      [error(StaticWarningCode.invalidNullAwareOperator, 42, 2)],
    );
  }

  /// Here we test that analysis does not crash while checking whether to
  /// report [StaticWarningCode.invalidNullAwareOperator]. But we also
  /// report another error.
  test_setter_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertErrorsInCode(
      '''
import 'a.dart' as p;

f() {
  p?.x = 0;
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 31, 1)],
    );
  }

  test_super() async {
    await assertErrorsInCode(
      '''
class A {
  void foo() {}
}

class B extends A {
  void bar() {
    super?.foo();
  }
}
''',
      [error(ParserErrorCode.invalidOperatorQuestionmarkPeriodForSuper, 73, 2)],
    );
  }
}
