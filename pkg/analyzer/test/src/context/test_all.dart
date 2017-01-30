// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'builder_test.dart' as builder_test;
import 'cache_test.dart' as cache_test;
import 'context_test.dart' as context_test;
import 'source_test.dart' as source_test;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    builder_test.main();
    cache_test.main();
    context_test.main();
    source_test.main();
  }, name: 'context');
}
