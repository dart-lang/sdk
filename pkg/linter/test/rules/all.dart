// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_prefixes

import 'always_declare_return_types_test.dart' as always_declare_return_types;
import 'always_put_control_body_on_new_line_test.dart'
    as always_put_control_body_on_new_line;
import 'always_put_required_named_parameters_first_test.dart'
    as always_put_required_named_parameters_first;
import 'always_specify_types_test.dart' as always_specify_types;
import 'always_use_package_imports_test.dart' as always_use_package_imports;
import 'analyzer_use_new_elements_test.dart' as analyzer_use_new_elements;
import 'annotate_overrides_test.dart' as annotate_overrides;
import 'annotate_redeclares_test.dart' as annotate_redeclares;
import 'avoid_annotating_with_dynamic_test.dart'
    as avoid_annotating_with_dynamic;
import 'avoid_bool_literals_in_conditional_expressions_test.dart'
    as avoid_bool_literals_in_conditional_expressions;
import 'avoid_catches_without_on_clauses_test.dart'
    as avoid_catches_without_on_clauses;
import 'avoid_catching_errors_test.dart' as avoid_catching_errors;
import 'avoid_classes_with_only_static_members_test.dart'
    as avoid_classes_with_only_static_members;
import 'avoid_double_and_int_checks_test.dart' as avoid_double_and_int_checks;
import 'avoid_dynamic_calls_test.dart' as avoid_dynamic_calls;
import 'avoid_empty_else_test.dart' as avoid_empty_else;
import 'avoid_equals_and_hash_code_on_mutable_classes_test.dart'
    as avoid_equals_and_hash_code_on_mutable_classes;
import 'avoid_escaping_inner_quotes_test.dart' as avoid_escaping_inner_quotes;
import 'avoid_field_initializers_in_const_classes_test.dart'
    as avoid_field_initializers_in_const_classes;
import 'avoid_field_initializers_in_non_const_classes_test.dart'
    as avoid_field_initializers_in_non_const_classes;
import 'avoid_final_parameters_test.dart' as avoid_final_parameters;
import 'avoid_function_literals_in_foreach_calls_test.dart'
    as avoid_function_literals_in_foreach_calls;
import 'avoid_futureor_void_test.dart' as avoid_futureor_void;
import 'avoid_implementing_value_types_test.dart'
    as avoid_implementing_value_types;
import 'avoid_init_to_null_test.dart' as avoid_init_to_null;
import 'avoid_js_rounded_ints_test.dart' as avoid_js_rounded_ints;
import 'avoid_multiple_declarations_per_line_test.dart'
    as avoid_multiple_declarations_per_line;
import 'avoid_null_checks_in_equality_operators_test.dart'
    as avoid_null_checks_in_equality_operators;
import 'avoid_positional_boolean_parameters_test.dart'
    as avoid_positional_boolean_parameters;
import 'avoid_print_test.dart' as avoid_print;
import 'avoid_private_typedef_functions_test.dart'
    as avoid_private_typedef_functions;
import 'avoid_redundant_argument_values_test.dart'
    as avoid_redundant_argument_values;
import 'avoid_relative_lib_imports_test.dart' as avoid_relative_lib_imports;
import 'avoid_renaming_method_parameters_test.dart'
    as avoid_renaming_method_parameters;
import 'avoid_return_types_on_setters_test.dart'
    as avoid_return_types_on_setters;
import 'avoid_returning_null_for_void_test.dart'
    as avoid_returning_null_for_void;
import 'avoid_returning_null_test.dart' as avoid_returning_null;
import 'avoid_returning_this_test.dart' as avoid_returning_this;
import 'avoid_setters_without_getters_test.dart'
    as avoid_setters_without_getters;
import 'avoid_shadowing_type_parameters_test.dart'
    as avoid_shadowing_type_parameters;
import 'avoid_single_cascade_in_expression_statements_test.dart'
    as avoid_single_cascade_in_expression_statements;
import 'avoid_slow_async_io_test.dart' as avoid_slow_async_io;
import 'avoid_type_to_string_test.dart' as avoid_type_to_string;
import 'avoid_types_as_parameter_names_test.dart'
    as avoid_types_as_parameter_names;
