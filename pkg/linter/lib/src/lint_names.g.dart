// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/generate_lints.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

// An enumeration of the names of the analyzer's built-in lint rules.
abstract final class LintNames {
  static const String always_declare_return_types =
      'always_declare_return_types';

  static const String always_put_control_body_on_new_line =
      'always_put_control_body_on_new_line';

  static const String always_put_required_named_parameters_first =
      'always_put_required_named_parameters_first';

  static const String always_require_non_null_named_parameters =
      'always_require_non_null_named_parameters';

  static const String always_specify_types = 'always_specify_types';

  static const String always_use_package_imports = 'always_use_package_imports';

  static const String annotate_overrides = 'annotate_overrides';

  static const String annotate_redeclares = 'annotate_redeclares';

  static const String avoid_annotating_with_dynamic =
      'avoid_annotating_with_dynamic';

  static const String avoid_as = 'avoid_as';

  static const String avoid_bool_literals_in_conditional_expressions =
      'avoid_bool_literals_in_conditional_expressions';

  static const String avoid_catches_without_on_clauses =
      'avoid_catches_without_on_clauses';

  static const String avoid_catching_errors = 'avoid_catching_errors';

  static const String avoid_classes_with_only_static_members =
      'avoid_classes_with_only_static_members';

  static const String avoid_double_and_int_checks =
      'avoid_double_and_int_checks';

  static const String avoid_dynamic_calls = 'avoid_dynamic_calls';

  static const String avoid_empty_else = 'avoid_empty_else';

  static const String avoid_equals_and_hash_code_on_mutable_classes =
      'avoid_equals_and_hash_code_on_mutable_classes';

  static const String avoid_escaping_inner_quotes =
      'avoid_escaping_inner_quotes';

  static const String avoid_field_initializers_in_const_classes =
      'avoid_field_initializers_in_const_classes';

  static const String avoid_final_parameters = 'avoid_final_parameters';

  static const String avoid_function_literals_in_foreach_calls =
      'avoid_function_literals_in_foreach_calls';

  static const String avoid_futureor_void = 'avoid_futureor_void';

  static const String avoid_implementing_value_types =
      'avoid_implementing_value_types';

  static const String avoid_init_to_null = 'avoid_init_to_null';

  static const String avoid_js_rounded_ints = 'avoid_js_rounded_ints';

  static const String avoid_multiple_declarations_per_line =
      'avoid_multiple_declarations_per_line';

  static const String avoid_null_checks_in_equality_operators =
      'avoid_null_checks_in_equality_operators';

  static const String avoid_positional_boolean_parameters =
      'avoid_positional_boolean_parameters';

  static const String avoid_print = 'avoid_print';

  static const String avoid_private_typedef_functions =
      'avoid_private_typedef_functions';

  static const String avoid_redundant_argument_values =
      'avoid_redundant_argument_values';

  static const String avoid_relative_lib_imports = 'avoid_relative_lib_imports';

  static const String avoid_renaming_method_parameters =
      'avoid_renaming_method_parameters';

  static const String avoid_return_types_on_setters =
      'avoid_return_types_on_setters';

  static const String avoid_returning_null = 'avoid_returning_null';

  static const String avoid_returning_null_for_future =
      'avoid_returning_null_for_future';

  static const String avoid_returning_null_for_void =
      'avoid_returning_null_for_void';

  static const String avoid_returning_this = 'avoid_returning_this';

  static const String avoid_setters_without_getters =
      'avoid_setters_without_getters';

  static const String avoid_shadowing_type_parameters =
      'avoid_shadowing_type_parameters';

  static const String avoid_single_cascade_in_expression_statements =
      'avoid_single_cascade_in_expression_statements';

  static const String avoid_slow_async_io = 'avoid_slow_async_io';

  static const String avoid_type_to_string = 'avoid_type_to_string';

  static const String avoid_types_as_parameter_names =
      'avoid_types_as_parameter_names';

  static const String avoid_types_on_closure_parameters =
      'avoid_types_on_closure_parameters';

  static const String avoid_unnecessary_containers =
      'avoid_unnecessary_containers';

  static const String avoid_unstable_final_fields =
      'avoid_unstable_final_fields';

  static const String avoid_unused_constructor_parameters =
      'avoid_unused_constructor_parameters';

  static const String avoid_void_async = 'avoid_void_async';

  static const String avoid_web_libraries_in_flutter =
      'avoid_web_libraries_in_flutter';

  static const String await_only_futures = 'await_only_futures';

  static const String camel_case_extensions = 'camel_case_extensions';

  static const String camel_case_types = 'camel_case_types';

  static const String cancel_subscriptions = 'cancel_subscriptions';

