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
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';

augment class A {
  void f() {
    this;
  }
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {}
''');

    await resolveFile2(a);

    nodeTextConfiguration.withInterfaceTypeElements = true;

    final node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: A
    element: self::@class::A
''');
  }

  test_mixin_inAugmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';

augment mixin M {
  void f() {
    this;
  }
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

mixin M {}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    nodeTextConfiguration.withInterfaceTypeElements = true;

    final node = findNode.singleThisExpression;
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: M
    element: self::@mixin::M
''');
  }
}
