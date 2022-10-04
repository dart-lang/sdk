// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPattern_BooleanLiteral_ResolutionTest);
    defineReflectiveTests(ConstantPattern_DoubleLiteral_ResolutionTest);
    defineReflectiveTests(ConstantPattern_IntegerLiteral_ResolutionTest);
    defineReflectiveTests(ConstantPattern_NullLiteral_ResolutionTest);
    defineReflectiveTests(ConstantPattern_SimpleIdentifier_ResolutionTest);
    defineReflectiveTests(ConstantPattern_SimpleStringLiteral_ResolutionTest);
  });
}

@reflectiveTest
class ConstantPattern_BooleanLiteral_ResolutionTest
    extends PatternsResolutionTest {
  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case true as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: BooleanLiteral
      literal: true
      staticType: bool
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case true) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: BooleanLiteral
    literal: true
    staticType: bool
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case true!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: BooleanLiteral
      literal: true
      staticType: bool
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case true?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: BooleanLiteral
      literal: true
      staticType: bool
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case true:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: BooleanLiteral
    literal: true
''');
  }
}

@reflectiveTest
class ConstantPattern_DoubleLiteral_ResolutionTest
    extends PatternsResolutionTest {
  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1.0 as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
      staticType: double
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 1.0) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: DoubleLiteral
    literal: 1.0
    staticType: double
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1.0!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
      staticType: double
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1.0?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: DoubleLiteral
      literal: 1.0
      staticType: double
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 1.0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: DoubleLiteral
    literal: 1.0
''');
  }
}

@reflectiveTest
class ConstantPattern_IntegerLiteral_ResolutionTest
    extends PatternsResolutionTest {
  test_contextType_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: double
''');
  }

  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0 as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: IntegerLiteral
      literal: 0
      staticType: int
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}

@reflectiveTest
class ConstantPattern_NullLiteral_ResolutionTest
    extends PatternsResolutionTest {
  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case null as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: NullLiteral
      literal: null
      staticType: Null
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case null) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: NullLiteral
    literal: null
    staticType: Null
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case null!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: NullLiteral
      literal: null
      staticType: Null
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case null?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: NullLiteral
      literal: null
      staticType: Null
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case null:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: NullLiteral
    literal: null
''');
  }
}

@reflectiveTest
class ConstantPattern_SimpleIdentifier_ResolutionTest
    extends PatternsResolutionTest {
  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x, int y) {
  switch (x) {
    case y as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: y
      staticElement: self::@function::f::@parameter::y
      staticType: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x, int y) {
  if (x case y) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
    staticElement: self::@function::f::@parameter::y
    staticType: int
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x, int y) {
  switch (x) {
    case y!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
      staticElement: self::@function::f::@parameter::y
      staticType: int
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x, int y) {
  switch (x) {
    case y?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleIdentifier
      token: y
      staticElement: self::@function::f::@parameter::y
      staticType: int
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x, y) {
  switch (x) {
    case y:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleIdentifier
    token: y
''');
  }
}

@reflectiveTest
class ConstantPattern_SimpleStringLiteral_ResolutionTest
    extends PatternsResolutionTest {
  test_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 'x' as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleStringLiteral
      literal: 'x'
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
      staticElement: dart:core::@class::Object
      staticType: null
    type: Object
''');
  }

  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 'x') {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
ConstantPattern
  expression: SimpleStringLiteral
    literal: 'x'
''');
  }

  test_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 'x'!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleStringLiteral
      literal: 'x'
  operator: !
''');
  }

  test_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 'x'?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: ConstantPattern
    expression: SimpleStringLiteral
      literal: 'x'
  operator: ?
''');
  }

  test_inside_switchStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case 'x':
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ConstantPattern
  expression: SimpleStringLiteral
    literal: 'x'
''');
  }
}
