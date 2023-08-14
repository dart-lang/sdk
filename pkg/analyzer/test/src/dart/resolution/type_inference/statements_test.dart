// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertTest);
    defineReflectiveTests(DoTest);
    defineReflectiveTests(ForTest);
    defineReflectiveTests(IfTest);
    defineReflectiveTests(WhileTest);
  });
}

@reflectiveTest
class AssertTest extends PubPackageResolutionTest {
  test_downward() async {
    await assertNoErrorsInCode('''
void f() {
  assert(a());
}
T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }
}

@reflectiveTest
class DoTest extends PubPackageResolutionTest {
  test_downward() async {
    await assertNoErrorsInCode('''
void f() {
  do {} while(a());
}
T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }
}

@reflectiveTest
class ForTest extends PubPackageResolutionTest {
  test_awaitForIn_int_downward() async {
    await assertErrorsInCode('''
void f() async {
  await for (int e in a()) {}
}
T a<T>() => throw '';
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<int> Function()
  staticType: Stream<int>
  typeArgumentTypes
    Stream<int>
''');
  }

  test_awaitForIn_var_downward() async {
    await assertErrorsInCode('''
void f() async {
  await for (var e in a()) {}
}
T a<T>() => throw '';
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Stream<Object?> Function()
  staticType: Stream<Object?>
  typeArgumentTypes
    Stream<Object?>
''');
  }

  test_awaitForIn_var_upward() async {
    await assertNoErrorsInCode('''
void f(Stream<int> s) async {
  await for (var e in s) {
    e;
  }
}
''');
    assertType(findNode.simple('e;'), 'int');
  }

  test_for_downward() async {
    await assertNoErrorsInCode('''
void f() {
  for (int i = 0; a(); i++) {}
}
T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_forIn_dynamic_downward() async {
    await assertErrorsInCode('''
void f() {
  for (var e in a()) {}
}
T a<T>() => throw '';
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<Object?> Function()
  staticType: Iterable<Object?>
  typeArgumentTypes
    Iterable<Object?>
''');
  }

  test_forIn_int_downward() async {
    await assertErrorsInCode('''
void f() {
  for (int e in a()) {}
}
T a<T>() => throw '';
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Iterable<int> Function()
  staticType: Iterable<int>
  typeArgumentTypes
    Iterable<int>
''');
  }

  test_forIn_var_upward() async {
    await assertNoErrorsInCode('''
void f(List<int> s) async {
  for (var e in s) {
    e;
  }
}
''');
    assertType(findNode.simple('e;'), 'int');
  }
}

@reflectiveTest
class IfTest extends PubPackageResolutionTest {
  test_downward() async {
    await assertNoErrorsInCode('''
void f() {
  if (a()) {}
}
T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }
}

@reflectiveTest
class WhileTest extends PubPackageResolutionTest {
  test_downward() async {
    await assertNoErrorsInCode('''
void f() {
  while (a()) {}
}
T a<T>() => throw '';
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }
}
