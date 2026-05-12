// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExtensionMemberAccessTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AmbiguousExtensionMemberAccessTest extends PubPackageResolutionTest {
  test_call() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E1 on A {
  int call() => 0;
}

extension E2 on A {
  int call() => 0;
}

int f(A a) => a();
//            ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'call' is defined in 'extension E1 on A' and 'extension E2 on A', and neither is more specific.
''');
  }

  test_getter_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int {
  void get a => 1;
}

extension E2 on int {
  void get a => 2;
}

f() {
  0.a;
//  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'a' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');

    var node = findNode.propertyAccess('0.a');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_getter_getterStatic() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int {
  void get a => 1;
}

extension E2 on int {
  static void get a => 2;
}

f() {
  0.a;
}
''');

    var node = findNode.propertyAccess('0.a');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <testLibrary>::@extension::E1::@getter::a
    staticType: void
  staticType: void
''');
  }

  test_getter_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  void a() {}
}

f() {
  0.a;
//  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'a' is defined in 'extension E on int' and 'extension E2 on int', and neither is more specific.
}
''');

    var node = findNode.propertyAccess('0.a');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_getter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  set a(int v) { }
}

f() {
  0.a;
//  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'a' is defined in 'extension E on int' and 'extension E2 on int', and neither is more specific.
}
''');

    var node = findNode.propertyAccess('0.a');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_method_conflict_conflict_notSpecific() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
extension E on int? { void foo() {} }
void f() {
  0.foo();
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');
  }

  test_method_conflict_conflict_notSpecific_sameName() async {
    var one = newFile('$testPackageLibPath/one.dart', '''
extension E on int { void foo() {} }
''');
    var two = newFile('$testPackageLibPath/two.dart', '''
extension E on int { void foo() {} }
''');
    await assertErrorsInCode(
      '''
// ignore_for_file: unused_import
import 'one.dart';
import 'two.dart';
void f() {
  0.foo();
}
''',
      [
        error(
          diag.ambiguousExtensionMemberAccessTwo,
          87,
          3,
          messageContains: [
            "'extension E on int (where E is defined in ${one.path})' and "
                "'extension E on int (where E is defined in ${two.path})',",
          ],
          contextMessages: [message(one, 10, 1), message(two, 10, 1)],
        ),
      ],
    );
  }

  test_method_conflict_conflict_notSpecific_sameName_invalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
void f(Iterable<void> p) {
  p.foo();
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo][context 1][context 2] A member named 'foo' is defined in 'extension on Iterable<InvalidType> (where <unnamed extension> is defined in /home/test/lib/test.dart)' and 'extension on Iterable<InvalidType> (where <unnamed extension> is defined in /home/test/lib/test.dart)', and neither is more specific.
}
extension on Iterable<Undef1> { void foo() {} }
// [context 1][column 1][length 0] <unnamed extension> is defined in /home/test/lib/test.dart
//                    ^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'Undef1' isn't a type, so it can't be used as a type argument.
extension on Iterable<Undef2> { void foo() {} }
// [context 2][column 1][length 0] <unnamed extension> is defined in /home/test/lib/test.dart
//                    ^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'Undef2' isn't a type, so it can't be used as a type argument.
''');
  }

  test_method_conflict_conflict_specific() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int? { void foo() {} }
extension E2 on int? { void foo() {} }
extension E on int { void foo() {} }
void f() {
  0.foo();
}
''');
  }

  test_method_conflict_notSpecific_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int { void foo() {} }
extension E on int? { void foo() {} }
extension E2 on int { void foo() {} }
void f() {
  0.foo();
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');
  }

  test_method_conflict_specific_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int? { void foo() {} }
extension E on int { void foo() {} }
extension E2 on int? { void foo() {} }
void f() {
  0.foo();
}
''');
  }

  test_method_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int {
  void a() {}
}

extension E2 on int {
  void a() {}
}

