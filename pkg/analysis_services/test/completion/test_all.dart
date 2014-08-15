// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:unittest/unittest.dart';

import 'completion_computer_test.dart' as completion_test;
import 'imported_type_computer_test.dart' as importedType_test;
import 'invocation_computer_test.dart' as invocation_test;
import 'local_computer_test.dart' as local_test;
import 'keyword_computer_test.dart' as keyword_test;

/// Utility for manually running all tests.
main() {
  groupSep = ' | ';
  group('completion', () {
    completion_test.main();
    importedType_test.main();
    keyword_test.main();
    invocation_test.main();
    local_test.main();
  });
}
