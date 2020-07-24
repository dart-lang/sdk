// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../driver_resolution.dart';
import '../with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThrowWithNullSafetyTest);
  });
}

@reflectiveTest
class ThrowWithNullSafetyTest extends DriverResolutionTest
    with WithNullSafetyMixin {
  test_downward() async {
    await resolveTestCode('''
void f() {
  throw a();
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'dynamic Function()');
  }
}
