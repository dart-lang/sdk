// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationStatementResolutionTest);
  });
}

@reflectiveTest
class FunctionDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_generic() async {
    await assertErrorsInCode(r'''
void f() {
  T g<T, U>(T a, U b) => a;
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 15, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: T
      element: T@17
      type: T
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@17
          TypeParameter
            name: U
            declaredElement: U@20
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element: T@17
            type: T
          name: a
          declaredElement: g@15::@parameter::a
            type: T
        parameter: SimpleFormalParameter
          type: NamedType
            name: U
            element: U@20
            type: U
          name: b
          declaredElement: g@15::@parameter::b
            type: U
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: SimpleIdentifier
          token: a
          staticElement: g@15::@parameter::a
          staticType: T
        semicolon: ;
      declaredElement: g@15
        type: T Function<T, U>(T, U)
      staticType: T Function<T, U>(T, U)
    declaredElement: g@15
      type: T Function<T, U>(T, U)
''');
  }

  test_generic_fBounded() async {
    await assertErrorsInCode(r'''
void f() {
  void g<T extends U, U, V extends U>(T x, U y, V z) {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            extendsKeyword: extends
            bound: NamedType
              name: U
              element: U@33
              type: U
            declaredElement: T@20
          TypeParameter
            name: U
            declaredElement: U@33
          TypeParameter
            name: V
            extendsKeyword: extends
            bound: NamedType
              name: U
              element: U@33
              type: U
            declaredElement: V@36
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element: T@20
            type: T
          name: x
          declaredElement: g@18::@parameter::x
            type: T
        parameter: SimpleFormalParameter
          type: NamedType
            name: U
            element: U@33
            type: U
          name: y
          declaredElement: g@18::@parameter::y
            type: U
        parameter: SimpleFormalParameter
          type: NamedType
            name: V
            element: V@36
            type: V
          name: z
          declaredElement: g@18::@parameter::z
            type: V
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@18
        type: void Function<T extends U, U, V extends U>(T, U, V)
      staticType: void Function<T extends U, U, V extends U>(T, U, V)
    declaredElement: g@18
      type: void Function<T extends U, U, V extends U>(T, U, V)
''');
  }

  test_generic_formalParameters_optionalNamed() async {
    await assertErrorsInCode(r'''
void f() {
  void g<T>({T? a}) {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@20
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        leftDelimiter: {
        parameter: DefaultFormalParameter
          parameter: SimpleFormalParameter
            type: NamedType
              name: T
              question: ?
              element: T@20
              type: T?
            name: a
            declaredElement: g@18::@parameter::a
              type: T?
          declaredElement: g@18::@parameter::a
            type: T?
        rightDelimiter: }
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@18
        type: void Function<T>({T? a})
      staticType: void Function<T>({T? a})
    declaredElement: g@18
      type: void Function<T>({T? a})
''');
  }

  test_generic_formalParameters_optionalPositional() async {
    await assertErrorsInCode(r'''
void f() {
  void g<T>([T? a]) {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@20
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        leftDelimiter: [
        parameter: DefaultFormalParameter
          parameter: SimpleFormalParameter
            type: NamedType
              name: T
              question: ?
              element: T@20
              type: T?
            name: a
            declaredElement: g@18::@parameter::a
              type: T?
          declaredElement: g@18::@parameter::a
            type: T?
        rightDelimiter: ]
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@18
        type: void Function<T>([T?])
      staticType: void Function<T>([T?])
    declaredElement: g@18
      type: void Function<T>([T?])
''');
  }

  test_generic_formalParameters_requiredNamed() async {
    await assertErrorsInCode(r'''
void f() {
  void g<T>({required T? a}) {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@20
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        leftDelimiter: {
        parameter: DefaultFormalParameter
          parameter: SimpleFormalParameter
            requiredKeyword: required
            type: NamedType
              name: T
              question: ?
              element: T@20
              type: T?
            name: a
            declaredElement: g@18::@parameter::a
              type: T?
          declaredElement: g@18::@parameter::a
            type: T?
        rightDelimiter: }
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@18
        type: void Function<T>({required T? a})
      staticType: void Function<T>({required T? a})
    declaredElement: g@18
      type: void Function<T>({required T? a})
''');
  }

  test_generic_formalParameters_requiredPositional() async {
    await assertErrorsInCode(r'''
void f() {
  void g<T>(T a) {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 18, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: T@20
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element: T@20
            type: T
          name: a
          declaredElement: g@18::@parameter::a
            type: T
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@18
        type: void Function<T>(T)
      staticType: void Function<T>(T)
    declaredElement: g@18
      type: void Function<T>(T)
''');
  }

  test_returnType_implicit_blockBody() async {
    await assertErrorsInCode(r'''
void f() {
  g() {}
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 13, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    name: g
    functionExpression: FunctionExpression
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: g@13
        type: Null Function()
      staticType: Null Function()
    declaredElement: g@13
      type: Null Function()
''');
  }

  test_returnType_implicit_expressionBody() async {
    await assertErrorsInCode(r'''
void f() {
  g() => 0;
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 13, 1),
    ]);

    final node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    name: g
    functionExpression: FunctionExpression
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
        semicolon: ;
      declaredElement: g@13
        type: int Function()
      staticType: int Function()
    declaredElement: g@13
      type: int Function()
''');
  }
}
