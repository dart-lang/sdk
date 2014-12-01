// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.all;

import 'package:unittest/unittest.dart';

import 'dart_index_contributor_test.dart' as dart_index_contributor_test;
import 'local_file_index_test.dart' as local_file_index_test;
import 'local_index_test.dart' as local_index_test;
import 'store/test_all.dart' as store_test_all;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('index', () {
    dart_index_contributor_test.main();
    local_file_index_test.main();
    local_index_test.main();
    store_test_all.main();
  });
}
