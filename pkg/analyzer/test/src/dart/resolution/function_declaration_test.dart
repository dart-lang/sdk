// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionDeclarationResolutionTest extends PubPackageResolutionTest {
  test_asyncGenerator_blockBody_return() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

Stream<int> f() async* {
  return 0;
//^^^^^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
}
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Stream
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: dart:async::@class::Stream
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
    declaredFragment: <testLibraryFragment> f@34
      element: <testLibrary>::@function::f
        type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredFragment: <testLibraryFragment> f@34
    element: <testLibrary>::@function::f
      type: Stream<int> Function()
''');
  }

  test_asyncGenerator_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:async';

Stream<int> f() async* => 0;
//                     ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Stream
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: dart:async::@class::Stream
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
    declaredFragment: <testLibraryFragment> f@34
      element: <testLibrary>::@function::f
        type: Stream<int> Function()
    staticType: Stream<int> Function()
  declaredFragment: <testLibraryFragment> f@34
    element: <testLibrary>::@function::f
      type: Stream<int> Function()
''');
  }

  test_formalParameterScope_defaultValue() async {
    var result = await resolveTestCodeWithDiagnostics('''
const foo = 0;

void bar([int foo = foo + 1]) {
}
''');

    var node = result.findNode.simple('foo + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');
  }

  test_formalParameterScope_type() async {
    var result = await resolveTestCodeWithDiagnostics('''
class a {}

void bar(a a) {
  a;
}
''');

    var node1 = result.findNode.namedType('a a');
    assertResolvedNodeText(node1, r'''
NamedType
  name: a
  element: <testLibrary>::@class::a
  type: a
''');

    var node2 = result.findNode.simple('a;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::bar::@formalParameter::a
  staticType: a
''');
  }

  test_genericFunction_fBoundedDefaultType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void m<T extends List<T>>() {}
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element: <null>
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
                  element: #E0 T
                  type: T
              rightBracket: >
            element: dart:core::@class::List
            type: List<T>
          declaredFragment: <testLibraryFragment> T@7
            defaultType: List<dynamic>
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> m@5
      element: <testLibrary>::@function::m
        type: void Function<T extends List<T>>()
    staticType: void Function<T extends List<T>>()
  declaredFragment: <testLibraryFragment> m@5
    element: <testLibrary>::@function::m
      type: void Function<T extends List<T>>()
''');
  }

  test_genericFunction_simpleDefaultType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void m<T extends num>() {}
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element: <null>
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
            element: dart:core::@class::num
            type: num
          declaredFragment: <testLibraryFragment> T@7
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> m@5
      element: <testLibrary>::@function::m
        type: void Function<T extends num>()
    staticType: void Function<T extends num>()
  declaredFragment: <testLibraryFragment> m@5
    element: <testLibrary>::@function::m
      type: void Function<T extends num>()
''');
  }

  test_genericLocalFunction_fBoundedDefaultType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  void m<T extends List<T>>() {}
//     ^
// [diag.unusedElement] The declaration 'm' isn't referenced.
}
''');

    var node =
        result.findNode.singleFunctionDeclarationStatement.functionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element: <null>
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
                  element: #E0 T
                  type: T
              rightBracket: >
            element: dart:core::@class::List
            type: List<T>
          declaredFragment: <testLibraryFragment> T@20
            defaultType: List<dynamic>
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> m@18
      element: m@18
        type: void Function<T extends List<T>>()
    staticType: void Function<T extends List<T>>()
  declaredFragment: <testLibraryFragment> m@18
    element: m@18
      type: void Function<T extends List<T>>()
''');
  }

  test_genericLocalFunction_simpleDefaultType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  void m<T extends num>() {}
//     ^
// [diag.unusedElement] The declaration 'm' isn't referenced.
}
''');

    var node =
        result.findNode.singleFunctionDeclarationStatement.functionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
    element: <null>
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
            element: dart:core::@class::num
            type: num
          declaredFragment: <testLibraryFragment> T@20
            defaultType: num
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> m@18
      element: m@18
        type: void Function<T extends num>()
    staticType: void Function<T extends num>()
  declaredFragment: <testLibraryFragment> m@18
    element: m@18
      type: void Function<T extends num>()
