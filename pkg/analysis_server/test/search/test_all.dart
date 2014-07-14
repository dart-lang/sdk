// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library test.search;

import 'package:unittest/unittest.dart';

import 'element_references_test.dart' as element_references_test;
import 'search_domain_test.dart' as search_domain_test;
import 'search_result_test.dart' as search_result_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('analysis_server', () {
    element_references_test.main();
    search_domain_test.main();
    search_result_test.main();
  });
}