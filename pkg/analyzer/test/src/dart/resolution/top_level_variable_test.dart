// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelVariableResolutionTest extends PubPackageResolutionTest {
  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_dontUseInferredType() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final x = f(g, (z) => z.length);
//                      ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'length' can't be unconditionally accessed because the receiver can be 'null'.
''');
    var node = result.findNode.variableDeclaration('x =');
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
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::a
            substitution: {T: String}
          element: <testLibrary>::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: z
              declaredFragment: <testLibraryFragment> z@100
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
          declaredFragment: <testLibraryFragment> null@null
            element: null@null
              type: InvalidType Function(Object?)
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::b
            substitution: {T: String}
          staticType: InvalidType Function(Object?)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredFragment: <testLibraryFragment> x@90
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/51137
  test_initializer_contextType_typeAnnotation() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart=2.17
T? f<T>(T Function() a, int Function(T) b) => null;
String g() => '';
final String? x = f(g, (z) => z.length);
''');
    var node = result.findNode.variableDeclaration('x =');
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
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::a
            substitution: {T: String}
          element: <testLibrary>::@function::g
          staticType: String Function()
        FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              name: z
              declaredFragment: <testLibraryFragment> z@108
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
          declaredFragment: <testLibraryFragment> null@null
            element: null@null
              type: int Function(String)
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@function::f::@formalParameter::b
            substitution: {T: String}
          staticType: int Function(String)
      rightParenthesis: )
    staticInvokeType: String? Function(String Function(), int Function(String))
    staticType: String?
    typeArgumentTypes
      String
  declaredFragment: <testLibraryFragment> x@98
''');
  }

  test_session_getterSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = 0;
''');
    var getter = result.findElement.topGet('v');
    expect(getter.session, result.session);

    var setter = result.findElement.topSet('v');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = 0;
''');
    assertType(result.findElement.topVar('v').type, 'int');
  }

  test_type_inferred_Never() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = throw 42;
''');
    assertType(result.findElement.topVar('v').type, 'Never');
  }

  test_type_inferred_noInitializer() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v;
''');
    assertType(result.findElement.topVar('v').type, 'dynamic');
  }

  test_type_inferred_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
var v = null;
''');
    assertType(result.findElement.topVar('v').type, 'dynamic');
  }
}
