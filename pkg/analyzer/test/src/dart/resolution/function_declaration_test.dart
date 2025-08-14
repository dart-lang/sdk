// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationResolutionTest);
  });
}

@reflectiveTest
class FunctionDeclarationResolutionTest extends PubPackageResolutionTest {
  test_asyncGenerator_blockBody_return() async {
    await assertErrorsInCode(
      '''
import 'dart:async';

Stream<int> f() async* {
  return 0;
}
''',
      [error(CompileTimeErrorCode.returnInGenerator, 49, 6)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Stream
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    element2: dart:async::@class::Stream
    type: Stream<int>
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      keyword: async
      star: *
      block: Block
        leftBracket: {
        statements
          ReturnStatement
            returnKeyword: return
            expression: IntegerLiteral
              literal: 0
              staticType: int
            semicolon: ;
        rightBracket: }
    declaredElement: <testLibraryFragment> f@34
      element: <testLibrary>::@function::f
        type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredElement: <testLibraryFragment> f@34
    element: <testLibrary>::@function::f
      type: Stream<int> Function()
''');
  }

  test_asyncGenerator_expressionBody() async {
    await assertErrorsInCode(
      '''
import 'dart:async';

Stream<int> f() async* => 0;
''',
      [error(CompileTimeErrorCode.returnInGenerator, 45, 2)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Stream
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    element2: dart:async::@class::Stream
    type: Stream<int>
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      keyword: async
      star: *
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
      semicolon: ;
    declaredElement: <testLibraryFragment> f@34
      element: <testLibrary>::@function::f
        type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredElement: <testLibraryFragment> f@34
    element: <testLibrary>::@function::f
      type: Stream<int> Function()
''');
  }

  test_formalParameterScope_defaultValue() async {
    await assertNoErrorsInCode('''
const foo = 0;

void bar([int foo = foo + 1]) {
}
''');

    var node = findNode.simple('foo + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');
  }

  test_formalParameterScope_type() async {
    await assertNoErrorsInCode('''
class a {}

void bar(a a) {
  a;
}
''');

    var node_1 = findNode.namedType('a a');
    assertResolvedNodeText(node_1, r'''
NamedType
  name: a
  element2: <testLibrary>::@class::a
  type: a
''');

    var node_2 = findNode.simple('a;');
    assertResolvedNodeText(node_2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::bar::@formalParameter::a
  staticType: a
''');
  }

  test_genericFunction_fBoundedDefaultType() async {
    await assertNoErrorsInCode('''
void m<T extends List<T>>() {}
''');

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: m
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: List
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: T
                  element2: #E0 T
                  type: T
              rightBracket: >
            element2: dart:core::@class::List
            type: List<T>
          declaredElement: <testLibraryFragment> T@7
            defaultType: List<dynamic>
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> m@5
      element: <testLibrary>::@function::m
        type: void Function<T extends List<T>>()
    staticType: void Function<T extends List<T>>()
  declaredElement: <testLibraryFragment> m@5
    element: <testLibrary>::@function::m
      type: void Function<T extends List<T>>()
''');
  }

  test_genericFunction_simpleDefaultType() async {
    await assertNoErrorsInCode('''
void m<T extends num>() {}
''');

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: m
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: num
            element2: dart:core::@class::num
            type: num
          declaredElement: <testLibraryFragment> T@7
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> m@5
      element: <testLibrary>::@function::m
        type: void Function<T extends num>()
    staticType: void Function<T extends num>()
  declaredElement: <testLibraryFragment> m@5
    element: <testLibrary>::@function::m
      type: void Function<T extends num>()
''');
  }

  test_genericLocalFunction_fBoundedDefaultType() async {
    await assertErrorsInCode(
      '''
void f() {
  void m<T extends List<T>>() {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement.functionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: m
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: List
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: T
                  element2: #E0 T
                  type: T
              rightBracket: >
            element2: dart:core::@class::List
            type: List<T>
          declaredElement: <testLibraryFragment> T@20
            defaultType: List<dynamic>
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> m@18
      element: m@18
        type: void Function<T extends List<T>>()
    staticType: void Function<T extends List<T>>()
  declaredElement: <testLibraryFragment> m@18
    element: m@18
      type: void Function<T extends List<T>>()
''');
  }

  test_genericLocalFunction_simpleDefaultType() async {
    await assertErrorsInCode(
      '''
void f() {
  void m<T extends num>() {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );

    var node = findNode.singleFunctionDeclarationStatement.functionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: m
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: num
            element2: dart:core::@class::num
            type: num
          declaredElement: <testLibraryFragment> T@20
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> m@18
      element: m@18
        type: void Function<T extends num>()
    staticType: void Function<T extends num>()
  declaredElement: <testLibraryFragment> m@18
    element: m@18
      type: void Function<T extends num>()
''');
  }

  test_getter_formalParameters() async {
    await assertErrorsInCode(
      '''
int get foo(double a) => 0;
''',
      [error(ParserErrorCode.getterWithParameters, 11, 1)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: double
          element2: dart:core::@class::double
          type: double
        name: a
        declaredElement: <testLibraryFragment> a@19
          element: isPublic
            type: double
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
      semicolon: ;
    declaredElement: <testLibraryFragment> foo@8
      element: <testLibrary>::@getter::foo
        type: int Function(double)
    staticType: int Function(double)
  declaredElement: <testLibraryFragment> foo@8
    element: <testLibrary>::@getter::foo
      type: int Function(double)
''');
  }

  test_syncGenerator_blockBody_return() async {
    await assertErrorsInCode(
      '''
Iterable<int> f() sync* {
  return 0;
}
''',
      [error(CompileTimeErrorCode.returnInGenerator, 28, 6)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Iterable
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    element2: dart:core::@class::Iterable
    type: Iterable<int>
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      keyword: sync
      star: *
      block: Block
        leftBracket: {
        statements
          ReturnStatement
            returnKeyword: return
            expression: IntegerLiteral
              literal: 0
              staticType: int
            semicolon: ;
        rightBracket: }
    declaredElement: <testLibraryFragment> f@14
      element: <testLibrary>::@function::f
        type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredElement: <testLibraryFragment> f@14
    element: <testLibrary>::@function::f
      type: Iterable<int> Function()
''');
  }

  test_syncGenerator_expressionBody() async {
    await assertErrorsInCode(
      '''
Iterable<int> f() sync* => 0;
''',
      [error(CompileTimeErrorCode.returnInGenerator, 24, 2)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Iterable
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    element2: dart:core::@class::Iterable
    type: Iterable<int>
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: ExpressionFunctionBody
      keyword: sync
      star: *
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
      semicolon: ;
    declaredElement: <testLibraryFragment> f@14
      element: <testLibrary>::@function::f
        type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredElement: <testLibraryFragment> f@14
    element: <testLibrary>::@function::f
      type: Iterable<int> Function()
''');
  }

  test_wildCardFunction() async {
    await assertErrorsInCode(
      '''
_() {}
''',
      [error(WarningCode.unusedElement, 0, 1)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  name: _
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> _@0
      element: <testLibrary>::@function::_
        type: dynamic Function()
    staticType: dynamic Function()
  declaredElement: <testLibraryFragment> _@0
    element: <testLibrary>::@function::_
      type: dynamic Function()
''');
  }

  test_wildCardFunction_preWildCards() async {
    await assertErrorsInCode(
      '''
// @dart = 3.4
// (pre wildcard-variables)

_() {}
''',
      [error(WarningCode.unusedElement, 44, 1)],
    );

    var node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  name: _
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredElement: <testLibraryFragment> _@44
      element: <testLibrary>::@function::_
        type: dynamic Function()
    staticType: dynamic Function()
  declaredElement: <testLibraryFragment> _@44
    element: <testLibrary>::@function::_
      type: dynamic Function()
''');
  }

  test_wildcardFunctionTypeParameter() async {
    // Corresponding language test:
    // language/wildcard_variables/multiple/local_declaration_type_parameter_error_test

    await assertErrorsInCode(
      r'''
void f<_ extends void Function<_>(_, _), _>() {}
''',
      [
        error(CompileTimeErrorCode.undefinedClass, 34, 1),
        error(CompileTimeErrorCode.undefinedClass, 37, 1),
      ],
    );

    var node = findNode.typeParameter('<_>');
    assertResolvedNodeText(node, r'''
TypeParameter
  name: _
  extendsKeyword: extends
  bound: GenericFunctionType
    returnType: NamedType
      name: void
      element2: <null>
      type: void
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: _
          declaredElement: <testLibraryFragment> _@31
            defaultType: null
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: _
          element2: <null>
          type: InvalidType
        declaredElement: <testLibraryFragment> null@null
          element: isPrivate
            type: InvalidType
      parameter: SimpleFormalParameter
        type: NamedType
          name: _
          element2: <null>
          type: InvalidType
        declaredElement: <testLibraryFragment> null@null
          element: isPrivate
            type: InvalidType
      rightParenthesis: )
    declaredElement: GenericFunctionTypeElement
      parameters
        <empty>
          kind: required positional
          element:
            type: InvalidType
        <empty>
          kind: required positional
          element:
            type: InvalidType
      returnType: void
      type: void Function<_>(InvalidType, InvalidType)
    type: void Function<_>(InvalidType, InvalidType)
  declaredElement: <testLibraryFragment> _@7
    defaultType: void Function<_>(InvalidType, InvalidType)
''');
  }
}