  static const String cascade_invocations = 'cascade_invocations';

  static const String cast_nullable_to_non_nullable =
      'cast_nullable_to_non_nullable';

  static const String close_sinks = 'close_sinks';

  static const String collection_methods_unrelated_type =
      'collection_methods_unrelated_type';

  static const String combinators_ordering = 'combinators_ordering';

  static const String comment_references = 'comment_references';

  static const String conditional_uri_does_not_exist =
      'conditional_uri_does_not_exist';

  static const String constant_identifier_names = 'constant_identifier_names';

  static const String control_flow_in_finally = 'control_flow_in_finally';

  static const String curly_braces_in_flow_control_structures =
      'curly_braces_in_flow_control_structures';

  static const String dangling_library_doc_comments =
      'dangling_library_doc_comments';

  static const String depend_on_referenced_packages =
      'depend_on_referenced_packages';

  static const String deprecated_consistency = 'deprecated_consistency';

  static const String deprecated_member_use_from_same_package =
      'deprecated_member_use_from_same_package';

  static const String diagnostic_describe_all_properties =
      'diagnostic_describe_all_properties';

  static const String directives_ordering = 'directives_ordering';

  static const String discarded_futures = 'discarded_futures';

  static const String do_not_use_environment = 'do_not_use_environment';

  static const String document_ignores = 'document_ignores';

  static const String empty_catches = 'empty_catches';

  static const String empty_constructor_bodies = 'empty_constructor_bodies';

  static const String empty_statements = 'empty_statements';

  static const String enable_null_safety = 'enable_null_safety';

  static const String eol_at_end_of_file = 'eol_at_end_of_file';

  static const String erase_dart_type_extension_types =
      'erase_dart_type_extension_types';

  static const String exhaustive_cases = 'exhaustive_cases';

  static const String file_names = 'file_names';

  static const String flutter_style_todos = 'flutter_style_todos';

  static const String hash_and_equals = 'hash_and_equals';

  static const String implementation_imports = 'implementation_imports';

  static const String implicit_call_tearoffs = 'implicit_call_tearoffs';

  static const String implicit_reopen = 'implicit_reopen';

  static const String invalid_case_patterns = 'invalid_case_patterns';

  static const String invalid_runtime_check_with_js_interop_types =
      'invalid_runtime_check_with_js_interop_types';

  static const String invariant_booleans = 'invariant_booleans';

  static const String iterable_contains_unrelated_type =
      'iterable_contains_unrelated_type';

  static const String join_return_with_assignment =
      'join_return_with_assignment';

  static const String leading_newlines_in_multiline_strings =
      'leading_newlines_in_multiline_strings';

  static const String library_annotations = 'library_annotations';

  static const String library_names = 'library_names';

  static const String library_prefixes = 'library_prefixes';

  static const String library_private_types_in_public_api =
      'library_private_types_in_public_api';

  static const String lines_longer_than_80_chars = 'lines_longer_than_80_chars';

  static const String list_remove_unrelated_type = 'list_remove_unrelated_type';

  static const String literal_only_boolean_expressions =
      'literal_only_boolean_expressions';

  static const String matching_super_parameters = 'matching_super_parameters';

  static const String missing_code_block_language_in_doc_comment =
      'missing_code_block_language_in_doc_comment';

  static const String missing_whitespace_between_adjacent_strings =
      'missing_whitespace_between_adjacent_strings';

  static const String no_adjacent_strings_in_list =
      'no_adjacent_strings_in_list';

  static const String no_default_cases = 'no_default_cases';

  static const String no_duplicate_case_values = 'no_duplicate_case_values';

  static const String no_leading_underscores_for_library_prefixes =
      'no_leading_underscores_for_library_prefixes';

  static const String no_leading_underscores_for_local_identifiers =
      'no_leading_underscores_for_local_identifiers';

  static const String no_literal_bool_comparisons =
      'no_literal_bool_comparisons';

  static const String no_logic_in_create_state = 'no_logic_in_create_state';

  static const String no_runtimeType_toString = 'no_runtimeType_toString';

  static const String no_self_assignments = 'no_self_assignments';

  static const String no_wildcard_variable_uses = 'no_wildcard_variable_uses';

  static const String non_constant_identifier_names =
      'non_constant_identifier_names';

  static const String noop_primitive_operations = 'noop_primitive_operations';

  static const String null_check_on_nullable_type_parameter =
      'null_check_on_nullable_type_parameter';

  static const String null_closures = 'null_closures';

  static const String omit_local_variable_types = 'omit_local_variable_types';

  static const String omit_obvious_local_variable_types =
      'omit_obvious_local_variable_types';

