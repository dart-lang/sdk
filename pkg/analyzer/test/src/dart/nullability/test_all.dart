// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_test.dart' as migration_test;
import 'unit_propagation_test.dart' as unit_propagation_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    migration_test.main();
    unit_propagation_test.main();
  }, name: 'nullability');
}