f() {
  0.a();
//  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'a' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');

    var node = findNode.methodInvocation('0.a()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_method_notSpecific_conflict_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int? { void foo() {} }
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
void f() {
  0.foo();
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');
  }

  test_method_notSpecific_conflict_conflict_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int? { void foo() {} }
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
extension E3 on int { void foo() {} }
void f() {
  0.foo();
//  ^^^
// [diag.ambiguousExtensionMemberAccessThreeOrMore] A member named 'foo' is defined in extension 'E1', extension 'E2', and extension 'E3', and none are more specific.
}
''');
  }

  test_method_specific_conflict_conflict() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int { void foo() {} }
extension E1 on int? { void foo() {} }
extension E2 on int? { void foo() {} }
void f() {
  0.foo();
}
''');
  }

  test_method_triple_conflict_sameName() async {
    var one = newFile('$testPackageLibPath/one.dart', '''
extension E on int { void foo() {} }
''');
    var two = newFile('$testPackageLibPath/two.dart', '''
extension E on int { void foo() {} }
''');
    newFile('$testPackageLibPath/three.dart', '''
extension E1 on int { void foo() {} }
''');
    await assertErrorsInCode(
      '''
// ignore_for_file: unused_import
import 'one.dart';
import 'two.dart';
import 'three.dart';
void f() {
  0.foo();
}
''',
      [
        error(
          diag.ambiguousExtensionMemberAccessThreeOrMore,
          108,
          3,
          contextMessages: [message(one, 10, 1), message(two, 10, 1)],
        ),
      ],
    );
  }

  test_noMoreSpecificExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
class Target<T> {}

class SubTarget<T> extends Target<T> {}

extension E1 on SubTarget<Object> {
  int get foo => 0;
}

extension E2<T> on Target<T> {
  int get foo => 0;
}

f(SubTarget<num> t) {
  // The instantiated on type of `E1(t)` is `SubTarget<Object>`.
  // The instantiated on type of `E2(t)` is `Target<num>`.
  // Neither is a subtype of the other, so the resolution is ambiguous.
  t.foo;
//  ^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'foo' is defined in 'extension E1 on SubTarget<Object>' and 'extension E2<T> on Target<T>', and neither is more specific.
}
''');
  }

  test_operator_binary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E1 on A {
  A operator +(A a) => a;
}

extension E2 on A {
  A operator +(A a) => a;
}

A f(A a) => a + a;
//          ^^^^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named '+' is defined in 'extension E1 on A' and 'extension E2 on A', and neither is more specific.
''');
  }

  test_operator_binary_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E1 on A {
  A operator +(_) => this;
}

extension E2 on A {
  A operator +(_) => this;
}

void f(A a) {
  a += 0;
//  ^^
// [diag.ambiguousExtensionMemberAccessTwo] A member named '+' is defined in 'extension E1 on A' and 'extension E2 on A', and neither is more specific.
}
''');
  }

  test_operator_index_index() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E1 on A {
  int operator [](int i) => 0;
}

extension E2 on A {
  int operator [](int i) => 0;
}

int f(A a) => a[0];
//            ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named '[]' is defined in 'extension E1 on A' and 'extension E2 on A', and neither is more specific.
''');
  }

  test_operator_index_indexEq() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int {
  int operator[](int index) => 0;
}

extension E2 on int {
  void operator[]=(int index, int value) {}
}

f() {
  0[1] += 2;
//^
// [diag.ambiguousExtensionMemberAccessTwo] A member named '[]' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');
  }

  test_operator_unary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E1 on A {
  int operator -() => 0;
}

extension E2 on A {
  int operator -() => 0;
}

int f(A a) => -a;
//             ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'unary-' is defined in 'extension E1 on A' and 'extension E2 on A', and neither is more specific.
''');
  }

  test_setter_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E1 on int {
  set a(x) {}
}

extension E2 on int {
  set a(x) {}
}

f() {
  0.a = 3;
//  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'a' is defined in 'extension E1 on int' and 'extension E2 on int', and neither is more specific.
}
''');

    assertResolvedNodeText(findNode.assignment('= 3'), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: IntegerLiteral
      literal: 0
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: a
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
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

  test_unnamed_extensions() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class C extends A implements B {}

extension on List<A> {
  int call() => 0;
}

extension on List<B> {
  int call() => 0;
}

int f(List<C> x) => x();
//                  ^
// [diag.ambiguousExtensionMemberAccessTwo] A member named 'call' is defined in 'extension on List<A>' and 'extension on List<B>', and neither is more specific.

// Additional calls to avoid UNUSED_ELEMENT
int g(List<A> x) => x();
int h(List<B> x) => x();
''');
  }
}
