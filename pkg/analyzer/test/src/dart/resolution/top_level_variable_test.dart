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
    await assertErrorsInCode(
      '''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final x = f(g, (z) => z.length);
''',
      [
        error(
          CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue,
          108,
          6,
        ),
      ],
    );
    var node = findNode.variableDeclaration('x =');
    assertResolvedNodeText(node, r'''
VariableDeclaration
  name: x
  equals: =
  initializer: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@function::f::@formalParameter::a
            substitution: {T: String}
          element: <testLibrary>::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: <testLibraryFragment> z@100
                element: hasImplicitType isPublic
                  type: Object?
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                element: z@100
                staticType: Object?
              period: .
              identifier: SimpleIdentifier
                token: length
                element: <null>
                staticType: InvalidType
              element: <null>
              staticType: InvalidType
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: InvalidType Function(Object?)
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@function::f::@formalParameter::b
            substitution: {T: String}
          staticType: InvalidType Function(Object?)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: <testLibraryFragment> x@90
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
      element: <testLibrary>::@function::f
      staticType: T? Function<T>(T Function(), int Function(T))
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: g
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@function::f::@formalParameter::a
            substitution: {T: String}
          element: <testLibrary>::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: SimpleFormalParameter
              name: z
              declaredElement: <testLibraryFragment> z@108
                element: hasImplicitType isPublic
                  type: String
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: z
                element: z@108
                staticType: String
              period: .
              identifier: SimpleIdentifier
                token: length
                element: dart:core::@class::String::@getter::length
                staticType: int
              element: dart:core::@class::String::@getter::length
              staticType: int
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: int Function(String)
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@function::f::@formalParameter::b
            substitution: {T: String}
          staticType: int Function(String)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredElement: <testLibraryFragment> x@98
''');
  }

  test_session_getterSetter() async {
    await resolveTestCode('''
var v = 0;
''');
    var getter = findElement2.topGet('v');
    expect(getter.session, result.session);

    var setter = findElement2.topSet('v');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    await resolveTestCode('''
var v = 0;
''');
    assertType(findElement2.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
var v = throw 42;
''');
    assertType(findElement2.topVar('v').type, 'Never');
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
var v;
''');
    assertType(findElement2.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
var v = null;
''');
    assertType(findElement2.topVar('v').type, 'dynamic');
  }
}
