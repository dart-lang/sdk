// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.all;

import 'package:unittest/unittest.dart';

import 'edit_domain_test.dart' as domain_edit_test;
import 'fix_test.dart' as fix_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('edit', () {
    domain_edit_test.main();
    fix_test.main();
  });
}