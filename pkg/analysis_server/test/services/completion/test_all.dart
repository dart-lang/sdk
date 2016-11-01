// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_target_test.dart' as completion_target_test;
import 'dart/test_all.dart' as dart_contributor_tests;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    completion_target_test.main();
    dart_contributor_tests.main();
  }, name: 'completion');
}
