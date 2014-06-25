// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.all;

import 'package:unittest/unittest.dart';

import 'element_test.dart' as element_test;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('index', () {
    element_test.main();
  });
}