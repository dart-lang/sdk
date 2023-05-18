// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitExpressionResolutionTest);
    defineReflectiveTests(AwaitExpressionResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class AwaitExpressionResolutionTest extends PubPackageResolutionTest {
  test_futureOrQ() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }

  test_futureQ() async {
    await assertNoErrorsInCode(r'''
f(Future<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }

  test_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() async {
    await super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 39, 5),
    ]);

    final node = findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: SuperExpression
    superKeyword: super
    staticType: A
  staticType: A
''');
  }

  test_super_property() async {
    await assertNoErrorsInCode(r'''
class A {
  void f() async {
    await super.hashCode;
  }
}
''');

    final node = findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: hashCode
      staticElement: dart:core::@class::Object::@getter::hashCode
      staticType: int
    staticType: int
  staticType: int
''');
  }
}

@reflectiveTest
class AwaitExpressionResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_future() async {
    await assertNoErrorsInCode(r'''
f(Future<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }

  test_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }
}
