// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitFunctionInstantiationResolutionTest);
    defineReflectiveTests(ImplicitFunctionInstantiationLegacyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImplicitFunctionInstantiationLegacyTest extends PubPackageResolutionTest
    with BeforeConstructorTearoffsMixin {
  test_importPrefixedStaticMethod() async {
    newFile('$testPackageLibPath/a.dart', '''
class C {
  static T id<T>(T value) => value;
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;
int Function(int) f() => p.C.id;
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: PropertyAccess
    target2: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: package:test/a.dart::@class::C
        staticType: null
      element: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: id
      element: package:test/a.dart::@class::C::@method::id
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: PropertyAccess
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: C
      element: package:test/a.dart::@class::C
      staticType: null
    element: package:test/a.dart::@class::C
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: id
    element: package:test/a.dart::@class::C::@method::id
    staticType: int Function(int)
    tearOffTypeArgumentTypes
      int
  staticType: int Function(int)
''',
    );
  }

  test_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  T id<T>(T value) => value;
}
int Function(int) f(C c) => c.id;
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibrary>::@function::f::@formalParameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: id
      element: <testLibrary>::@class::C::@method::id
      staticType: T Function<T>(T)
    element: <testLibrary>::@class::C::@method::id
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: id
    element: <testLibrary>::@class::C::@method::id
    staticType: int Function(int)
    tearOffTypeArgumentTypes
      int
  element: <testLibrary>::@class::C::@method::id
  staticType: int Function(int)
''',
    );
  }

  test_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static T id<T>(T value) => value;
}
int Function(int) f() => C.id;
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: id
      element: <testLibrary>::@class::C::@method::id
      staticType: T Function<T>(T)
    element: <testLibrary>::@class::C::@method::id
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: PrefixedIdentifier
  prefix: SimpleIdentifier
    token: C
    element: <testLibrary>::@class::C
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: id
    element: <testLibrary>::@class::C::@method::id
    staticType: int Function(int)
    tearOffTypeArgumentTypes
      int
  element: <testLibrary>::@class::C::@method::id
  staticType: int Function(int)
''',
    );
  }

  test_topLevelFunction() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
int Function(int) f() => id;
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: UnqualifiedNameExpression
    name: id
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: SimpleIdentifier
  token: id
  element: <testLibrary>::@function::id
  staticType: int Function(int)
  tearOffTypeArgumentTypes
    int
''',
    );
  }
}

@reflectiveTest
class ImplicitFunctionInstantiationResolutionTest
    extends PubPackageResolutionTest {
  test_conditionalExpression_genericFunctionBranches() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
int Function(int) f(bool b) => b ? id : id;
''');
    assertResolvedNodeText(result.findNode.singleConditionalExpression, r'''
ConditionalExpression
  condition2: UnqualifiedNameExpression
    name: b
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::b
      type: bool
    staticType: bool
  condition(v1): SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression2: ImplicitFunctionInstantiation
    operand: UnqualifiedNameExpression
      name: id
      resolution: ExecutableTearOffResolution
        element: <testLibrary>::@function::id
        type: T Function<T>(T)
      staticType: T Function<T>(T)
    staticType: int Function(int)
    typeArgumentTypes
      int
  thenExpression(v1): FunctionReference
    function: SimpleIdentifier
      token: id
      element: <testLibrary>::@function::id
      staticType: T Function<T>(T)
    staticType: int Function(int)
    typeArgumentTypes
      int
  colon: :
  elseExpression2: ImplicitFunctionInstantiation
    operand: UnqualifiedNameExpression
      name: id
      resolution: ExecutableTearOffResolution
        element: <testLibrary>::@function::id
        type: T Function<T>(T)
      staticType: T Function<T>(T)
    staticType: int Function(int)
    typeArgumentTypes
      int
  elseExpression(v1): FunctionReference
    function: SimpleIdentifier
      token: id
      element: <testLibrary>::@function::id
      staticType: T Function<T>(T)
    staticType: int Function(int)
    typeArgumentTypes
      int
  staticType: int Function(int)
''');
  }

  test_implicitCallReference_generic_context_nonGenericFunctionType() async {
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

  test_parameter_genericFunction_promotedToNonNullable() async {
    var result = await resolveTestCodeWithDiagnostics('''
int Function(int) f(T Function<T>(T)? value) {
  if (value == null) throw 0;
  return value;
}
''');
    assertResolvedNodeText(
      result.findNode.singleImplicitFunctionInstantiation,
      r'''
ImplicitFunctionInstantiation
  operand: UnqualifiedNameExpression
    name: value
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::value
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: FunctionReference
  function: SimpleIdentifier
    token: value
    element: <testLibrary>::@function::f::@formalParameter::value
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''',
    );
  }

  test_topLevelFunction_generic_context_Function() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
Function f() => id;
''');
    assertResolvedNodeText(
      result.findNode.expressionFunctionBody('=> id;'),
      r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression2: UnqualifiedNameExpression
    name: id
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  expression(v1): SimpleIdentifier
    token: id
    element: <testLibrary>::@function::id
    staticType: T Function<T>(T)
  semicolon: ;
''',
    );
  }

  test_topLevelFunction_generic_context_genericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
T Function<T>(T) f() => id;
''');
    assertResolvedNodeText(
      result.findNode.expressionFunctionBody('=> id;'),
      r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression2: UnqualifiedNameExpression
    name: id
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  expression(v1): SimpleIdentifier
    token: id
    element: <testLibrary>::@function::id
    staticType: T Function<T>(T)
  semicolon: ;
''',
    );
  }

  test_topLevelFunction_generic_context_none() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
var f = id;
''');
    assertResolvedNodeText(result.findNode.variableDeclaration('f ='), r'''
VariableDeclaration
  name: f
  equals: =
  initializer2: UnqualifiedNameExpression
    name: id
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  initializer(v1): SimpleIdentifier
    token: id
    element: <testLibrary>::@function::id
    staticType: T Function<T>(T)
  declaredFragment: <testLibraryFragment> f@31
''');
  }

  test_topLevelFunction_generic_context_nonGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
T id<T>(T value) => value;
int Function(int) f() => id;
''');
    var node = result.findNode.singleImplicitFunctionInstantiation;
    assertResolvedNodeText(node, r'''
ImplicitFunctionInstantiation
  operand: UnqualifiedNameExpression
    name: id
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::id
      type: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
V1: FunctionReference
  function: SimpleIdentifier
    token: id
    element: <testLibrary>::@function::id
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_topLevelFunction_nonGeneric_context_nonGenericFunctionType() async {
    var result = await resolveTestCodeWithDiagnostics('''
int inc(int value) => value + 1;
int Function(int) f() => inc;
''');
    assertResolvedNodeText(
      result.findNode.expressionFunctionBody('=> inc'),
      r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression2: UnqualifiedNameExpression
    name: inc
    resolution: ExecutableTearOffResolution
      element: <testLibrary>::@function::inc
      type: int Function(int)
    staticType: int Function(int)
  expression(v1): SimpleIdentifier
    token: inc
    element: <testLibrary>::@function::inc
    staticType: int Function(int)
  semicolon: ;
''',
    );
  }
}
