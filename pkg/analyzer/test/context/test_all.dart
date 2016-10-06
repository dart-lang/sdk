// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.context.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'declared_variables_test.dart' as declared_variables;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    declared_variables.main();
  }, name: 'context');
}
