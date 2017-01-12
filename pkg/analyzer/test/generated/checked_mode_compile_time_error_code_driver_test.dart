// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checked_mode_compile_time_error_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest_Driver);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest_Driver
    extends CheckedModeCompileTimeErrorCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
