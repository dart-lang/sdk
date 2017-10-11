// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_hint_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class NonHintCodeTest_Kernel extends NonHintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    return super.test_deprecatedMemberUse_inDeprecatedLibrary();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unusedImport_annotationOnDirective() async {
    return super.test_unusedImport_annotationOnDirective();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_unusedImport_metadata() async {
    return super.test_unusedImport_metadata();
  }
}
