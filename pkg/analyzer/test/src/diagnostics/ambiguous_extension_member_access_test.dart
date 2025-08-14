// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExtensionMemberAccessTest);
  });
}

@reflectiveTest
class AmbiguousExtensionMemberAccessTest extends PubPackageResolutionTest {
  test_call() async {
    await assertErrorsInCode(
      '''
class A {}

extension E1 on A {
  int call() => 0;
}

extension E2 on A {
  int call() => 0;
}

int f(A a) => a();
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 110, 1)],
    );
  }

  test_getter_getter() async {
    await assertErrorsInCode(
      '''
extension E1 on int {
  void get a => 1;
}

extension E2 on int {
  void get a => 2;
}

f() {
  0.a;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 98, 1)],
    );

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
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  void a() {}
}

f() {
  0.a;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 91, 1)],
    );

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
    await assertErrorsInCode(
      '''
extension E on int {
  int get a => 1;
}

extension E2 on int {
  set a(int v) { }
}

f() {
  0.a;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 96, 1)],
    );

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
    await assertErrorsInCode(
      '''
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
extension E on int? { void foo() {} }
void f() {
  0.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
          129,
          3,
          messageContains: [
            "in 'extension E1 on int' and 'extension E2 on int',",
          ],
        ),
      ],
    );
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
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
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
    await assertErrorsInCode(
      '''
// ignore_for_file: unused_element
void f(Iterable<void> p) {
  p.foo();
}
extension on Iterable<Undef1> { void foo() {} }
extension on Iterable<Undef2> { void foo() {} }
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
          66,
          3,
          messageContains: [
            "'extension on Iterable<InvalidType> "
                "(where <unnamed extension> is defined in ${testFile.path})' and "
                "'extension on Iterable<InvalidType> "
                "(where <unnamed extension> is defined in ${testFile.path})',",
          ],
          contextMessages: [message(testFile, -1, 0), message(testFile, -1, 0)],
        ),
        error(CompileTimeErrorCode.nonTypeAsTypeArgument, 97, 6),
        error(CompileTimeErrorCode.nonTypeAsTypeArgument, 145, 6),
      ],
    );
  }

  test_method_conflict_conflict_specific() async {
    await assertNoErrorsInCode('''
extension E1 on int? { void foo() {} }
extension E2 on int? { void foo() {} }
extension E on int { void foo() {} }
void f() {
  0.foo();
}
''');
  }

  test_method_conflict_notSpecific_conflict() async {
    await assertErrorsInCode(
      '''
extension E1 on int { void foo() {} }
extension E on int? { void foo() {} }
extension E2 on int { void foo() {} }
void f() {
  0.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
          129,
          3,
          messageContains: [
            "in 'extension E1 on int' and 'extension E2 on int',",
          ],
        ),
      ],
    );
  }

  test_method_conflict_specific_conflict() async {
    await assertNoErrorsInCode('''
extension E1 on int? { void foo() {} }
extension E on int { void foo() {} }
extension E2 on int? { void foo() {} }
void f() {
  0.foo();
}
''');
  }

  test_method_method() async {
    await assertErrorsInCode(
      '''
extension E1 on int {
  void a() {}
}

extension E2 on int {
  void a() {}
}

f() {
  0.a();
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 88, 1)],
    );

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
    await assertErrorsInCode(
      '''
extension E on int? { void foo() {} }
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
void f() {
  0.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
          129,
          3,
          messageContains: [
            "in 'extension E1 on int' and 'extension E2 on int',",
          ],
        ),
      ],
    );
  }

  test_method_notSpecific_conflict_conflict_conflict() async {
    await assertErrorsInCode(
      '''
extension E on int? { void foo() {} }
extension E1 on int { void foo() {} }
extension E2 on int { void foo() {} }
extension E3 on int { void foo() {} }
void f() {
  0.foo();
}
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessThreeOrMore,
          167,
          3,
          messageContains: [
            "in extension 'E1', extension 'E2', and extension 'E3',",
          ],
        ),
      ],
    );
  }

  test_method_specific_conflict_conflict() async {
    await assertNoErrorsInCode('''
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
          CompileTimeErrorCode.ambiguousExtensionMemberAccessThreeOrMore,
          108,
          3,
          contextMessages: [message(one, 10, 1), message(two, 10, 1)],
        ),
      ],
    );
  }

  test_noMoreSpecificExtension() async {
    await assertErrorsInCode(
      r'''
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
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 396, 3)],
    );
  }

  test_operator_binary() async {
    await assertErrorsInCode(
      '''
class A {}

extension E1 on A {
  A operator +(A a) => a;
}

extension E2 on A {
  A operator +(A a) => a;
}

A f(A a) => a + a;
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 122, 5)],
    );
  }

  test_operator_binary_compoundAssignment() async {
    await assertErrorsInCode(
      '''
class A {}

extension E1 on A {
  A operator +(_) => this;
}

extension E2 on A {
  A operator +(_) => this;
}

void f(A a) {
  a += 0;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 130, 2)],
    );
  }

  test_operator_index_index() async {
    await assertErrorsInCode(
      '''
class A {}

extension E1 on A {
  int operator [](int i) => 0;
}

extension E2 on A {
  int operator [](int i) => 0;
}

int f(A a) => a[0];
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 134, 1)],
    );
  }

  test_operator_index_indexEq() async {
    await assertErrorsInCode(
      '''
extension E1 on int {
  int operator[](int index) => 0;
}

extension E2 on int {
  void operator[]=(int index, int value) {}
}

f() {
  0[1] += 2;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 136, 1)],
    );
  }

  test_operator_unary() async {
    await assertErrorsInCode(
      '''
class A {}

extension E1 on A {
  int operator -() => 0;
}

extension E2 on A {
  int operator -() => 0;
}

int f(A a) => -a;
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 123, 1)],
    );
  }

  test_setter_setter() async {
    await assertErrorsInCode(
      '''
extension E1 on int {
  set a(x) {}
}

extension E2 on int {
  set a(x) {}
}

f() {
  0.a = 3;
}
''',
      [error(CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo, 88, 1)],
    );

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
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_unnamed_extensions() async {
    await assertErrorsInCode(
      '''
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

// Additional calls to avoid UNUSED_ELEMENT
int g(List<A> x) => x();
int h(List<B> x) => x();
''',
      [
        error(
          CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
          167,
          1,
          messageContains: [
            "'extension on List<A>' and 'extension on List<B>',",
          ],
        ),
      ],
    );
  }
}
