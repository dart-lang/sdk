// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.context.test_all;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'cache_test.dart' as cache_test;
import 'context_test.dart' as context_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('context tests', () {
    cache_test.main();
    context_test.main();
  });
}
