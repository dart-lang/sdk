// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_warning_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest_Kernel);
  });
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class StaticTypeWarningCodeTest_Kernel
    extends StaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest_Kernel
    extends StrongModeStaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;
}
