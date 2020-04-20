// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDriverResolutionTest);
  });
}

@reflectiveTest
class EnumDriverResolutionTest extends DriverResolutionTest {
  test_inference_listLiteral() async {
    await assertNoErrorsInCode(r'''
enum E1 {a, b}
enum E2 {a, b}

var v = [E1.a, E2.b];
''');

    var v = findElement.topVar('v');
    assertType(v.type, 'List<Object>');
  }

  test_isConstantEvaluated() async {
    await assertNoErrorsInCode(r'''
enum E {
  aaa, bbb
}
''');

    expect(findElement.field('aaa').isConstantEvaluated, isTrue);
    expect(findElement.field('bbb').isConstantEvaluated, isTrue);
    expect(findElement.field('values').isConstantEvaluated, isTrue);
  }
}
