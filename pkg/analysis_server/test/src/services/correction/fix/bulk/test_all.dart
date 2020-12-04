// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_await_test.dart' as add_await;
import 'add_const_test.dart' as add_const;
import 'add_diagnostic_property_reference_test.dart'
    as add_diagnostic_property_reference;
import 'add_override_test.dart' as add_override;
import 'bulk_fix_processor_test.dart' as bulk_fix_processor;
import 'convert_documentation_into_line_test.dart'
    as convert_documentation_into_line;
import 'convert_map_from_iterable_to_for_literal_test.dart'
    as convert_map_from_iterable_to_for_literal;
import 'convert_to_contains_test.dart' as convert_to_contains;
import 'convert_to_generic_function_syntax_test.dart'
    as convert_to_generic_function_syntax;
import 'convert_to_if_element_test.dart' as convert_to_if_element;
import 'convert_to_if_null_test.dart' as convert_to_if_null;
import 'convert_to_int_literal_test.dart' as convert_to_int_literal;
import 'convert_to_list_literal_test.dart' as convert_to_list_literal;
import 'convert_to_map_literal_test.dart' as convert_to_map_literal;
import 'convert_to_null_aware_test.dart' as convert_to_null_aware;
import 'convert_to_relative_import_test.dart' as convert_to_relative_import;
import 'convert_to_set_literal_test.dart' as convert_to_set_literal;
import 'convert_to_single_quoted_strings_test.dart'
    as convert_to_single_quoted_strings;
import 'convert_to_spread_test.dart' as convert_to_spread;
import 'convert_to_where_type_test.dart' as convert_to_where_type;
import 'create_method_test.dart' as create_method;
import 'data_driven_test.dart' as data_driven;
import 'inline_invocation_test.dart' as inline_invocation;
import 'make_final_test.dart' as make_final;
import 'remove_argument_test.dart' as remove_argument;
import 'remove_await_test.dart' as remove_await;
import 'remove_duplicate_case_test.dart' as remove_duplicate_case;
import 'remove_empty_catch_test.dart' as remove_empty_catch;
import 'remove_empty_constructor_body_test.dart'
    as remove_empty_constructor_body;
import 'remove_empty_else_test.dart' as remove_empty_else;
import 'remove_empty_statement_test.dart' as remove_empty_statement;
import 'remove_initializer_test.dart' as remove_initializer;
import 'remove_interpolation_braces_test.dart' as remove_interpolation_braces;
import 'remove_method_declaration_test.dart' as remove_method_declaration;
import 'remove_non_null_assertion_test.dart' as remove_non_null_assertion;
import 'remove_operator_test.dart' as remove_operator;
import 'remove_this_expression_test.dart' as remove_this_expression;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'remove_unnecessary_const_test.dart' as remove_unnecessary_const;
import 'remove_unnecessary_new_test.dart' as remove_unnecessary_new;
import 'rename_to_camel_case_test.dart' as rename_to_camel_case;
import 'replace_colon_with_equals_test.dart' as replace_colon_with_equals;
import 'replace_final_with_const_test.dart' as replace_final_with_const;
import 'replace_new_with_const_test.dart' as replace_new_with_const;
import 'replace_null_with_closure_test.dart' as replace_null_with_closure;
import 'replace_with_conditional_assignment_test.dart'
    as replace_with_conditional_assignment;
import 'replace_with_is_empty_test.dart' as replace_with_is_empty;
import 'replace_with_tear_off_test.dart' as replace_with_tear_off;
import 'replace_with_var_test.dart' as replace_with_var;
import 'sort_child_properties_last_test.dart' as sort_child_properties_last;
import 'use_curly_braces_test.dart' as use_curly_braces;
import 'use_is_not_empty_test.dart' as use_is_not_empty;
import 'use_rethrow_test.dart' as use_rethrow;

void main() {
  defineReflectiveSuite(() {
    add_await.main();
    add_const.main();
    add_diagnostic_property_reference.main();
    add_override.main();
    bulk_fix_processor.main();
    convert_documentation_into_line.main();
    convert_map_from_iterable_to_for_literal.main();
    convert_to_contains.main();
    convert_to_generic_function_syntax.main();
    convert_to_if_element.main();
    convert_to_if_null.main();
    convert_to_int_literal.main();
    convert_to_list_literal.main();
    convert_to_map_literal.main();
    convert_to_null_aware.main();
    convert_to_relative_import.main();
    convert_to_set_literal.main();
    convert_to_single_quoted_strings.main();
    convert_to_spread.main();
    convert_to_where_type.main();
    create_method.main();
    data_driven.main();
    inline_invocation.main();
    make_final.main();
    remove_argument.main();
    remove_await.main();
    remove_duplicate_case.main();
    remove_initializer.main();
    remove_empty_catch.main();
    remove_empty_constructor_body.main();
    remove_empty_else.main();
    remove_empty_statement.main();
    remove_interpolation_braces.main();
    remove_method_declaration.main();
    remove_non_null_assertion.main();
    remove_operator.main();
    remove_this_expression.main();
    remove_type_annotation.main();
    remove_unnecessary_const.main();
    remove_unnecessary_new.main();
    rename_to_camel_case.main();
    replace_with_conditional_assignment.main();
    replace_colon_with_equals.main();
    replace_final_with_const.main();
    replace_new_with_const.main();
    replace_null_with_closure.main();
    replace_with_is_empty.main();
    replace_with_tear_off.main();
    replace_with_var.main();
    sort_child_properties_last.main();
    use_curly_braces.main();
    use_is_not_empty.main();
    use_rethrow.main();
  }, name: 'bulk');
}
