// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralTest);
  });
}

@reflectiveTest
class RecordLiteralTest extends PubPackageResolutionTest {
  test_noContext_mixed() async {
    await assertNoErrorsInCode(r'''
final x = (0, f1: 1, 2, f2: 3, 4);
''');

    final node = findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 1
        staticType: int
    IntegerLiteral
      literal: 2
      staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 3
        staticType: int
    IntegerLiteral
      literal: 4
      staticType: int
  rightParenthesis: )
  staticType: (int, int, int, {int f1, int f2})
''');
  }

  test_noContext_named() async {
    await assertNoErrorsInCode(r'''
final x = (f1: 0, f2: true);
''');

    final node = findNode.recordLiteral('(f1:');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f1
          staticElement: <null>
          staticType: null
        colon: :
      expression: IntegerLiteral
        literal: 0
        staticType: int
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: f2
          staticElement: <null>
          staticType: null
        colon: :
      expression: BooleanLiteral
        literal: true
        staticType: bool
  rightParenthesis: )
  staticType: ({int f1, bool f2})
''');
  }

  test_noContext_positional() async {
    await assertNoErrorsInCode(r'''
final x = (0, true);
''');

    final node = findNode.recordLiteral('(0,');
    assertResolvedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
      staticType: int
    BooleanLiteral
      literal: true
      staticType: bool
  rightParenthesis: )
  staticType: (int, bool)
''');
  }
}
