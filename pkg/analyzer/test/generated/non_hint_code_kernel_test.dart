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

@reflectiveTest
class NonHintCodeTest_Kernel extends NonHintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    return super.test_deprecatedMemberUse_inDeprecatedLibrary();
  }

  @override
  @failingTest
  test_unusedImport_annotationOnDirective() async {
    return super.test_unusedImport_annotationOnDirective();
  }

  @override
  @failingTest
  test_unusedImport_metadata() async {
    return super.test_unusedImport_metadata();
  }
}
