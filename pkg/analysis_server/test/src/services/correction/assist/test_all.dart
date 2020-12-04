// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_diagnostic_property_reference_test.dart' as add_diagnostic_property;
import 'add_not_null_assert_test.dart' as add_not_null_assert;
import 'add_return_type_test.dart' as add_return_type;
import 'add_type_annotation_test.dart' as add_type_annotation;
import 'assign_to_local_variable_test.dart' as assign_to_local_variable;
import 'convert_class_to_mixin_test.dart' as convert_class_to_mixin;
import 'convert_documentation_into_block_test.dart'
    as convert_documentation_into_block;
import 'convert_documentation_into_line_test.dart'
    as convert_documentation_into_line;
import 'convert_into_async_body_test.dart' as convert_into_async_body;
import 'convert_into_block_body_test.dart' as convert_into_block_body;
import 'convert_into_expression_body_test.dart' as convert_into_expression_body;
import 'convert_into_final_field_test.dart' as convert_into_final_field;
import 'convert_into_for_index_test.dart' as convert_into_for_index;
import 'convert_into_generic_function_syntax_test.dart'
    as convert_into_generic_function_syntax;
import 'convert_into_getter_test.dart' as convert_into_getter;
import 'convert_into_is_not_empty_test.dart' as convert_into_is_not_empty;
import 'convert_into_is_not_test.dart' as convert_into_is_not;
import 'convert_part_of_to_uri_test.dart' as convert_part_of_to_uri;
import 'convert_to_double_quoted_string_test.dart'
    as convert_to_double_quoted_string;
import 'convert_to_field_parameter_test.dart' as convert_to_field_parameter;
import 'convert_to_for_element_test.dart' as convert_to_for_element;
import 'convert_to_if_element_test.dart' as convert_to_if_element;
import 'convert_to_int_literal_test.dart' as convert_to_int_literal;
import 'convert_to_list_literal_test.dart' as convert_to_list_literal;
import 'convert_to_map_literal_test.dart' as convert_to_map_literal;
import 'convert_to_multiline_string_test.dart' as convert_to_multiline_string;
import 'convert_to_normal_parameter_test.dart' as convert_to_normal_parameter;
import 'convert_to_null_aware_test.dart' as convert_to_null_aware;
import 'convert_to_package_import_test.dart' as convert_to_package_import;
import 'convert_to_set_literal_test.dart' as convert_to_set_literal;
import 'convert_to_single_quoted_string_test.dart'
    as convert_to_single_quoted_string;
import 'convert_to_spread_test.dart' as convert_to_spread;
import 'encapsulate_field_test.dart' as encapsulate_field;
import 'exchange_operands_test.dart' as exchange_operands;
import 'flutter_convert_to_children_test.dart' as flutter_convert_to_children;
import 'flutter_convert_to_stateful_widget_test.dart'
    as flutter_convert_to_stateful_widget;
import 'flutter_move_down_test.dart' as flutter_move_down;
import 'flutter_move_up_test.dart' as flutter_move_up;
import 'flutter_remove_widget_test.dart' as flutter_remove_widget;
import 'flutter_surround_with_set_state_test.dart' as surround_with_set_state;
import 'flutter_swap_with_child_test.dart' as flutter_swap_with_child;
import 'flutter_swap_with_parent_test.dart' as flutter_swap_with_parent;
import 'flutter_wrap_center_test.dart' as flutter_wrap_center;
import 'flutter_wrap_column_test.dart' as flutter_wrap_column;
import 'flutter_wrap_container_test.dart' as flutter_wrap_container;
import 'flutter_wrap_generic_test.dart' as flutter_wrap_generic;
import 'flutter_wrap_padding_test.dart' as flutter_wrap_padding;
import 'flutter_wrap_row_test.dart' as flutter_wrap_row;
import 'flutter_wrap_sized_box_test.dart' as flutter_wrap_sized_box;
import 'flutter_wrap_stream_builder_test.dart' as flutter_wrap_stream_builder;
import 'import_add_show_test.dart' as import_add_show;
import 'inline_invocation_test.dart' as inline_invocation;
import 'introduce_local_cast_type_test.dart' as introduce_local_cast_type;
import 'invert_if_statement_test.dart' as invert_if_statement;
import 'join_if_with_inner_test.dart' as join_if_with_inner;
import 'join_if_with_outer_test.dart' as join_if_with_outer;
import 'join_variable_declaration_test.dart' as join_variable_declaration;
import 'remove_type_annotation_test.dart' as remove_type_annotation;
import 'replace_conditional_with_if_else_test.dart'
    as replace_conditional_with_if_else;
