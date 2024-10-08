// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternResolutionTest);
  });
}

@reflectiveTest
class ConstantPatternResolutionTest extends PubPackageResolutionTest {
  test_expression_class_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static const foo = 0;
}

void f(x) {
  if (x case A.foo) {}
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_instanceCreation() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

void f(x) {
  if (x case const A()) {}
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral_contextType_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: double
  matchedValueType: double
''');
  }

  test_expression_listLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const [0]) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 0
        staticType: int
    rightBracket: ]
    staticType: List<int>
  matchedValueType: dynamic
''');
  }

  test_expression_mapLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0: 1}) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      MapLiteralEntry
        key: IntegerLiteral
          literal: 0
          staticType: int
        separator: :
        value: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    isMap: true
    staticType: Map<int, int>
  matchedValueType: dynamic
''');
  }

  test_expression_prefix_class_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const foo = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.A.foo) {}
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: <testLibraryFragment>::@prefix::prefix
        element: <testLibraryFragment>::@prefix2::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: package:test/a.dart::<fragment>::@class::A
        element: package:test/a.dart::<fragment>::@class::A#element
        staticType: null
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@class::A::@getter::foo
      element: package:test/a.dart::<fragment>::@class::A::@getter::foo#element
      staticType: int
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_prefix_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.foo) {}
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@getter::foo
      element: package:test/a.dart::<fragment>::@getter::foo#element
      staticType: int
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    element: package:test/a.dart::<fragment>::@getter::foo#element
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_setLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const {0, 1}) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  const: const
  expression: SetOrMapLiteral
    leftBracket: {
    elements
      IntegerLiteral
        literal: 0
        staticType: int
      IntegerLiteral
        literal: 1
        staticType: int
    rightBracket: }
    isMap: false
    staticType: Set<int>
  matchedValueType: dynamic
''');
  }

  test_expression_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
const foo = 0;

void f(x) {
  if (x case foo) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_typeLiteral_notPrefixed() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: int
      element: dart:core::<fragment>::@class::int
      element2: dart:core::<fragment>::@class::int#element
      type: int
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_notPrefixed_nested() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case [0, int]) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: Object?
    ConstantPattern
      expression: TypeLiteral
        type: NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        staticType: Type
      matchedValueType: Object?
  rightBracket: ]
  matchedValueType: Object?
  requiredType: List<Object?>
''');
  }

  test_expression_typeLiteral_notPrefixed_typeAlias() async {
    await assertNoErrorsInCode(r'''
typedef A = int;

void f(Object? x) {
  if (x case A) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: A
      element: <testLibraryFragment>::@typeAlias::A
      element2: <testLibraryFragment>::@typeAlias::A#element
      type: int
        alias: <testLibraryFragment>::@typeAlias::A
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed() async {
    await assertNoErrorsInCode(r'''
import 'dart:math' as math;

void f(Object? x) {
  if (x case math.Random) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: math
        period: .
        element: <testLibraryFragment>::@prefix::math
        element2: <testLibraryFragment>::@prefix2::math
      name: Random
      element: dart:math::<fragment>::@class::Random
      element2: dart:math::<fragment>::@class::Random#element
      type: Random
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = int;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(Object? x) {
  if (x case prefix.A) {}
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element: package:test/a.dart::<fragment>::@typeAlias::A
      element2: package:test/a.dart::<fragment>::@typeAlias::A#element
      type: int
        alias: package:test/a.dart::<fragment>::@typeAlias::A
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_location_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_location_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }
}
