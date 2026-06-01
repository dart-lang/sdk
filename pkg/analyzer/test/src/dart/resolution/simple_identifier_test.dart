// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleIdentifierResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SimpleIdentifierResolutionTest extends PubPackageResolutionTest {
  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as mycore;

main() {
  dynamic;
//^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'dynamic'.
}
''');

    var node = result.findNode.simple('dynamic;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: dynamic
  element: <null>
  staticType: InvalidType
''');
  }

  test_expression_topLevelVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
final a = 0;

void f() {
  a;
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
final a = 0;

class C {
  C() {
    return a;
//         ^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
  }
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
final a = 0;

class C {
  C() => a;
//    ^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//       ^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'int' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_invocationArgument_afterNamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
final a = 0;

void foo(int a, {int? b}) {}

void f() {
  foo(b: 0, a);
}
''');

    var node = result.findNode.simple('a);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_implicitCall_tearOff() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int call() => 0;
}

int Function() foo(A a) {
  return a;
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::foo::@formalParameter::a
  staticType: A
''');
  }

  test_implicitCall_tearOff_nullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int call() => 0;
}

int Function() foo(A? a) {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'A?' can't be returned from the function 'foo' because it has a return type of 'int Function()'.
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::foo::@formalParameter::a
  staticType: A?
''');
  }

  test_inClass_getterInherited_setterDeclaredLocally() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 7;
}
class B extends A {
  set foo(int _) {}

  void f() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_inExtension_onFunctionType_call() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int Function(double) {
  void f() {
    call;
  }
}
''');

    var node = result.findNode.simple('call;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: call
  element: <null>
  staticType: int Function(double)
''');
  }

  test_inExtension_onFunctionType_call_inference() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int Function<T>(T) {
  int Function(double) f() {
    return call;
  }
}
''');

    var node = result.findNode.simple('call;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: call
  element: <null>
  staticType: int Function(double)
  tearOffTypeArgumentTypes
    double
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E<T extends ({int foo})> on T {
  void f() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E<T extends (int, String)> on T {
  void f() {
    $1;
  }
}
''');

    var node = result.findNode.simple(r'$1;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $1
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on ({int foo}) {
  void f() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named_fromExtension() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on ({int foo}) {
  bool get bar => true;

  void f() {
    bar;
  }
}
''');

    var node = result.findNode.simple('bar;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: bar
  element: <testLibrary>::@extension::E::@getter::bar
  staticType: bool
''');
  }

  test_inExtension_onRecordType_named_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on ({int foo}) {
  void f() {
    bar;
//  ^^^
// [diag.undefinedIdentifier] Undefined name 'bar'.
  }
}
''');

    var node = result.findNode.simple('bar;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: bar
  element: <null>
  staticType: InvalidType
''');
  }

  test_inExtension_onRecordType_positional_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void f() {
    $1;
  }
}
''');

    var node = result.findNode.simple(r'$1;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $1
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_positional_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void f() {
    $2;
  }
}
''');

    var node = result.findNode.simple(r'$2;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $2
  element: <null>
  staticType: String
''');
  }

  test_inExtension_onRecordType_positional_2_fromExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  bool get $3 => true;

  void f() {
    $3;
  }
}
''');

    var node = result.findNode.simple(r'$3;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $3
  element: <testLibrary>::@extension::E::@getter::$3
  staticType: bool
''');
  }

  test_inExtension_onRecordType_positional_2_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void f() {
    $3;
//  ^^
// [diag.undefinedIdentifier] Undefined name '$3'.
  }
}
''');

    var node = result.findNode.simple(r'$3;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $3
  element: <null>
  staticType: InvalidType
''');
  }

  test_inExtensionType_declared() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;

  void f() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_inExtensionType_explicitThis_exposed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B extends A {}

extension type X(B it) implements A {
  void f() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  test_localFunction_generic() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  static void foo<S>(S s) {
    void f<U>(S s, U u) {}
    f;
  }
}
''');

    var node = result.findNode.simple('f;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: f
  element: f@50
  staticType: void Function<U>(S, U)
''');
  }

  test_tearOff_function_topLevel() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo(int a) {}

main() {
  foo;
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@function::foo
  staticType: void Function(int)
''');
  }

  test_tearOff_method() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int a) {}

  bar() {
    foo;
  }
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function(int)
''');
  }
}
