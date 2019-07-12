// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ambiguous_import_test.dart' as ambiguous_import;
import 'ambiguous_set_or_map_literal_test.dart' as ambiguous_set_or_map_literal;
import 'argument_type_not_assignable_test.dart' as argument_type_not_assignable;
import 'assignment_to_const_test.dart' as assignment_to_const;
import 'assignment_to_final_local_test.dart' as assignment_to_final_local;
import 'assignment_to_final_no_setter_test.dart'
    as assignment_to_final_no_setter;
import 'assignment_to_final_test.dart' as assignment_to_final;
import 'assignment_to_function_test.dart' as assignment_to_function;
import 'assignment_to_method_test.dart' as assignment_to_method;
import 'assignment_to_type_test.dart' as assignment_to_type;
import 'async_keyword_used_as_identifier_test.dart'
    as async_keyword_used_as_identifier;
import 'can_be_null_after_null_aware_test.dart' as can_be_null_after_null_aware;
import 'case_block_not_terminated_test.dart' as case_block_not_terminated;
import 'cast_to_non_type_test.dart' as cast_to_non_type;
import 'concrete_class_with_abstract_member_test.dart'
    as concrete_class_with_abstract_member;
import 'const_constructor_param_type_mismatch_test.dart'
    as const_constructor_param_type_mismatch;
import 'const_constructor_with_mixin_with_field_test.dart'
    as const_constructor_with_mixin_with_field;
import 'const_eval_throws_exception_test.dart' as const_eval_throws_exception;
import 'const_map_key_expression_type_implements_equals_test.dart'
    as const_map_key_expression_type_implements_equals;
import 'const_set_element_type_implements_equals_test.dart'
    as const_set_element_type_implements_equals;
import 'const_spread_expected_list_or_set_test.dart'
    as const_spread_expected_list_or_set;
import 'const_spread_expected_map_test.dart' as const_spread_expected_map;
import 'const_with_abstract_class_test.dart' as const_with_abstract_class;
import 'dead_code_test.dart' as dead_code;
import 'default_list_constructor_mismatch_test.dart'
    as default_list_constructor_mismatch;
import 'default_value_on_required_parameter_test.dart'
    as default_value_on_required_paramter;
import 'deprecated_extends_function_test.dart' as deprecated_extends_function;
import 'deprecated_function_class_declaration_test.dart'
    as deprecated_function_class_declaration;
import 'deprecated_member_use_test.dart' as deprecated_member_use;
import 'deprecated_mixin_function_test.dart' as deprecated_mixin_function;
import 'division_optimization_test.dart' as division_optimization;
import 'down_cast_composite_test.dart' as down_cast_composite;
import 'duplicate_hidden_name_test.dart' as duplicate_hidden_name;
import 'duplicate_import_test.dart' as duplicate_import;
import 'duplicate_shown_name_test.dart' as duplicate_shown_name;
import 'equal_elements_in_const_set_test.dart' as equal_elements_in_const_set;
import 'equal_keys_in_const_map_test.dart' as equal_keys_in_const_map;
import 'expression_in_map_test.dart' as expression_in_map;
import 'extends_non_class_test.dart' as extends_non_class;
import 'extension_declares_abstract_method_test.dart'
    as extension_declares_abstract_method;
import 'extension_declares_constructor_test.dart'
    as extension_declares_constructor;
import 'extension_declares_field_test.dart' as extension_declares_field;
import 'final_not_initialized_test.dart' as final_not_initialized;
import 'implements_non_class_test.dart' as implements_non_class;
import 'implicit_this_reference_in_initializer_test.dart'
    as implicit_this_reference_in_initializer;
import 'import_deferred_library_with_load_function_test.dart'
    as import_deferred_library_with_load_function;
import 'invalid_assignment_test.dart' as invalid_assignment;
import 'invalid_cast_new_expr_test.dart' as invalid_cast_new_expr;
import 'invalid_factory_annotation_test.dart' as invalid_factory_annotation;
import 'invalid_factory_method_impl_test.dart' as invalid_factory_method_impl;
import 'invalid_immutable_annotation_test.dart' as invalid_immutable_annotation;
import 'invalid_literal_annotation_test.dart' as invalid_literal_annotation;
import 'invalid_optional_parameter_type_test.dart'
    as invalid_optional_parameter_type;
import 'invalid_override_different_default_values_named_test.dart'
    as invalid_override_different_default_values_named;