import 'replace_if_else_with_conditional_test.dart'
    as replace_if_else_with_conditional;
import 'replace_with_var_test.dart' as replace_with_var;
import 'shadow_field_test.dart' as shadow_field;
import 'sort_child_property_last_test.dart' as sort_child_property_last;
import 'split_and_condition_test.dart' as split_and_condition;
import 'split_variable_declaration_test.dart' as split_variable_declaration;
import 'surround_with_block_test.dart' as surround_with_block;
import 'surround_with_do_while_test.dart' as surround_with_do_while;
import 'surround_with_for_in_test.dart' as surround_with_for_in;
import 'surround_with_for_test.dart' as surround_with_for;
import 'surround_with_if_test.dart' as surround_with_if;
import 'surround_with_try_catch_test.dart' as surround_with_try_catch;
import 'surround_with_try_finally_test.dart' as surround_with_try_finally;
import 'surround_with_while_test.dart' as surround_with_while;
import 'use_curly_braces_test.dart' as use_curly_braces;

void main() {
  defineReflectiveSuite(() {
    add_diagnostic_property.main();
    add_not_null_assert.main();
    add_return_type.main();
    add_type_annotation.main();
    assign_to_local_variable.main();
    convert_class_to_mixin.main();
    convert_documentation_into_block.main();
    convert_documentation_into_line.main();
    convert_into_async_body.main();
    convert_into_block_body.main();
    convert_into_expression_body.main();
    convert_into_final_field.main();
    convert_into_for_index.main();
    convert_into_generic_function_syntax.main();
    convert_into_getter.main();
    convert_into_is_not.main();
    convert_into_is_not_empty.main();
    convert_part_of_to_uri.main();
    convert_to_double_quoted_string.main();
    convert_to_field_parameter.main();
    convert_to_for_element.main();
    convert_to_if_element.main();
    convert_to_int_literal.main();
    convert_to_list_literal.main();
    convert_to_map_literal.main();
    convert_to_multiline_string.main();
    convert_to_normal_parameter.main();
    convert_to_null_aware.main();
    convert_to_package_import.main();
    convert_to_set_literal.main();
    convert_to_single_quoted_string.main();
    convert_to_spread.main();
    encapsulate_field.main();
    exchange_operands.main();
    flutter_convert_to_children.main();
    flutter_convert_to_stateful_widget.main();
    flutter_move_down.main();
    flutter_move_up.main();
    flutter_remove_widget.main();
    flutter_swap_with_child.main();
    flutter_swap_with_parent.main();
    flutter_wrap_center.main();
    flutter_wrap_column.main();
    flutter_wrap_container.main();
    flutter_wrap_generic.main();
    flutter_wrap_padding.main();
    flutter_wrap_row.main();
    flutter_wrap_sized_box.main();
    flutter_wrap_stream_builder.main();
    import_add_show.main();
    inline_invocation.main();
    introduce_local_cast_type.main();
    invert_if_statement.main();
    join_if_with_inner.main();
    join_if_with_outer.main();
    join_variable_declaration.main();
    remove_type_annotation.main();
    replace_conditional_with_if_else.main();
    replace_if_else_with_conditional.main();
    replace_with_var.main();
    shadow_field.main();
    sort_child_property_last.main();
    split_and_condition.main();
    split_variable_declaration.main();
    surround_with_block.main();
    surround_with_do_while.main();
    surround_with_for.main();
    surround_with_for_in.main();
    surround_with_if.main();
    surround_with_set_state.main();
    surround_with_try_catch.main();
    surround_with_try_finally.main();
    surround_with_while.main();
    use_curly_braces.main();
  }, name: 'assist');
}
