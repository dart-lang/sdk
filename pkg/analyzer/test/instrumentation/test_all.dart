// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.instrumentation.test_all;

import 'package:unittest/unittest.dart';

import 'instrumentation_test.dart' as instrumentation_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('instrumentation', () {
    instrumentation_test.main();
  });
}