import 'avoid_types_on_closure_parameters_test.dart'
    as avoid_types_on_closure_parameters;
import 'avoid_unnecessary_containers_test.dart' as avoid_unnecessary_containers;
import 'avoid_unused_constructor_parameters_test.dart'
    as avoid_unused_constructor_parameters;
import 'avoid_void_async_test.dart' as avoid_void_async;
import 'avoid_web_libraries_in_flutter_test.dart'
    as avoid_web_libraries_in_flutter;
import 'await_only_futures_test.dart' as await_only_futures;
import 'camel_case_extensions_test.dart' as camel_case_extensions;
import 'camel_case_types_test.dart' as camel_case_types;
import 'cancel_subscriptions_test.dart' as cancel_subscriptions;
import 'cascade_invocations_test.dart' as cascade_invocations;
import 'cast_nullable_to_non_nullable_test.dart'
    as cast_nullable_to_non_nullable;
import 'close_sinks_test.dart' as close_sinks;
import 'collection_methods_unrelated_type_test.dart'
    as collection_methods_unrelated_type;
import 'combinators_ordering_test.dart' as combinators_ordering;
import 'comment_references_test.dart' as comment_references;
import 'conditional_uri_does_not_exist_test.dart'
    as conditional_uri_does_not_exist;
import 'constant_identifier_names_test.dart' as constant_identifier_names;
import 'control_flow_in_finally_test.dart' as control_flow_in_finally;
import 'curly_braces_in_flow_control_structures_test.dart'
    as curly_braces_in_flow_control_structures;
import 'dangling_library_doc_comments_test.dart'
    as dangling_library_doc_comments;
import 'depend_on_referenced_packages_test.dart'
    as depend_on_referenced_packages;
import 'deprecated_consistency_test.dart' as deprecated_consistency;
import 'deprecated_member_use_from_same_package_test.dart'
    as deprecated_member_use_from_same_package;
import 'diagnostic_describe_all_properties_test.dart'
    as diagnostic_describe_all_properties;
import 'directives_ordering_test.dart' as directives_ordering;
import 'discarded_futures_test.dart' as discarded_futures;
import 'do_not_use_environment_test.dart' as do_not_use_environment;
import 'document_ignores_test.dart' as document_ignores;
import 'empty_catches_test.dart' as empty_catches;
import 'empty_constructor_bodies_test.dart' as empty_constructor_bodies;
import 'empty_statements_test.dart' as empty_statements;
import 'eol_at_end_of_file_test.dart' as eol_at_end_of_file;
import 'erase_dart_type_extension_types_test.dart'
    as erase_dart_type_extension_types;
import 'exhaustive_cases_test.dart' as exhaustive_cases;
import 'file_names_test.dart' as file_names;
import 'flutter_style_todos_test.dart' as flutter_style_todos;
import 'hash_and_equals_test.dart' as hash_and_equals;
import 'implementation_imports_test.dart' as implementation_imports;
import 'implicit_call_tearoffs_test.dart' as implicit_call_tearoffs;
import 'implicit_reopen_test.dart' as implicit_reopen;
import 'invalid_case_patterns_test.dart' as invalid_case_patterns;
import 'invalid_runtime_check_with_js_interop_types_test.dart'
    as invalid_runtime_check_with_js_interop_types;
import 'join_return_with_assignment_test.dart' as join_return_with_assignment;
import 'leading_newlines_in_multiline_strings_test.dart'
    as leading_newlines_in_multiline_strings;
import 'library_annotations_test.dart' as library_annotations;
import 'library_names_test.dart' as library_names;
import 'library_prefixes_test.dart' as library_prefixes;
import 'library_private_types_in_public_api_test.dart'
    as library_private_types_in_public_api;
import 'lines_longer_than_80_chars_test.dart' as lines_longer_than_80_chars;
import 'literal_only_boolean_expressions_test.dart'
    as literal_only_boolean_expressions;
import 'matching_super_parameters_test.dart' as matching_super_parameters;
import 'missing_code_block_language_in_doc_comment_test.dart'
    as missing_code_block_language_in_doc_comment;