import 'invalid_override_different_default_values_positional_test.dart'
    as invalid_override_different_default_values_positional;
import 'invalid_required_param_test.dart' as invalid_required_param;
import 'invalid_sealed_annotation_test.dart' as invalid_sealed_annotation;
import 'invalid_use_of_null_value_test.dart' as invalid_use_of_null_value;
import 'invalid_use_of_protected_member_test.dart'
    as invalid_use_of_protected_member;
import 'invalid_use_of_visible_for_template_member_test.dart'
    as invalid_use_of_visible_for_template_member;
import 'invalid_use_of_visible_for_testing_member_test.dart'
    as invalid_use_of_visible_for_testing_member;
import 'invalid_visibility_annotation_test.dart'
    as invalid_visibility_annotation;
import 'is_double_test.dart' as is_double;
import 'is_int_test.dart' as is_int;
import 'is_not_double_test.dart' as is_not_double;
import 'is_not_int_test.dart' as is_not_int;
import 'list_element_type_not_assignable_test.dart'
    as list_element_type_not_assignable;
import 'map_entry_not_in_map_test.dart' as map_entry_not_in_map;
import 'map_key_type_not_assignable_test.dart' as map_key_type_not_assignable;
import 'map_value_type_not_assignable_test.dart'
    as map_value_type_not_assignable;
import 'missing_default_value_for_parameter_test.dart'
    as missing_default_value_for_paramter;
import 'missing_js_lib_annotation_test.dart' as missing_js_lib_annotation;
import 'missing_required_param_test.dart' as missing_required_param;
import 'missing_return_test.dart' as missing_return;
import 'mixin_of_non_class_test.dart' as mixin_of_non_class;
import 'mixin_on_sealed_class_test.dart' as mixin_on_sealed_class;
import 'mixin_super_class_constraint_non_interface_test.dart'
    as mixin_super_class_constraint_non_interface;
import 'must_be_immutable_test.dart' as must_be_immutable;
import 'must_call_super_test.dart' as must_call_super;
import 'non_bool_condition_test.dart' as non_bool_condition;
import 'non_bool_negation_expression_test.dart' as non_bool_negation_expression;
import 'non_bool_operand_test.dart' as non_bool_operand;
import 'non_constant_if_element_condition_from_deferred_library_test.dart'
    as non_constant_if_element_condition_from_deferred_library;
import 'non_constant_list_element_from_deferred_library_test.dart'
    as non_constant_list_element_from_deferred_library;
import 'non_constant_list_element_test.dart' as non_constant_list_element;
import 'non_constant_map_element_test.dart' as non_constant_map_element;
import 'non_constant_map_key_from_deferred_library_test.dart'
    as non_constant_map_key_from_deferred_library;
import 'non_constant_map_key_test.dart' as non_constant_map_key;
import 'non_constant_map_value_from_deferred_library_test.dart'
    as non_constant_map_value_from_deferred_library;
import 'non_constant_map_value_test.dart' as non_constant_map_value;
import 'non_constant_set_element_from_deferred_library_test.dart'
    as non_constant_set_element_from_deferred_library;
import 'non_constant_set_element_test.dart' as non_constant_set_element;
import 'non_constant_spread_expression_from_deferred_library_test.dart'
    as non_constant_spread_expression_from_deferred_library;
import 'non_null_opt_out_test.dart' as non_null_opt_out;
import 'not_assigned_potentially_non_nullable_local_variable_test.dart'
    as not_assigned_potentially_non_nullable_local_variable;
import 'not_initialized_non_nullable_static_field_test.dart'
    as not_initialized_non_nullable_static_field;
import 'not_initialized_non_nullable_top_level_variable_test.dart'
    as not_initialized_non_nullable_top_level_variable;
import 'not_iterable_spread_test.dart' as not_iterable_spread;
import 'not_map_spread_test.dart' as not_map_spread;
import 'not_null_aware_null_spread_test.dart' as not_null_aware_null_spread;
import 'null_aware_before_operator_test.dart' as null_aware_before_operator;
import 'null_aware_in_condition_test.dart' as null_aware_in_condition;
import 'null_aware_in_logical_operator_test.dart'
    as null_aware_in_logical_operator;
import 'nullable_type_in_catch_clause_test.dart'
    as nullable_type_in_catch_clause;
import 'nullable_type_in_extends_clause_test.dart'
    as nullable_type_in_extends_clause;
