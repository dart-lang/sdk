// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'invalid_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest_Driver);
  });
}

@reflectiveTest
class InvalidCodeTest_Driver extends InvalidCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;

  /**
   * This fails because we have a method with the empty name, and the default
   * constructor, which also has the empty name. Then, when we link, we get
   * a reference to this empty-named method, so we resynthesize a
   * `MethodHandle` with the corresponding `ElementLocation`. But at the level
   * of `ElementLocation` we cannot distinguish a reference to a method or
   * a constructor. So, we return a `ConstructorElement`, and cast to
   * `MethodElement` fails.
   */
  @failingTest
  @override
  test_constructorAndMethodNameCollision() async {
    return super.test_constructorAndMethodNameCollision();
  }
}
