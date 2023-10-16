// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/presubmit/verify_error_fix_status.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VerifyErrorFixStatusTest);
  });
}

@reflectiveTest
class VerifyErrorFixStatusTest {
  void test_statusFile() {
    var errors = verifyErrorFixStatus();
    if (errors != null) {
      fail(errors);
    }
  }
}
