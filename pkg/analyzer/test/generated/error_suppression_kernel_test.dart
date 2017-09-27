// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'error_suppression_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorSuppressionTest_Kernel);
  });
}

@reflectiveTest
class ErrorSuppressionTest_Kernel extends ErrorSuppressionTest_Driver {
  @override
  bool get enableKernelDriver => true;
}
