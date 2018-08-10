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
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_deadCode_afterForEachWithBreakLabel() async {
    await super.test_deadCode_afterForEachWithBreakLabel();
  }

  @override
  @failingTest
  test_deadCode_afterForWithBreakLabel() async {
    await super.test_deadCode_afterForWithBreakLabel();
  }

  @override
  @failingTest
  test_unusedImport_annotationOnDirective() async {
    await super.test_unusedImport_annotationOnDirective();
  }
}
