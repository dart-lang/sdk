// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.element.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'builder_test.dart' as builder;
import 'element_test.dart' as element;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    builder.main();
    element.main();
  }, name: 'element');
}
