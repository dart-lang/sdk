// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.search.all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_type_hierarchy_test.dart' as get_type_hierarchy_test;

/**
 * Utility for manually running all integration tests.
 */
main() {
  defineReflectiveSuite(() {
    get_type_hierarchy_test.main();
  }, name: 'search');
}
