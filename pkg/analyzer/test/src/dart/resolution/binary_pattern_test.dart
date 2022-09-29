// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryPattern_LogicalAnd_ResolutionTest);
    defineReflectiveTests(BinaryPattern_LogicalOr_ResolutionTest);
  });
}

@reflectiveTest
class BinaryPattern_LogicalAnd_ResolutionTest extends PatternsResolutionTest {
  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int? _ & double? _) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      question: ?
      type: int?
    name: _
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      question: ?
      type: double?
    name: _
''');
  }

  test_inside_logicalAnd_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ & double? _ & Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        question: ?
        type: int?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
    name: _
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ & double? _ | Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        question: ?
        type: int?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
    name: _
''');
  }

  test_inside_logicalOr_right() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ | double? _ & Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      question: ?
      type: int?
    name: _
  operator: |
  rightOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
    operator: &
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: Object
          staticElement: dart:core::@class::Object
          staticType: null
        question: ?
        type: Object?
      name: _
''');
  }
}

@reflectiveTest
class BinaryPattern_LogicalOr_ResolutionTest extends PatternsResolutionTest {
  test_inside_ifStatement_case() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int? _ | double? _) {}
}
''');
    final node = findNode.caseClause('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      question: ?
      type: int?
    name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      question: ?
      type: double?
    name: _
''');
  }

  test_inside_logicalOr_left() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int? _ | double? _ | Object? _:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
BinaryPattern
  leftOperand: BinaryPattern
    leftOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        question: ?
        type: int?
      name: _
    operator: |
    rightOperand: VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        question: ?
        type: double?
      name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: Object
        staticElement: dart:core::@class::Object
        staticType: null
      question: ?
      type: Object?
    name: _
''');
  }
}
