// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'argument_type_not_assignable_test.dart' as argument_type_not_assignable;
import 'can_be_null_after_null_aware_test.dart' as can_be_null_after_null_aware;
import 'deprecated_member_use_test.dart' as deprecated_member_use;
import 'division_optimization_test.dart' as division_optimization;
import 'invalid_assignment_test.dart' as invalid_assignment;
import 'invalid_cast_new_expr_test.dart' as invalid_cast_new_expr;
import 'invalid_override_different_default_values_named_test.dart'
    as invalid_override_different_default_values_named;
import 'invalid_override_different_default_values_positional_test.dart'
    as invalid_override_different_default_values_positional;
import 'invalid_required_param_test.dart' as invalid_required_param;
import 'top_level_instance_getter_test.dart' as top_level_instance_getter;
import 'top_level_instance_method_test.dart' as top_level_instance_method;
import 'type_check_is_not_null_test.dart' as type_check_is_not_null;
import 'type_check_is_null_test.dart' as type_check_is_null;
import 'undefined_getter_test.dart' as undefined_getter;
import 'undefined_hidden_name_test.dart' as undefined_hidden_name;
import 'undefined_operator_test.dart' as undefined_operator;
import 'undefined_prefixed_name_test.dart' as undefined_prefixed_name;
import 'undefined_setter_test.dart' as undefined_setter;
import 'undefined_shown_name_test.dart' as undefined_shown_name;
import 'unnecessary_cast_test.dart' as unnecessary_cast;
import 'unnecessary_no_such_method_test.dart' as unnecessary_no_such_method;
import 'unnecessary_type_check_false_test.dart' as unnecessary_type_check_false;
import 'unnecessary_type_check_true_test.dart' as unnecessary_type_check_true;
import 'unused_catch_clause_test.dart' as unused_catch_clause;
import 'unused_catch_stack_test.dart' as unused_catch_stack;
import 'unused_element_test.dart' as unused_element;
import 'unused_field_test.dart' as unused_field;
import 'unused_import_test.dart' as unused_import;
import 'unused_label_test.dart' as unused_label;
import 'unused_local_variable_test.dart' as unused_local_variable;
import 'unused_shown_name_test.dart' as unused_shown_name;
import 'use_of_void_result_test.dart' as use_of_void_result;

main() {
  defineReflectiveSuite(() {
    argument_type_not_assignable.main();
    can_be_null_after_null_aware.main();
    deprecated_member_use.main();
    division_optimization.main();
    invalid_assignment.main();
    invalid_cast_new_expr.main();
    invalid_override_different_default_values_named.main();
    invalid_override_different_default_values_positional.main();
    invalid_required_param.main();
    top_level_instance_getter.main();
    top_level_instance_method.main();
    type_check_is_not_null.main();
    type_check_is_null.main();
    undefined_getter.main();
    undefined_hidden_name.main();
    undefined_operator.main();
    undefined_prefixed_name.main();
    undefined_setter.main();
    undefined_shown_name.main();
    unnecessary_cast.main();
    unnecessary_no_such_method.main();
    unnecessary_type_check_false.main();
    unnecessary_type_check_true.main();
    unused_catch_clause.main();
    unused_catch_stack.main();
    unused_element.main();
    unused_field.main();
    unused_import.main();
    unused_label.main();
    unused_local_variable.main();
    unused_shown_name.main();
    use_of_void_result.main();
  }, name: 'diagnostics');
}
