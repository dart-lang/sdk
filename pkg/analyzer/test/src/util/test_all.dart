// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.util;

import 'package:unittest/unittest.dart';

import 'asserts_test.dart' as asserts_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('task tests', () {
    asserts_test.main();
  });
}
