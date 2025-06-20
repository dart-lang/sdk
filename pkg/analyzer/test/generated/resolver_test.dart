// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest);
    defineReflectiveTests(TypePropagationTest);
  });
}

/// The class `StrictModeTest` contains tests to ensure that the correct errors
/// and warnings are reported when the analysis engine is run in strict mode.
@reflectiveTest
class StrictModeTest extends PubPackageResolutionTest {
  test_assert_is() async {
    await assertErrorsInCode(
      r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''',
      [error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 47, 1)],
    );
  }

  test_conditional_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
  }

  test_conditional_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
  }

  test_conditional_isNot() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}
''');
  }

  test_conditional_or_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}
''');
  }

  test_for() async {
    await assertNoErrorsInCode(r'''
void f(List<int> list) {
  num sum = 0; // ignore: unused_local_variable
  for (int i = 0; i < list.length; i++) {
    sum += list[i];
  }
}
''');
  }

  test_forEach() async {
    await assertErrorsInCode(
      r'''
void f(List<int> list) {
  num sum = 0; // ignore: unused_local_variable
  for (num n in list) {
    sum += n & 0x0F;
  }
}
''',
      [error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 110, 1)],
    );
  }

  test_if_and_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_if_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
  }

  test_if_isNot() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''');
  }

  test_if_isNot_abrupt() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}
''');
  }

  test_if_or_is() async {
    await assertNoErrorsInCode(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}
''');
  }

  test_localVar() async {
    await assertErrorsInCode(
      r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''',
      [error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 37, 1)],
    );
  }
}

@reflectiveTest
class TypePropagationTest extends PubPackageResolutionTest {
  test_assignment_null() async {
    await resolveTestCode(r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}
''');

    var node = findNode.simple('v; // return');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@15
  staticType: int
''');
  }

  test_initializer_hasStaticType() async {
    await resolveTestCode(r'''
f() {
  int v = 0;
  return v;
}''');

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@12
  staticType: int
''');
  }

  test_initializer_hasStaticType_parameterized() async {
    await resolveTestCode(r'''
f() {
  List<int> v = <int>[];
  return v;
}''');

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@18
  staticType: List<int>
''');
  }

  test_initializer_null() async {
    await resolveTestCode(r'''
main() {
  int v = null;
  return v;
}''');

    var node = findNode.simple('v;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: v@15
  staticType: int
''');
  }

  test_invocation_target_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int max(int x, int y) => 0;
''');

    await resolveTestCode('''
import 'a.dart' as helper;
main() {
  helper.max(10, 10); // marker
}''');

    var node = findNode.simple('max(10, 10)');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: max
  element: package:test/a.dart::@function::max
  staticType: int Function(int, int)
''');
  }

  test_is_subclass() async {
    await resolveTestCode(r'''
class A {}
class B extends A {
  B m() => this;
}
A f(A p) {
  if (p is B) {
    return p.m();
  }
  return p;
}''');

    var node = findNode.methodInvocation('p.m()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    element: <testLibrary>::@function::f::@formalParameter::p
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::B::@method::m
    staticType: B Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: B Function()
  staticType: B
''');
  }

  test_mutatedOutsideScope() async {
    // https://code.google.com/p/dart/issues/detail?id=22732
    await assertNoErrorsInCode(r'''
class Base {
}

class Derived extends Base {
  get y => null;
}

class C {
  void f(Base x) {
    x = Base();
    if (x is Derived) {
      print(x.y); // BAD
    }
    x = Base();
  }
}

void g(Base x) {
  x = Base();
  if (x is Derived) {
    print(x.y); // GOOD
  }
  x = Base();
}
''');
  }

  test_objectAccessInference_disabled_for_library_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
dynamic get hashCode => 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.hashCode;
}''');
    assertTypeDynamic(findNode.prefixed('helper.hashCode'));
  }

  test_objectAccessInference_disabled_for_local_getter() async {
    await assertNoErrorsInCode('''
dynamic get hashCode => null;
main() {
  hashCode; // marker
}''');
    assertTypeDynamic(findNode.simple('hashCode; // marker'));
  }

  test_objectMethodInference_disabled_for_library_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
dynamic toString = (int x) => x + 42;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as helper;
main() {
  helper.toString();
}''');
    assertTypeDynamic(
      findNode.functionExpressionInvocation('helper.toString()'),
    );
  }

  test_objectMethodInference_disabled_for_local_function() async {
    await resolveTestCode('''
main() {
  dynamic toString = () => null;
  toString(); // marker
}''');

    var node = findNode.simple('toString(); // marker');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: toString
  element: toString@19
  staticType: dynamic
''');
  }

  @failingTest
  test_propagatedReturnType_functionExpression() async {
    // TODO(scheglov): disabled because we don't resolve function expression
    await resolveTestCode(r'''
main() {
  var v = (() {return 42;})();
}''');
    assertTypeDynamic(findNode.simple('v = '));
  }
}
