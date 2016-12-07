// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.operation.all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'operation_queue_test.dart' as operation_queue_test;
import 'operation_test.dart' as operation_test;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    operation_queue_test.main();
    operation_test.main();
  }, name: 'operation');
}
