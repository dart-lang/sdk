// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'combine_test.dart' as combine_test;
import 'file_state_test.dart' as file_state;
import 'format_test.dart' as format;
import 'kernel_driver_test.dart' as kernel_driver;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    combine_test.main();
    file_state.main();
    format.main();
    kernel_driver.main();
  }, name: 'incremental');
}
