// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearOffTest);
  });
}

@reflectiveTest
class TearOffTest extends PubPackageResolutionTest {
  test_empty_contextNotInstantiated() async {
    await assertErrorsInCode(
      '''
T f<T>(T x) => x;

void test() {
  U Function<U>(U) context;
  context = f; // 1
}
''',
      [error(WarningCode.unusedLocalVariable, 52, 7)],
    );

    var node = findNode.simple('f; // 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: f
  correspondingParameter: <null>
  element: <testLibrary>::@function::f
  staticType: T Function<T>(T)
''');
  }

  test_empty_notGeneric() async {
    await assertErrorsInCode(
      '''
int f(int x) => x;

void test() {
  int Function(int) context;
  context = f; // 1
}
''',
      [error(WarningCode.unusedLocalVariable, 54, 7)],
    );

    var node = findNode.simple('f; // 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: f
  correspondingParameter: <null>
  element: <testLibrary>::@function::f
  staticType: int Function(int)
''');
  }

  test_notEmpty_instanceMethod() async {
    await assertNoErrorsInCode('''
class C {
  T f<T>(T x) => x;
}

int Function(int) test() {
  return new C().f;
}
''');

    var node = findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: C
          element2: <testLibrary>::@class::C
          type: C
        element: <testLibrary>::@class::C::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::C::@method::f
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_notEmpty_localFunction() async {
    await assertNoErrorsInCode('''
int Function(int) test() {
  T f<T>(T x) => x;
  return f;
}
''');

    var node = findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: f@31
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_notEmpty_staticMethod() async {
    await assertNoErrorsInCode('''
class C {
  static T f<T>(T x) => x;
}

int Function(int) test() {
  return C.f;
}
''');

    var node = findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@class::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::C::@method::f
      staticType: T Function<T>(T)
    element: <testLibrary>::@class::C::@method::f
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_notEmpty_superMethod() async {
    await assertNoErrorsInCode('''
class C {
  T f<T>(T x) => x;
}

class D extends C {
  int Function(int) test() {
    return super.f;
  }
}
''');

    var node = findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: D
    operator: .
    propertyName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::C::@method::f
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_notEmpty_topLevelFunction() async {
    await assertNoErrorsInCode('''
T f<T>(T x) => x;

int Function(int) test() {
  return f;
}
''');

    var node = findNode.functionReference('f;');
    assertResolvedNodeText(node, r'''
FunctionReference
  function: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>(T)
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_null_notTearOff() async {
    await assertNoErrorsInCode('''
T f<T>(T x) => x;

void test() {
  f(0);
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@function::f::@formalParameter::x
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
  typeArgumentTypes
    int
''');
  }
}
