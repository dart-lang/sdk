// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart/test_all.dart' as dart_contributor_tests;
import 'statement/statement_completion_test.dart' as statement_completion_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    dart_contributor_tests.main();
    statement_completion_test.main();
  }, name: 'completion');
}
