// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryPatternResolutionTest);
  });
}

@reflectiveTest
class BinaryPatternResolutionTest extends PatternsResolutionTest {
  test_logicalAnd_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _ & double _) {}
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
      type: int
    name: _
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
''');
  }

  test_logicalAnd_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _ & double _:
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
      type: int
    name: _
  operator: &
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
''');
  }

  test_logicalOr_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _ | double _) {}
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
      type: int
    name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
''');
  }

  test_logicalOr_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _ | double _:
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
      type: int
    name: _
  operator: |
  rightOperand: VariablePattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
''');
  }
}
