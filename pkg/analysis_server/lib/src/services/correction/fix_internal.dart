// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/add_async.dart';
import 'package:analysis_server/src/services/correction/dart/add_await.dart';
import 'package:analysis_server/src/services/correction/dart/add_call_super.dart';
import 'package:analysis_server/src/services/correction/dart/add_class_modifier.dart';
import 'package:analysis_server/src/services/correction/dart/add_const.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_empty_argument_list.dart';
import 'package:analysis_server/src/services/correction/dart/add_enum_constant.dart';
import 'package:analysis_server/src/services/correction/dart/add_eol_at_end_of_file.dart';
import 'package:analysis_server/src/services/correction/dart/add_explicit_call.dart';
import 'package:analysis_server/src/services/correction/dart/add_explicit_cast.dart';
import 'package:analysis_server/src/services/correction/dart/add_extension_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_field_formal_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/add_key_to_constructors.dart';
import 'package:analysis_server/src/services/correction/dart/add_late.dart';
import 'package:analysis_server/src/services/correction/dart/add_leading_newline_to_string.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_enum_like_case_clauses.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_parameter_named.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_required_argument.dart';
import 'package:analysis_server/src/services/correction/dart/add_missing_switch_cases.dart';
import 'package:analysis_server/src/services/correction/dart/add_ne_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_null_check.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/add_redeclare.dart';
import 'package:analysis_server/src/services/correction/dart/add_reopen.dart';
import 'package:analysis_server/src/services/correction/dart/add_required_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_null.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_static.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_constructor_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/add_super_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/add_switch_case_break.dart';
import 'package:analysis_server/src/services/correction/dart/add_trailing_comma.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/ambiguous_import_fix.dart';
import 'package:analysis_server/src/services/correction/dart/change_argument_name.dart';
import 'package:analysis_server/src/services/correction/dart/change_to.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_nearest_precise_value.dart';
import 'package:analysis_server/src/services/correction/dart/change_to_static_access.dart';
import 'package:analysis_server/src/services/correction/dart/change_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_enum.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_child.dart';
import 'package:analysis_server/src/services/correction/dart/convert_flutter_children.dart';
import 'package:analysis_server/src/services/correction/dart/convert_for_each_to_for_loop.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_block_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_getter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_null_check_to_null_aware_element_or_entry.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_related_to_cascade.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_boolean_expression.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_cascade.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_constant_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_flutter_style_todo.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_for_each.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_function_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_initializing_formal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_named_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_list_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_map_entry.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_set_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_on_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_raw_string.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_super_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_where_type.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_wildcard_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_wildcard_variable.dart';
import 'package:analysis_server/src/services/correction/dart/create_class.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_for_final_fields.dart';
import 'package:analysis_server/src/services/correction/dart/create_constructor_super.dart';
import 'package:analysis_server/src/services/correction/dart/create_extension_member.dart';
import 'package:analysis_server/src/services/correction/dart/create_field.dart';
import 'package:analysis_server/src/services/correction/dart/create_file.dart';
import 'package:analysis_server/src/services/correction/dart/create_function.dart';
import 'package:analysis_server/src/services/correction/dart/create_getter.dart';
import 'package:analysis_server/src/services/correction/dart/create_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/create_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_method_or_function.dart';
import 'package:analysis_server/src/services/correction/dart/create_missing_overrides.dart';
import 'package:analysis_server/src/services/correction/dart/create_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/create_no_such_method.dart';
import 'package:analysis_server/src/services/correction/dart/create_operator.dart';
import 'package:analysis_server/src/services/correction/dart/create_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/create_setter.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/extend_class_for_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/extract_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_remove_widget.dart';
import 'package:analysis_server/src/services/correction/dart/import_library.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/inline_typedef.dart';
import 'package:analysis_server/src/services/correction/dart/insert_body.dart';
import 'package:analysis_server/src/services/correction/dart/insert_on_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/insert_semicolon.dart';
import 'package:analysis_server/src/services/correction/dart/make_class_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/make_conditional_on_debug_mode.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_field_public.dart';
import 'package:analysis_server/src/services/correction/dart/make_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_required_named_parameters_first.dart';
import 'package:analysis_server/src/services/correction/dart/make_return_type_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/make_super_invocation_last.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_not_final.dart';
import 'package:analysis_server/src/services/correction/dart/make_variable_nullable.dart';
import 'package:analysis_server/src/services/correction/dart/merge_combinators.dart';
import 'package:analysis_server/src/services/correction/dart/move_annotation_to_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/move_doc_comment_to_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/move_type_arguments_to_class.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/qualify_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_abstract.dart';
import 'package:analysis_server/src/services/correction/dart/remove_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_assertion.dart';
import 'package:analysis_server/src/services/correction/dart/remove_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/remove_async.dart';
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_break.dart';
import 'package:analysis_server/src/services/correction/dart/remove_character.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comma.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comment.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comparison.dart';
import 'package:analysis_server/src/services/correction/dart/remove_const.dart';
import 'package:analysis_server/src/services/correction/dart/remove_constructor.dart';
import 'package:analysis_server/src/services/correction/dart/remove_constructor_name.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_code.dart';
import 'package:analysis_server/src/services/correction/dart/remove_dead_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/remove_default_value.dart';
import 'package:analysis_server/src/services/correction/dart/remove_deprecated_new_in_comment_reference.dart';
import 'package:analysis_server/src/services/correction/dart/remove_duplicate_case.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_catch.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_constructor_body.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_else.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_statement.dart';
import 'package:analysis_server/src/services/correction/dart/remove_extends_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_if_null_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_ignored_diagnostic.dart';
import 'package:analysis_server/src/services/correction/dart/remove_initializer.dart';
import 'package:analysis_server/src/services/correction/dart/remove_interpolation_braces.dart';
import 'package:analysis_server/src/services/correction/dart/remove_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_late.dart';
import 'package:analysis_server/src/services/correction/dart/remove_leading_underscore.dart';
import 'package:analysis_server/src/services/correction/dart/remove_lexeme.dart';
import 'package:analysis_server/src/services/correction/dart/remove_library_name.dart';
import 'package:analysis_server/src/services/correction/dart/remove_method_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_name_from_combinator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_name_from_declaration_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_non_null_assertion.dart';
import 'package:analysis_server/src/services/correction/dart/remove_on_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_operator.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parameters_in_getter_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_parentheses_in_getter_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_print.dart';
import 'package:analysis_server/src/services/correction/dart/remove_question_mark.dart';
import 'package:analysis_server/src/services/correction/dart/remove_required.dart';
import 'package:analysis_server/src/services/correction/dart/remove_returned_value.dart';
import 'package:analysis_server/src/services/correction/dart/remove_this_expression.dart';
import 'package:analysis_server/src/services/correction/dart/remove_to_list.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unawaited.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unexpected_underscores.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_cast.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_final.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_late.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_library_directive.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_parentheses.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_raw_string.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_string_escape.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_string_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_wildcard_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_clause.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_catch_stack.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_label.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/remove_var.dart';
import 'package:analysis_server/src/services/correction/dart/remove_var_keyword.dart';
import 'package:analysis_server/src/services/correction/dart/rename_method_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/rename_to_camel_case.dart';
import 'package:analysis_server/src/services/correction/dart/replace_boolean_with_bool.dart';
import 'package:analysis_server/src/services/correction/dart/replace_cascade_with_dot.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_in.dart';
import 'package:analysis_server/src/services/correction/dart/replace_container_with_colored_box.dart';
import 'package:analysis_server/src/services/correction/dart/replace_container_with_sized_box.dart';
import 'package:analysis_server/src/services/correction/dart/replace_empty_map_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_final_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/replace_new_with_const.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_check_with_cast.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_closure.dart';
import 'package:analysis_server/src/services/correction/dart/replace_null_with_void.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_future.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_iterable.dart';
import 'package:analysis_server/src/services/correction/dart/replace_return_type_stream.dart';
import 'package:analysis_server/src/services/correction/dart/replace_var_with_dynamic.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_arrow.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_brackets.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_conditional_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_decorated_box.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_eight_digit_hex.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_extension_name.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_identifier.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_interpolation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_empty.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_is_nan.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_named_constant.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_not_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_not_null_aware_element_or_entry.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_part_of_uri.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_tear_off.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_unicode_escape.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_wildcard.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/sort_combinators.dart';
import 'package:analysis_server/src/services/correction/dart/sort_constructor_first.dart';
import 'package:analysis_server/src/services/correction/dart/sort_unnamed_constructor_first.dart';
import 'package:analysis_server/src/services/correction/dart/split_multiple_declarations.dart';
import 'package:analysis_server/src/services/correction/dart/surround_with_parentheses.dart';
import 'package:analysis_server/src/services/correction/dart/update_sdk_constraints.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server/src/services/correction/dart/use_different_division_operator.dart';
import 'package:analysis_server/src/services/correction/dart/use_effective_integer_division.dart';
import 'package:analysis_server/src/services/correction/dart/use_eq_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/use_not_eq_null.dart';
import 'package:analysis_server/src/services/correction/dart/use_rethrow.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_text.dart';
import 'package:analysis_server/src/services/correction/dart/wrap_in_unawaited.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analysis_server_plugin/src/correction/ignore_diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:linter/src/lint_codes.dart';

