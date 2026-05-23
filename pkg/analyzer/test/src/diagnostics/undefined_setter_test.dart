// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedSetterTest extends PubPackageResolutionTest {
  test_functionAlias_typeInstantiated() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo = 7;
//        ^^^
// [diag.undefinedSetterOnFunctionType] The setter 'foo' isn't defined for the 'Fn' function type.
}

extension E on Type {
  set foo(int value) {}
}
''');
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await resolveTestCodeWithDiagnostics('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');
  }

  test_importWithPrefix_defined() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
set y(int value) {}''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}
''');
  }

  test_instance_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {}
f(T e1) { e1.m = 0; }
//           ^
// [diag.undefinedSetter] The setter 'm' isn't defined for the type 'T'.
''');
  }

  test_instance_undefined_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  f() { this.m = 0; }
//           ^
// [diag.undefinedSetter] The setter 'm' isn't defined for the type 'M'.
}
''');
  }

  test_inSubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(a) {
  if (a is A) {
    a.b = 0;
//    ^
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'A'.
  }
}
''');
  }

  test_inType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f(a) {
  if(a is A) {
    a.m = 0;
//    ^
// [diag.undefinedSetter] The setter 'm' isn't defined for the type 'A'.
  }
}
''');
  }

  test_new_cascade() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c..new = 1;
//   ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'C?'.
}
''');
  }

  test_new_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f(dynamic d) {
  d.new = 1;
//  ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'dynamic'.
}
''');
  }

  test_new_instance() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C c) {
  c.new = 1;
//  ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_interfaceType() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f() {
  C.new = 1;
//  ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_nullAware() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

f(C? c) {
  c?.new = 1;
//   ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'C'.
}
''');
  }

  test_new_typeVariable() async {
    await resolveTestCodeWithDiagnostics('''
f<T>(T t) {
  t.new = 1;
//  ^^^
// [diag.undefinedSetter] The setter 'new' isn't defined for the type 'T'.
}
''');
  }

  test_set_abstract_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  abstract int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_set_external_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_set_external_static_field_valid() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  external static int x;
}
void f(int x) {
  A.x = x;
}
''');
  }

  test_static_conditionalAccess_defined() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static var x;
}
f() { A?.x = 1; }
//     ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
''');
  }

  test_static_definedInSuperclass() async {
    await resolveTestCodeWithDiagnostics('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(p) {
  f(C.s = 1);
//    ^
// [diag.undefinedSetter] The setter 's' isn't defined for the type 'C'.
}''');
  }

  test_static_extension_instanceAccess() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}

extension E on C {
  static set a(int v) {}
}

f(C c) {
  c.a = 2;
//  ^
// [diag.undefinedSetter] The setter 'a' isn't defined for the type 'C'.
}
''');

    var node = result.findNode.assignment('a =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: a
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_static_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
f() { A.B = 0;}
//      ^
// [diag.undefinedSetter] The setter 'B' isn't defined for the type 'A'.
''');
  }

  test_typeLiteral_cascadeTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
//   ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type 'Type'.
}
''');
  }

  test_withExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}

extension E on C {}

f(C c) {
  c.a = 1;
//  ^
// [diag.undefinedSetter] The setter 'a' isn't defined for the type 'C'.
}
''');
  }
}
