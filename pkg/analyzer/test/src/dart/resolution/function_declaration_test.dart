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
    await assertErrorsInCode('''
import 'dart:async';

Stream<int> f() async* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 49, 6),
    ]);

    final node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: SimpleIdentifier
      token: Stream
      staticElement: dart:async::@class::Stream
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
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
    declaredElement: self::@function::f
      type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredElement: self::@function::f
    type: Stream<int> Function()
''');
  }

  test_asyncGenerator_expressionBody() async {
    await assertErrorsInCode('''
import 'dart:async';

Stream<int> f() async* => 0;
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 45, 2),
    ]);

    final node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: SimpleIdentifier
      token: Stream
      staticElement: dart:async::@class::Stream
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
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
    declaredElement: self::@function::f
      type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredElement: self::@function::f
    type: Stream<int> Function()
''');
  }

  test_formalParameterScope_defaultValue() async {
    await assertNoErrorsInCode('''
const foo = 0;

void bar([int foo = foo + 1]) {
}
''');

    assertElement(
      findNode.simple('foo + 1'),
      findElement.topGet('foo'),
    );
  }

  test_formalParameterScope_type() async {
    await assertNoErrorsInCode('''
class a {}

void bar(a a) {
  a;
}
''');

    assertElement(
      findNode.simple('a a'),
      findElement.class_('a'),
    );

    assertElement(
      findNode.simple('a;'),
      findElement.parameter('a'),
    );
  }

  test_getter_formalParameters() async {
    await assertErrorsInCode('''
int get foo(double a) => 0;
''', [
      error(ParserErrorCode.GETTER_WITH_PARAMETERS, 11, 1),
    ]);

    final node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: SimpleIdentifier
            token: double
            staticElement: dart:core::@class::double
            staticType: null
          type: double
        name: a
        declaredElement: self::@getter::foo::@parameter::a
          type: double
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
      semicolon: ;
    declaredElement: self::@getter::foo
      type: int Function(double)
    staticType: int Function(double)
  declaredElement: self::@getter::foo
    type: int Function(double)
''');
  }

  test_syncGenerator_blockBody_return() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 28, 6),
    ]);

    final node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: SimpleIdentifier
      token: Iterable
      staticElement: dart:core::@class::Iterable
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
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
    declaredElement: self::@function::f
      type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredElement: self::@function::f
    type: Iterable<int> Function()
''');
  }

  test_syncGenerator_expressionBody() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* => 0;
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 24, 2),
    ]);

    final node = findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: SimpleIdentifier
      token: Iterable
      staticElement: dart:core::@class::Iterable
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
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
    declaredElement: self::@function::f
      type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredElement: self::@function::f
    type: Iterable<int> Function()
''');
  }
}
