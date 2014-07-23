// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library test.analysis;

import 'package:unittest/unittest.dart';

import 'get_errors_test.dart' as get_errors_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('search', () {
    get_errors_test.main();
  });
}