final _builtInLintGenerators = <LintCode, List<ProducerGenerator>>{
  LinterLintCode.always_declare_return_types_of_functions: [AddReturnType.new],
  LinterLintCode.always_declare_return_types_of_methods: [AddReturnType.new],
  LinterLintCode.always_put_control_body_on_new_line: [UseCurlyBraces.nonBulk],
  LinterLintCode.always_put_required_named_parameters_first: [
    MakeRequiredNamedParametersFirst.new,
  ],
  LinterLintCode.always_specify_types_add_type: [AddTypeAnnotation.bulkFixable],
  LinterLintCode.always_specify_types_specify_type: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.always_specify_types_replace_keyword: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.always_specify_types_split_to_types: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.always_use_package_imports: [ConvertToPackageImport.new],
  LinterLintCode.annotate_overrides: [AddOverride.new],
  LinterLintCode.annotate_redeclares: [AddRedeclare.new],
  LinterLintCode.avoid_annotating_with_dynamic: [RemoveTypeAnnotation.other],
  LinterLintCode.avoid_bool_literals_in_conditional_expressions: [
    ConvertToBooleanExpression.new,
  ],
  LinterLintCode.avoid_empty_else: [RemoveEmptyElse.new],
  LinterLintCode.avoid_escaping_inner_quotes: [ConvertQuotes.new],
  LinterLintCode.avoid_function_literals_in_foreach_calls: [
    ConvertForEachToForLoop.new,
  ],
  LinterLintCode.avoid_init_to_null: [RemoveInitializer.bulkFixable],
  LinterLintCode.avoid_multiple_declarations_per_line: [
    SplitMultipleDeclarations.new,
  ],
  LinterLintCode.avoid_null_checks_in_equality_operators: [
    RemoveComparison.new,
  ],
  LinterLintCode.avoid_print: [MakeConditionalOnDebugMode.new, RemovePrint.new],
  LinterLintCode.avoid_private_typedef_functions: [InlineTypedef.new],
  LinterLintCode.avoid_redundant_argument_values: [RemoveArgument.new],
  LinterLintCode.avoid_relative_lib_imports: [ConvertToPackageImport.new],
  LinterLintCode.avoid_renaming_method_parameters: [RenameMethodParameter.new],
  LinterLintCode.avoid_return_types_on_setters: [RemoveTypeAnnotation.other],
  LinterLintCode.avoid_returning_null_for_void_from_function: [
    RemoveReturnedValue.new,
  ],
  LinterLintCode.avoid_returning_null_for_void_from_method: [
    RemoveReturnedValue.new,
  ],
  LinterLintCode.avoid_single_cascade_in_expression_statements: [
    // TODO(brianwilkerson): This fix should be applied to some non-lint
    //  diagnostics and should also be available as an assist.
    ReplaceCascadeWithDot.new,
  ],
  LinterLintCode.avoid_types_as_parameter_names_formal_parameter: [
    ConvertToOnType.new,
  ],
  LinterLintCode.avoid_types_on_closure_parameters: [
    ReplaceWithIdentifier.new,
    RemoveTypeAnnotation.other,
  ],
  LinterLintCode.avoid_unused_constructor_parameters: [
    RemoveUnusedParameter.new,
  ],
  LinterLintCode.avoid_unnecessary_containers: [FlutterRemoveWidget.new],
  LinterLintCode.avoid_void_async: [ReplaceReturnTypeFuture.new],
  LinterLintCode.await_only_futures: [RemoveAwait.new],
  LinterLintCode.cascade_invocations: [
    ConvertToCascade.new,
    ConvertRelatedToCascade.new,
  ],
  LinterLintCode.cast_nullable_to_non_nullable: [
    AddNullCheck.withoutAssignabilityCheck,
  ],
  LinterLintCode.combinators_ordering: [SortCombinators.new],
  LinterLintCode.constant_identifier_names: [RenameToCamelCase.new],
  LinterLintCode.curly_braces_in_flow_control_structures: [UseCurlyBraces.new],
  LinterLintCode.dangling_library_doc_comments: [
    MoveDocCommentToLibraryDirective.new,
  ],
  LinterLintCode.diagnostic_describe_all_properties: [
    AddDiagnosticPropertyReference.new,
  ],
  LinterLintCode.directives_ordering_dart: [OrganizeImports.new],
  LinterLintCode.directives_ordering_alphabetical: [OrganizeImports.new],
  LinterLintCode.directives_ordering_exports: [OrganizeImports.new],
  LinterLintCode.directives_ordering_package_before_relative: [
    OrganizeImports.new,
  ],
  LinterLintCode.discarded_futures: [
    AddAsync.discardedFutures,
    WrapInUnawaited.new,
  ],
  LinterLintCode.empty_catches: [RemoveEmptyCatch.new],
  LinterLintCode.empty_constructor_bodies: [RemoveEmptyConstructorBody.new],
  LinterLintCode.empty_statements: [
    RemoveEmptyStatement.new,
    ReplaceWithBrackets.new,
  ],
  LinterLintCode.eol_at_end_of_file: [AddEolAtEndOfFile.new],
  LinterLintCode.exhaustive_cases: [AddMissingEnumLikeCaseClauses.new],
  LinterLintCode.flutter_style_todos: [ConvertToFlutterStyleTodo.new],
  LinterLintCode.hash_and_equals: [CreateMethod.equalityOrHashCode],
  LinterLintCode.implicit_call_tearoffs: [AddExplicitCall.new],
  LinterLintCode.implicit_reopen: [AddReopen.new],
  LinterLintCode.invalid_case_patterns: [AddConst.new],
  LinterLintCode.leading_newlines_in_multiline_strings: [
    AddLeadingNewlineToString.new,
  ],
  LinterLintCode.library_annotations: [MoveAnnotationToLibraryDirective.new],
  LinterLintCode.no_duplicate_case_values: [RemoveDuplicateCase.new],
  LinterLintCode.no_leading_underscores_for_library_prefixes: [
    RemoveLeadingUnderscore.new,
  ],
  LinterLintCode.no_leading_underscores_for_local_identifiers: [
    RemoveLeadingUnderscore.new,
  ],
  LinterLintCode.no_literal_bool_comparisons: [ConvertToBooleanExpression.new],
  LinterLintCode.non_constant_identifier_names: [RenameToCamelCase.new],
  LinterLintCode.noop_primitive_operations: [RemoveInvocation.new],
  LinterLintCode.null_check_on_nullable_type_parameter: [
    ReplaceNullCheckWithCast.new,
  ],
  LinterLintCode.null_closures: [ReplaceNullWithClosure.new],
  LinterLintCode.omit_local_variable_types: [
    ReplaceWithVar.new,
    RemoveTypeAnnotation.other,
  ],
  LinterLintCode.omit_obvious_local_variable_types: [
    ReplaceWithVar.new,
    RemoveTypeAnnotation.other,
  ],
  LinterLintCode.omit_obvious_property_types: [
    ReplaceWithVar.new,
    RemoveTypeAnnotation.other,
  ],
  LinterLintCode.prefer_adjacent_string_concatenation: [RemoveOperator.new],
  LinterLintCode.prefer_collection_literals: [
    ConvertToMapLiteral.new,
    ConvertToSetLiteral.new,
  ],
  LinterLintCode.prefer_conditional_assignment: [
    ReplaceWithConditionalAssignment.new,
  ],
  LinterLintCode.prefer_const_constructors: [
    AddConst.new,
    ReplaceNewWithConst.new,
  ],
  LinterLintCode.prefer_const_constructors_in_immutables: [AddConst.new],
  LinterLintCode.prefer_const_declarations: [ReplaceFinalWithConst.new],
  LinterLintCode.prefer_const_literals_to_create_immutables: [AddConst.new],
  LinterLintCode.prefer_contains_always_false: [ConvertToContains.new],
  LinterLintCode.prefer_contains_always_true: [ConvertToContains.new],
  LinterLintCode.prefer_contains_use_contains: [ConvertToContains.new],
  LinterLintCode.prefer_double_quotes: [ConvertToDoubleQuotes.new],
  LinterLintCode.prefer_expression_function_bodies: [
    ConvertToExpressionFunctionBody.new,
  ],
  LinterLintCode.prefer_final_fields: [MakeFinal.new],
  LinterLintCode.prefer_final_in_for_each_pattern: [MakeFinal.new],
  LinterLintCode.prefer_final_in_for_each_variable: [MakeFinal.new],
  LinterLintCode.prefer_final_locals: [MakeFinal.new],
  LinterLintCode.prefer_final_parameters: [MakeFinal.new],
  LinterLintCode.prefer_for_elements_to_map_fromIterable: [
    ConvertMapFromIterableToForLiteral.new,
  ],
  LinterLintCode.prefer_foreach: [ConvertToForEach.new],
  LinterLintCode.prefer_function_declarations_over_variables: [
    ConvertToFunctionDeclaration.new,
  ],
  LinterLintCode.prefer_generic_function_type_aliases: [
    ConvertToGenericFunctionSyntax.new,
  ],
  LinterLintCode.prefer_if_elements_to_conditional_expressions: [
    ConvertConditionalExpressionToIfElement.new,
  ],
  LinterLintCode.prefer_if_null_operators: [ConvertToIfNull.preferIfNull],
  LinterLintCode.prefer_initializing_formals: [ConvertToInitializingFormal.new],
  LinterLintCode.prefer_inlined_adds_single: [
    ConvertAddAllToSpread.new,
    InlineInvocation.new,
  ],
  LinterLintCode.prefer_inlined_adds_multiple: [
    ConvertAddAllToSpread.new,
    InlineInvocation.new,
  ],
  LinterLintCode.prefer_int_literals: [ConvertToIntLiteral.new],
  LinterLintCode.prefer_interpolation_to_compose_strings: [
    ReplaceWithInterpolation.new,
  ],
  LinterLintCode.prefer_is_empty_always_false: [ReplaceWithIsEmpty.new],
  LinterLintCode.prefer_is_empty_always_true: [ReplaceWithIsEmpty.new],
  LinterLintCode.prefer_is_empty_use_is_empty: [ReplaceWithIsEmpty.new],
  LinterLintCode.prefer_is_empty_use_is_not_empty: [ReplaceWithIsEmpty.new],
  LinterLintCode.prefer_is_not_empty: [UseIsNotEmpty.new],
  LinterLintCode.prefer_is_not_operator: [ConvertIntoIsNot.new],
  LinterLintCode.prefer_iterable_whereType: [ConvertToWhereType.new],
  LinterLintCode.prefer_null_aware_operators: [ConvertToNullAware.new],
  LinterLintCode.prefer_relative_imports: [ConvertToRelativeImport.new],
  LinterLintCode.prefer_single_quotes: [ConvertToSingleQuotes.new],
  LinterLintCode.prefer_spread_collections: [ConvertAddAllToSpread.new],
  LinterLintCode.prefer_typing_uninitialized_variables_for_field: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.prefer_typing_uninitialized_variables_for_local_variable: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.prefer_void_to_null: [ReplaceNullWithVoid.new],
  LinterLintCode.require_trailing_commas: [AddTrailingComma.new],
  LinterLintCode.sized_box_for_whitespace: [ReplaceContainerWithSizedBox.new],
  LinterLintCode.slash_for_doc_comments: [ConvertDocumentationIntoLine.new],
  LinterLintCode.sort_child_properties_last: [SortChildPropertyLast.new],
  LinterLintCode.sort_constructors_first: [SortConstructorFirst.new],
  LinterLintCode.sort_unnamed_constructors_first: [
    SortUnnamedConstructorFirst.new,
  ],
  LinterLintCode.specify_nonobvious_local_variable_types: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.specify_nonobvious_property_types: [
    AddTypeAnnotation.bulkFixable,
  ],
  LinterLintCode.strict_top_level_inference_add_type: [AddReturnType.new],
  LinterLintCode.type_annotate_public_apis: [AddTypeAnnotation.bulkFixable],
  LinterLintCode.type_init_formals: [RemoveTypeAnnotation.other],
  LinterLintCode.type_literal_in_constant_pattern: [
    ConvertToConstantPattern.new,
    ConvertToWildcardPattern.new,
  ],
  LinterLintCode.unawaited_futures: [AddAwait.unawaited, WrapInUnawaited.new],
  LinterLintCode.unnecessary_async: [RemoveAsync.unnecessary],
  LinterLintCode.unnecessary_await_in_return: [RemoveAwait.new],
  LinterLintCode.unnecessary_brace_in_string_interps: [
    RemoveInterpolationBraces.new,
  ],
  LinterLintCode.unnecessary_breaks: [RemoveBreak.new],
  LinterLintCode.unnecessary_const: [RemoveUnnecessaryConst.new],
  LinterLintCode.unnecessary_constructor_name: [RemoveConstructorName.new],
  LinterLintCode.unnecessary_final_with_type: [ReplaceFinalWithVar.new],
  LinterLintCode.unnecessary_final_without_type: [ReplaceFinalWithVar.new],
  LinterLintCode.unnecessary_getters_setters: [MakeFieldPublic.new],
  LinterLintCode.unnecessary_ignore_name: [RemoveIgnoredDiagnostic.new],
  LinterLintCode.unnecessary_ignore_name_file: [RemoveIgnoredDiagnostic.new],
  LinterLintCode.unnecessary_ignore: [RemoveComment.ignore],
  LinterLintCode.unnecessary_ignore_file: [RemoveComment.ignore],
  LinterLintCode.unnecessary_lambdas: [ReplaceWithTearOff.new],
  LinterLintCode.unnecessary_late: [RemoveUnnecessaryLate.new],
  LinterLintCode.unnecessary_library_directive: [
    RemoveUnnecessaryLibraryDirective.new,
  ],
  LinterLintCode.unnecessary_library_name: [RemoveLibraryName.new],
  LinterLintCode.unnecessary_new: [RemoveUnnecessaryNew.new],
  LinterLintCode.unnecessary_null_aware_assignments: [RemoveAssignment.new],
  LinterLintCode.unnecessary_null_checks: [RemoveNonNullAssertion.new],
  LinterLintCode.unnecessary_null_in_if_null_operators: [
    RemoveIfNullOperator.new,
  ],
  LinterLintCode.unnecessary_nullable_for_final_variable_declarations: [
    RemoveQuestionMark.new,
  ],
  LinterLintCode.unnecessary_overrides: [RemoveMethodDeclaration.new],
  LinterLintCode.unnecessary_parenthesis: [RemoveUnnecessaryParentheses.new],
  LinterLintCode.unnecessary_raw_strings: [RemoveUnnecessaryRawString.new],
  LinterLintCode.unnecessary_string_escapes: [
    RemoveUnnecessaryStringEscape.new,
  ],
  LinterLintCode.unnecessary_string_interpolations: [
    RemoveUnnecessaryStringInterpolation.new,
  ],
  LinterLintCode.unnecessary_to_list_in_spreads: [RemoveToList.new],
  LinterLintCode.unnecessary_this: [RemoveThisExpression.new],
  LinterLintCode.unnecessary_unawaited: [RemoveUnawaited.new],
  LinterLintCode.unnecessary_underscores: [ConvertToWildcardVariable.new],
  LinterLintCode.unreachable_from_main: [RemoveUnusedElement.new],
  LinterLintCode.use_colored_box: [ReplaceContainerWithColoredBox.new],
  LinterLintCode.use_decorated_box: [ReplaceWithDecoratedBox.new],
  LinterLintCode.use_enums: [ConvertClassToEnum.new],
  LinterLintCode.use_full_hex_values_for_flutter_colors: [
    ReplaceWithEightDigitHex.new,
  ],
  LinterLintCode.use_function_type_syntax_for_parameters: [
    ConvertToGenericFunctionSyntax.new,
  ],
  LinterLintCode.use_if_null_to_convert_nulls_to_bools: [
    ConvertToIfNull.useToConvertNullsToBools,
  ],
  LinterLintCode.use_key_in_widget_constructors: [AddKeyToConstructors.new],
  LinterLintCode.use_named_constants: [ReplaceWithNamedConstant.new],
  LinterLintCode.use_null_aware_elements: [
    ConvertNullCheckToNullAwareElementOrEntry.new,
  ],
  LinterLintCode.use_raw_strings: [ConvertToRawString.new],
  LinterLintCode.use_rethrow_when_possible: [UseRethrow.new],
  LinterLintCode.use_string_in_part_of_directives: [
    ReplaceWithPartOrUriEmpty.new,
  ],
  LinterLintCode.use_super_parameters_single: [ConvertToSuperParameters.new],
  LinterLintCode.use_super_parameters_multiple: [ConvertToSuperParameters.new],
  LinterLintCode.use_truncating_division: [UseEffectiveIntegerDivision.new],
};

