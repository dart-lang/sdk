// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IndexExpressionResolutionTest extends PubPackageResolutionTest {
  test_contextType_read() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator [](int index) => false;
  operator []=(String index, bool value) {}
}

void f(A a) {
  a[ g() ];
}

T g<T>() => throw 0;
''');

    var node = findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_contextType_readWrite_readLower() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator [](int index) => 0;
  operator []=(num index, int value) {}
}

void f(A a) {
  a[ g() ]++;
}

T g<T>() => throw 0;
''');

    var node = findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_contextType_readWrite_writeLower() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator [](num index) => 0;
  operator []=(int index, int value) {}
}

void f(A a) {
  a[ g() ]++;
}

T g<T>() => throw 0;
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 107, 3)],
    );

    var node = findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_contextType_write() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator [](int index) => false;
  operator []=(String index, bool value) {}
}

void f(A a) {
  a[ g() ] = true;
}

T g<T>() => throw 0;
''');

    var node = findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    element: <testLibrary>::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
  staticInvokeType: String Function()
  staticType: String
  typeArgumentTypes
    String
''');
  }

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode(r'''
void f({a = b?[0]}) {}
''');

    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49101
    assertResolvedNodeText(findNode.index('[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode(r'''
typedef void F({a = b?[0]});
''');

    assertResolvedNodeText(findNode.index('[0]'), r'''
IndexExpression
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_read() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A a) {
  a[0];
}
''');

    var indexExpression = findNode.index('a[0]');
    assertResolvedNodeText(indexExpression, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');
  }

  test_read_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?..[0]..[1];
}
''');

    assertResolvedNodeText(findNode.index('..[0]'), r'''
IndexExpression
  period: ?..
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');

    assertResolvedNodeText(findNode.index('..[1]'), r'''
IndexExpression
  period: ..
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_read_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
}

void f(A<double> a) {
  a[0];
}
''');

    var indexExpression = findNode.index('a[0]');
    assertResolvedNodeText(indexExpression, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A<double>
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: ParameterMember
      baseElement: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      substitution: {T: double}
    staticType: int
  rightBracket: ]
  element: MethodMember
    baseElement: <testLibrary>::@class::A::@method::[]
    substitution: {T: double}
  staticType: double
''');
  }

  test_read_index_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    this[super];
  }

  int operator[](Object index) => 0;
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 32, 5)],
    );

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: ThisExpression
    thisKeyword: this
    staticType: A
  leftBracket: [
  index: SuperExpression
    superKeyword: super
    staticType: A
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: int
''');
  }

  test_read_index_unresolved() async {
    await assertErrorsInCode(
      r'''
void f(List<int> a) {
  a[b];
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 26, 1)],
    );

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: List<int>
  leftBracket: [
  index: SimpleIdentifier
    token: b
    correspondingParameter: ParameterMember
      baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
      substitution: {E: int}
    element: <null>
    staticType: InvalidType
  rightBracket: ]
  element: MethodMember
    baseElement: dart:core::@class::List::@method::[]
    substitution: {E: int}
  staticType: int
''');
  }

  test_read_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?[0];
}
''');

    var indexExpression = findNode.index('a?[0]');
    assertResolvedNodeText(indexExpression, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  question: ?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool?
''');
  }

  test_read_ofExtension() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  bool operator[](int index) => false;
}

void f() {
  0[1];
}
''');

    var indexExpression = findNode.singleIndexExpression;
    assertResolvedNodeText(indexExpression, r'''
IndexExpression
  target: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@extension::E::@method::[]
  staticType: bool
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_read_ofExtension_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E {
  bool operator[](int index) => false;
}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

extension E on int {}

void f() {
  0[1];
}
''');

    var indexExpression = findNode.singleIndexExpression;
    assertResolvedNodeText(indexExpression, r'''
IndexExpression
  target: IntegerLiteral
    literal: 0
    staticType: int
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    parameter: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]
  element: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]#element
  staticType: bool
''');
  }

  test_read_switchExpression() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(Object? x) {
  (switch (x) {
    _ => A(),
  }[0]);
}
''');

    var node = findNode.index('[0]');
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: InstanceCreationExpression
          constructorName: ConstructorName
            type: NamedType
              name: A
              element2: <testLibrary>::@class::A
              type: A
            element: <testLibrary>::@class::A::@constructor::new
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticType: A
    rightBracket: }
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
    staticType: int
  rightBracket: ]
  element: <testLibrary>::@class::A::@method::[]
  staticType: bool
''');
  }

  test_read_target_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a[0];
}
''');

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: dynamic
''');
  }

  test_read_target_unresolved() async {
    await assertErrorsInCode(
      r'''
void f() {
  a[0];
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 13, 1)],
    );

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    element: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  rightBracket: ]
  element: <null>
  staticType: InvalidType
''');
  }

  test_readWrite_assignment() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] += 1.2;
}
''');

    var assignment = findNode.assignment('a[0]');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_readWrite_assignment_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] += 1.2;
}
''');

    var assignment = findNode.assignment('a[0]');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: ParameterMember
        baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
    staticType: double
  readElement2: MethodMember
    baseElement: <testLibrary>::@class::A::@method::[]
    substitution: {T: double}
  readType: double
  writeElement2: MethodMember
    baseElement: <testLibrary>::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  element: dart:core::@class::double::@method::+
  staticType: double
