// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionResolutionTest);
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
    staticElement: self::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@class::A::@method::[]::@parameter::index
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
    staticElement: self::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@class::A::@method::[]=::@parameter::index
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_contextType_readWrite_writeLower() async {
    await assertErrorsInCode(r'''
class A {
  int operator [](num index) => 0;
  operator []=(int index, int value) {}
}

void f(A a) {
  a[ g() ]++;
}

T g<T>() => throw 0;
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 107, 3),
    ]);

    var node = findNode.methodInvocation('g()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: g
    staticElement: self::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@class::A::@method::[]=::@parameter::index
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
    staticElement: self::@function::g
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@class::A::@method::[]=::@parameter::index
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
    staticElement: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
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
    staticElement: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
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
    staticElement: self::@function::f::@parameter::a
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@class::A::@method::[]
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
    parameter: self::@class::A::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@class::A::@method::[]
  staticType: bool
''');

    assertResolvedNodeText(findNode.index('..[1]'), r'''
IndexExpression
  period: ..
  leftBracket: [
  index: IntegerLiteral
    literal: 1
    parameter: self::@class::A::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@class::A::@method::[]
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
    staticElement: self::@function::f::@parameter::a
    staticType: A<double>
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: self::@class::A::@method::[]::@parameter::index
      substitution: {T: double}
    staticType: int
  rightBracket: ]
  staticElement: MethodMember
    base: self::@class::A::@method::[]
    substitution: {T: double}
  staticType: double
''');
  }

  test_read_index_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    this[super];
  }

  int operator[](Object index) => 0;
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 32, 5),
    ]);

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
  staticElement: self::@class::A::@method::[]
  staticType: int
''');
  }

  test_read_index_unresolved() async {
    await assertErrorsInCode(r'''
void f(List<int> a) {
  a[b];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 26, 1),
    ]);

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: List<int>
  leftBracket: [
  index: SimpleIdentifier
    token: b
    parameter: ParameterMember
      base: dart:core::@class::List::@method::[]::@parameter::index
      substitution: {E: int}
    staticElement: <null>
    staticType: InvalidType
  rightBracket: ]
  staticElement: MethodMember
    base: dart:core::@class::List::@method::[]
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
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@class::A::@method::[]
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
    parameter: self::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@extension::E::@method::[]
  staticType: bool
''');
  }

  test_read_ofExtension_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment extension E {
  bool operator[](int index) => false;
}
''');

    await assertNoErrorsInCode(r'''
import augment 'a.dart';

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
    parameter: self::@augmentation::package:test/a.dart::@extensionAugmentation::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@augmentation::package:test/a.dart::@extensionAugmentation::E::@method::[]
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
      staticElement: self::@function::f::@parameter::x
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
              element: self::@class::A
              type: A
            staticElement: self::@class::A::@constructor::new
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticType: A
    rightBracket: }
    staticType: A
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: self::@class::A::@method::[]
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
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_read_target_unresolved() async {
    await assertErrorsInCode(r'''
void f() {
  a[0];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var node = findNode.singleIndexExpression;
    assertResolvedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    staticElement: <null>
    staticType: InvalidType
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  rightBracket: ]
  staticElement: <null>
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
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: double
  readElement: self::@class::A::@method::[]
  readType: num
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
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
      staticElement: self::@function::f::@parameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: self::@class::A::@method::[]=::@parameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: dart:core::@class::double::@method::+::@parameter::other
    staticType: double
  readElement: MethodMember
    base: self::@class::A::@method::[]
    substitution: {T: double}
  readType: double
  writeElement: MethodMember
    base: self::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  staticElement: dart:core::@class::double::@method::+
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
      staticElement: self::@function::f::@parameter::a
      staticType: A?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: double
  readElement: self::@class::A::@method::[]
  readType: num
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: double?
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
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: self::@class::A::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
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
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  cascadeSections
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ?..
        leftBracket: [
        index: IntegerLiteral
          literal: 0
          parameter: self::@class::A::@method::[]=::@parameter::index
          staticType: int
        rightBracket: ]
        staticElement: <null>
        staticType: null
      operator: =
      rightHandSide: SimpleIdentifier
        token: a
        parameter: self::@class::A::@method::[]=::@parameter::a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      readElement: <null>
      readType: null
      writeElement: self::@class::A::@method::[]=
      writeType: A
      staticElement: <null>
      staticType: A
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 1
          parameter: self::@class::A::@method::[]=::@parameter::index
          staticType: int
        rightBracket: ]
        staticElement: <null>
        staticType: null
      operator: =
      rightHandSide: SimpleIdentifier
        token: a
        parameter: self::@class::A::@method::[]=::@parameter::a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      readElement: <null>
      readType: null
      writeElement: self::@class::A::@method::[]=
      writeType: A
      staticElement: <null>
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
      staticElement: self::@function::f::@parameter::a
      staticType: A<double>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: self::@class::A::@method::[]=::@parameter::index
        substitution: {T: double}
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: ParameterMember
      base: self::@class::A::@method::[]=::@parameter::value
      substitution: {T: double}
    staticType: double
  readElement: <null>
  readType: null
  writeElement: MethodMember
    base: self::@class::A::@method::[]=
    substitution: {T: double}
  writeType: double
  staticElement: <null>
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
      staticElement: self::@function::f::@parameter::a
      staticType: A?
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: self::@class::A::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
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
      parameter: self::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 2.3
    parameter: self::@extension::E::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: double
''');
  }

  test_write_ofExtension_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment extension E {
  operator[]=(int index, num value) {}
}
''');

    await assertNoErrorsInCode(r'''
import augment 'a.dart';

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
      parameter: self::@augmentation::package:test/a.dart::@extensionAugmentation::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 2.3
    parameter: self::@augmentation::package:test/a.dart::@extensionAugmentation::E::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@extensionAugmentation::E::@method::[]=
  writeType: num
  staticElement: <null>
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
        staticElement: self::@function::f::@parameter::x
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
                element: self::@class::A
                type: A
              staticElement: self::@class::A::@constructor::new
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticType: A
      rightBracket: }
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: DoubleLiteral
    literal: 1.2
    parameter: self::@class::A::@method::[]=::@parameter::value
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: double
''');
  }
}
