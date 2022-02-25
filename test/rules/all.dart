// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'annotate_overrides_test.dart' as annotate_overrides;
import 'avoid_annotating_with_dynamic_test.dart'
    as avoid_annotating_with_dynamic;
import 'avoid_equals_and_hash_code_on_mutable_classes_test.dart'
    as avoid_equals_and_hash_code_on_mutable_classes;
import 'avoid_function_literals_in_foreach_calls_test.dart'
    as avoid_function_literals_in_foreach_calls;
import 'avoid_init_to_null_test.dart' as avoid_init_to_null;
import 'avoid_redundant_argument_values_test.dart'
    as avoid_redundant_argument_values;
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
import 'conditional_uri_does_not_exist_test.dart'
    as conditional_uri_does_not_exist;
import 'deprecated_consistency_test.dart' as deprecated_consistency;
import 'file_names_test.dart' as file_names;
import 'hash_and_equals_test.dart' as hash_and_equals;
import 'library_private_types_in_public_api_test.dart'
    as library_private_types_in_public_api;
import 'literal_only_boolean_expressions_test.dart'
    as literal_only_boolean_expressions;
import 'missing_whitespace_between_adjacent_strings_test.dart'
    as missing_whitespace_between_adjacent_strings;
import 'non_constant_identifier_names_test.dart'
    as non_constant_identifier_names;
import 'null_closures_test.dart' as null_closures;
import 'omit_local_variable_types_test.dart' as omit_local_variable_types;
import 'overridden_fields_test.dart' as overridden_fields;
import 'prefer_asserts_in_initializer_lists_test.dart'
    as prefer_asserts_in_initializer_lists;
import 'prefer_collection_literals_test.dart' as prefer_collection_literals;
import 'prefer_const_constructors_in_immutables_test.dart'
    as prefer_const_constructors_in_immutables;
import 'prefer_const_constructors_test.dart' as prefer_const_constructors;
import 'prefer_const_literals_to_create_immutables_test.dart'
    as prefer_const_literals_to_create_immutables;
import 'prefer_contains_test.dart' as prefer_contains;
import 'prefer_equal_for_default_values_test.dart'
    as prefer_equal_for_default_values;
import 'prefer_final_fields_test.dart' as prefer_final_fields;
import 'prefer_generic_function_type_aliases_test.dart'
    as prefer_generic_function_type_aliases;
import 'prefer_spread_collections_test.dart' as prefer_spread_collections;
import 'public_member_api_docs_test.dart' as public_member_api_docs;
import 'sort_constructors_first.dart' as sort_constructors_first;
import 'sort_unnamed_constructors_first.dart'
    as sort_unnamed_constructors_first;
import 'super_goes_last_test.dart' as super_goes_last;
import 'tighten_type_of_initializing_formals_test.dart'
    as tighten_type_of_initializing_formals;
import 'type_init_formals_test.dart' as type_init_formals;
import 'unawaited_futures_test.dart' as unawaited_futures;
import 'unnecessary_getters_setters_test.dart' as unnecessary_getters_setters;
import 'unnecessary_null_checks_test.dart' as unnecessary_null_checks;
import 'unnecessary_overrides_test.dart' as unnecessary_overrides;
import 'use_is_even_rather_than_modulo_test.dart'
    as use_is_even_rather_than_modulo;
import 'void_checks_test.dart' as void_checks;

void main() {
  annotate_overrides.main();
  avoid_annotating_with_dynamic.main();
  avoid_equals_and_hash_code_on_mutable_classes.main();
  avoid_function_literals_in_foreach_calls.main();
  avoid_setters_without_getters.main();
  avoid_init_to_null.main();
  avoid_redundant_argument_values.main();
  avoid_renaming_method_parameters.main();
  avoid_returning_this.main();
  avoid_shadowing_type_parameters.main();
  avoid_types_as_parameter_names.main();
  avoid_unused_constructor_parameters.main();
  avoid_void_async.main();
  conditional_uri_does_not_exist.main();
  deprecated_consistency.main();
  file_names.main();
  hash_and_equals.main();
  library_private_types_in_public_api.main();
  literal_only_boolean_expressions.main();
  missing_whitespace_between_adjacent_strings.main();
  non_constant_identifier_names.main();
  null_closures.main();
  omit_local_variable_types.main();
  overridden_fields.main();
  prefer_asserts_in_initializer_lists.main();
  prefer_collection_literals.main();
  prefer_const_constructors.main();
  prefer_const_constructors_in_immutables.main();
  prefer_const_literals_to_create_immutables.main();
  prefer_contains.main();
  prefer_equal_for_default_values.main();
  prefer_final_fields.main();
  prefer_generic_function_type_aliases.main();
  prefer_spread_collections.main();
  public_member_api_docs.main();
  sort_constructors_first.main();
  sort_unnamed_constructors_first.main();
  super_goes_last.main();
  tighten_type_of_initializing_formals.main();
  type_init_formals.main();
  unawaited_futures.main();
  unnecessary_getters_setters.main();
  unnecessary_null_checks.main();
  unnecessary_overrides.main();
  use_is_even_rather_than_modulo.main();
  void_checks.main();
}
