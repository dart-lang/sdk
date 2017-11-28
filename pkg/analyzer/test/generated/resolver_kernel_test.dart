// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest_Kernel);
    defineReflectiveTests(TypePropagationTest_Kernel);
  });
}

@reflectiveTest
class StrictModeTest_Kernel extends StrictModeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}

@reflectiveTest
class TypePropagationTest_Kernel extends TypePropagationTest_Driver {
  @override
  bool get enableKernelDriver => true;
}
