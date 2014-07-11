// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.scheglov.all;

import 'package:unittest/unittest.dart';

import 'search_engine_test.dart' as search_engine_test;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('search', () {
    search_engine_test.main();
  });
}