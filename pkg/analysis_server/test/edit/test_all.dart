// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.all;

import 'package:unittest/unittest.dart';

import 'assists_test.dart' as assists_test;
import 'fixes_test.dart' as fixes_test;
import 'refactoring_test.dart' as refactoring_test;
import 'sort_members_test.dart' as sort_members_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('edit', () {
    assists_test.main();
    fixes_test.main();
    refactoring_test.main();
    sort_members_test.main();
  });
}
