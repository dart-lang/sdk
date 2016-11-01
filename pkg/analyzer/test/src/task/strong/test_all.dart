// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.strong.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checker_test.dart' as checker_test;
import 'inferred_type_test.dart' as inferred_type_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    checker_test.main();
    inferred_type_test.main();
  }, name: 'strong');
}
