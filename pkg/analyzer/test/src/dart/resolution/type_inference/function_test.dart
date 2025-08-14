// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTest);
  });
}

@reflectiveTest
class FunctionTest extends PubPackageResolutionTest {
  test_genericFunction_upwards() async {
    await assertNoErrorsInCode('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2);
}
''');

    var node = findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::y
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int, int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_genericFunction_upwards_missingRequiredArgument() async {
    await assertErrorsInCode(
      '''
void foo<T>({required T x, required T y}) {}

f() {
  foo(x: 1);
}
''',
      [error(CompileTimeErrorCode.missingRequiredArgument, 54, 3)],
    );

    var node = findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>({required T x, required T y})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: x
            element: ParameterMember
              baseElement: <testLibrary>::@function::foo::@formalParameter::x
              substitution: {T: int}
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 1
          staticType: int
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
    rightParenthesis: )
  staticInvokeType: void Function({required int x, required int y})
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_genericFunction_upwards_notEnoughPositionalArguments() async {
    await assertErrorsInCode(
      '''
void foo<T>(T x, T y) {}

f() {
  foo(1);
}
''',
      [
        error(
          CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural,
          39,
          1,
        ),
      ],
    );

    var node = findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int, int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_genericFunction_upwards_tooManyPositionalArguments() async {
    await assertErrorsInCode(
      '''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, 3);
}
''',
      [error(CompileTimeErrorCode.extraPositionalArguments, 44, 1)],
    );

    var node = findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::y
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 3
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int, int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_genericFunction_upwards_undefinedNamedParameter() async {
    await assertErrorsInCode(
      '''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, z: 3);
}
''',
      [error(CompileTimeErrorCode.undefinedNamedParameter, 44, 1)],
    );

    var node = findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::foo::@formalParameter::y
          substitution: {T: int}
        staticType: int
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: z
            element: <null>
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 3
          staticType: int
        correspondingParameter: <null>
    rightParenthesis: )
  staticInvokeType: void Function(int, int)
  staticType: void
  typeArgumentTypes
    int
''');
  }
}
