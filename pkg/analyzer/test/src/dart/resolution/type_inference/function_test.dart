// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionTest extends PubPackageResolutionTest {
  test_genericFunction_upwards() async {
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2);
}
''');

    var node = result.findNode.methodInvocation('foo(');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>({required T x, required T y}) {}

f() {
  foo(x: 1);
//^^^
// [diag.missingRequiredArgument] The named parameter 'y' is required, but there's no corresponding argument.
}
''');

    var node = result.findNode.methodInvocation('foo(');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function<T>({required T x, required T y})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: x
        colon: :
        argumentExpression: IntegerLiteral
          literal: 1
          staticType: int
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T x, T y) {}

f() {
  foo(1);
//     ^
// [diag.notEnoughPositionalArgumentsNamePlural] 2 positional arguments expected by 'foo', but 1 found.
}
''');

    var node = result.findNode.methodInvocation('foo(');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, 3);
//          ^
// [diag.extraPositionalArguments] Too many positional arguments: 2 expected, but 3 found.
}
''');

    var node = result.findNode.methodInvocation('foo(');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
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
    var result = await resolveTestCodeWithDiagnostics('''
void foo<T>(T x, T y) {}

f() {
  foo(1, 2, z: 3);
//          ^
// [diag.undefinedNamedParameter] The named parameter 'z' isn't defined.
}
''');

    var node = result.findNode.methodInvocation('foo(');
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::foo::@formalParameter::x
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::foo::@formalParameter::y
          substitution: {T: int}
        staticType: int
      NamedArgument
        name: z
        colon: :
        argumentExpression: IntegerLiteral
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
