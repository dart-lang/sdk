// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThrowTest);
  });
}

@reflectiveTest
class ThrowTest extends PubPackageResolutionTest {
  test_downward() async {
    await resolveTestCode('''
void f() {
  throw a();
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
  staticInvokeType: dynamic Function()
  staticType: dynamic
  typeArgumentTypes
    dynamic
''');
  }
}
