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
    await assertErrorsInCode(
      r'''
void f() {
  T g<T, U>(T a, U b) => a;
}
''',
      [error(WarningCode.unusedElement, 15, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: T
      element2: #E0 T
      type: T
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: <testLibraryFragment> T@17
              defaultType: dynamic
          TypeParameter
            name: U
            declaredElement: <testLibraryFragment> U@20
              defaultType: dynamic
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element2: #E0 T
            type: T
          name: a
          declaredElement: <testLibraryFragment> a@25
            element: isPublic
              type: T
        parameter: SimpleFormalParameter
          type: NamedType
            name: U
            element2: #E1 U
            type: U
          name: b
          declaredElement: <testLibraryFragment> b@30
            element: isPublic
              type: U
        rightParenthesis: )
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: SimpleIdentifier
          token: a
          element: a@25
          staticType: T
        semicolon: ;
      declaredElement: <testLibraryFragment> g@15
        element: g@15
          type: T Function<T, U>(T, U)
      staticType: T Function<T, U>(T, U)
    declaredElement: <testLibraryFragment> g@15
      element: g@15
        type: T Function<T, U>(T, U)
''');
  }

  test_generic_fBounded() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T extends U, U, V extends U>(T x, U y, V z) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element2: <null>
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
              element2: #E0 U
              type: U
            declaredElement: <testLibraryFragment> T@20
              defaultType: dynamic
          TypeParameter
            name: U
            declaredElement: <testLibraryFragment> U@33
              defaultType: dynamic
          TypeParameter
            name: V
            extendsKeyword: extends
            bound: NamedType
              name: U
              element2: #E0 U
              type: U
            declaredElement: <testLibraryFragment> V@36
              defaultType: dynamic
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element2: #E1 T
            type: T
          name: x
          declaredElement: <testLibraryFragment> x@51
            element: isPublic
              type: T
        parameter: SimpleFormalParameter
          type: NamedType
            name: U
            element2: #E0 U
            type: U
          name: y
          declaredElement: <testLibraryFragment> y@56
            element: isPublic
              type: U
        parameter: SimpleFormalParameter
          type: NamedType
            name: V
            element2: #E2 V
            type: V
          name: z
          declaredElement: <testLibraryFragment> z@61
            element: isPublic
              type: V
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: <testLibraryFragment> g@18
        element: g@18
          type: void Function<T extends U, U, V extends U>(T, U, V)
      staticType: void Function<T extends U, U, V extends U>(T, U, V)
    declaredElement: <testLibraryFragment> g@18
      element: g@18
        type: void Function<T extends U, U, V extends U>(T, U, V)
''');
  }

  test_generic_formalParameters_optionalNamed() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T>({T? a}) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: <testLibraryFragment> T@20
              defaultType: dynamic
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        leftDelimiter: {
        parameter: DefaultFormalParameter
          parameter: SimpleFormalParameter
            type: NamedType
              name: T
              question: ?
              element2: #E0 T
              type: T?
            name: a
            declaredElement: <testLibraryFragment> a@27
              element: isPublic
                type: T?
          declaredElement: <testLibraryFragment> a@27
            element: isPublic
              type: T?
        rightDelimiter: }
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: <testLibraryFragment> g@18
        element: g@18
          type: void Function<T>({T? a})
      staticType: void Function<T>({T? a})
    declaredElement: <testLibraryFragment> g@18
      element: g@18
        type: void Function<T>({T? a})
''');
  }

  test_generic_formalParameters_optionalPositional() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T>([T? a]) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: <testLibraryFragment> T@20
              defaultType: dynamic
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        leftDelimiter: [
        parameter: DefaultFormalParameter
          parameter: SimpleFormalParameter
            type: NamedType
              name: T
              question: ?
              element2: #E0 T
              type: T?
            name: a
            declaredElement: <testLibraryFragment> a@27
              element: isPublic
                type: T?
          declaredElement: <testLibraryFragment> a@27
            element: isPublic
              type: T?
        rightDelimiter: ]
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: <testLibraryFragment> g@18
        element: g@18
          type: void Function<T>([T?])
      staticType: void Function<T>([T?])
    declaredElement: <testLibraryFragment> g@18
      element: g@18
        type: void Function<T>([T?])
''');
  }

  test_generic_formalParameters_requiredNamed() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T>({required T? a}) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: <testLibraryFragment> T@20
              defaultType: dynamic
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
              element2: #E0 T
              type: T?
            name: a
            declaredElement: <testLibraryFragment> a@36
              element: isPublic
                type: T?
          declaredElement: <testLibraryFragment> a@36
            element: isPublic
              type: T?
        rightDelimiter: }
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: <testLibraryFragment> g@18
        element: g@18
          type: void Function<T>({required T? a})
      staticType: void Function<T>({required T? a})
    declaredElement: <testLibraryFragment> g@18
      element: g@18
        type: void Function<T>({required T? a})
''');
  }

  test_generic_formalParameters_requiredPositional() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T>(T a) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
    assertResolvedNodeText(node, r'''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    name: g
    functionExpression: FunctionExpression
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: T
            declaredElement: <testLibraryFragment> T@20
              defaultType: dynamic
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: T
            element2: #E0 T
            type: T
          name: a
          declaredElement: <testLibraryFragment> a@25
            element: isPublic
              type: T
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
      declaredElement: <testLibraryFragment> g@18
        element: g@18
          type: void Function<T>(T)
      staticType: void Function<T>(T)
    declaredElement: <testLibraryFragment> g@18
      element: g@18
        type: void Function<T>(T)
''');
  }

  test_returnType_implicit_blockBody() async {
    await assertErrorsInCode(
      r'''
void f() {
  g() {}
}
''',
      [error(WarningCode.unusedElement, 13, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
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
      declaredElement: <testLibraryFragment> g@13
        element: g@13
          type: Null Function()
      staticType: Null Function()
    declaredElement: <testLibraryFragment> g@13
      element: g@13
        type: Null Function()
''');
  }

  test_returnType_implicit_expressionBody() async {
    await assertErrorsInCode(
      r'''
void f() {
  g() => 0;
}
''',
      [error(WarningCode.unusedElement, 13, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement;
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
      declaredElement: <testLibraryFragment> g@13
        element: g@13
          type: int Function()
      staticType: int Function()
    declaredElement: <testLibraryFragment> g@13
      element: g@13
        type: int Function()
''');
  }
}