import 'missing_whitespace_between_adjacent_strings_test.dart'
    as missing_whitespace_between_adjacent_strings;
import 'no_adjacent_strings_in_list_test.dart' as no_adjacent_strings_in_list;
import 'no_default_cases_test.dart' as no_default_cases;
import 'no_duplicate_case_values_test.dart' as no_duplicate_case_values;
import 'no_leading_underscores_for_library_prefixes_test.dart'
    as no_leading_underscores_for_library_prefixes;
import 'no_leading_underscores_for_local_identifiers_test.dart'
    as no_leading_underscores_for_local_identifiers;
import 'no_literal_bool_comparisons_test.dart' as no_literal_bool_comparisons;
import 'no_logic_in_create_state_test.dart' as no_logic_in_create_state;
import 'no_runtimeType_toString_test.dart' as no_runtimeType_toString;
import 'no_self_assignments_test.dart' as no_self_assignments;
import 'no_wildcard_variable_uses_test.dart' as no_wildcard_variable_uses;
import 'non_constant_identifier_names_test.dart'
    as non_constant_identifier_names;
import 'noop_primitive_operations_test.dart' as noop_primitive_operations;
import 'null_check_on_nullable_type_parameter_test.dart'
    as null_check_on_nullable_type_parameter;
import 'null_closures_test.dart' as null_closures;
import 'omit_local_variable_types_test.dart' as omit_local_variable_types;
import 'omit_obvious_local_variable_types_test.dart'
    as omit_obvious_local_variable_types;
import 'omit_obvious_property_types_test.dart' as omit_obvious_property_types;
import 'one_member_abstracts_test.dart' as one_member_abstracts;
import 'only_throw_errors_test.dart' as only_throw_errors;
import 'overridden_fields_test.dart' as overridden_fields;
import 'package_names_test.dart' as package_names;
import 'package_prefixed_library_names_test.dart'
    as package_prefixed_library_names;
import 'parameter_assignments_test.dart' as parameter_assignments;
import 'prefer_adjacent_string_concatenation_test.dart'
    as prefer_adjacent_string_concatenation;
import 'prefer_asserts_in_initializer_lists_test.dart'
    as prefer_asserts_in_initializer_lists;
import 'prefer_asserts_with_message_test.dart' as prefer_asserts_with_message;
import 'prefer_collection_literals_test.dart' as prefer_collection_literals;
import 'prefer_conditional_assignment_test.dart'
    as prefer_conditional_assignment;
import 'prefer_const_constructors_in_immutables_test.dart'
    as prefer_const_constructors_in_immutables;
import 'prefer_const_constructors_test.dart' as prefer_const_constructors;
import 'prefer_const_declarations_test.dart' as prefer_const_declarations;
import 'prefer_const_literals_to_create_immutables_test.dart'
    as prefer_const_literals_to_create_immutables;
import 'prefer_constructors_over_static_methods_test.dart'
    as prefer_constructors_over_static_methods;
import 'prefer_contains_test.dart' as prefer_contains;
import 'prefer_double_quotes_test.dart' as prefer_double_quotes;
import 'prefer_expression_function_bodies_test.dart'
    as prefer_expression_function_bodies;
import 'prefer_final_fields_test.dart' as prefer_final_fields;
import 'prefer_final_in_for_each_test.dart' as prefer_final_in_for_each;
import 'prefer_final_locals_test.dart' as prefer_final_locals;
import 'prefer_final_parameters_test.dart' as prefer_final_parameters;
import 'prefer_for_elements_to_map_fromIterable_test.dart'
    as prefer_for_elements_to_map_fromIterable;
import 'prefer_foreach_test.dart' as prefer_foreach;
import 'prefer_function_declarations_over_variables_test.dart'
    as prefer_function_declarations_over_variables;
import 'prefer_generic_function_type_aliases_test.dart'
    as prefer_generic_function_type_aliases;
import 'prefer_if_elements_to_conditional_expressions_test.dart'
    as prefer_if_elements_to_conditional_expressions;
