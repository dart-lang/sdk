// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypedFormalParameterResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionTypedFormalParameterResolutionTest
    extends PubPackageResolutionTest {
  test_defaultValue_inFunctionExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

var g = (void h([int a = foo])) {};
//                     ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = result.findNode.regularFormalParameter('int a');
    var element = node.declaredFragment!.element;
    assertResolvedNodeText(element.constantInitializer2!, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::foo
    type: int
  staticType: int
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');

    assertElementDefaultValueIsClauseValue(node);
    assertDartObjectText(element.computeConstantValue(), r'''
int 0
  variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_defaultValue_inLocalFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f() {
  void g(void h([int a = foo])) {}
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
//                     ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
}
''');

    var node = result.findNode.regularFormalParameter('int a');
    var element = node.declaredFragment!.element;
    assertResolvedNodeText(element.constantInitializer2!, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::foo
    type: int
  staticType: int
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');

    assertElementDefaultValueIsClauseValue(node);
    assertDartObjectText(element.computeConstantValue(), r'''
int 0
  variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_defaultValue_inTopLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;

void f(void g([int a = foo])) {}
//                   ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
''');

    var node = result.findNode.regularFormalParameter('int a');
    var element = node.declaredFragment!.element;
    assertResolvedNodeText(element.constantInitializer2!, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::foo
    type: int
  staticType: int
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');

    assertElementDefaultValueIsClauseValue(node);
    assertDartObjectText(element.computeConstantValue(), r'''
int 0
  variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  test_hasTypeParameters() async {
    var result = await resolveTestCode('''
void f<V>(T p<T, U>(U a, V b)) {}
''');

    var node = result.findNode.firstFormalParameter;
    assertResolvedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: T
    element: #E0 T
    type: T
  name: p
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@14
            defaultType: null
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@17
            defaultType: null
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          type: NamedType
            name: U
            element: #E1 U
            type: U
          name: a
          declaredFragment: <testLibraryFragment> a@22
            element: isPublic
              type: U
        RegularFormalParameter
          type: NamedType
            name: V
            element: #E2 V
            type: V
          name: b
          declaredFragment: <testLibraryFragment> b@27
            element: isPublic
              type: V
      rightParenthesis: )
    formalParameters(v1): FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: U
          element: #E1 U
          type: U
        name: a
        declaredFragment: <testLibraryFragment> a@22
          element: isPublic
            type: U
      parameter: RegularFormalParameter
        type: NamedType
          name: V
          element: #E2 V
          type: V
        name: b
        declaredFragment: <testLibraryFragment> b@27
          element: isPublic
            type: V
      rightParenthesis: )
  declaredFragment: <testLibraryFragment> p@12
    element: isPublic
      type: T Function<T, U>(U, V)
''');
  }

  test_simple() async {
    var result = await resolveTestCode('''
void f(void p(int a)) {}
''');

    var node = result.findNode.firstFormalParameter;
    assertResolvedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: void
    element: <null>
    type: void
  name: p
  functionTypedSuffix: FunctionTypedFormalParameterSuffix
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: <testLibraryFragment> a@18
            element: isPublic
              type: int
      rightParenthesis: )
    formalParameters(v1): FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@18
          element: isPublic
            type: int
      rightParenthesis: )
  declaredFragment: <testLibraryFragment> p@12
    element: isPublic
      type: void Function(int)
''');
  }
}
