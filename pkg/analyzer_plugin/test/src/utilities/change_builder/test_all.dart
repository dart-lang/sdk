// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'change_builder_core_test.dart' as change_builder_core_test;
import 'change_builder_dart_test.dart' as change_builder_dart_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    change_builder_core_test.main();
    change_builder_dart_test.main();
  });
}