''');
  }

  test_getter_formalParameters() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get foo(double a) => 0;
//         ^
// [diag.getterWithParameters] Getters must be declared without a parameter list.
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: double
          element: dart:core::@class::double
          type: double
        name: a
        declaredFragment: <testLibraryFragment> a@19
          element: isPublic
            type: double
      rightParenthesis: )
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
      semicolon: ;
    declaredFragment: <testLibraryFragment> foo@8
      element: <testLibrary>::@getter::foo
        type: int Function(double)
    staticType: int Function(double)
  declaredFragment: <testLibraryFragment> foo@8
    element: <testLibrary>::@getter::foo
      type: int Function(double)
''');
  }

  test_syncGenerator_blockBody_return() async {
    var result = await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  return 0;
//^^^^^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
}
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Iterable
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: dart:core::@class::Iterable
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
    declaredFragment: <testLibraryFragment> f@14
      element: <testLibrary>::@function::f
        type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredFragment: <testLibraryFragment> f@14
    element: <testLibrary>::@function::f
      type: Iterable<int> Function()
''');
  }

  test_syncGenerator_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* => 0;
//                      ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');

    var node = result.findNode.singleFunctionDeclaration;
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: Iterable
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: dart:core::@class::Iterable
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
    declaredFragment: <testLibraryFragment> f@14
      element: <testLibrary>::@function::f
        type: Iterable<int> Function()
    staticType: Iterable<int> Function()
  declaredFragment: <testLibraryFragment> f@14
    element: <testLibrary>::@function::f
      type: Iterable<int> Function()
''');
  }

  test_wildCardFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
_() {}
// [diag.unusedElement][column 1][length 1] The declaration '_' isn't referenced.
''');

    var node = result.findNode.singleFunctionDeclaration;
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
    declaredFragment: <testLibraryFragment> _@0
      element: <testLibrary>::@function::_
        type: dynamic Function()
    staticType: dynamic Function()
  declaredFragment: <testLibraryFragment> _@0
    element: <testLibrary>::@function::_
      type: dynamic Function()
''');
  }

  test_wildCardFunction_preWildCards() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 3.4
// (pre wildcard-variables)

_() {}
// [diag.unusedElement][column 1][length 1] The declaration '_' isn't referenced.
''');

    var node = result.findNode.singleFunctionDeclaration;
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
    declaredFragment: <testLibraryFragment> _@44
      element: <testLibrary>::@function::_
        type: dynamic Function()
    staticType: dynamic Function()
  declaredFragment: <testLibraryFragment> _@44
    element: <testLibrary>::@function::_
      type: dynamic Function()
''');
  }

  test_wildcardFunctionTypeParameter() async {
    // Corresponding language test:
    // language/wildcard_variables/multiple/local_declaration_type_parameter_error_test

    var result = await resolveTestCodeWithDiagnostics(r'''
void f<_ extends void Function<_>(_, _), _>() {}
//                                ^
// [diag.undefinedClass] Undefined class '_'.
//                                   ^
// [diag.undefinedClass] Undefined class '_'.
''');

    var node = result.findNode.typeParameter('<_>');
    assertResolvedNodeText(node, r'''
TypeParameter
  name: _
  extendsKeyword: extends
  bound: GenericFunctionType
    returnType: NamedType
      name: void
      element: <null>
      type: void
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: _
          declaredFragment: <testLibraryFragment> _@31
            defaultType: null
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: _
          element: <null>
          type: InvalidType
        declaredFragment: <testLibraryFragment> null@null
          element: isPrivate
            type: InvalidType
      parameter: RegularFormalParameter
        type: NamedType
          name: _
          element: <null>
          type: InvalidType
        declaredFragment: <testLibraryFragment> null@null
          element: isPrivate
            type: InvalidType
      rightParenthesis: )
    declaredFragment: GenericFunctionTypeElement
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
  declaredFragment: <testLibraryFragment> _@7
    defaultType: void Function<_>(InvalidType, InvalidType)
''');
  }
}