  static const String omit_obvious_property_types =
      'omit_obvious_property_types';

  static const String one_member_abstracts = 'one_member_abstracts';

  static const String only_throw_errors = 'only_throw_errors';

  static const String overridden_fields = 'overridden_fields';

  static const String package_api_docs = 'package_api_docs';

  static const String package_names = 'package_names';

  static const String package_prefixed_library_names =
      'package_prefixed_library_names';

  static const String parameter_assignments = 'parameter_assignments';

  static const String prefer_adjacent_string_concatenation =
      'prefer_adjacent_string_concatenation';

  static const String prefer_asserts_in_initializer_lists =
      'prefer_asserts_in_initializer_lists';

  static const String prefer_asserts_with_message =
      'prefer_asserts_with_message';

  static const String prefer_bool_in_asserts = 'prefer_bool_in_asserts';

  static const String prefer_collection_literals = 'prefer_collection_literals';

  static const String prefer_conditional_assignment =
      'prefer_conditional_assignment';

  static const String prefer_const_constructors = 'prefer_const_constructors';

  static const String prefer_const_constructors_in_immutables =
      'prefer_const_constructors_in_immutables';

  static const String prefer_const_declarations = 'prefer_const_declarations';

  static const String prefer_const_literals_to_create_immutables =
      'prefer_const_literals_to_create_immutables';

  static const String prefer_constructors_over_static_methods =
      'prefer_constructors_over_static_methods';

  static const String prefer_contains = 'prefer_contains';

  static const String prefer_double_quotes = 'prefer_double_quotes';

  static const String prefer_equal_for_default_values =
      'prefer_equal_for_default_values';

  static const String prefer_expression_function_bodies =
      'prefer_expression_function_bodies';

  static const String prefer_final_fields = 'prefer_final_fields';

  static const String prefer_final_in_for_each = 'prefer_final_in_for_each';

  static const String prefer_final_locals = 'prefer_final_locals';

  static const String prefer_final_parameters = 'prefer_final_parameters';

  static const String prefer_for_elements_to_map_fromIterable =
      'prefer_for_elements_to_map_fromIterable';

  static const String prefer_foreach = 'prefer_foreach';

  static const String prefer_function_declarations_over_variables =
      'prefer_function_declarations_over_variables';

  static const String prefer_generic_function_type_aliases =
      'prefer_generic_function_type_aliases';

  static const String prefer_if_elements_to_conditional_expressions =
      'prefer_if_elements_to_conditional_expressions';

  static const String prefer_if_null_operators = 'prefer_if_null_operators';

  static const String prefer_initializing_formals =
      'prefer_initializing_formals';

  static const String prefer_inlined_adds = 'prefer_inlined_adds';

  static const String prefer_int_literals = 'prefer_int_literals';

  static const String prefer_interpolation_to_compose_strings =
      'prefer_interpolation_to_compose_strings';

  static const String prefer_is_empty = 'prefer_is_empty';

  static const String prefer_is_not_empty = 'prefer_is_not_empty';

  static const String prefer_is_not_operator = 'prefer_is_not_operator';

  static const String prefer_iterable_whereType = 'prefer_iterable_whereType';

  static const String prefer_mixin = 'prefer_mixin';

  static const String prefer_null_aware_method_calls =
      'prefer_null_aware_method_calls';

  static const String prefer_null_aware_operators =
      'prefer_null_aware_operators';

  static const String prefer_relative_imports = 'prefer_relative_imports';

  static const String prefer_single_quotes = 'prefer_single_quotes';

  static const String prefer_spread_collections = 'prefer_spread_collections';

  static const String prefer_typing_uninitialized_variables =
      'prefer_typing_uninitialized_variables';

  static const String prefer_void_to_null = 'prefer_void_to_null';

  static const String provide_deprecation_message =
      'provide_deprecation_message';

  static const String public_member_api_docs = 'public_member_api_docs';

  static const String recursive_getters = 'recursive_getters';

  static const String require_trailing_commas = 'require_trailing_commas';

  static const String secure_pubspec_urls = 'secure_pubspec_urls';

  static const String sized_box_for_whitespace = 'sized_box_for_whitespace';

  static const String sized_box_shrink_expand = 'sized_box_shrink_expand';

  static const String slash_for_doc_comments = 'slash_for_doc_comments';

  static const String sort_child_properties_last = 'sort_child_properties_last';

  static const String sort_constructors_first = 'sort_constructors_first';

  static const String sort_pub_dependencies = 'sort_pub_dependencies';

  static const String sort_unnamed_constructors_first =
      'sort_unnamed_constructors_first';

  static const String specify_nonobvious_local_variable_types =
      'specify_nonobvious_local_variable_types';

