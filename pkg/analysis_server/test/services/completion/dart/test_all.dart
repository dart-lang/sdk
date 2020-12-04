// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'arglist_contributor_test.dart' as arglist_test;
import 'combinator_contributor_test.dart' as combinator_test;
import 'completion_manager_test.dart' as completion_manager;
import 'completion_ranking_internal_test.dart'
    as completion_ranking_internal_test;
import 'extension_member_contributor_test.dart' as extension_member_contributor;
import 'field_formal_contributor_test.dart' as field_formal_contributor_test;
import 'imported_reference_contributor_test.dart' as imported_ref_test;
import 'keyword_contributor_test.dart' as keyword_test;
import 'label_contributor_test.dart' as label_contributor_test;
import 'library_member_contributor_test.dart' as library_member_test;
import 'library_prefix_contributor_test.dart' as library_prefix_test;
import 'local_library_contributor_test.dart' as local_lib_test;
import 'local_reference_contributor_test.dart' as local_ref_test;
import 'named_constructor_contributor_test.dart' as named_contributor_test;
import 'override_contributor_test.dart' as override_contributor_test;
import 'relevance/test_all.dart' as relevance_tests;
import 'static_member_contributor_test.dart' as static_contributor_test;
import 'type_member_contributor_test.dart' as type_member_contributor_test;
import 'uri_contributor_test.dart' as uri_contributor_test;
import 'variable_name_contributor_test.dart' as variable_name_contributor_test;

void main() {
  defineReflectiveSuite(() {
    arglist_test.main();
    combinator_test.main();
    completion_manager.main();
    completion_ranking_internal_test.main();
    extension_member_contributor.main();
    field_formal_contributor_test.main();
    imported_ref_test.main();
    keyword_test.main();
    label_contributor_test.main();
    library_member_test.main();
    library_prefix_test.main();
    local_lib_test.main();
    local_ref_test.main();
    named_contributor_test.main();
    override_contributor_test.main();
    relevance_tests.main();
    static_contributor_test.main();
    type_member_contributor_test.main();
    uri_contributor_test.main();
    variable_name_contributor_test.main();
  }, name: 'dart');
}
