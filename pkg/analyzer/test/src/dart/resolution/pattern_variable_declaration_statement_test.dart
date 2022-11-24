// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableDeclarationStatementResolutionTest);
  });
}

@reflectiveTest
class PatternVariableDeclarationStatementResolutionTest
    extends PatternsResolutionTest {
  test_inferredType() async {
    await assertNoErrorsInCode(r'''
void f((int, String) x) {
  var (a, b) = x;
}
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        RecordPatternField
          pattern: VariablePattern
            name: a
            declaredElement: hasImplicitType a@33
              type: int
          fieldElement: <null>
        RecordPatternField
          pattern: VariablePattern
            name: b
            declaredElement: hasImplicitType b@36
              type: String
          fieldElement: <null>
      rightParenthesis: )
    equals: =
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: (int, String)
  semicolon: ;
''');
  }

  test_typeSchema_fromVariableType() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (int a) = g();
}

T g<T>() => throw 0;
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: a
        declaredElement: a@22
          type: int
      rightParenthesis: )
    equals: =
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
  semicolon: ;
''');
  }
}
