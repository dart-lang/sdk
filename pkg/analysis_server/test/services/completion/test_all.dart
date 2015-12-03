// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion;

import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'combinator_contributor_test.dart' as combinator_test;
import 'completion_computer_test.dart' as completion_computer_test;
import 'completion_manager_test.dart' as completion_manager_test;
import 'completion_target_test.dart' as completion_target_test;
import 'dart/test_all.dart' as dart_contributor_tests;
import 'imported_reference_contributor_test.dart' as imported_test;
import 'local_declaration_visitor_test.dart' as local_declaration_visitor_test;
import 'local_reference_contributor_test.dart'
    as local_reference_contributor_test;
import 'optype_test.dart' as optype_test;
import 'prefixed_element_contributor_test.dart' as invocation_test;
import 'uri_contributor_test.dart' as uri_contributor_test;

/// Utility for manually running all tests.
main() {
  initializeTestEnvironment();
  group('completion', () {
    combinator_test.main();
    completion_computer_test.main();
    completion_manager_test.main();
    completion_target_test.main();
    dart_contributor_tests.main();
    imported_test.main();
    invocation_test.main();
    local_declaration_visitor_test.main();
    local_reference_contributor_test.main();
    optype_test.main();
    uri_contributor_test.main();
  });
}
