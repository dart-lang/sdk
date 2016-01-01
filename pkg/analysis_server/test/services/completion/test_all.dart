// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'completion_target_test.dart' as completion_target_test;
import 'dart/test_all.dart' as dart_contributor_tests;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('completion', () {
    completion_target_test.main();
    dart_contributor_tests.main();
  });
}
