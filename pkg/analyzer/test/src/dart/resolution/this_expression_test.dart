// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThisExpressionResolutionTest);
  });
}

@reflectiveTest
class ThisExpressionResolutionTest extends PubPackageResolutionTest {
  test_class_inAugmentation() async {
    await assertNoErrorsInCode(r'''
class A {}

augment class A {
  void f() {
    this;
  }
}
''');

    nodeTextConfiguration.withInterfaceTypeElements = true;

    var node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: A
    element: <testLibrary>::@class::A
''');
  }

  test_mixin_inAugmentation() async {
    await assertNoErrorsInCode(r'''
mixin M {}

augment mixin M {
  void f() {
    this;
  }
}
''');

    nodeTextConfiguration.withInterfaceTypeElements = true;

    var node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: M
    element: <testLibrary>::@mixin::M
''');
  }
}
