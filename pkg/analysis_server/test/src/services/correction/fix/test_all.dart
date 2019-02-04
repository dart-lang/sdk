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
import 'add_ne_null_test.dart' as add_ne_null;
import 'add_override_test.dart' as add_override;
import 'add_required_test.dart' as add_required;
import 'add_static_test.dart' as add_static;
import 'add_super_constructor_invocation_test.dart'
    as add_super_constructor_invocation;
import 'change_to_nearest_precise_value_test.dart'
    as change_to_nearest_precise_value;
import 'change_to_static_access_test.dart' as change_to_static_access;
import 'change_to_test.dart' as change_to;
import 'change_type_annotation_test.dart' as change_type_annotation;
import 'convert_flutter_child_test.dart' as convert_flutter_child;
import 'convert_flutter_children_test.dart' as convert_flutter_children;
import 'convert_to_named_arguments_test.dart' as convert_to_named_arguments;
import 'create_class_test.dart' as create_class;
import 'create_constructor_for_final_fields_test.dart'
    as create_constructor_for_final_field;
import 'create_constructor_super_test.dart' as create_constructor_super;
import 'create_constructor_test.dart' as create_constructor;
import 'create_field_test.dart' as create_field;
import 'create_file_test.dart' as create_file;
import 'create_function_test.dart' as create_function;
import 'create_getter_test.dart' as create_getter;
import 'create_local_variable_test.dart' as create_local_variable;
import 'create_method_test.dart' as create_method;
import 'create_missing_overrides_test.dart' as create_missing_overrides;
import 'create_mixin_test.dart' as create_mixin;
import 'create_no_such_method_test.dart' as create_no_such_method;
import 'extend_class_for_mixin_test.dart' as extend_class_for_mixin;
import 'fix_test.dart' as fix;
import 'import_async_test.dart' as import_async;
import 'import_library_prefix_test.dart' as import_library_prefix;
import 'import_library_project_test.dart' as import_library_project;
import 'import_library_sdk_test.dart' as import_library_sdk;
import 'import_library_show_test.dart' as import_library_show;
import 'insert_semicolon_test.dart' as insert_semicolon;
import 'make_class_abstract_test.dart' as make_class_abstract;
import 'make_field_not_final_test.dart' as make_field_not_final;
import 'make_final_test.dart' as make_final;
import 'move_type_arguments_to_class_test.dart' as move_type_arguments_to_class;
import 'remove_annotation_test.dart' as remove_annotation;
import 'remove_await_test.dart' as remove_await;
import 'remove_dead_code_test.dart' as remove_dead_code;
import 'remove_empty_catch_test.dart' as remove_empty_catch;
import 'remove_empty_constructor_body_test.dart'
    as remove_empty_constructor_body;
import 'remove_empty_else_test.dart' as remove_empty_else;
import 'remove_empty_statement_test.dart' as remove_empty_statement;
import 'remove_initializer_test.dart' as remove_initializer;
import 'remove_interpolation_braces_test.dart' as remove_interpolation_braces;
import 'remove_method_declaration_test.dart' as remove_method_declaration;
import 'remove_name_from_combinator_test.dart' as remove_name_from_combinator;
import 'remove_parameters_in_getter_declaration_test.dart'
    as remove_parameters_in_getter_declaration;
import 'remove_parentheses_in_getter_invocation_test.dart'
    as remove_parentheses_in_getter_invocation;
