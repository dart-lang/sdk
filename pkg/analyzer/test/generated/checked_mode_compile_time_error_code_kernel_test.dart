// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checked_mode_compile_time_error_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckedModeCompileTimeErrorCodeTest_Kernel);
  });
}

@reflectiveTest
class CheckedModeCompileTimeErrorCodeTest_Kernel
    extends CheckedModeCompileTimeErrorCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
