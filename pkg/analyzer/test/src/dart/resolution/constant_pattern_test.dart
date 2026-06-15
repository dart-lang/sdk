// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstantPatternResolutionTest extends PubPackageResolutionTest {
  test_expression_class_field() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static const foo = 0;
}

void f(x) {
  if (x case A.foo) {}
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: int
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_instanceCreation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

void f(x) {
  if (x case const A()) {}
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  constKeyword: const
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case 0) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_integerLiteral_contextType_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(double x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: double
  matchedValueType: double
''');
  }

  test_expression_listLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case const [0]) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case const {0: 1}) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.A.foo) {}
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        element: <testLibraryFragment>::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@class::A::@getter::foo
      staticType: int
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_prefix_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f(x) {
  if (x case prefix.foo) {}
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: int
    element: package:test/a.dart::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_setLiteral() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case const {0, 1}) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  constKeyword: const
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f(x) {
  if (x case foo) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_expression_typeLiteral_notPrefixed_dynamicElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case dynamic) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: dynamic
      element: dynamic
      type: dynamic
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_notPrefixed_interfaceElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_notPrefixed_nested() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case [0, int]) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
          element: dart:core::@class::int
          type: int
        staticType: Type
      matchedValueType: Object?
  rightBracket: ]
  matchedValueType: Object?
  requiredType: List<Object?>
''');
  }

  test_expression_typeLiteral_notPrefixed_neverElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case Never) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: Never
      element: Never
      type: Never
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_notPrefixed_typeAliasElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int;

void f(Object? x) {
  if (x case A) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: A
      element: <testLibrary>::@typeAlias::A
      type: int
        alias: <testLibrary>::@typeAlias::A
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_notPrefixed_typeParameterElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>(Object? x) {
  if (x case T) {}
//           ^
// [diag.constTypeParameter] Type parameters can't be used in a constant expression.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      name: T
      element: #E0 T
      type: T
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed_dynamicElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f(core.Object? x) {
  if (x case core.dynamic) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: core
        period: .
        element: <testLibraryFragment>::@prefix::core
      name: dynamic
      element: dynamic
      type: dynamic
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed_interfaceElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f(core.Object? x) {
  if (x case core.int) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: core
        period: .
        element: <testLibraryFragment>::@prefix::core
      name: int
      element: dart:core::@class::int
      type: int
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed_neverElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core;

void f(core.Object? x) {
  if (x case core.Never) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: core
        period: .
        element: <testLibraryFragment>::@prefix::core
      name: Never
      element: Never
      type: Never
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_expression_typeLiteral_prefixed_typeAliasElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = int;
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f(Object? x) {
  if (x case prefix.A) {}
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: TypeLiteral
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      element: package:test/a.dart::@typeAlias::A
      type: int
        alias: package:test/a.dart::@typeAlias::A
    staticType: Type
  matchedValueType: Object?
''');
  }

  test_location_ifCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case 0) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }

  test_location_switchCase() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
  matchedValueType: dynamic
''');
  }
}