import 'nullable_type_in_implements_clause_test.dart'
    as nullable_type_in_implements_clause;
import 'nullable_type_in_on_clause_test.dart' as nullable_type_in_on_clause;
import 'nullable_type_in_with_clause_test.dart' as nullable_type_in_with_clause;
import 'override_equals_but_not_hashcode_test.dart'
    as override_equals_but_not_hashcode;
import 'override_on_non_overriding_field_test.dart'
    as override_on_non_overriding_field;
import 'override_on_non_overriding_getter_test.dart'
    as override_on_non_overriding_getter;
import 'override_on_non_overriding_method_test.dart'
    as override_on_non_overriding_method;
import 'override_on_non_overriding_setter_test.dart'
    as override_on_non_overriding_setter;
import 'sdk_version_as_expression_in_const_context_test.dart'
    as sdk_version_as_expression_in_const_context;
import 'sdk_version_async_exported_from_core_test.dart'
    as sdk_version_async_exported_from_core;
import 'sdk_version_bool_operator_test.dart' as sdk_version_bool_operator;
import 'sdk_version_eq_eq_operator_test.dart' as sdk_version_eq_eq_operator;
import 'sdk_version_gt_gt_gt_operator_test.dart'
    as sdk_version_gt_gt_gt_operator;
import 'sdk_version_is_expression_in_const_context_test.dart'
    as sdk_version_is_expression_in_const_context;
import 'sdk_version_never_test.dart' as sdk_version_never;
import 'sdk_version_set_literal_test.dart' as sdk_version_set_literal;
import 'sdk_version_ui_as_code_test.dart' as sdk_version_ui_as_code;
import 'set_element_type_not_assignable_test.dart'
    as set_element_type_not_assignable;
import 'subtype_of_sealed_class_test.dart' as subtype_of_sealed_class;
import 'top_level_instance_getter_test.dart' as top_level_instance_getter;
import 'top_level_instance_method_test.dart' as top_level_instance_method;
import 'type_check_is_not_null_test.dart' as type_check_is_not_null;
import 'type_check_is_null_test.dart' as type_check_is_null;
import 'unchecked_use_of_nullable_value_test.dart'
    as unchecked_use_of_nullable_value;
import 'undefined_getter_test.dart' as undefined_getter;
import 'undefined_hidden_name_test.dart' as undefined_hidden_name;
import 'undefined_identifier_test.dart' as undefined_identifier;
import 'undefined_operator_test.dart' as undefined_operator;
import 'undefined_prefixed_name_test.dart' as undefined_prefixed_name;
import 'undefined_setter_test.dart' as undefined_setter;
import 'undefined_shown_name_test.dart' as undefined_shown_name;
import 'unnecessary_cast_test.dart' as unnecessary_cast;
import 'unnecessary_no_such_method_test.dart' as unnecessary_no_such_method;
import 'unnecessary_null_aware_call_test.dart' as unnecessary_null_aware_call;
import 'unnecessary_null_aware_spread_test.dart'
    as unnecessary_null_aware_spread;
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
import 'variable_type_mismatch_test.dart' as variable_type_mismatch;
import 'wrong_type_parameter_variance_in_superinterface_test.dart'
    as wrong_type_parameter_variance_in_superinterface;

