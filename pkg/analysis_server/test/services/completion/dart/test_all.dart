// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'arglist_contributor_test.dart' as arglist_test;
import 'closure_contributor_test.dart' as closure_contributor;
import 'completion_manager_test.dart' as completion_manager;
import 'declaration/test_all.dart' as declaration;
import 'imported_reference_contributor_test.dart' as imported_ref_test;
import 'local_library_contributor_test.dart' as local_lib_test;
import 'local_reference_contributor_test.dart' as local_ref_test;
import 'location/test_all.dart' as location;
import 'named_constructor_contributor_test.dart' as named_contributor_test;
import 'relevance/test_all.dart' as relevance_tests;
import 'static_member_contributor_test.dart' as static_contributor_test;
import 'text_expectations.dart';
import 'type_member_contributor_test.dart' as type_member_contributor_test;
import 'uri_contributor_test.dart' as uri_contributor_test;
import 'variable_name_contributor_test.dart' as variable_name_contributor_test;

void main() {
  defineReflectiveSuite(() {
    arglist_test.main();
    closure_contributor.main();
    completion_manager.main();
    declaration.main();
    imported_ref_test.main();
    local_lib_test.main();
    local_ref_test.main();
    location.main();
    named_contributor_test.main();
    relevance_tests.main();
    static_contributor_test.main();
    type_member_contributor_test.main();
    uri_contributor_test.main();
    variable_name_contributor_test.main();
    defineReflectiveTests(UpdateTextExpectations);
  }, name: 'dart');
}
