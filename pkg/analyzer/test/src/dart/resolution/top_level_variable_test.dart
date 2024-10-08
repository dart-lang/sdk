// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableResolutionTest);
  });
}

@reflectiveTest
class TopLevelVariableResolutionTest extends PubPackageResolutionTest {
  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_dontUseInferredType() async {
    await assertErrorsInCode('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final x = f(g, (z) => z.length);
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          108, 6),
    ]);
    var node = findNode.variableDeclaration('x =');
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          parameter: ParameterMember
            base: <testLibraryFragment>::@function::f::@parameter::a
            substitution: {T: String}
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: @99::@parameter::z
                type: Object?
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                staticElement: @99::@parameter::z
                element: @99::@parameter::z#element
                staticType: Object?
              period: .
              identifier: SimpleIdentifier
                token: length
                staticElement: <null>
                element: <null>
                staticType: InvalidType
              staticElement: <null>
              element: <null>
              staticType: InvalidType
          declaredElement: @99
            type: InvalidType Function(Object?)
          parameter: ParameterMember
            base: <testLibraryFragment>::@function::f::@parameter::b
            substitution: {T: String}
          staticType: InvalidType Function(Object?)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_typeAnnotation() async {
    await assertNoErrorsInCode('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final String? x = f(g, (z) => z.length);
''');
    var node = findNode.variableDeclaration('x =');
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          parameter: ParameterMember
            base: <testLibraryFragment>::@function::f::@parameter::a
            substitution: {T: String}
          staticElement: <testLibraryFragment>::@function::g
          element: <testLibraryFragment>::@function::g#element
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: @107::@parameter::z
                type: String
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                staticElement: @107::@parameter::z
                element: @107::@parameter::z#element
                staticType: String
              period: .
              identifier: SimpleIdentifier
                token: length
                staticElement: dart:core::<fragment>::@class::String::@getter::length
                element: dart:core::<fragment>::@class::String::@getter::length#element
                staticType: int
              staticElement: dart:core::<fragment>::@class::String::@getter::length
              element: dart:core::<fragment>::@class::String::@getter::length#element
              staticType: int
          declaredElement: @107
            type: int Function(String)
          parameter: ParameterMember
            base: <testLibraryFragment>::@function::f::@parameter::b
            substitution: {T: String}
          staticType: int Function(String)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: <testLibraryFragment>::@topLevelVariable::x
''');
  }

  test_session_getterSetter() async {
    await resolveTestCode('''
var v = 0;
''');
    var getter = findElement.topGet('v');
    expect(getter.session, result.session);

    var setter = findElement.topSet('v');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    await resolveTestCode('''
var v = 0;
''');
    assertType(findElement.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
var v = throw 42;
''');
    assertType(findElement.topVar('v').type, 'Never');
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
var v;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
var v = null;
''');
    assertType(findElement.topVar('v').type, 'dynamic');
  }
}
