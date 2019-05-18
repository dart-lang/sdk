// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeResolutionTest);
  });
}

@reflectiveTest
class GenericFunctionTypeResolutionTest extends DriverResolutionTest {
  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_field_static_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

class B {
  static const x = const A<bool Function()>();
}

int Function(int a) y;
''');
  }

  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_topLevel() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

const x = const A<bool Function()>();

int Function(int a) y;
''');
  }
}
