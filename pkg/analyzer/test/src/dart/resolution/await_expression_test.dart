// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AwaitExpressionResolutionTest extends PubPackageResolutionTest {
  test_future() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Future<int> a) async {
  await a;
}
''');
    assertType(result.findNode.awaitExpression('await a'), 'int');
  }

  test_futureOr() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

f(FutureOr<int> a) async {
  await a;
}
''');
    assertType(result.findNode.awaitExpression('await a'), 'int');
  }

  test_futureOrQ() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

f(FutureOr<int>? a) async {
  await a;
}
''');
    assertType(result.findNode.awaitExpression('await a'), 'int?');
  }

  test_futureQ() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
f(Future<int>? a) async {
  await a;
}
''');
    assertType(result.findNode.awaitExpression('await a'), 'int?');
  }

  test_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() async {
    await super;
//        ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');
    var node = result.findNode.singleAwaitExpression;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() async {
    await super.hashCode;
  }
}
''');

    var node = result.findNode.singleAwaitExpression;
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
      element: dart:core::@class::Object::@getter::hashCode
      staticType: int
    staticType: int
  staticType: int
''');
  }

  test_unresolved_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() async {
  await unresolved;
//      ^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');

    var node = result.findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: SimpleIdentifier
    token: unresolved
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_unresolved_prefixedIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;

void f() async {
  await prefix.unresolved;
//             ^^^^^^^^^^
// [diag.undefinedPrefixedName] The name 'unresolved' is being referenced through the prefix 'prefix', but it isn't defined in any of the libraries imported using that prefix.
}
''');

    var node = result.findNode.singleAwaitExpression;
    assertResolvedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: unresolved
      element: <null>
      staticType: InvalidType
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_unresolved_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() async {
  await 0.isEven.unresolved;
//               ^^^^^^^^^^
// [diag.undefinedGetter] The getter 'unresolved' isn't defined for the type 'bool'.
}
''');

    var node = result.findNode.singleAwaitExpression;
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
        element: dart:core::@class::int::@getter::isEven
        staticType: bool
      staticType: bool
    operator: .
    propertyName: SimpleIdentifier
      token: unresolved
      element: <null>
      staticType: InvalidType
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
