// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'invalid_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest_Kernel);
  });
}

@reflectiveTest
class InvalidCodeTest_Kernel extends InvalidCodeTest {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_constructorAndMethodNameCollision() async {
    return super.test_constructorAndMethodNameCollision();
  }
}