final _builtInLintMultiGenerators = {
  LinterLintCode.comment_references: [
    ImportLibrary.forType,
    ImportLibrary.forExtension,
  ],
  LinterLintCode.deprecated_member_use_from_same_package_without_message: [
    DataDriven.new,
  ],
  LinterLintCode.deprecated_member_use_from_same_package_with_message: [
    DataDriven.new,
  ],
};

final _builtInNonLintGenerators = <DiagnosticCode, List<ProducerGenerator>>{
  CompileTimeErrorCode.abstractFieldInitializer: [
    RemoveAbstract.new,
    RemoveInitializer.new,
  ],
  CompileTimeErrorCode.abstractFieldConstructorInitializer: [
    RemoveAbstract.new,
    RemoveInitializer.new,
  ],
  CompileTimeErrorCode.assertInRedirectingConstructor: [RemoveAssertion.new],
  CompileTimeErrorCode.assignmentToFinal: [MakeFieldNotFinal.new, AddLate.new],
  CompileTimeErrorCode.assignmentToFinalLocal: [MakeVariableNotFinal.new],
  CompileTimeErrorCode.argumentTypeNotAssignable: [
    AddExplicitCast.new,
    AddNullCheck.new,
    WrapInText.new,
    AddAwait.argumentType,
  ],
  CompileTimeErrorCode.asyncForInWrongContext: [AddAsync.new],
  CompileTimeErrorCode.augmentationModifierExtra: [RemoveLexeme.modifier],
  CompileTimeErrorCode.awaitInLateLocalVariableInitializer: [RemoveLate.new],
  CompileTimeErrorCode.awaitInWrongContext: [AddAsync.new],
  CompileTimeErrorCode.bodyMightCompleteNormally: [AddAsync.missingReturn],
  CompileTimeErrorCode.castToNonType: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.classInstantiationAccessToStaticMember: [
    RemoveTypeArguments.new,
  ],
  CompileTimeErrorCode.concreteClassWithAbstractMember: [
    ConvertIntoBlockBody.missingBody,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.constInitializedWithNonConstantValue: [
    RemoveConst.new,
    RemoveNew.new,
  ],
  CompileTimeErrorCode.constInstanceField: [AddStatic.new],
  CompileTimeErrorCode.constWithNonConst: [RemoveConst.new],
  CompileTimeErrorCode.constWithNonType: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.constantPatternWithNonConstantExpression: [AddConst.new],
  CompileTimeErrorCode.defaultValueOnRequiredParameter: [
    RemoveDefaultValue.new,
    RemoveRequired.new,
  ],
  CompileTimeErrorCode.dotShorthandUndefinedGetter: [
    AddEnumConstant.new,
    ChangeTo.getterOrSetter,
    CreateGetter.new,
    CreateField.new,
  ],
  CompileTimeErrorCode.dotShorthandUndefinedInvocation: [
    ChangeTo.method,
    CreateConstructor.new,
    CreateMethod.method,
  ],
  CompileTimeErrorCode.emptyMapPattern: [
    ReplaceEmptyMapPattern.any,
    ReplaceEmptyMapPattern.empty,
  ],
  CompileTimeErrorCode.enumWithAbstractMember: [
    ConvertIntoBlockBody.missingBody,
  ],
  CompileTimeErrorCode.extendsDisallowedClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.extendsNonClass: [
    ChangeTo.classOrMixin,
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.extendsTypeAliasExpandsToTypeParameter: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.extensionDeclaresMemberOfObject: [
    RemoveMethodDeclaration.new,
  ],
  CompileTimeErrorCode.extensionDeclaresInstanceField: [ConvertIntoGetter.new],
  CompileTimeErrorCode.extensionTypeDeclaresMemberOfObject: [
    RemoveMethodDeclaration.new,
  ],
  CompileTimeErrorCode.extensionTypeDeclaresInstanceField: [
    ConvertIntoGetter.new,
  ],
  CompileTimeErrorCode.extensionOverrideAccessToStaticMember: [
    ReplaceWithExtensionName.new,
  ],
  CompileTimeErrorCode.extensionOverrideWithCascade: [
    ReplaceCascadeWithDot.new,
  ],
  CompileTimeErrorCode.extensionTypeWithAbstractMember: [
    ConvertIntoBlockBody.missingBody,
  ],
  CompileTimeErrorCode.extraPositionalArguments: [CreateConstructor.new],
  CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed: [
    CreateConstructor.new,
    ConvertToNamedArguments.new,
  ],
  CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.finalNotInitialized: [
    AddLate.new,
    CreateConstructorForFinalFields.requiredNamed,
    CreateConstructorForFinalFields.requiredPositional,
  ],
  CompileTimeErrorCode.finalNotInitializedConstructor1: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  CompileTimeErrorCode.finalNotInitializedConstructor2: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  CompileTimeErrorCode.finalNotInitializedConstructor3Plus: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  CompileTimeErrorCode.forInOfInvalidType: [AddAwait.forIn],
  CompileTimeErrorCode.illegalAsyncGeneratorReturnType: [
    ReplaceReturnTypeStream.new,
  ],
  CompileTimeErrorCode.illegalAsyncReturnType: [
    ReplaceReturnTypeFuture.new,
    RemoveAsync.new,
  ],
  CompileTimeErrorCode.illegalSyncGeneratorReturnType: [
    ReplaceReturnTypeIterable.new,
  ],
  CompileTimeErrorCode.implementsDisallowedClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.implementsNonClass: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.implementsRepeated: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.implementsSuperClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.implementsTypeAliasExpandsToTypeParameter: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.implicitSuperInitializerMissingArguments: [
    AddSuperParameter.new,
  ],
  CompileTimeErrorCode.implicitThisReferenceInInitializer: [
    ConvertIntoGetter.implicitThis,
    AddLate.implicitThis,
  ],
  CompileTimeErrorCode.importOfNonLibrary: [RemoveUnusedImport.new],
  CompileTimeErrorCode.importInternalLibrary: [RemoveUnusedImport.new],
  CompileTimeErrorCode.initializingFormalForNonExistentField: [
    ChangeTo.field,
    CreateField.new,
  ],
  CompileTimeErrorCode.instanceAccessToStaticMember: [ChangeToStaticAccess.new],
  CompileTimeErrorCode.integerLiteralImpreciseAsDouble: [
    ChangeToNearestPreciseValue.new,
  ],
  CompileTimeErrorCode.invalidAnnotation: [ChangeTo.annotation],
  CompileTimeErrorCode.invalidAssignment: [
    AddExplicitCast.new,
    AddNullCheck.new,
    ChangeTypeAnnotation.new,
    MakeVariableNullable.new,
    AddAwait.assignment,
  ],
  CompileTimeErrorCode.invalidConstant: [RemoveConst.new],
  CompileTimeErrorCode.invalidModifierOnConstructor: [RemoveLexeme.modifier],
  CompileTimeErrorCode.invalidModifierOnSetter: [RemoveLexeme.modifier],
  CompileTimeErrorCode.invalidUseOfCovariant: [RemoveLexeme.keyword],
  CompileTimeErrorCode.invocationOfNonFunctionExpression: [
    RemoveParenthesesInGetterInvocation.new,
  ],
  CompileTimeErrorCode.lateFinalLocalAlreadyAssigned: [
    MakeVariableNotFinal.new,
  ],
  CompileTimeErrorCode.listElementTypeNotAssignableNullability: [
    ConvertToNullAwareListElement.new,
  ],
  CompileTimeErrorCode.mapKeyTypeNotAssignableNullability: [
    ConvertToNullAwareMapEntryKey.new,
  ],
  CompileTimeErrorCode.mapValueTypeNotAssignableNullability: [
    ConvertToNullAwareMapEntryValue.new,
  ],
  CompileTimeErrorCode.missingDefaultValueForParameter: [
    AddRequiredKeyword.new,
    MakeVariableNullable.new,
  ],
  CompileTimeErrorCode.missingDefaultValueForParameterPositional: [
    MakeVariableNullable.new,
  ],
  CompileTimeErrorCode.missingDefaultValueForParameterWithAnnotation: [
    AddRequiredKeyword.new,
  ],
  CompileTimeErrorCode.missingRequiredArgument: [
    AddMissingRequiredArgument.new,
  ],
  CompileTimeErrorCode.mixinApplicationNotImplementedInterface: [
    ExtendClassForMixin.new,
  ],
  CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject: [
    RemoveExtendsClause.new,
  ],
  CompileTimeErrorCode.mixinSubtypeOfBaseIsNotBase: [
    AddClassModifier.baseModifier,
  ],
  CompileTimeErrorCode.mixinSubtypeOfFinalIsNotBase: [
    AddClassModifier.baseModifier,
  ],
  CompileTimeErrorCode.mixinOfDisallowedClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.mixinOfNonClass: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.mixinSuperClassConstraintNonInterface: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.newWithNonType: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.newWithUndefinedConstructor: [CreateConstructor.new],
  CompileTimeErrorCode.noAnnotationConstructorArguments: [
    AddEmptyArgumentList.new,
  ],
  CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFivePlus: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFour: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberThree: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberTwo: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.nonBoolCondition: [AddNeNull.new, AddAwait.nonBool],
  CompileTimeErrorCode.nonConstGenerativeEnumConstructor: [AddConst.new],
  CompileTimeErrorCode.nonConstantListElement: [RemoveConst.new],
  CompileTimeErrorCode.nonConstantListElementFromDeferredLibrary: [
    RemoveConst.new,
  ],
  CompileTimeErrorCode.nonConstantMapElement: [RemoveConst.new],
  CompileTimeErrorCode.nonConstantMapKey: [RemoveConst.new],
  CompileTimeErrorCode.nonConstantMapKeyFromDeferredLibrary: [RemoveConst.new],
  CompileTimeErrorCode.nonConstantMapPatternKey: [AddConst.new],
  CompileTimeErrorCode.nonConstantMapValue: [RemoveConst.new],
  CompileTimeErrorCode.nonConstantMapValueFromDeferredLibrary: [
    RemoveConst.new,
  ],
  CompileTimeErrorCode.nonConstantRelationalPatternExpression: [AddConst.new],
  CompileTimeErrorCode.nonConstantSetElement: [RemoveConst.new],
  CompileTimeErrorCode.nonExhaustiveSwitchExpression: [
    AddMissingSwitchCases.new,
  ],
  CompileTimeErrorCode.nonExhaustiveSwitchStatement: [
    AddMissingSwitchCases.new,
  ],
  CompileTimeErrorCode.nonFinalFieldInEnum: [MakeFinal.new],
  CompileTimeErrorCode.notAType: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.notInitializedNonNullableInstanceField: [AddLate.new],
  CompileTimeErrorCode.nullableTypeInExtendsClause: [RemoveQuestionMark.new],
  CompileTimeErrorCode.nullableTypeInImplementsClause: [RemoveQuestionMark.new],
  CompileTimeErrorCode.nullableTypeInOnClause: [RemoveQuestionMark.new],
  CompileTimeErrorCode.nullableTypeInWithClause: [RemoveQuestionMark.new],
  CompileTimeErrorCode.obsoleteColonForDefaultValue: [
    ReplaceColonWithEquals.new,
  ],
  CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma: [
    AddTrailingComma.new,
  ],
  CompileTimeErrorCode.returnOfInvalidTypeFromClosure: [
    AddAsync.wrongReturnType,
  ],
  CompileTimeErrorCode.returnOfInvalidTypeFromFunction: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  CompileTimeErrorCode.returnOfInvalidTypeFromMethod: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  CompileTimeErrorCode.setElementFromDeferredLibrary: [RemoveConst.new],
  CompileTimeErrorCode.setElementTypeNotAssignableNullability: [
    ConvertToNullAwareSetElement.new,
  ],
  CompileTimeErrorCode.spreadExpressionFromDeferredLibrary: [RemoveConst.new],
  CompileTimeErrorCode.subtypeOfBaseIsNotBaseFinalOrSealed: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  CompileTimeErrorCode.subtypeOfFinalIsNotBaseFinalOrSealed: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  CompileTimeErrorCode.superFormalParameterTypeIsNotSubtypeOfAssociated: [
    RemoveTypeAnnotation.other,
  ],
  CompileTimeErrorCode.superFormalParameterWithoutAssociatedNamed: [
    ChangeTo.superFormalParameter,
  ],
  CompileTimeErrorCode.superInvocationNotLast: [MakeSuperInvocationLast.new],
  CompileTimeErrorCode.switchCaseCompletesNormally: [AddSwitchCaseBreak.new],
  CompileTimeErrorCode.typeTestWithUndefinedName: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.uncheckedInvocationOfNullableValue: [AddNullCheck.new],
  CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
    CreateExtensionMethod.new,
  ],
  CompileTimeErrorCode.uncheckedOperatorInvocationOfNullableValue: [
    AddNullCheck.new,
    CreateExtensionOperator.new,
    CreateOperator.new,
  ],
  CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
    CreateExtensionGetter.new,
    CreateExtensionSetter.new,
  ],
  CompileTimeErrorCode.uncheckedUseOfNullableValueAsCondition: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.uncheckedUseOfNullableValueAsIterator: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.uncheckedUseOfNullableValueInSpread: [
    AddNullCheck.new,
    ConvertToNullAwareSpread.new,
  ],
  CompileTimeErrorCode.uncheckedUseOfNullableValueInYieldEach: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.undefinedAnnotation: [ChangeTo.annotation],
  CompileTimeErrorCode.undefinedClass: [ChangeTo.classOrMixin],
  CompileTimeErrorCode.undefinedClassBoolean: [ReplaceBooleanWithBool.new],
  CompileTimeErrorCode.undefinedEnumConstant: [
    AddEnumConstant.new,
    ChangeTo.getterOrSetter,
    CreateMethodOrFunction.new,
  ],
  CompileTimeErrorCode.undefinedEnumConstructorNamed: [CreateConstructor.new],
  CompileTimeErrorCode.undefinedEnumConstructorUnnamed: [CreateConstructor.new],
  CompileTimeErrorCode.undefinedExtensionGetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionGetter.new,
    CreateExtensionMethod.new,
  ],
  CompileTimeErrorCode.undefinedExtensionMethod: [
    ChangeTo.method,
    CreateExtensionMethod.new,
    CreateMethod.method,
  ],
  CompileTimeErrorCode.undefinedExtensionSetter: [
    ChangeTo.getterOrSetter,
    CreateSetter.new,
  ],
  CompileTimeErrorCode.undefinedFunction: [
    ChangeTo.function,
    CreateFunction.new,
  ],
  CompileTimeErrorCode.undefinedGetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionGetter.new,
    CreateField.new,
    CreateGetter.new,
    CreateLocalVariable.new,
    CreateMethodOrFunction.new,
  ],
  CompileTimeErrorCode.undefinedIdentifier: [
    ChangeTo.getterOrSetter,
    CreateField.new,
    CreateGetter.new,
    CreateLocalVariable.new,
    CreateParameter.new,
    CreateMethodOrFunction.new,
    CreateSetter.new,
    CreateExtensionGetter.new,
    CreateExtensionMethod.new,
    CreateExtensionSetter.new,
  ],
  CompileTimeErrorCode.undefinedIdentifierAwait: [AddAsync.new],
  CompileTimeErrorCode.undefinedMethod: [
    ChangeTo.method,
    CreateExtensionMethod.new,
    CreateFunction.new,
    CreateMethod.method,
  ],
  CompileTimeErrorCode.undefinedNamedParameter: [
    AddMissingParameterNamed.new,
    ConvertFlutterChild.new,
    ConvertFlutterChildren.new,
  ],
  CompileTimeErrorCode.undefinedOperator: [
    CreateExtensionOperator.new,
    CreateOperator.new,
  ],
  CompileTimeErrorCode.undefinedSetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionSetter.new,
    CreateField.new,
    CreateSetter.new,
  ],
  CompileTimeErrorCode.unqualifiedReferenceToNonLocalStaticMember: [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing _addFix methods would need to be
    //  updated so that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  CompileTimeErrorCode.unqualifiedReferenceToStaticMemberOfExtendedType: [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing producers would need to be updated so
    //  that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  CompileTimeErrorCode.uriDoesNotExist: [CreateFile.new],
  ParserErrorCode.variablePatternKeywordInDeclarationContext: [RemoveVar.new],
  CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor: [
    MoveTypeArgumentsToClass.new,
    RemoveTypeArguments.new,
  ],
  CompileTimeErrorCode.yieldOfInvalidType: [MakeReturnTypeNullable.new],
  FfiCode.subtypeOfStructClassInExtends: [RemoveNameFromDeclarationClause.new],
  FfiCode.subtypeOfStructClassInImplements: [
    RemoveNameFromDeclarationClause.new,
  ],
  FfiCode.subtypeOfStructClassInWith: [RemoveNameFromDeclarationClause.new],
  HintCode.deprecatedColonForDefaultValue: [ReplaceColonWithEquals.new],
  HintCode.unnecessaryImport: [RemoveUnusedImport.new],
  ParserErrorCode.abstractClassMember: [RemoveAbstract.bulkFixable],
  ParserErrorCode.abstractStaticField: [RemoveLexeme.modifier],
  ParserErrorCode.abstractStaticMethod: [RemoveLexeme.modifier],
  ParserErrorCode.colonInPlaceOfIn: [ReplaceColonWithIn.new],
  ParserErrorCode.constClass: [RemoveConst.new],
  ParserErrorCode.constFactory: [RemoveConst.new],
  ParserErrorCode.constMethod: [RemoveConst.new],
  ParserErrorCode.covariantMember: [RemoveLexeme.modifier],
  ParserErrorCode.defaultInSwitchExpression: [ReplaceWithWildcard.new],
  ParserErrorCode.duplicatedModifier: [RemoveLexeme.modifier],
  ParserErrorCode.emptyRecordLiteralWithComma: [RemoveComma.emptyRecordLiteral],
  ParserErrorCode.emptyRecordTypeWithComma: [RemoveComma.emptyRecordType],
  ParserErrorCode.expectedCatchClauseBody: [InsertBody.new],
  ParserErrorCode.expectedClassBody: [InsertBody.new],
  ParserErrorCode.expectedExtensionBody: [InsertBody.new],
  ParserErrorCode.expectedExtensionTypeBody: [InsertBody.new],
  ParserErrorCode.expectedFinallyClauseBody: [InsertBody.new],
  ParserErrorCode.expectedMixinBody: [InsertBody.new],
  ParserErrorCode.expectedSwitchExpressionBody: [InsertBody.new],
  ParserErrorCode.expectedSwitchStatementBody: [InsertBody.new],
  ParserErrorCode.expectedTryStatementBody: [InsertBody.new],
  ParserErrorCode.expectedToken: [
    InsertSemicolon.new,
    ReplaceWithArrow.new,
    InsertOnKeyword.new,
  ],
  ParserErrorCode.extensionAugmentationHasOnClause: [RemoveOnClause.new],
  ParserErrorCode.extensionDeclaresConstructor: [RemoveConstructor.new],
  ParserErrorCode.externalClass: [RemoveLexeme.modifier],
  ParserErrorCode.externalEnum: [RemoveLexeme.modifier],
  ParserErrorCode.externalTypedef: [RemoveLexeme.modifier],
  ParserErrorCode.extraneousModifier: [RemoveLexeme.modifier],
  ParserErrorCode.factoryTopLevelDeclaration: [RemoveLexeme.modifier],
  ParserErrorCode.finalEnum: [RemoveLexeme.modifier],
  ParserErrorCode.finalConstructor: [RemoveLexeme.modifier],
  ParserErrorCode.finalMethod: [RemoveLexeme.modifier],
  ParserErrorCode.finalMixin: [RemoveLexeme.modifier],
  ParserErrorCode.finalMixinClass: [RemoveLexeme.modifier],
  ParserErrorCode.getterConstructor: [RemoveLexeme.keyword],
  ParserErrorCode.getterWithParameters: [
    RemoveParametersInGetterDeclaration.new,
  ],
  ParserErrorCode.interfaceMixin: [RemoveLexeme.modifier],
  ParserErrorCode.interfaceMixinClass: [RemoveLexeme.modifier],
  ParserErrorCode.invalidConstantPatternBinary: [AddConst.new],
  ParserErrorCode.invalidConstantPatternGeneric: [AddConst.new],
  ParserErrorCode.invalidConstantPatternNegation: [AddConst.new],
  ParserErrorCode.invalidInsideUnaryPattern: [SurroundWithParentheses.new],
  ParserErrorCode.invalidUseOfCovariantInExtension: [RemoveLexeme.modifier],
  ParserErrorCode.latePatternVariableDeclaration: [RemoveLate.new],
  ParserErrorCode.literalWithNew: [RemoveLexeme.keyword],
  ParserErrorCode.missingConstFinalVarOrType: [AddTypeAnnotation.new],
  ParserErrorCode.missingEnumBody: [InsertBody.new],
  ParserErrorCode.missingFunctionBody: [ConvertIntoBlockBody.missingBody],
  ParserErrorCode.missingTypedefParameters: [AddEmptyArgumentList.new],
  ParserErrorCode.mixinDeclaresConstructor: [RemoveConstructor.new],
  ParserErrorCode.patternAssignmentDeclaresVariable: [RemoveVarKeyword.new],
  ParserErrorCode.recordLiteralOnePositionalNoTrailingComma: [
    AddTrailingComma.new,
  ],
  ParserErrorCode.recordTypeOnePositionalNoTrailingComma: [
    AddTrailingComma.new,
  ],
  ParserErrorCode.representationFieldTrailingComma: [
    RemoveComma.representationField,
  ],
  ParserErrorCode.sealedMixin: [RemoveLexeme.modifier],
  ParserErrorCode.sealedMixinClass: [RemoveLexeme.modifier],
  ParserErrorCode.setterConstructor: [RemoveLexeme.keyword],
  ParserErrorCode.staticConstructor: [RemoveLexeme.keyword],
  ParserErrorCode.staticGetterWithoutBody: [ConvertIntoBlockBody.missingBody],
  ParserErrorCode.staticSetterWithoutBody: [ConvertIntoBlockBody.missingBody],
  ParserErrorCode.staticOperator: [RemoveLexeme.keyword],
  ParserErrorCode.varAndType: [
    RemoveTypeAnnotation.fixVarAndType,
    RemoveVar.new,
  ],
  ParserErrorCode.varAsTypeName: [ReplaceVarWithDynamic.new],
  ParserErrorCode.varReturnType: [RemoveVar.new],
  ParserErrorCode.wrongSeparatorForPositionalParameter: [
    ReplaceColonWithEquals.new,
  ],
  ScannerErrorCode.unexpectedSeparatorInNumber: [
    RemoveUnexpectedUnderscores.new,
  ],
  StaticWarningCode.deadNullAwareExpression: [RemoveDeadIfNull.new],
  StaticWarningCode.invalidNullAwareElement: [
    ReplaceWithNotNullAwareElementOrEntry.entry,
  ],
  StaticWarningCode.invalidNullAwareMapEntryKey: [
    ReplaceWithNotNullAwareElementOrEntry.mapKey,
  ],
  StaticWarningCode.invalidNullAwareMapEntryValue: [
    ReplaceWithNotNullAwareElementOrEntry.mapValue,
  ],
  StaticWarningCode.invalidNullAwareOperator: [ReplaceWithNotNullAware.new],
  StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit: [
    ReplaceWithNotNullAware.new,
  ],
  StaticWarningCode.missingEnumConstantInSwitch: [
    AddMissingEnumCaseClauses.new,
  ],
  StaticWarningCode.unnecessaryNonNullAssertion: [RemoveNonNullAssertion.new],
  StaticWarningCode.unnecessaryNullCheckPattern: [RemoveQuestionMark.new],
  StaticWarningCode.unnecessaryNullAssertPattern: [RemoveNonNullAssertion.new],
  WarningCode.bodyMightCompleteNormallyNullable: [AddReturnNull.new],
  WarningCode.deadCode: [RemoveDeadCode.new],
  WarningCode.deadCodeCatchFollowingCatch: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  WarningCode.deadCodeLateWildcardVariableInitializer: [
    RemoveInitializer.notLate,
    RemoveLate.new,
  ],
  WarningCode.deadCodeOnCatchSubtype: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  WarningCode.deprecatedExtend: [RemoveExtendsClause.new],
  WarningCode.deprecatedImplement: [RemoveNameFromDeclarationClause.new],
  WarningCode.deprecatedImplementsFunction: [
    RemoveNameFromDeclarationClause.new,
  ],
  WarningCode.deprecatedNewInCommentReference: [
    RemoveDeprecatedNewInCommentReference.new,
  ],
  WarningCode.deprecatedSubclass: [RemoveNameFromDeclarationClause.new],
  WarningCode.duplicateHiddenName: [RemoveNameFromCombinator.new],
  WarningCode.duplicateImport: [RemoveUnusedImport.new],
  WarningCode.duplicateShownName: [RemoveNameFromCombinator.new],
  WarningCode.invalidAnnotationTarget: [RemoveAnnotation.new],
  WarningCode.invalidInternalAnnotation: [RemoveAnnotation.new],
  WarningCode.invalidLiteralAnnotation: [RemoveAnnotation.new],
  WarningCode.invalidNonVirtualAnnotation: [RemoveAnnotation.new],
  WarningCode.invalidReopenAnnotation: [RemoveAnnotation.new],
  WarningCode.invalidRequiredNamedParam: [RemoveAnnotation.new],
  WarningCode.invalidRequiredOptionalPositionalParam: [RemoveAnnotation.new],
  WarningCode.invalidRequiredPositionalParam: [RemoveAnnotation.new],
  WarningCode.invalidVisibilityAnnotation: [RemoveAnnotation.new],
  WarningCode.invalidVisibleForOverridingAnnotation: [RemoveAnnotation.new],
  WarningCode.missingOverrideOfMustBeOverriddenOne: [
    CreateMissingOverrides.new,
  ],
  WarningCode.missingOverrideOfMustBeOverriddenTwo: [
    CreateMissingOverrides.new,
  ],
  WarningCode.missingOverrideOfMustBeOverriddenThreePlus: [
    CreateMissingOverrides.new,
  ],
  WarningCode.missingRequiredParam: [AddMissingRequiredArgument.new],
  WarningCode.missingRequiredParamWithDetails: [AddMissingRequiredArgument.new],
  WarningCode.mustCallSuper: [AddCallSuper.new],
  WarningCode.nonConstCallToLiteralConstructorUsingNew: [
    ReplaceNewWithConst.new,
  ],
  WarningCode.nullCheckAlwaysFails: [RemoveNonNullAssertion.new],
  WarningCode.nullableTypeInCatchClause: [RemoveQuestionMark.new],
  WarningCode.overrideOnNonOverridingField: [RemoveAnnotation.new],
  WarningCode.overrideOnNonOverridingGetter: [RemoveAnnotation.new],
  WarningCode.overrideOnNonOverridingMethod: [RemoveAnnotation.new],
  WarningCode.overrideOnNonOverridingSetter: [RemoveAnnotation.new],
  WarningCode.redeclareOnNonRedeclaringMember: [RemoveAnnotation.new],
  WarningCode.sdkVersionGtGtGtOperator: [UpdateSdkConstraints.version_2_14_0],
  WarningCode.textDirectionCodePointInComment: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  WarningCode.textDirectionCodePointInLiteral: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  WarningCode.typeCheckIsNotNull: [UseNotEqNull.new],
  WarningCode.typeCheckIsNull: [UseEqEqNull.new],
  WarningCode.undefinedHiddenName: [RemoveNameFromCombinator.new],
  WarningCode.undefinedShownName: [RemoveNameFromCombinator.new],
  WarningCode.unnecessaryCast: [RemoveUnnecessaryCast.new],
  WarningCode.unnecessaryFinal: [RemoveUnnecessaryFinal.new],
  WarningCode.unnecessaryNanComparisonFalse: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  WarningCode.unnecessaryNanComparisonTrue: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  WarningCode.unnecessaryNullComparisonAlwaysNullFalse: [RemoveComparison.new],
  WarningCode.unnecessaryNullComparisonAlwaysNullTrue: [RemoveComparison.new],
  WarningCode.unnecessaryNullComparisonNeverNullFalse: [RemoveComparison.new],
  WarningCode.unnecessaryNullComparisonNeverNullTrue: [RemoveComparison.new],
  WarningCode.unnecessaryQuestionMark: [RemoveQuestionMark.new],
  WarningCode.unnecessarySetLiteral: [ConvertIntoBlockBody.setLiteral],
  WarningCode.unnecessaryTypeCheckFalse: [RemoveComparison.typeCheck],
  WarningCode.unnecessaryTypeCheckTrue: [RemoveComparison.typeCheck],
  WarningCode.unnecessaryWildcardPattern: [
    RemoveUnnecessaryWildcardPattern.new,
  ],
  WarningCode.unreachableSwitchCase: [RemoveDeadCode.new],
  WarningCode.unreachableSwitchDefault: [RemoveDeadCode.new],
  WarningCode.unusedCatchClause: [RemoveUnusedCatchClause.new],
  WarningCode.unusedCatchStack: [RemoveUnusedCatchStack.new],
  WarningCode.unusedElement: [RemoveUnusedElement.new],
  WarningCode.unusedElementParameter: [RemoveUnusedParameter.new],
  WarningCode.unusedField: [RemoveUnusedField.new],
  WarningCode.unusedImport: [RemoveUnusedImport.new],
  WarningCode.unusedLabel: [RemoveUnusedLabel.new],
  WarningCode.unusedLocalVariable: [
    RemoveUnusedLocalVariable.new,
    ConvertToWildcardVariable.new,
  ],
  WarningCode.unusedShownName: [
    OrganizeImports.new,
    RemoveNameFromCombinator.new,
  ],
};