''');
  }

  test_readWrite_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] += 1.2;
}
''');

    var assignment = findNode.assignment('a?[0]');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double?
''');
  }

  test_rewrite_nullShorting() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  T Function<T>(T) operator[](int i);
}
abstract class B {
  A get a;
}
int Function(int)? f(B? b) => b?.a[0];
''');

    var node = findNode.functionReference('b?.a[0]');
    assertResolvedNodeText(node, r'''FunctionReference
  function: IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      operator: ?.
      propertyName: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::i
      staticType: int
    rightBracket: ]
    element: <testLibrary>::@class::A::@method::[]
    staticType: T Function<T>(T)
  staticType: int Function(int)?
  typeArgumentTypes
    int
''');
  }

  test_write() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] = 1.2;
}
''');

    var assignment = findNode.assignment('a[0]');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }

  test_write_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, A a) {}
}

void f(A? a) {
  a?..[0] = a..[1] = a;
}
''');

    var node = findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  cascadeSections
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ?..
        leftBracket: [
        index: IntegerLiteral
          literal: 0
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide: SimpleIdentifier
        token: a
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      readElement2: <null>
      readType: null
      writeElement2: <testLibrary>::@class::A::@method::[]=
      writeType: A
      element: <null>
      staticType: A
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide: SimpleIdentifier
        token: a
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      readElement2: <null>
      readType: null
      writeElement2: <testLibrary>::@class::A::@method::[]=
      writeType: A
      element: <null>
      staticType: A
  staticType: A?
''');
  }

  test_write_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] = 1.2;
}
''');

    var assignment = findNode.assignment('a[0]');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: ParameterMember
        baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: ParameterMember
      baseElement: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
      substitution: {T: double}
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: MethodMember
    baseElement: <testLibrary>::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  element: <null>
  staticType: double
''');
  }

  test_write_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] = 1.2;
}
''');

    var assignment = findNode.assignment('a?[0]');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    question: ?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double?
''');
  }

  test_write_ofExtension() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  operator[]=(int index, num value) {}
}

void f() {
  0[1] = 2.3;
}
''');

    var indexExpression = findNode.singleAssignmentExpression;
    assertResolvedNodeText(indexExpression, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: IntegerLiteral
      literal: 0
      staticType: int
    leftBracket: [
    index: IntegerLiteral
      literal: 1
      correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 2.3
    correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_write_ofExtension_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E {
  operator[]=(int index, num value) {}
}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

extension E on int {}

void f() {
  0[1] = 2.3;
}
''');

    var indexExpression = findNode.singleAssignmentExpression;
    assertResolvedNodeText(indexExpression, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: IntegerLiteral
      literal: 0
      staticType: int
    leftBracket: [
    index: IntegerLiteral
      literal: 1
      parameter: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 2.3
    parameter: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]=
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@method::[]=#element
  writeType: num
  staticElement: <null>
  element: <null>
  staticType: double
''');
  }

  test_write_switchExpression() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(Object? x) {
  (switch (x) {
    _ => A(),
  }[0] = 1.2);
}
''');

    var node = findNode.assignment('[0]');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SwitchExpression
      switchKeyword: switch
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: Object?
      rightParenthesis: )
      leftBracket: {
      cases
        SwitchExpressionCase
          guardedPattern: GuardedPattern
            pattern: WildcardPattern
              name: _
              matchedValueType: Object?
          arrow: =>
          expression: InstanceCreationExpression
            constructorName: ConstructorName
              type: NamedType
                name: A
                element2: <testLibrary>::@class::A
                type: A
              element: <testLibrary>::@class::A::@constructor::new
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticType: A
      rightBracket: }
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: double
''');
  }
}
