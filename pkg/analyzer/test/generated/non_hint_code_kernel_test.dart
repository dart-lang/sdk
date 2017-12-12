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
  bool get previewDart2 => true;

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_deadCode_deadBlock_if_debugConst_propertyAccessor() async {
    await super.test_deadCode_deadBlock_if_debugConst_propertyAccessor();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    await super.test_deprecatedMemberUse_inDeprecatedLibrary();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_duplicateImport_as() async {
    // Expected 0 errors of type HintCode.UNUSED_IMPORT, found 1 (38)
    await super.test_duplicateImport_as();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_importDeferredLibraryWithLoadFunction() async {
    await super.test_importDeferredLibraryWithLoadFunction();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unnecessaryCast_generics() async {
    // Expected 0 errors of type HintCode.UNNECESSARY_CAST, found 1 (90)
    await super.test_unnecessaryCast_generics();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_as_equalPrefixes() async {
    await super.test_unusedImport_as_equalPrefixes();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_metadata() async {
    await super.test_unusedImport_metadata();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_prefix_topLevelFunction() async {
    await super.test_unusedImport_prefix_topLevelFunction();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_prefix_topLevelFunction2() async {
    await super.test_unusedImport_prefix_topLevelFunction2();
  }
}
