// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:unittest/unittest.dart';

import 'completion_computer_test.dart' as completion_computer_test;
import 'completion_manager_test.dart' as completion_manager_test;
import 'imported_computer_test.dart' as imported_test;
import 'invocation_computer_test.dart' as invocation_test;
import 'keyword_computer_test.dart' as keyword_test;
import 'local_computer_test.dart' as local_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('completion', () {
    completion_computer_test.main();
    completion_manager_test.main();
    imported_test.main();
    keyword_test.main();
    invocation_test.main();
    local_test.main();
  });
}
