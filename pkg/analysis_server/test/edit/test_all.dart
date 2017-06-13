// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assists_test.dart' as assists_test;
import 'fixes_test.dart' as fixes_test;
import 'format_test.dart' as format_test;
import 'organize_directives_test.dart' as organize_directives_test;
import 'refactoring_test.dart' as refactoring_test;
import 'sort_members_test.dart' as sort_members_test;
import 'statement_completion_test.dart' as statement_completion_test;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    assists_test.main();
    fixes_test.main();
    format_test.main();
    organize_directives_test.main();
    refactoring_test.main();
    sort_members_test.main();
    statement_completion_test.main();
  }, name: 'edit');
}
