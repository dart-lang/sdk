// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An enumeration of lint names.
class LintNames {
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
  static const String avoid_empty_else = 'avoid_empty_else';
  static const String avoid_escaping_inner_quotes =
      'avoid_escaping_inner_quotes';
  static const String avoid_function_literals_in_foreach_calls =
      'avoid_function_literals_in_foreach_calls';
  static const String avoid_init_to_null = 'avoid_init_to_null';
  static const String avoid_multiple_declarations_per_line =
      'avoid_multiple_declarations_per_line';
  static const String avoid_null_checks_in_equality_operators =
      'avoid_null_checks_in_equality_operators';
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
  static const String avoid_returning_null_for_future =
      'avoid_returning_null_for_future';
  static const String avoid_returning_null_for_void =
      'avoid_returning_null_for_void';
  static const String avoid_single_cascade_in_expression_statements =
      'avoid_single_cascade_in_expression_statements';
  static const String avoid_types_as_parameter_names =
      'avoid_types_as_parameter_names';
  static const String avoid_types_on_closure_parameters =
      'avoid_types_on_closure_parameters';
  static const String avoid_unused_constructor_parameters =
      'avoid_unused_constructor_parameters';
  static const String avoid_unnecessary_containers =
      'avoid_unnecessary_containers';
  static const String avoid_void_async = 'avoid_void_async';
  static const String await_only_futures = 'await_only_futures';
  static const String cascade_invocations = 'cascade_invocations';
  static const String cast_nullable_to_non_nullable =
      'cast_nullable_to_non_nullable';
  static const String combinators_ordering = 'combinators_ordering';
  static const String comment_references = 'comment_references';
  static const String constant_identifier_names = 'constant_identifier_names';
  static const String curly_braces_in_flow_control_structures =
      'curly_braces_in_flow_control_structures';
  static const String dangling_library_doc_comments =
      'dangling_library_doc_comments';
  static const String deprecated_member_use_from_same_package =
      'deprecated_member_use_from_same_package';
  static const String deprecated_member_use_from_same_package_with_message =
      'deprecated_member_use_from_same_package_with_message';
  static const String diagnostic_describe_all_properties =
      'diagnostic_describe_all_properties';
  static const String directives_ordering = 'directives_ordering';
  static const String discarded_futures = 'discarded_futures';
  static const String empty_catches = 'empty_catches';
  static const String empty_constructor_bodies = 'empty_constructor_bodies';
  static const String empty_statements = 'empty_statements';
  static const String eol_at_end_of_file = 'eol_at_end_of_file';
  static const String exhaustive_cases = 'exhaustive_cases';
  static const String hash_and_equals = 'hash_and_equals';
  static const String implicit_call_tearoffs = 'implicit_call_tearoffs';
  static const String implicit_reopen = 'implicit_reopen';
  static const String invalid_case_patterns = 'invalid_case_patterns';
  static const String leading_newlines_in_multiline_strings =
      'leading_newlines_in_multiline_strings';
  static const String library_annotations = 'library_annotations';
  static const String no_literal_bool_comparisons =
      'no_literal_bool_comparisons';
  static const String no_duplicate_case_values = 'no_duplicate_case_values';
  static const String no_leading_underscores_for_library_prefixes =
      'no_leading_underscores_for_library_prefixes';
  static const String no_leading_underscores_for_local_identifiers =
      'no_leading_underscores_for_local_identifiers';
  static const String non_constant_identifier_names =
      'non_constant_identifier_names';
  static const String noop_primitive_operations = 'noop_primitive_operations';
  static const String null_check_on_nullable_type_parameter =
      'null_check_on_nullable_type_parameter';
  static const String null_closures = 'null_closures';
  static const String omit_local_variable_types = 'omit_local_variable_types';
  static const String prefer_adjacent_string_concatenation =
      'prefer_adjacent_string_concatenation';
  static const String prefer_collection_literals = 'prefer_collection_literals';
  static const String prefer_conditional_assignment =
      'prefer_conditional_assignment';
  static const String prefer_const_constructors = 'prefer_const_constructors';
  static const String prefer_const_constructors_in_immutables =
      'prefer_const_constructors_in_immutables';
  static const String prefer_const_declarations = 'prefer_const_declarations';
  static const String prefer_const_literals_to_create_immutables =
      'prefer_const_literals_to_create_immutables';
  static const String prefer_contains = 'prefer_contains';
  static const String prefer_double_quotes = 'prefer_double_quotes';
  static const String prefer_expression_function_bodies =
      'prefer_expression_function_bodies';
  static const String prefer_final_fields = 'prefer_final_fields';
  static const String prefer_final_in_for_each = 'prefer_final_in_for_each';
  static const String prefer_final_locals = 'prefer_final_locals';
  static const String prefer_final_parameters = 'prefer_final_parameters';
  static const String prefer_function_declarations_over_variables =
      'prefer_function_declarations_over_variables';
  static const String prefer_for_elements_to_map_fromIterable =
      'prefer_for_elements_to_map_fromIterable';
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
  static const String prefer_null_aware_operators =
      'prefer_null_aware_operators';
  static const String prefer_relative_imports = 'prefer_relative_imports';
  static const String prefer_single_quotes = 'prefer_single_quotes';
  static const String prefer_spread_collections = 'prefer_spread_collections';
  static const String prefer_typing_uninitialized_variables =
      'prefer_typing_uninitialized_variables';
  static const String prefer_void_to_null = 'prefer_void_to_null';
  static const String require_trailing_commas = 'require_trailing_commas';
  static const String sized_box_for_whitespace = 'sized_box_for_whitespace';
  static const String slash_for_doc_comments = 'slash_for_doc_comments';
  static const String sort_child_properties_last = 'sort_child_properties_last';
  static const String sort_constructors_first = 'sort_constructors_first';
  static const String sort_unnamed_constructors_first =
      'sort_unnamed_constructors_first';
  static const String type_annotate_public_apis = 'type_annotate_public_apis';
  static const String type_init_formals = 'type_init_formals';
  static const String type_literal_in_constant_pattern =
      'type_literal_in_constant_pattern';
  static const String unawaited_futures = 'unawaited_futures';
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
  static const String unnecessary_new = 'unnecessary_new';
  static const String unnecessary_null_aware_assignments =
      'unnecessary_null_aware_assignments';
  static const String unnecessary_null_checks = 'unnecessary_null_checks';
  static const String unnecessary_null_in_if_null_operators =
      'unnecessary_null_in_if_null_operators';
  static const String unnecessary_nullable_for_final_variable_declarations =
      'unnecessary_nullable_for_final_variable_declarations';
  static const String unnecessary_overrides = 'unnecessary_overrides';
  static const String unnecessary_parenthesis = 'unnecessary_parenthesis';
  static const String unnecessary_raw_strings = 'unnecessary_raw_strings';
  static const String unnecessary_string_escapes = 'unnecessary_string_escapes';
  static const String unnecessary_string_interpolations =
      'unnecessary_string_interpolations';
  static const String unnecessary_to_list_in_spreads =
      'unnecessary_to_list_in_spreads';
  static const String unnecessary_this = 'unnecessary_this';
  static const String unreachable_from_main = 'unreachable_from_main';
  static const String use_decorated_box = 'use_decorated_box';
  static const String use_enums = 'use_enums';
  static const String use_full_hex_values_for_flutter_colors =
      'use_full_hex_values_for_flutter_colors';
  static const String use_function_type_syntax_for_parameters =
      'use_function_type_syntax_for_parameters';
  static const String use_key_in_widget_constructors =
      'use_key_in_widget_constructors';
  static const String use_raw_strings = 'use_raw_strings';
  static const String use_rethrow_when_possible = 'use_rethrow_when_possible';
  static const String use_string_in_part_of_directives =
      'use_string_in_part_of_directives';
  static const String use_super_parameters = 'use_super_parameters';
}
