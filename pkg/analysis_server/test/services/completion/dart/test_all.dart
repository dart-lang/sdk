// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'arglist_contributor_test.dart' as arglist_test;
import 'completion_manager_test.dart' as completion_manager;
import 'completion_test_test.dart' as completion_test;
import 'declaration/test_all.dart' as declaration;
import 'imported_reference_contributor_test.dart' as imported_ref_test;
import 'local_reference_contributor_test.dart' as local_ref_test;
import 'location/test_all.dart' as location;
import 'relevance/test_all.dart' as relevance_tests;
import 'text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    arglist_test.main();
    completion_manager.main();
    completion_test.main();
    declaration.main();
    imported_ref_test.main();
    local_ref_test.main();
    location.main();
    relevance_tests.main();
    defineReflectiveTests(UpdateTextExpectations);
  }, name: 'dart');
}
