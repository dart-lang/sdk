// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'index_test.dart' as index_test;
import 'index_unit_test.dart' as index_unit_test;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    index_test.main();
    index_unit_test.main();
  }, name: 'index');
}