main() {
  defineReflectiveSuite(() {
    ambiguous_import.main();
    ambiguous_set_or_map_literal.main();
    argument_type_not_assignable.main();

    assignment_to_const.main();
    assignment_to_final_local.main();
    assignment_to_final_no_setter.main();
    assignment_to_final.main();
    assignment_to_function.main();
    assignment_to_method.main();
    assignment_to_type.main();
    async_keyword_used_as_identifier.main();
    can_be_null_after_null_aware.main();
    case_block_not_terminated.main();
    cast_to_non_type.main();
    concrete_class_with_abstract_member.main();
    const_constructor_param_type_mismatch.main();
    const_constructor_with_mixin_with_field.main();
    const_eval_throws_exception.main();
    const_map_key_expression_type_implements_equals.main();
    const_set_element_type_implements_equals.main();
    const_spread_expected_list_or_set.main();
    const_spread_expected_map.main();
    const_with_abstract_class.main();
    dead_code.main();
    default_list_constructor_mismatch.main();
    default_value_on_required_paramter.main();
    deprecated_extends_function.main();
    deprecated_function_class_declaration.main();
    deprecated_member_use.main();
    deprecated_mixin_function.main();
    division_optimization.main();
    down_cast_composite.main();
    duplicate_hidden_name.main();
    duplicate_import.main();
    duplicate_shown_name.main();
    equal_elements_in_const_set.main();
    equal_keys_in_const_map.main();
    expression_in_map.main();
    extends_non_class.main();
    extension_declares_abstract_method.main();
    extension_declares_constructor.main();
    extension_declares_field.main();
    final_not_initialized.main();
    implements_non_class.main();
    implicit_this_reference_in_initializer.main();
    import_deferred_library_with_load_function.main();
    invalid_assignment.main();
    invalid_cast_new_expr.main();
    invalid_factory_annotation.main();
    invalid_factory_method_impl.main();
    invalid_immutable_annotation.main();
    invalid_literal_annotation.main();
    invalid_optional_parameter_type.main();
    invalid_override_different_default_values_named.main();
    invalid_override_different_default_values_positional.main();
    invalid_required_param.main();
    invalid_sealed_annotation.main();
    invalid_use_of_null_value.main();
    invalid_use_of_protected_member.main();
    invalid_use_of_visible_for_template_member.main();
    invalid_use_of_visible_for_testing_member.main();
    invalid_visibility_annotation.main();
    is_double.main();
    is_int.main();
    is_not_double.main();
    is_not_int.main();
    list_element_type_not_assignable.main();
    map_entry_not_in_map.main();
    map_key_type_not_assignable.main();
    map_value_type_not_assignable.main();
    missing_default_value_for_paramter.main();
    missing_js_lib_annotation.main();
    missing_required_param.main();
    missing_return.main();
    mixin_of_non_class.main();
    mixin_on_sealed_class.main();
    mixin_super_class_constraint_non_interface.main();
    must_be_immutable.main();
    must_call_super.main();
    non_bool_condition.main();
    non_bool_negation_expression.main();
    non_bool_operand.main();
    non_constant_if_element_condition_from_deferred_library.main();
    non_constant_list_element.main();
    non_constant_list_element_from_deferred_library.main();
    non_constant_map_key.main();
    non_constant_map_key_from_deferred_library.main();
    non_constant_map_element.main();
    non_constant_map_value.main();
    non_constant_map_value_from_deferred_library.main();
    non_constant_set_element.main();
    non_constant_set_element_from_deferred_library.main();
    non_constant_spread_expression_from_deferred_library.main();
    non_null_opt_out.main();
    not_assigned_potentially_non_nullable_local_variable.main();
    not_initialized_non_nullable_static_field.main();
    not_initialized_non_nullable_top_level_variable.main();
    not_iterable_spread.main();
    not_map_spread.main();
    not_null_aware_null_spread.main();
    null_aware_before_operator.main();
    null_aware_in_condition.main();
    null_aware_in_logical_operator.main();
    nullable_type_in_catch_clause.main();
    nullable_type_in_extends_clause.main();
    nullable_type_in_implements_clause.main();
    nullable_type_in_on_clause.main();
    nullable_type_in_with_clause.main();
    override_equals_but_not_hashcode.main();
    override_on_non_overriding_field.main();
    override_on_non_overriding_getter.main();
    override_on_non_overriding_method.main();
    override_on_non_overriding_setter.main();
    sdk_version_as_expression_in_const_context.main();
    sdk_version_async_exported_from_core.main();
    sdk_version_bool_operator.main();
    sdk_version_eq_eq_operator.main();
    sdk_version_gt_gt_gt_operator.main();
    sdk_version_is_expression_in_const_context.main();
    sdk_version_never.main();
    sdk_version_set_literal.main();
    sdk_version_ui_as_code.main();
    set_element_type_not_assignable.main();
    subtype_of_sealed_class.main();
    top_level_instance_getter.main();
    top_level_instance_method.main();
    type_check_is_not_null.main();
    type_check_is_null.main();
    unchecked_use_of_nullable_value.main();
    undefined_getter.main();
    undefined_identifier.main();
    undefined_hidden_name.main();
    undefined_operator.main();
    undefined_prefixed_name.main();
    undefined_setter.main();
    undefined_shown_name.main();
    unnecessary_cast.main();
    unnecessary_no_such_method.main();
    unnecessary_null_aware_call.main();
    unnecessary_null_aware_spread.main();
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
    variable_type_mismatch.main();
    wrong_type_parameter_variance_in_superinterface.main();
  }, name: 'diagnostics');
}