final _builtInNonLintMultiGenerators = {
  CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo: [
    AddExtensionOverride.new,
  ],
  CompileTimeErrorCode.ambiguousExtensionMemberAccessThreeOrMore: [
    AddExtensionOverride.new,
  ],
  CompileTimeErrorCode.ambiguousImport: [AmbiguousImportFix.new],
  CompileTimeErrorCode.argumentTypeNotAssignable: [DataDriven.new],
  CompileTimeErrorCode.castToNonType: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.constWithNonType: [
    CreateClass.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.extendsNonClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.extraPositionalArguments: [
    AddMissingParameter.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed: [
    AddMissingParameter.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.implementsNonClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.implicitSuperInitializerMissingArguments: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.invalidAnnotation: [
    CreateClass.new,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.invalidOverride: [DataDriven.new],
  CompileTimeErrorCode.invalidOverrideSetter: [DataDriven.new],
  CompileTimeErrorCode.missingRequiredArgument: [DataDriven.new],
  CompileTimeErrorCode.mixinOfNonClass: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.mixinWithNonClassSuperclass: [
    CreateClass.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.newWithNonType: [CreateClass.new, ImportLibrary.forType],
  CompileTimeErrorCode.newWithUndefinedConstructorDefault: [DataDriven.new],
  CompileTimeErrorCode.noDefaultSuperConstructorExplicit: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.noDefaultSuperConstructorImplicit: [
    AddSuperConstructorInvocation.new,
    CreateConstructorSuper.new,
  ],
  CompileTimeErrorCode.nonTypeInCatchClause: [ImportLibrary.forType],
  CompileTimeErrorCode.nonTypeAsTypeArgument: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.notAType: [
    CreateClass.new,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural: [DataDriven.new],
  CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.notEnoughPositionalArgumentsPlural: [DataDriven.new],
  CompileTimeErrorCode.notEnoughPositionalArgumentsSingular: [DataDriven.new],
  CompileTimeErrorCode.typeTestWithUndefinedName: [
    CreateClass.new,
    CreateMixin.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  CompileTimeErrorCode.uncheckedOperatorInvocationOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  CompileTimeErrorCode.undefinedAnnotation: [
    CreateClass.new,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.undefinedClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.undefinedConstructorInInitializerDefault: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.undefinedExtensionGetter: [DataDriven.new],
  CompileTimeErrorCode.undefinedFunction: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionType,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.undefinedGetter: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.undefinedIdentifier: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.undefinedMethod: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.undefinedNamedParameter: [
    ChangeArgumentName.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.undefinedOperator: [
    ImportLibrary.forExtensionMember,
    UseDifferentDivisionOperator.new,
  ],
  CompileTimeErrorCode.undefinedPrefixedName: [DataDriven.new],
  CompileTimeErrorCode.undefinedSetter: [
    DataDriven.new,
    // TODO(brianwilkerson): Support ImportLibrary for non-extension members.
    ImportLibrary.forExtensionMember,
  ],
  CompileTimeErrorCode.wrongNumberOfTypeArguments: [DataDriven.new],
  CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor: [DataDriven.new],
  CompileTimeErrorCode.wrongNumberOfTypeArgumentsExtension: [DataDriven.new],
  CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod: [DataDriven.new],
  HintCode.deprecatedMemberUse: [DataDriven.new],
  HintCode.deprecatedMemberUseWithMessage: [DataDriven.new],
  WarningCode.deprecatedExportUse: [DataDriven.new],
  WarningCode.multipleCombinators: [MergeCombinators.new],
  WarningCode.overrideOnNonOverridingMethod: [DataDriven.new],
};

final _builtInParseLintGenerators = <LintCode, List<ProducerGenerator>>{
  LinterLintCode.prefer_generic_function_type_aliases: [
    ConvertToGenericFunctionSyntax.new,
  ],
  LinterLintCode.slash_for_doc_comments: [ConvertDocumentationIntoLine.new],
  LinterLintCode.unnecessary_const: [RemoveUnnecessaryConst.new],
  LinterLintCode.unnecessary_new: [RemoveUnnecessaryNew.new],
  LinterLintCode.unnecessary_string_escapes: [
    RemoveUnnecessaryStringEscape.new,
  ],
  LinterLintCode.use_function_type_syntax_for_parameters: [
    ConvertToGenericFunctionSyntax.new,
  ],
};

/// Registers each mapping of diagnostic -> list-of-producer-generators with
/// [FixProcessor].
void registerBuiltInFixGenerators() {
  // This function can be called many times during test runs so these statements
  // should not result in duplicate producers (i.e. they should only add to maps
  // or sets or otherwise ensure producers that already exist are not added).

  registeredFixGenerators.lintMultiProducers.addAll(
    _builtInLintMultiGenerators,
  );
  registeredFixGenerators.lintProducers.addAll(_builtInLintGenerators);
  registeredFixGenerators.nonLintMultiProducers.addAll(
    _builtInNonLintMultiGenerators,
  );
  registeredFixGenerators.nonLintProducers.addAll(_builtInNonLintGenerators);
  registeredFixGenerators.parseLintProducers.addAll(
    _builtInParseLintGenerators,
  );
  registeredFixGenerators.ignoreProducerGenerators.addAll([
    IgnoreDiagnosticOnLine.new,
    IgnoreDiagnosticInFile.new,
    IgnoreDiagnosticInAnalysisOptionsFile.new,
  ]);
}