import 'prefer_if_null_operators_test.dart' as prefer_if_null_operators;
import 'prefer_initializing_formals_test.dart' as prefer_initializing_formals;
import 'prefer_inlined_adds_test.dart' as prefer_inlined_adds;
import 'prefer_int_literals_test.dart' as prefer_int_literals;
import 'prefer_interpolation_to_compose_strings_test.dart'
    as prefer_interpolation_to_compose_strings;
import 'prefer_is_empty_test.dart' as prefer_is_empty;
import 'prefer_is_not_empty_test.dart' as prefer_is_not_empty;
import 'prefer_is_not_operator_test.dart' as prefer_is_not_operator;
import 'prefer_iterable_whereType_test.dart' as prefer_iterable_whereType;
import 'prefer_mixin_test.dart' as prefer_mixin;
import 'prefer_null_aware_method_calls_test.dart'
    as prefer_null_aware_method_calls;
import 'prefer_null_aware_operators_test.dart' as prefer_null_aware_operators;
import 'prefer_relative_imports_test.dart' as prefer_relative_imports;
import 'prefer_single_quotes_test.dart' as prefer_single_quotes;
import 'prefer_spread_collections_test.dart' as prefer_spread_collections;
import 'prefer_typing_uninitialized_variables_test.dart'
    as prefer_typing_uninitialized_variables;
import 'prefer_void_to_null_test.dart' as prefer_void_to_null;
import 'provide_deprecation_message_test.dart' as provide_deprecation_message;
import 'public_member_api_docs_test.dart' as public_member_api_docs;
import 'recursive_getters_test.dart' as recursive_getters;
import 'require_trailing_commas_test.dart' as require_trailing_commas;
import 'secure_pubspec_urls_test.dart' as secure_pubspec_urls;
import 'sized_box_for_whitespace_test.dart' as sized_box_for_whitespace;
import 'sized_box_shrink_expand_test.dart' as sized_box_shrink_expand;
import 'slash_for_doc_comments_test.dart' as slash_for_doc_comments;
import 'sort_child_properties_last_test.dart' as sort_child_properties_last;
import 'sort_constructors_first_test.dart' as sort_constructors_first;
import 'sort_pub_dependencies_test.dart' as sort_pub_dependencies;
import 'sort_unnamed_constructors_first_test.dart'
    as sort_unnamed_constructors_first;
import 'specify_nonobvious_local_variable_types_test.dart'
    as specify_nonobvious_local_variable_types;
import 'specify_nonobvious_property_types_test.dart'
    as specify_nonobvious_property_types;
import 'strict_top_level_inference_test.dart' as strict_top_level_inference;
import 'test_types_in_equals_test.dart' as test_types_in_equals;
import 'throw_in_finally_test.dart' as throw_in_finally;
import 'tighten_type_of_initializing_formals_test.dart'
    as tighten_type_of_initializing_formals;
import 'type_annotate_public_apis_test.dart' as type_annotate_public_apis;
import 'type_init_formals_test.dart' as type_init_formals;
import 'type_literal_in_constant_pattern_test.dart'
    as type_literal_in_constant_pattern;
import 'unawaited_futures_test.dart' as unawaited_futures;
import 'unintended_html_in_doc_comment_test.dart'
    as unintended_html_in_doc_comment;
import 'unnecessary_async_test.dart' as unnecessary_async;
import 'unnecessary_await_in_return_test.dart' as unnecessary_await_in_return;
import 'unnecessary_brace_in_string_interps_test.dart'
    as unnecessary_brace_in_string_interps;
import 'unnecessary_breaks_test.dart' as unnecessary_breaks;
import 'unnecessary_const_test.dart' as unnecessary_const;
import 'unnecessary_constructor_name_test.dart' as unnecessary_constructor_name;
import 'unnecessary_final_test.dart' as unnecessary_final;
import 'unnecessary_getters_setters_test.dart' as unnecessary_getters_setters;
import 'unnecessary_lambdas_test.dart' as unnecessary_lambdas;
import 'unnecessary_late_test.dart' as unnecessary_late;
import 'unnecessary_library_directive_test.dart'
    as unnecessary_library_directive;
import 'unnecessary_library_name_test.dart' as unnecessary_library_name;
import 'unnecessary_new_test.dart' as unnecessary_new;
import 'unnecessary_null_aware_assignments_test.dart'
    as unnecessary_null_aware_assignments;
