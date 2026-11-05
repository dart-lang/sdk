// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitCallTearOffResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImplicitCallTearOffResolutionTest extends PubPackageResolutionTest {
  test_argument() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
void g(int Function(int) value) {}
void f(C c) {
  g(c);
}
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  correspondingParameter: <testLibrary>::@function::g::@formalParameter::value
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  correspondingParameter: <testLibrary>::@function::g::@formalParameter::value
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
''');
  }

  test_conditional() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
int Function(int) f(bool b, C c, C d) => b ? c : d;
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: ConditionalExpression
    condition2: UnqualifiedNameExpression
      name: b
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::b
        type: bool
      staticType: bool
    question: ?
    thenExpression2: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    colon: :
    elseExpression2: UnqualifiedNameExpression
      name: d
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::d
        type: C
      staticType: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
V1: ImplicitCallReference
  expression: ConditionalExpression
    condition: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: bool
    question: ?
    thenExpression: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    colon: :
    elseExpression: SimpleIdentifier
      token: d
      element: <testLibrary>::@function::f::@formalParameter::d
      staticType: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
''');
  }

  test_generic_context_Function() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T value) => value;
}
Function f(C c) => c;
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: T Function<T>(T)
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: T Function<T>(T)
''');
  }

  test_generic_context_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T value) => value;
}
T Function<T>(T) f(C c) => c;
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: T Function<T>(T)
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: T Function<T>(T)
''');
  }

  test_generic_context_nonGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T call<T>(T value) => value;
}
int Function(int) f(C c) => c;
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: ImplicitCallTearOff
    operand: UnqualifiedNameExpression
      name: c
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::c
        type: C
      staticType: C
    element: <testLibrary>::@class::C::@method::call
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
  typeArgumentTypes
    int
''',
    );
  }

  test_genericClass() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  T call(T value) => value;
}
int Function(int) f(C<int> c) => c;
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C<int>
    staticType: C<int>
  element: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::C::@method::call
    substitution: {T: int}
  staticType: int Function(int)
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C<int>
  element: SubstitutedMethodElementImpl
    baseElement: <testLibrary>::@class::C::@method::call
    substitution: {T: int}
  staticType: int Function(int)
''');
  }

  test_noContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
void f(C c) {
  var value = c;
//    ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'value' isn't used.
}
''');
    assertResolvedNodeText(result.findNode.variableDeclaration('value ='), r'''
VariableDeclaration
  name: value
  equals: =
  initializer2: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  initializer(v1): SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  declaredFragment: isPublic value@64
    element: hasImplicitType isPublic
      type: C
''');
  }

  test_nonGeneric() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
int Function(int) f(C c) => c;
''');
    assertResolvedNodeText(result.findNode.singleImplicitCallTearOff, r'''
ImplicitCallTearOff
  operand: UnqualifiedNameExpression
    name: c
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::c
      type: C
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
V1: ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  element: <testLibrary>::@class::C::@method::call
  staticType: int Function(int)
''');
  }

  test_parenthesized() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int call(int value) => value;
}
int Function(int) f(C c) => (c);
''');
    assertResolvedNodeText(
      result.findNode.expressionFunctionBody('=> (c)'),
      r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: ImplicitCallTearOff
      operand: UnqualifiedNameExpression
        name: c
        resolution: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::c
          type: C
        staticType: C
      element: <testLibrary>::@class::C::@method::call
      staticType: int Function(int)
    expression(v1): ImplicitCallReference
      expression: SimpleIdentifier
        token: c
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
      element: <testLibrary>::@class::C::@method::call
      staticType: int Function(int)
    rightParenthesis: )
    staticType: int Function(int)
  semicolon: ;
''',
    );
  }
}
