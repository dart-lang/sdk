// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bool_assignment_test.dart' as bool_assignments;
import 'deprecated_member_test.dart' as deprecated_members;
import 'instance_member_test.dart' as instance_member;
import 'is_no_such_method_test.dart' as is_no_such_method;
import 'local_variable_test.dart' as local_variable;
import 'named_argument_test.dart' as named_argument;
import 'non_type_member_test.dart' as non_type_member;
import 'static_member_test.dart' as static_member;
import 'switch_statement_test.dart' as switch_statement;

void main() {
  defineReflectiveSuite(() {
    bool_assignments.main();
    deprecated_members.main();
    instance_member.main();
    is_no_such_method.main();
    local_variable.main();
    named_argument.main();
    non_type_member.main();
    static_member.main();
    switch_statement.main();
  });
}