import 'unnecessary_null_aware_operator_on_extension_on_nullable_test.dart'
    as unnecessary_null_aware_operator_on_extension_on_nullable;
import 'unnecessary_null_checks_test.dart' as unnecessary_null_checks;
import 'unnecessary_null_in_if_null_operators_test.dart'
    as unnecessary_null_in_if_null_operators;
import 'unnecessary_nullable_for_final_variable_declarations_test.dart'
    as unnecessary_nullable_for_final_variable_declarations;
import 'unnecessary_overrides_test.dart' as unnecessary_overrides;
import 'unnecessary_parenthesis_test.dart' as unnecessary_parenthesis;
import 'unnecessary_raw_strings_test.dart' as unnecessary_raw_strings;
import 'unnecessary_statements_test.dart' as unnecessary_statements;
import 'unnecessary_string_escapes_test.dart' as unnecessary_string_escapes;
import 'unnecessary_string_interpolations_test.dart'
    as unnecessary_string_interpolations;
import 'unnecessary_this_test.dart' as unnecessary_this;
import 'unnecessary_to_list_in_spreads_test.dart'
    as unnecessary_to_list_in_spreads;
import 'unnecessary_underscores_test.dart' as unnecessary_underscores;
import 'unreachable_from_main_test.dart' as unreachable_from_main;
import 'unrelated_type_equality_checks_test.dart'
    as unrelated_type_equality_checks;
import 'unsafe_variance_test.dart' as unsafe_variance;
import 'use_build_context_synchronously_test.dart'
    as use_build_context_synchronously;
import 'use_colored_box_test.dart' as use_colored_box;
import 'use_decorated_box_test.dart' as use_decorated_box;
import 'use_enums_test.dart' as use_enums;
import 'use_full_hex_values_for_flutter_colors_test.dart'
    as use_full_hex_values_for_flutter_colors;
import 'use_function_type_syntax_for_parameters_test.dart'
    as use_function_type_syntax_for_parameters;
import 'use_if_null_to_convert_nulls_to_bools_test.dart'
    as use_if_null_to_convert_nulls_to_bools;
import 'use_is_even_rather_than_modulo_test.dart'
    as use_is_even_rather_than_modulo;
import 'use_key_in_widget_constructors_test.dart'
    as use_key_in_widget_constructors;
import 'use_late_for_private_fields_and_variables_test.dart'
    as use_late_for_private_fields_and_variables;
import 'use_named_constants_test.dart' as use_named_constants;
import 'use_raw_strings_test.dart' as use_raw_strings;
import 'use_rethrow_when_possible_test.dart' as use_rethrow_when_possible;
import 'use_setters_to_change_properties_test.dart'
    as use_setters_to_change_properties;
import 'use_string_buffers_test.dart' as use_string_buffers;
import 'use_string_in_part_of_directives_test.dart'
    as use_string_in_part_of_directives;
import 'use_super_parameters_test.dart' as use_super_parameters;
import 'use_test_throws_matchers_test.dart' as use_test_throws_matchers;
import 'use_to_and_as_if_applicable_test.dart' as use_to_and_as_if_applicable;
import 'use_truncating_division_test.dart' as use_truncating_division;
import 'valid_regexps_test.dart' as valid_regexps;
import 'void_checks_test.dart' as void_checks;

