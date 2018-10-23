// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantDriverTest);
    defineReflectiveTests(ConstantTaskTest);
  });
}

@reflectiveTest
class ConstantDriverTest extends DriverResolutionTest with ConstantMixin {}

abstract class ConstantMixin implements ResolutionTest {
  test_constFactoryRedirection_super() async {
    addTestFile(r'''
class I {
  const factory I(int f) = B;
}

class A implements I {
  final int f;

  const A(this.f);
}

class B extends A {
  const B(int f) : super(f);
}

@I(42)
main() {}
''');
    await resolveTestFile();
    assertNoTestErrors();

    var node = findNode.annotation('@I');
    var value = node.elementAnnotation.constantValue;
    expect(value.getField('(super)').getField('f').toIntValue(), 42);
  }
}

@reflectiveTest
class ConstantTaskTest extends TaskResolutionTest with ConstantMixin {}
