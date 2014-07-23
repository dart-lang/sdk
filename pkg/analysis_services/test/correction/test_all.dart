// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction;

import 'package:unittest/unittest.dart';

import 'change_test.dart' as change_test;
import 'fix_test.dart' as fix_test;
import 'name_suggestion_test.dart' as name_suggestion_test;
import 'source_range_test.dart' as source_range_test;
import 'strings_test.dart' as strings_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('correction', () {
    change_test.main();
    fix_test.main();
    name_suggestion_test.main();
    source_range_test.main();
    strings_test.main();
  });
}