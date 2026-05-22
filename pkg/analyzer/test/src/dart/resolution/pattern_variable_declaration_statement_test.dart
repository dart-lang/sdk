// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableDeclarationStatementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PatternVariableDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_final_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  final (num a) = 0;
  a;
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  final (a) = 0;
  a;
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a) = A();
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

class A {}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
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
          element: <testLibrary>::@class::A
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

  test_scope_shadows_beforeDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int a = 0;
void f() {
  a;
//^
// [diag.referencedBeforeDeclaration][context 1] Local variable 'a' can't be referenced before it is declared.
  var (a) = 1;
//     ^
// [context 1] The declaration of 'a' is here.
}
''');

    var node = result.findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: a@34
  staticType: InvalidType
''');
  }

  test_scope_shadows_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f() {
  var (A) = <A>[];
//           ^
// [diag.nonTypeAsTypeArgument] The name 'A' isn't a type, so it can't be used as a type argument.
}
''');

    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: A
        declaredFragment: isPublic A@30
          element: hasImplicitType isPublic
            type: List<InvalidType>
        matchedValueType: List<InvalidType>
      rightParenthesis: )
      matchedValueType: List<InvalidType>
    equals: =
    expression: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: A
            element: A@30
            type: InvalidType
        rightBracket: >
      leftBracket: [
      rightBracket: ]
      staticType: List<InvalidType>
    patternTypeSchema: _
  semicolon: ;
''');
  }

  test_var_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (num a) = 0;
  a;
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (int a) = g();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a) = 0;
  a;
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) x) {
  var (a, b) = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
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
          element: <null>
        PatternField
          pattern: DeclaredVariablePattern
            name: b
            declaredFragment: isPublic b@36
              element: hasImplicitType isPublic
                type: String
            matchedValueType: String
          element: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a,) = g((0,));
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>(T a) => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclarationStatement;
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
          element: <null>
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
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (final a) = 0;
//     ^^^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
  a;
}
''');
  }

  test_var_withKeyword_var() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (var a) = 0;
//     ^^^
// [diag.variablePatternKeywordInDeclarationContext] Variable patterns in declaration context can't specify 'var' or 'final' keyword.
  a;
}
''');
  }
}
