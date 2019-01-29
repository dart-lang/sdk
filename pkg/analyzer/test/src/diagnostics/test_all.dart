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
import 'undefined_getter.dart' as undefined_getter;
import 'unnecessary_cast_test.dart' as unnecessary_cast;
import 'unused_field_test.dart' as unused_field;
import 'unused_import_test.dart' as unused_import;
import 'unused_label_test.dart' as unused_label;
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
    undefined_getter.main();
    unnecessary_cast.main();
    unused_field.main();
    unused_import.main();
    unused_label.main();
    unused_shown_name.main();
    use_of_void_result.main();
  }, name: 'diagnostics');
}
