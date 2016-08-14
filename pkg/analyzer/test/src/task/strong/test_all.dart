// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.task.strong.test_all;

import 'package:unittest/unittest.dart';

import '../../../utils.dart';
import 'checker_test.dart' as checker_test;
import 'inferred_type_test.dart' as inferred_type_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('strong tests', () {
    checker_test.main();
    inferred_type_test.main();
  });
}
