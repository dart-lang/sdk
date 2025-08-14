// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableDeclarationStatementResolutionTest);
  });
}

@reflectiveTest
class PatternVariableDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_final_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  final (num a) = 0;
  a;
}
''');
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isFinal isPublic a@24
          element: isFinal isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: num
  semicolon: ;
''');
  }

  test_final_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  final (a) = 0;
  a;
}
''');
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@20
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: _
  semicolon: ;
''');
  }

  test_rewrite_expression() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (a) = A();
}

class A {}
''',
      [error(WarningCode.unusedLocalVariable, 18, 1)],
    );
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@18
          element: hasImplicitType isPublic
            type: A
        matchedValueType: A
      rightParenthesis: )
      matchedValueType: A
    equals: =
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
    patternTypeSchema: _
  semicolon: ;
''');
  }

  test_var_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (num a) = 0;
  a;
}
''');
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isPublic a@22
          element: isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: num
  semicolon: ;
''');
  }

  test_var_typed_typeSchema() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (int a) = g();
}

T g<T>() => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 22, 1)],
    );
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@22
          element: isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
    patternTypeSchema: int
  semicolon: ;
''');
  }

  test_var_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a) = 0;
  a;
}
''');
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@18
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: _
  semicolon: ;
''');
  }

  test_var_untyped_multiple() async {
    await assertErrorsInCode(
      r'''
void f((int, String) x) {
  var (a, b) = x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 33, 1),
        error(WarningCode.unusedLocalVariable, 36, 1),
      ],
    );
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
            declaredFragment: isPublic a@33
              element: hasImplicitType isPublic
                type: int
            matchedValueType: int
          element2: <null>
        PatternField
          pattern: DeclaredVariablePattern
            name: b
            declaredFragment: isPublic b@36
              element: hasImplicitType isPublic
                type: String
            matchedValueType: String
          element2: <null>
      rightParenthesis: )
      matchedValueType: (int, String)
    equals: =
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: (int, String)
    patternTypeSchema: (_, _)
  semicolon: ;
''');
  }

  test_var_untyped_recordPattern() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (a,) = g((0,));
}

T g<T>(T a) => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 18, 1)],
    );
    var node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: RecordPattern
      leftParenthesis: (
      fields
        PatternField
          pattern: DeclaredVariablePattern
            name: a
            declaredFragment: isPublic a@18
              element: hasImplicitType isPublic
                type: int
            matchedValueType: int
          element2: <null>
      rightParenthesis: )
      matchedValueType: (int,)
    equals: =
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>(T)
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          RecordLiteral
            leftParenthesis: (
            fields
              IntegerLiteral
                literal: 0
                staticType: int
            rightParenthesis: )
            staticType: (int,)
        rightParenthesis: )
      staticInvokeType: (int,) Function((int,))
      staticType: (int,)
      typeArgumentTypes
        (int,)
    patternTypeSchema: (_,)
  semicolon: ;
''');
  }

  test_var_withKeyword_final() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (final a) = 0;
  a;
}
''',
      [
        error(
          ParserErrorCode.variablePatternKeywordInDeclarationContext,
          18,
          5,
        ),
      ],
    );
  }

  test_var_withKeyword_var() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (var a) = 0;
  a;
}
''',
      [
        error(
          ParserErrorCode.variablePatternKeywordInDeclarationContext,
          18,
          3,
        ),
      ],
    );
  }
}
