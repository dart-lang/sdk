// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.all;

import 'package:unittest/unittest.dart';

import 'b_plus_tree_test.dart' as b_plus_tree_test;
import 'file_page_manager_test.dart' as file_page_manager_test;
import 'lru_cache_test.dart' as lru_cache_test;
import 'page_node_manager_test.dart' as page_node_manager_test;
import 'store/test_all.dart' as store_test_all;


/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('index', () {
    b_plus_tree_test.main();
    page_node_manager_test.main();
    file_page_manager_test.main();
    lru_cache_test.main();
    store_test_all.main();
  });
}