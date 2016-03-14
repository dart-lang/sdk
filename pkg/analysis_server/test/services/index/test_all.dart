// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'index_test.dart' as index_test;

/**
 * Utility for manually running all tests.
 */
main() {
  initializeTestEnvironment();
  group('index', () {
    index_test.main();
  });
}
