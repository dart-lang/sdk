// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library test.search;

import 'package:unittest/unittest.dart';

import 'element_references_test.dart' as element_references_test;
import 'member_declarations_test.dart' as member_declarations;
import 'member_references_test.dart' as member_references_test;
import 'search_result_test.dart' as search_result_test;
import 'top_level_declarations_test.dart' as top_level_declarations_test;
import 'type_hierarchy_test.dart' as type_hierarchy_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('search', () {
    element_references_test.main();
    member_declarations.main();
    member_references_test.main();
    search_result_test.main();
    top_level_declarations_test.main();
    type_hierarchy_test.main();
  });
}
