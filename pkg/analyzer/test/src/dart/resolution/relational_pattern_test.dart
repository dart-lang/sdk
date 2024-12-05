// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RelationalPatternResolutionTest);
  });
}

@reflectiveTest
class RelationalPatternResolutionTest extends PubPackageResolutionTest {
  test_equal_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::==
  element2: <testLibraryFragment>::@class::A::@method::==#element
  matchedValueType: A
''');
  }

  test_equal_ofObject() async {
    await assertNoErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: dart:core::<fragment>::@class::Object::@method::==
  element2: dart:core::<fragment>::@class::Object::@method::==#element
  matchedValueType: A
''');
  }

  test_greaterThan_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator >(_) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::>
  element2: <testLibraryFragment>::@class::A::@method::>#element
  matchedValueType: A
''');
  }

  test_greaterThan_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator >(_) => true;
}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@extension::E::@method::>
  element2: <testLibraryFragment>::@extension::E::@method::>#element
  matchedValueType: A
''');
  }

  test_greaterThan_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case > 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 50, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <null>
  element2: <null>
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator >=(_) => true;
}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::>=
  element2: <testLibraryFragment>::@class::A::@method::>=#element
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator >=(_) => true;
}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@extension::E::@method::>=
  element2: <testLibraryFragment>::@extension::E::@method::>=#element
  matchedValueType: A
''');
  }

  test_greaterThanOrEqualTo_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case >= 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 50, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: >=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <null>
  element2: <null>
  matchedValueType: A
''');
  }

  test_ifCase() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  if (x case == 0) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::==
  element2: <testLibraryFragment>::@class::A::@method::==#element
  matchedValueType: A
''');
  }

  test_lessThan_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator <(_) => true;
}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::<
  element2: <testLibraryFragment>::@class::A::@method::<#element
  matchedValueType: A
''');
  }

  test_lessThan_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator <(_) => true;
}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@extension::E::@method::<
  element2: <testLibraryFragment>::@extension::E::@method::<#element
  matchedValueType: A
''');
  }

  test_lessThan_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case < 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 50, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <null>
  element2: <null>
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator <=(_) => true;
}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::<=
  element2: <testLibraryFragment>::@class::A::@method::<=#element
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_ofExtension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A {
  bool operator <=(_) => true;
}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@extension::E::@method::<=
  element2: <testLibraryFragment>::@extension::E::@method::<=#element
  matchedValueType: A
''');
  }

  test_lessThanOrEqualTo_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case <= 0:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 50, 2),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: <=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <null>
  element2: <null>
  matchedValueType: A
''');
  }

  test_notEqual_ofClass() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case != 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::==
  element2: <testLibraryFragment>::@class::A::@method::==#element
  matchedValueType: A
''');
  }

  test_notEqual_ofObject() async {
    await assertNoErrorsInCode(r'''
class A {}

void f(A x) {
  switch (x) {
    case != 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: !=
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: dart:core::<fragment>::@class::Object::@method::==
  element2: dart:core::<fragment>::@class::Object::@method::==#element
  matchedValueType: A
''');
  }

  test_rewrite_operand() async {
    await assertErrorsInCode(r'''
void f(x, int Function() a) {
  switch (x) {
    case == a():
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION, 57,
          3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  element: dart:core::<fragment>::@class::Object::@method::==
  element2: dart:core::<fragment>::@class::Object::@method::==#element
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(_) => true;
}

void f(A x) {
  switch (x) {
    case == 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RelationalPattern
  operator: ==
  operand: IntegerLiteral
    literal: 0
    staticType: int
  element: <testLibraryFragment>::@class::A::@method::==
  element2: <testLibraryFragment>::@class::A::@method::==#element
  matchedValueType: A
''');
  }
}
