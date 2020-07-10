// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bool_assignment_relevance_test.dart' as bool_assignments;
import 'deprecated_member_relevance_test.dart' as deprecated_members;
import 'instance_member_relevance_test.dart' as instance_member_relevance;
import 'local_variable_relevance_test.dart' as local_variable_relevance;
import 'named_argument_relevance_test.dart' as named_argument_relevance;
import 'non_type_member_relevance_test.dart' as non_type_member_relevance;
import 'static_member_relevance_test.dart' as static_member_relevance;

void main() {
  defineReflectiveSuite(() {
    bool_assignments.main();
    deprecated_members.main();
    instance_member_relevance.main();
    local_variable_relevance.main();
    named_argument_relevance.main();
    non_type_member_relevance.main();
    static_member_relevance.main();
  });
}
