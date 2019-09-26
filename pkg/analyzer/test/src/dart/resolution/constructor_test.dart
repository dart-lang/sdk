// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorResolutionTest);
  });
}

@reflectiveTest
class ConstructorResolutionTest extends DriverResolutionTest {
  test_initializer_field_functionExpression_expressionBody() async {
    await resolveTestCode(r'''
class C {
  final int x;
  C(int a) : x = (() => a + 1)();
}
''');
    assertElement(findNode.simple('a + 1'), findElement.parameter('a'));
  }

  test_initializer_field_functionExpression_blockBody() async {
    await resolveTestCode(r'''
class C {
  var x;
  C(int a) : x = (() {return a + 1;})();
}
''');
    assertElement(findNode.simple('a + 1'), findElement.parameter('a'));
  }
}
