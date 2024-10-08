// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitExpressionResolutionTest);
  });
}

@reflectiveTest
class AwaitExpressionResolutionTest extends PubPackageResolutionTest {
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

    var node = findNode.singleAwaitExpression;
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

    var node = findNode.singleAwaitExpression;
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
      staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
      element: dart:core::<fragment>::@class::Object::@getter::hashCode#element
      staticType: int
    staticType: int
  staticType: int
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(r'''
void f() async {
  await unresolved;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 25, 10),
    ]);

    var node = findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: SimpleIdentifier
    token: unresolved
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_unresolved_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as prefix;

void f() async {
  await prefix.unresolved;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 63, 10),
    ]);

    var node = findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: unresolved
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_unresolved_propertyAccess() async {
    await assertErrorsInCode(r'''
void f() async {
  await 0.isEven.unresolved;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 34, 10),
    ]);

    var node = findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: PropertyAccess
    target: PropertyAccess
      target: IntegerLiteral
        literal: 0
        staticType: int
      operator: .
      propertyName: SimpleIdentifier
        token: isEven
        staticElement: dart:core::<fragment>::@class::int::@getter::isEven
        element: dart:core::<fragment>::@class::int::@getter::isEven#element
        staticType: bool
      staticType: bool
    operator: .
    propertyName: SimpleIdentifier
      token: unresolved
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