  static const String specify_nonobvious_property_types =
      'specify_nonobvious_property_types';

  static const String super_goes_last = 'super_goes_last';

  static const String test_types_in_equals = 'test_types_in_equals';

  static const String throw_in_finally = 'throw_in_finally';

  static const String tighten_type_of_initializing_formals =
      'tighten_type_of_initializing_formals';

  static const String type_annotate_public_apis = 'type_annotate_public_apis';

  static const String type_init_formals = 'type_init_formals';

  static const String type_literal_in_constant_pattern =
      'type_literal_in_constant_pattern';

  static const String unawaited_futures = 'unawaited_futures';

  static const String unintended_html_in_doc_comment =
      'unintended_html_in_doc_comment';

  static const String unnecessary_await_in_return =
      'unnecessary_await_in_return';

  static const String unnecessary_brace_in_string_interps =
      'unnecessary_brace_in_string_interps';

  static const String unnecessary_breaks = 'unnecessary_breaks';

  static const String unnecessary_const = 'unnecessary_const';

  static const String unnecessary_constructor_name =
      'unnecessary_constructor_name';

  static const String unnecessary_final = 'unnecessary_final';

  static const String unnecessary_getters_setters =
      'unnecessary_getters_setters';

  static const String unnecessary_lambdas = 'unnecessary_lambdas';

  static const String unnecessary_late = 'unnecessary_late';

  static const String unnecessary_library_directive =
      'unnecessary_library_directive';

  static const String unnecessary_library_name = 'unnecessary_library_name';

  static const String unnecessary_new = 'unnecessary_new';

  static const String unnecessary_null_aware_assignments =
      'unnecessary_null_aware_assignments';

  static const String unnecessary_null_aware_operator_on_extension_on_nullable =
      'unnecessary_null_aware_operator_on_extension_on_nullable';

  static const String unnecessary_null_checks = 'unnecessary_null_checks';

  static const String unnecessary_null_in_if_null_operators =
      'unnecessary_null_in_if_null_operators';

  static const String unnecessary_nullable_for_final_variable_declarations =
      'unnecessary_nullable_for_final_variable_declarations';

  static const String unnecessary_overrides = 'unnecessary_overrides';

  static const String unnecessary_parenthesis = 'unnecessary_parenthesis';

  static const String unnecessary_raw_strings = 'unnecessary_raw_strings';

  static const String unnecessary_statements = 'unnecessary_statements';

  static const String unnecessary_string_escapes = 'unnecessary_string_escapes';

  static const String unnecessary_string_interpolations =
      'unnecessary_string_interpolations';

  static const String unnecessary_this = 'unnecessary_this';

  static const String unnecessary_to_list_in_spreads =
      'unnecessary_to_list_in_spreads';

  static const String unreachable_from_main = 'unreachable_from_main';

  static const String unrelated_type_equality_checks =
      'unrelated_type_equality_checks';

  static const String unsafe_html = 'unsafe_html';

  static const String unsafe_variance = 'unsafe_variance';

  static const String use_build_context_synchronously =
      'use_build_context_synchronously';

  static const String use_colored_box = 'use_colored_box';

  static const String use_decorated_box = 'use_decorated_box';

  static const String use_enums = 'use_enums';

  static const String use_full_hex_values_for_flutter_colors =
      'use_full_hex_values_for_flutter_colors';

  static const String use_function_type_syntax_for_parameters =
      'use_function_type_syntax_for_parameters';

  static const String use_if_null_to_convert_nulls_to_bools =
      'use_if_null_to_convert_nulls_to_bools';

  static const String use_is_even_rather_than_modulo =
      'use_is_even_rather_than_modulo';

  static const String use_key_in_widget_constructors =
      'use_key_in_widget_constructors';

  static const String use_late_for_private_fields_and_variables =
      'use_late_for_private_fields_and_variables';

  static const String use_named_constants = 'use_named_constants';

  static const String use_raw_strings = 'use_raw_strings';

  static const String use_rethrow_when_possible = 'use_rethrow_when_possible';

  static const String use_setters_to_change_properties =
      'use_setters_to_change_properties';

  static const String use_string_buffers = 'use_string_buffers';

  static const String use_string_in_part_of_directives =
      'use_string_in_part_of_directives';

  static const String use_super_parameters = 'use_super_parameters';

  static const String use_test_throws_matchers = 'use_test_throws_matchers';

  static const String use_to_and_as_if_applicable =
      'use_to_and_as_if_applicable';

  static const String use_truncating_division = 'use_truncating_division';

  static const String valid_regexps = 'valid_regexps';

  static const String void_checks = 'void_checks';
}