import 'remove_this_expression_test.dart' as remove_this_expression;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'remove_type_arguments_test.dart' as remove_type_arguments;
import 'remove_unnecessary_cast_test.dart' as remove_unnecessary_cast;
import 'remove_unused_catch_clause_test.dart' as remove_unused_catch_clause;
import 'remove_unused_catch_stack_test.dart' as remove_unused_catch_stack;
import 'remove_unused_import_test.dart' as remove_unused_import;
import 'rename_to_camel_case_test.dart' as rename_to_camel_case;
import 'replace_boolean_with_bool_test.dart' as replace_boolean_with_bool;
import 'replace_final_with_const_test.dart' as replace_final_with_const;
import 'replace_return_type_future_test.dart' as replace_return_type_future;
import 'replace_var_with_dynamic_test.dart' as replace_var_with_dynamic;
import 'replace_with_brackets_test.dart' as replace_with_brackets;
import 'replace_with_conditional_assignment_test.dart'
    as replace_with_conditional_assignment;
import 'replace_with_identifier_test.dart' as replace_with_identifier;
import 'replace_with_literal_test.dart' as replace_with_literal;
import 'replace_with_null_aware_test.dart' as replace_with_null_aware;
import 'replace_with_tear_off_test.dart' as replace_with_tear_off;
import 'update_sdk_constraints_test.dart' as update_sdk_constraints;
import 'use_const_test.dart' as use_const;
import 'use_effective_integer_division_test.dart'
    as use_effective_integer_division;
import 'use_eq_eq_null_test.dart' as use_eq_eq_null;
import 'use_is_not_empty_test.dart' as use_is_not_empty;
import 'use_not_eq_null_test.dart' as use_not_eq_null;

main() {
  defineReflectiveSuite(() {
    add_async.main();
    add_explicit_cast.main();
    add_field_formal_parameters.main();
    add_missing_parameter_named.main();
    add_missing_parameter_positional.main();
    add_missing_parameter_required.main();
    add_missing_required_argument.main();
    add_ne_null.main();
    add_override.main();
    add_required.main();
    add_static.main();
    add_super_constructor_invocation.main();
    change_to.main();
    change_to_nearest_precise_value.main();
    change_to_static_access.main();
    change_type_annotation.main();
    convert_flutter_child.main();
    convert_flutter_children.main();
    convert_to_named_arguments.main();
    create_class.main();
    create_constructor_for_final_field.main();
    create_constructor_super.main();
    create_constructor.main();
    create_field.main();
    create_file.main();
    create_function.main();
    create_getter.main();
    create_local_variable.main();
    create_method.main();
    create_missing_overrides.main();
    create_mixin.main();
    create_no_such_method.main();
    extend_class_for_mixin.main();
    fix.main();
    import_async.main();
    import_library_prefix.main();
    import_library_project.main();
    import_library_sdk.main();
    import_library_show.main();
    insert_semicolon.main();
    make_class_abstract.main();
    make_field_not_final.main();
    make_final.main();
    move_type_arguments_to_class.main();
    remove_annotation.main();
    remove_await.main();
    remove_dead_code.main();
    remove_empty_catch.main();
    remove_empty_constructor_body.main();
    remove_empty_else.main();
    remove_empty_statement.main();
    remove_initializer.main();
    remove_interpolation_braces.main();
    remove_method_declaration.main();
    remove_name_from_combinator.main();
    remove_parameters_in_getter_declaration.main();
    remove_parentheses_in_getter_invocation.main();
    remove_this_expression.main();
    remove_type_annotation.main();
    remove_type_arguments.main();
    remove_unnecessary_cast.main();
    remove_unused_catch_clause.main();
    remove_unused_catch_stack.main();
    remove_unused_import.main();
    rename_to_camel_case.main();
    replace_boolean_with_bool.main();
    replace_final_with_const.main();
    replace_return_type_future.main();
    replace_var_with_dynamic.main();
    replace_with_brackets.main();
    replace_with_conditional_assignment.main();
    replace_with_literal.main();
    replace_with_identifier.main();
    replace_with_null_aware.main();
    replace_with_tear_off.main();
    update_sdk_constraints.main();
    use_const.main();
    use_effective_integer_division.main();
    use_eq_eq_null.main();
    use_is_not_empty.main();
    use_not_eq_null.main();
  }, name: 'fix');
}
