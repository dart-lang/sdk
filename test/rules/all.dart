// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'annotate_overrides_test.dart' as annotate_overrides;
import 'avoid_annotating_with_dynamic_test.dart'
    as avoid_annotating_with_dynamic;
import 'avoid_equals_and_hash_code_on_mutable_classes_test.dart'
    as avoid_equals_and_hash_code_on_mutable_classes;
import 'avoid_escaping_inner_quotes_test.dart' as avoid_escaping_inner_quotes;
import 'avoid_final_parameters_test.dart' as avoid_final_parameters;
import 'avoid_function_literals_in_foreach_calls_test.dart'
    as avoid_function_literals_in_foreach_calls;
import 'avoid_init_to_null_test.dart' as avoid_init_to_null;
import 'avoid_private_typedef_functions_test.dart'
    as avoid_private_typedef_functions;
import 'avoid_redundant_argument_values_test.dart'
    as avoid_redundant_argument_values;
import 'avoid_relative_lib_imports_test.dart' as avoid_relative_lib_imports;
import 'avoid_renaming_method_parameters_test.dart'
    as avoid_renaming_method_parameters;
import 'avoid_returning_this_test.dart' as avoid_returning_this;
import 'avoid_setters_without_getters_test.dart'
    as avoid_setters_without_getters;
import 'avoid_shadowing_type_parameters_test.dart'
    as avoid_shadowing_type_parameters;
import 'avoid_types_as_parameter_names_test.dart'
    as avoid_types_as_parameter_names;
import 'avoid_unused_constructor_parameters_test.dart'
    as avoid_unused_constructor_parameters;
import 'avoid_void_async_test.dart' as avoid_void_async;
import 'cancel_subscriptions_test.dart' as cancel_subscriptions;
import 'collection_methods_unrelated_type_test.dart'
    as collection_methods_unrelated_type;
import 'conditional_uri_does_not_exist_test.dart'
    as conditional_uri_does_not_exist;
import 'constant_identifier_names_test.dart' as constant_identifier_names;
import 'dangling_library_doc_comments_test.dart'
    as dangling_library_doc_comments;
import 'deprecated_consistency_test.dart' as deprecated_consistency;
import 'directives_ordering_test.dart' as directives_ordering;
import 'discarded_futures_test.dart' as discarded_futures;
import 'eol_at_end_of_file_test.dart' as eol_at_end_of_file;
import 'exhaustive_cases_test.dart' as exhaustive_cases;
import 'file_names_test.dart' as file_names;
import 'flutter_style_todos_test.dart' as flutter_style_todos;
import 'hash_and_equals_test.dart' as hash_and_equals;
import 'invalid_case_patterns_test.dart' as invalid_case_patterns;
import 'library_annotations_test.dart' as library_annotations;
import 'library_names_test.dart' as library_names;
import 'library_private_types_in_public_api_test.dart'
    as library_private_types_in_public_api;
import 'literal_only_boolean_expressions_test.dart'
    as literal_only_boolean_expressions;
import 'missing_whitespace_between_adjacent_strings_test.dart'
    as missing_whitespace_between_adjacent_strings;
import 'no_duplicate_case_values_test.dart' as no_duplicate_case_values;
import 'non_adjacent_strings_in_list_test.dart' as no_adjacent_strings_in_list;
import 'non_constant_identifier_names_test.dart'
    as non_constant_identifier_names;
import 'null_closures_test.dart' as null_closures;
import 'omit_local_variable_types_test.dart' as omit_local_variable_types;
import 'only_throw_errors_test.dart' as only_throw_errors;
import 'overridden_fields_test.dart' as overridden_fields;
import 'parameter_assignments_test.dart' as parameter_assignments;
import 'prefer_asserts_in_initializer_lists_test.dart'
    as prefer_asserts_in_initializer_lists;
import 'prefer_collection_literals_test.dart' as prefer_collection_literals;
import 'prefer_const_constructors_in_immutables_test.dart'
    as prefer_const_constructors_in_immutables;
import 'prefer_const_constructors_test.dart' as prefer_const_constructors;
import 'prefer_const_declarations_test.dart' as prefer_const_declarations;
import 'prefer_const_literals_to_create_immutables_test.dart'
    as prefer_const_literals_to_create_immutables;
import 'prefer_constructors_over_static_methods_test.dart'
    as prefer_constructors_over_static_methods;
import 'prefer_contains_test.dart' as prefer_contains;
import 'prefer_final_fields_test.dart' as prefer_final_fields;
import 'prefer_final_parameters_test.dart' as prefer_final_parameters;
import 'prefer_generic_function_type_aliases_test.dart'
    as prefer_generic_function_type_aliases;