void main() {
  always_declare_return_types.main();
  always_put_control_body_on_new_line.main();
  always_put_required_named_parameters_first.main();
  always_specify_types.main();
  always_use_package_imports.main();
  analyzer_use_new_elements.main();
  annotate_overrides.main();
  annotate_redeclares.main();
  avoid_annotating_with_dynamic.main();
  avoid_bool_literals_in_conditional_expressions.main();
  avoid_catches_without_on_clauses.main();
  avoid_catching_errors.main();
  avoid_classes_with_only_static_members.main();
  avoid_double_and_int_checks.main();
  avoid_dynamic_calls.main();
  avoid_empty_else.main();
  avoid_equals_and_hash_code_on_mutable_classes.main();
  avoid_escaping_inner_quotes.main();
  avoid_field_initializers_in_const_classes.main();
  avoid_field_initializers_in_non_const_classes.main();
  avoid_final_parameters.main();
  avoid_function_literals_in_foreach_calls.main();
  avoid_futureor_void.main();
  avoid_implementing_value_types.main();
  avoid_init_to_null.main();
  avoid_js_rounded_ints.main();
  avoid_multiple_declarations_per_line.main();
  avoid_null_checks_in_equality_operators.main();
  avoid_positional_boolean_parameters.main();
  avoid_print.main();
  avoid_private_typedef_functions.main();
  avoid_redundant_argument_values.main();
  avoid_relative_lib_imports.main();
  avoid_renaming_method_parameters.main();
  avoid_return_types_on_setters.main();
  avoid_returning_null_for_void.main();
  avoid_returning_null.main();
  avoid_returning_this.main();
  avoid_setters_without_getters.main();
  avoid_shadowing_type_parameters.main();
  avoid_single_cascade_in_expression_statements.main();
  avoid_slow_async_io.main();
  avoid_type_to_string.main();
  avoid_types_as_parameter_names.main();
  avoid_types_on_closure_parameters.main();
  avoid_unnecessary_containers.main();
  avoid_unused_constructor_parameters.main();
  avoid_void_async.main();
  avoid_web_libraries_in_flutter.main();
  await_only_futures.main();
  camel_case_extensions.main();
  camel_case_types.main();
  cancel_subscriptions.main();
  cascade_invocations.main();
  cast_nullable_to_non_nullable.main();
  close_sinks.main();
  collection_methods_unrelated_type.main();
  combinators_ordering.main();
  comment_references.main();
  conditional_uri_does_not_exist.main();
  constant_identifier_names.main();
  control_flow_in_finally.main();
  curly_braces_in_flow_control_structures.main();
  dangling_library_doc_comments.main();
  depend_on_referenced_packages.main();
  deprecated_consistency.main();
  deprecated_member_use_from_same_package.main();
  diagnostic_describe_all_properties.main();
  directives_ordering.main();
  discarded_futures.main();
  do_not_use_environment.main();
  document_ignores.main();
  empty_catches.main();
  empty_constructor_bodies.main();
  empty_statements.main();
  eol_at_end_of_file.main();
  erase_dart_type_extension_types.main();
  exhaustive_cases.main();
  file_names.main();
  flutter_style_todos.main();
  hash_and_equals.main();
  implementation_imports.main();
  implicit_call_tearoffs.main();
  implicit_reopen.main();
  invalid_case_patterns.main();
  invalid_runtime_check_with_js_interop_types.main();
  join_return_with_assignment.main();
  leading_newlines_in_multiline_strings.main();
  library_annotations.main();
  library_names.main();
  library_prefixes.main();
  library_private_types_in_public_api.main();
  lines_longer_than_80_chars.main();
  literal_only_boolean_expressions.main();
  matching_super_parameters.main();
  missing_code_block_language_in_doc_comment.main();
  missing_whitespace_between_adjacent_strings.main();
  no_adjacent_strings_in_list.main();
  no_default_cases.main();
  no_duplicate_case_values.main();
  no_leading_underscores_for_library_prefixes.main();
  no_leading_underscores_for_local_identifiers.main();
  no_literal_bool_comparisons.main();
  no_logic_in_create_state.main();
  no_runtimeType_toString.main();
  no_self_assignments.main();
  no_wildcard_variable_uses.main();
  non_constant_identifier_names.main();
  noop_primitive_operations.main();
  null_check_on_nullable_type_parameter.main();
  null_closures.main();
  omit_local_variable_types.main();
  omit_obvious_local_variable_types.main();
  omit_obvious_property_types.main();
  one_member_abstracts.main();
  only_throw_errors.main();
  overridden_fields.main();
  package_names.main();
  package_prefixed_library_names.main();
  parameter_assignments.main();
  prefer_adjacent_string_concatenation.main();
  prefer_asserts_in_initializer_lists.main();
  prefer_asserts_with_message.main();
  prefer_collection_literals.main();
  prefer_conditional_assignment.main();
  prefer_const_constructors_in_immutables.main();
  prefer_const_constructors.main();
  prefer_const_declarations.main();
  prefer_const_literals_to_create_immutables.main();
  prefer_constructors_over_static_methods.main();
  prefer_contains.main();
  prefer_double_quotes.main();
  prefer_expression_function_bodies.main();
  prefer_final_fields.main();
  prefer_final_in_for_each.main();
  prefer_final_locals.main();
  prefer_final_parameters.main();
  prefer_for_elements_to_map_fromIterable.main();
  prefer_foreach.main();
  prefer_function_declarations_over_variables.main();
  prefer_generic_function_type_aliases.main();
  prefer_if_elements_to_conditional_expressions.main();
  prefer_if_null_operators.main();
  prefer_initializing_formals.main();
  prefer_inlined_adds.main();
  prefer_int_literals.main();
  prefer_interpolation_to_compose_strings.main();
  prefer_is_empty.main();
  prefer_is_not_empty.main();
  prefer_is_not_operator.main();
  prefer_iterable_whereType.main();
  prefer_mixin.main();
  prefer_null_aware_method_calls.main();
  prefer_null_aware_operators.main();
  prefer_relative_imports.main();
  prefer_single_quotes.main();
  prefer_spread_collections.main();
  prefer_typing_uninitialized_variables.main();
  prefer_void_to_null.main();
  provide_deprecation_message.main();
  public_member_api_docs.main();
  recursive_getters.main();
  require_trailing_commas.main();
  secure_pubspec_urls.main();
  sized_box_for_whitespace.main();
  sized_box_shrink_expand.main();
  slash_for_doc_comments.main();
  sort_child_properties_last.main();
  sort_constructors_first.main();
  sort_pub_dependencies.main();
  sort_unnamed_constructors_first.main();
  specify_nonobvious_local_variable_types.main();
  specify_nonobvious_property_types.main();
  strict_top_level_inference.main();
  test_types_in_equals.main();
  throw_in_finally.main();
  tighten_type_of_initializing_formals.main();
  type_annotate_public_apis.main();
  type_init_formals.main();
  type_literal_in_constant_pattern.main();
  unawaited_futures.main();
  unintended_html_in_doc_comment.main();
  unnecessary_async.main();
  unnecessary_await_in_return.main();
  unnecessary_brace_in_string_interps.main();
  unnecessary_breaks.main();
  unnecessary_const.main();
  unnecessary_constructor_name.main();
  unnecessary_final.main();
  unnecessary_getters_setters.main();
  unnecessary_lambdas.main();
  unnecessary_late.main();
  unnecessary_library_directive.main();
  unnecessary_library_name.main();
  unnecessary_new.main();
  unnecessary_null_aware_assignments.main();
  unnecessary_null_aware_operator_on_extension_on_nullable.main();
  unnecessary_null_checks.main();
  unnecessary_null_in_if_null_operators.main();
  unnecessary_nullable_for_final_variable_declarations.main();
  unnecessary_overrides.main();
  unnecessary_parenthesis.main();
  unnecessary_raw_strings.main();
  unnecessary_statements.main();
  unnecessary_string_escapes.main();
  unnecessary_string_interpolations.main();
  unnecessary_this.main();
  unnecessary_to_list_in_spreads.main();
  unnecessary_underscores.main();
  unreachable_from_main.main();
  unrelated_type_equality_checks.main();
  unsafe_variance.main();
  use_build_context_synchronously.main();
  use_colored_box.main();
  use_decorated_box.main();
  use_enums.main();
  use_full_hex_values_for_flutter_colors.main();
  use_function_type_syntax_for_parameters.main();
  use_if_null_to_convert_nulls_to_bools.main();
  use_is_even_rather_than_modulo.main();
  use_key_in_widget_constructors.main();
  use_late_for_private_fields_and_variables.main();
  use_named_constants.main();
  use_raw_strings.main();
  use_rethrow_when_possible.main();
  use_setters_to_change_properties.main();
  use_string_buffers.main();
  use_string_in_part_of_directives.main();
  use_super_parameters.main();
  use_test_throws_matchers.main();
  use_to_and_as_if_applicable.main();
  use_truncating_division.main();
  valid_regexps.main();
  void_checks.main();
}
