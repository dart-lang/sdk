// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.util.test_all;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'absolute_path_test.dart' as absolute_path_test;
import 'asserts_test.dart' as asserts_test;
import 'fast_uri_test.dart' as fast_uri_test;
import 'glob_test.dart' as glob_test;
import 'lru_map_test.dart' as lru_map_test;
import 'yaml_test.dart' as yaml_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('util tests', () {
    absolute_path_test.main();
    asserts_test.main();
    fast_uri_test.main();
    glob_test.main();
    lru_map_test.main();
    yaml_test.main();
  });
}
