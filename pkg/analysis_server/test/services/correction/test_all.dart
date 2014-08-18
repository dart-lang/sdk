// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction;

import 'package:unittest/unittest.dart';

import 'assist_test.dart' as assist_test;
import 'change_test.dart' as change_test;
import 'fix_test.dart' as fix_test;
import 'levenshtein_test.dart' as levenshtein_test;
import 'name_suggestion_test.dart' as name_suggestion_test;
import 'source_range_test.dart' as source_range_test;
import 'status_test.dart' as status_test;
import 'strings_test.dart' as strings_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('correction', () {
    assist_test.main();
    change_test.main();
    fix_test.main();
    levenshtein_test.main();
    name_suggestion_test.main();
    source_range_test.main();
    status_test.main();
    strings_test.main();
  });
}