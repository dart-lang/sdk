// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await resolveTestCodeWithDiagnostics(r'''
void f(String? s) {
  s?.length?.isEven;
// ^^
// [context 1] The operator '?.' is causing the short circuiting.
//         ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 1] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
}
''');
  }

  Future<void> test_index_previousTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String? s) {
  s?[4]?.length;
// ^
// [context 1] The operator '?' is causing the short circuiting.
//     ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 1] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
}
''');
  }

  Future<void> test_methodInvocation_noTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C? m1() => this;
  C m2() => this;
  void m3() {
    m1()?.m2()?.m2();
//      ^^
// [context 1] The operator '?.' is causing the short circuiting.
//            ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 1] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
  }
}
''');
  }

  Future<void> test_methodInvocation_previousTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String? s) {
  s?.substring(0, 5)?.length;
// ^^
// [context 1] The operator '?.' is causing the short circuiting.
//                  ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 1] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
}
''');
  }

  Future<void> test_methodInvocation_previousTwoTargets() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(String? s) {
  s?.substring(0, 5)?.toLowerCase()?.length;
// ^^
// [context 1] The operator '?.' is causing the short circuiting.
// [context 2] The operator '?.' is causing the short circuiting.
//                  ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 1] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
//                                 ^^
// [diag.invalidNullAwareOperatorAfterShortCircuit][context 2] The receiver can't be 'null' because of short-circuiting, so the null-aware operator '?.' can't be used.
}
''');
  }
}

@reflectiveTest
class InvalidNullAwareOperatorTest extends PubPackageResolutionTest {
  test_cascade_firstSectionOnly_getterReturningFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int Function() get g => () => 0;
}

f(C c) {
  c?..g().toString();
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_cascade_firstSectionOnly_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int operator[](int index) => 0;
}

f(C c) {
  // Note: no diagnostic on the second `..[0]`.
  c?..[0]..[0];
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_cascade_firstSectionOnly_methodInvocation() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int method() => 0;
}

f(C c) {
  // Note: no diagnostic on the second `..method()`.
  c?..method()..method();
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_cascade_firstSectionOnly_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int get property => 0;
}

f(C c) {
  // Note: no diagnostic on the second `..property`.
  c?..property..property;
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_extensionOverride_assignmentExpression_indexExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  operator[]=(int index, bool _) {}
}

void f(int? a, int b) {
  E(a)?[0] = true;
  E(b)?[0] = true;
//    ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?[' is unnecessary.
}
''');
  }

  test_extensionOverride_assignmentExpression_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set foo(bool _) {}
}

void f(int? a, int b) {
  E(a)?.foo = true;
  E(b)?.foo = true;
//    ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_extensionOverride_indexExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  bool operator[](int index) => true;
}

void f(int? a, int b) {
  E(a)?[0];
  E(b)?[0];
//    ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?[' is unnecessary.
}
''');
    assertType(result.findNode.index('E(a)'), 'bool?');
    assertType(result.findNode.index('E(b)'), 'bool?');
  }

  test_extensionOverride_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  bool foo() => true;
}

void f(int? a, int b) {
  E(a)?.foo();
  E(b)?.foo();
//    ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
    assertType(result.findNode.methodInvocation('E(a)'), 'bool?');
    assertType(result.findNode.methodInvocation('E(b)'), 'bool?');
  }

  test_extensionOverride_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  bool get foo => true;
}

void f(int? a, int b) {
  E(a)?.foo;
  E(b)?.foo;
//    ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
    assertType(result.findNode.propertyAccess('E(a)'), 'bool?');
    assertType(result.findNode.propertyAccess('E(b)'), 'bool?');
  }

  test_getter_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int x = 0;
}

f() {
  C?.x;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_getter_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int x = 0;
}

f() {
  E?.x;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_getter_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int x = 0;
}

f() {
  M?.x;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_getter_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  x?.isEven;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
  x?..isEven;
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_getter_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x?.isEven;
  x?..isEven;
}
''');
  }

  /// Here we test that analysis does not crash while checking whether to
  /// report [diag.invalidNullAwareOperator]. But we also
  /// report another error.
  test_getter_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

f() {
  p?.x;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_index_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int> x) {
  x?[0];
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?[' is unnecessary.
  x?..[0];
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_index_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int>? x) {
  x?[0];
  x?..[0];
}
''');
  }

  test_invalid_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nonNull;
  i.isEven;
//  ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'isEven' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
  }

  test_invalid_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nullable;
  i?.isEven;
}
''');
  }

  test_method_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void foo() {}
}

f() {
  C?.foo();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_class_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static void foo() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  prefix.C?.foo();
//        ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static void foo() {}
}

f() {
  E?.foo();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_extension_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static void foo() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

f() {
  prefix.E?.foo();
//        ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static void foo() {}
}

f() {
  M?.foo();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_mixin_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M {
  static void foo() {}
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

f() {
  prefix.M?.foo();
//        ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_method_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  x?.round();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
  x?..round();
// ^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?..' is unnecessary.
}
''');
  }

  test_method_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x?.round();
  x?..round();
}
''');
  }

  test_method_typeAlias_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}

typedef B = A; 

f() {
  B?.foo();
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_nonNullableSpread_nullableType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int> x) {
  [...x];
}
''');
  }

  test_nullableSpread_nonNullableType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int> x) {
  [...?x];
// ^^^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?...' is unnecessary.
}
''');
  }

  test_nullableSpread_nullableType() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int>? x) {
  [...?x];
}
''');
  }

  test_setter_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static int x = 0;
}

f() {
  C?.x = 0;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_setter_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int x = 0;
}

f() {
  E?.x = 0;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  test_setter_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static int x = 0;
}

f() {
  M?.x = 0;
// ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');
  }

  /// Here we test that analysis does not crash while checking whether to
  /// report [diag.invalidNullAwareOperator]. But we also
  /// report another error.
  test_setter_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

f() {
  p?.x = 0;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'p' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B extends A {
  void bar() {
    super?.foo();
//       ^^
// [diag.invalidOperatorQuestionmarkPeriodForSuper] The operator '?.' cannot be used with 'super' because 'super' cannot be null.
  }
}
''');
  }
}
