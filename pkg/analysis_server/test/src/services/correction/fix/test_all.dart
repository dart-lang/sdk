// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_async_test.dart' as add_async;
import 'add_explicit_cast_test.dart' as add_explicit_cast;
import 'add_field_formal_parameters_test.dart' as add_field_formal_parameters;
import 'add_missing_parameter_named_test.dart' as add_missing_parameter_named;
import 'add_missing_parameter_positional_test.dart'
    as add_missing_parameter_positional;
import 'add_missing_parameter_required_test.dart'
    as add_missing_parameter_required;
import 'add_missing_required_argument_test.dart'
    as add_missing_required_argument;
import 'add_static_test.dart' as add_static;
import 'add_super_constructor_invocation_test.dart'
    as add_super_constructor_invocation;
import 'change_to_static_access_test.dart' as change_to_static_access;
import 'change_type_annotation_test.dart' as change_type_annotation;
import 'convert_to_named_arguments_test.dart' as convert_to_named_arguments;
import 'create_class_test.dart' as create_class;
import 'create_constructor_for_final_fields_test.dart'
    as create_constructor_for_final_field;
import 'create_constructor_super_test.dart' as create_constructor_super;
import 'create_constructor_test.dart' as create_constructor;
import 'create_field_test.dart' as create_field;
import 'create_function_test.dart' as create_function;
import 'create_getter_test.dart' as create_getter;
import 'create_local_variable_test.dart' as create_local_variable;
import 'create_method_test.dart' as create_method;
import 'create_missing_overrides_test.dart' as create_missing_overrides;
import 'create_mixin_test.dart' as create_mixin;
import 'create_no_such_method_test.dart' as create_no_such_method;
import 'extend_class_for_mixin_test.dart' as extend_class_for_mixin;
import 'insert_semicolon_test.dart' as insert_semicolon;
import 'replace_boolean_with_bool_test.dart' as replace_boolean_with_bool;
import 'replace_with_null_aware_test.dart' as replace_with_null_aware;

main() {
  defineReflectiveSuite(() {
    add_async.main();
    add_explicit_cast.main();
    add_field_formal_parameters.main();
    add_missing_parameter_named.main();
    add_missing_parameter_positional.main();
    add_missing_parameter_required.main();
    add_missing_required_argument.main();
    add_static.main();
    add_super_constructor_invocation.main();
    change_to_static_access.main();
    change_type_annotation.main();
    convert_to_named_arguments.main();
    create_class.main();
    create_constructor_for_final_field.main();
    create_constructor_super.main();
    create_constructor.main();
    create_field.main();
    create_function.main();
    create_getter.main();
    create_local_variable.main();
    create_method.main();
    create_missing_overrides.main();
    create_mixin.main();
    create_no_such_method.main();
    extend_class_for_mixin.main();
    insert_semicolon.main();
    replace_boolean_with_bool.main();
    replace_with_null_aware.main();
  }, name: 'fix');
}