import 'prefer_mixin_test.dart' as prefer_mixin;
import 'prefer_relative_imports_test.dart' as prefer_relative_imports;
import 'prefer_spread_collections_test.dart' as prefer_spread_collections;
import 'public_member_api_docs_test.dart' as public_member_api_docs;
import 'recursive_getters_test.dart' as recursive_getters;
import 'sort_constructors_first_test.dart' as sort_constructors_first;
import 'sort_unnamed_constructors_first_test.dart'
    as sort_unnamed_constructors_first;
import 'tighten_type_of_initializing_formals_test.dart'
    as tighten_type_of_initializing_formals;
import 'type_init_formals_test.dart' as type_init_formals;
import 'unawaited_futures_test.dart' as unawaited_futures;
import 'unnecessary_brace_in_string_interps_test.dart'
    as unnecessary_brace_in_string_interps;
import 'unnecessary_breaks_test.dart' as unnecessary_breaks;
import 'unnecessary_const_test.dart' as unnecessary_const;
import 'unnecessary_lambdas_test.dart' as unnecessary_lambdas;
import 'unnecessary_library_directive_test.dart'
    as unnecessary_library_directive;
import 'unnecessary_null_checks_test.dart' as unnecessary_null_checks;
import 'unnecessary_overrides_test.dart' as unnecessary_overrides;
import 'unnecessary_parenthesis_test.dart' as unnecessary_parenthesis;
import 'unnecessary_string_escapes_test.dart' as unnecessary_string_escapes;
import 'unreachable_from_main_test.dart' as unreachable_from_main;
import 'use_build_context_synchronously_test.dart'
    as use_build_context_synchronously;
import 'use_enums_test.dart' as use_enums;
import 'use_is_even_rather_than_modulo_test.dart'
    as use_is_even_rather_than_modulo;
import 'use_late_for_private_fields_and_variables_test.dart'
    as use_late_for_private_fields_and_variables;
import 'use_super_parameters_test.dart' as use_super_parameters;
import 'void_checks_test.dart' as void_checks;

void main() {
  annotate_overrides.main();
  avoid_annotating_with_dynamic.main();
  avoid_equals_and_hash_code_on_mutable_classes.main();
  avoid_escaping_inner_quotes.main();
  avoid_function_literals_in_foreach_calls.main();
  avoid_final_parameters.main();
  avoid_init_to_null.main();
  avoid_private_typedef_functions.main();
  avoid_redundant_argument_values.main();
  avoid_relative_lib_imports.main();
  avoid_renaming_method_parameters.main();
  avoid_returning_this.main();
  avoid_setters_without_getters.main();
  avoid_shadowing_type_parameters.main();
  avoid_types_as_parameter_names.main();
  avoid_unused_constructor_parameters.main();
  avoid_void_async.main();
  cancel_subscriptions.main();
  collection_methods_unrelated_type.main();
  conditional_uri_does_not_exist.main();
  constant_identifier_names.main();
  dangling_library_doc_comments.main();
  deprecated_consistency.main();
  directives_ordering.main();
  discarded_futures.main();
  eol_at_end_of_file.main();
  exhaustive_cases.main();
  file_names.main();
  flutter_style_todos.main();
  hash_and_equals.main();
  invalid_case_patterns.main();
  library_annotations.main();
  library_names.main();
  library_private_types_in_public_api.main();
  literal_only_boolean_expressions.main();
  missing_whitespace_between_adjacent_strings.main();
  no_adjacent_strings_in_list.main();
  no_duplicate_case_values.main();
  non_constant_identifier_names.main();
  null_closures.main();
  omit_local_variable_types.main();
  only_throw_errors.main();
  overridden_fields.main();
  parameter_assignments.main();
  prefer_asserts_in_initializer_lists.main();
  prefer_collection_literals.main();
  prefer_const_constructors.main();
  prefer_const_constructors_in_immutables.main();
  prefer_const_declarations.main();
  prefer_const_literals_to_create_immutables.main();
  prefer_constructors_over_static_methods.main();
  prefer_contains.main();
  prefer_final_fields.main();
  prefer_final_parameters.main();
  prefer_generic_function_type_aliases.main();
  prefer_relative_imports.main();
  prefer_spread_collections.main();
  public_member_api_docs.main();
  prefer_mixin.main();
  recursive_getters.main();
  sort_constructors_first.main();
  sort_unnamed_constructors_first.main();
  tighten_type_of_initializing_formals.main();
  type_init_formals.main();
  unawaited_futures.main();
  unnecessary_brace_in_string_interps.main();
  unnecessary_breaks.main();
  unnecessary_const.main();
  unnecessary_lambdas.main();
  unnecessary_library_directive.main();
  unnecessary_null_checks.main();
  unnecessary_overrides.main();
  unnecessary_parenthesis.main();
  unnecessary_string_escapes.main();
  unreachable_from_main.main();
  use_build_context_synchronously.main();
  use_enums.main();
  use_is_even_rather_than_modulo.main();
  use_late_for_private_fields_and_variables.main();
  use_super_parameters.main();
  void_checks.main();
}
