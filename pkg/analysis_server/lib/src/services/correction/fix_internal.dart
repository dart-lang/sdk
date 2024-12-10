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
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_related_to_cascade.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_boolean_expression.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_cascade.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_constant_pattern.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_flutter_style_todo.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_function_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_null.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_initializing_formal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_named_arguments.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
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
import 'package:analysis_server/src/services/correction/dart/create_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/create_setter.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/extend_class_for_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/extract_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_remove_widget.dart';
import 'package:analysis_server/src/services/correction/dart/ignore_diagnostic.dart';
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
import 'package:analysis_server/src/services/correction/dart/remove_await.dart';
import 'package:analysis_server/src/services/correction/dart/remove_break.dart';
import 'package:analysis_server/src/services/correction/dart/remove_character.dart';
import 'package:analysis_server/src/services/correction/dart/remove_comma.dart';
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
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/ffi_code.g.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:linter/src/lint_codes.dart';

final _builtInLintMultiProducers = {
  LinterLintCode.comment_references: [ImportLibrary.forType],
  LinterLintCode.deprecated_member_use_from_same_package_without_message: [
    DataDriven.new,
  ],
  LinterLintCode.deprecated_member_use_from_same_package_with_message: [
    DataDriven.new,
  ],
};

final _builtInLintProducers = <LintCode, List<ProducerGenerator>>{
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
  LinterLintCode.avoid_types_as_parameter_names: [ConvertToOnType.new],
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
  LinterLintCode.discarded_futures: [AddAsync.new, WrapInUnawaited.new],
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
  LinterLintCode.omit_local_variable_types: [ReplaceWithVar.new],
  LinterLintCode.omit_obvious_local_variable_types: [ReplaceWithVar.new],
  LinterLintCode.omit_obvious_property_types: [ReplaceWithVar.new],
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
  LinterLintCode.prefer_function_declarations_over_variables: [
    ConvertToFunctionDeclaration.new,
  ],
  LinterLintCode.prefer_generic_function_type_aliases: [
    ConvertToGenericFunctionSyntax.new,
  ],
  LinterLintCode.prefer_if_elements_to_conditional_expressions: [
    ConvertConditionalExpressionToIfElement.new,
  ],
  LinterLintCode.prefer_if_null_operators: [ConvertToIfNull.new],
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
  LinterLintCode.type_annotate_public_apis: [AddTypeAnnotation.bulkFixable],
  LinterLintCode.type_init_formals: [RemoveTypeAnnotation.other],
  LinterLintCode.type_literal_in_constant_pattern: [
    ConvertToConstantPattern.new,
    ConvertToWildcardPattern.new,
  ],
  LinterLintCode.unawaited_futures: [AddAwait.unawaited, WrapInUnawaited.new],
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
  LinterLintCode.use_key_in_widget_constructors: [AddKeyToConstructors.new],
  LinterLintCode.use_named_constants: [ReplaceWithNamedConstant.new],
  LinterLintCode.use_raw_strings: [ConvertToRawString.new],
  LinterLintCode.use_rethrow_when_possible: [UseRethrow.new],
  LinterLintCode.use_string_in_part_of_directives: [
    ReplaceWithPartOrUriEmpty.new,
  ],
  LinterLintCode.use_super_parameters_single: [ConvertToSuperParameters.new],
  LinterLintCode.use_super_parameters_multiple: [ConvertToSuperParameters.new],
  LinterLintCode.use_truncating_division: [UseEffectiveIntegerDivision.new],
};

final _builtInNonLintMultiProducers = {
  CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO: [
    AddExtensionOverride.new,
  ],
  CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_THREE_OR_MORE: [
    AddExtensionOverride.new,
  ],
  CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [DataDriven.new],
  CompileTimeErrorCode.CAST_TO_NON_TYPE: [
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.CONST_WITH_NON_TYPE: [ImportLibrary.forType],
  CompileTimeErrorCode.EXTENDS_NON_CLASS: [
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
    AddMissingParameter.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
    AddMissingParameter.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.INVALID_ANNOTATION: [
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.INVALID_OVERRIDE: [DataDriven.new],
  CompileTimeErrorCode.INVALID_OVERRIDE_SETTER: [DataDriven.new],
  CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT: [DataDriven.new],
  CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
    DataDriven.new,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.NEW_WITH_NON_TYPE: [ImportLibrary.forType],
  CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [DataDriven.new],
  CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT: [
    AddSuperConstructorInvocation.new,
    CreateConstructorSuper.new,
  ],
  CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE: [ImportLibrary.forType],
  CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT: [
    ImportLibrary.forType,
    DataDriven.new,
  ],
  CompileTimeErrorCode.NOT_A_TYPE: [ImportLibrary.forType],
  CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL: [DataDriven.new],
  CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [ImportLibrary.forType],
  CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.UNDEFINED_CLASS: [DataDriven.new, ImportLibrary.forType],
  CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT: [
    AddSuperConstructorInvocation.new,
  ],
  CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [DataDriven.new],
  CompileTimeErrorCode.UNDEFINED_FUNCTION: [
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionType,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.UNDEFINED_GETTER: [
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.UNDEFINED_METHOD: [
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
    ChangeArgumentName.new,
    DataDriven.new,
  ],
  CompileTimeErrorCode.UNDEFINED_OPERATOR: [
    ImportLibrary.forExtensionMember,
    UseDifferentDivisionOperator.new,
  ],
  CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME: [DataDriven.new],
  CompileTimeErrorCode.UNDEFINED_SETTER: [
    DataDriven.new,
    // TODO(brianwilkerson): Support ImportLibrary for non-extension members.
    ImportLibrary.forExtensionMember,
  ],
  CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS: [DataDriven.new],
  CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION: [
    DataDriven.new,
  ],
  CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD: [DataDriven.new],
  HintCode.DEPRECATED_MEMBER_USE: [DataDriven.new],
  HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [DataDriven.new],
  WarningCode.DEPRECATED_EXPORT_USE: [DataDriven.new],
  WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [DataDriven.new],
};

final _builtInNonLintProducers = <ErrorCode, List<ProducerGenerator>>{
  CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER: [
    RemoveAbstract.new,
    RemoveInitializer.new,
  ],
  CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER: [
    RemoveAbstract.new,
    RemoveInitializer.new,
  ],
  CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR: [RemoveAssertion.new],
  CompileTimeErrorCode.ASSIGNMENT_TO_FINAL: [
    MakeFieldNotFinal.new,
    AddLate.new,
  ],
  CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL: [MakeVariableNotFinal.new],
  CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
    AddExplicitCast.new,
    AddNullCheck.new,
    WrapInText.new,
    AddAwait.argumentType,
  ],
  CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT: [AddAsync.new],
  CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA: [RemoveLexeme.modifier],
  CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER: [
    RemoveLate.new,
  ],
  CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT: [AddAsync.new],
  CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY: [AddAsync.missingReturn],
  CompileTimeErrorCode.CAST_TO_NON_TYPE: [
    ChangeTo.classOrMixin,
    CreateClass.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER: [
    RemoveTypeArguments.new,
  ],
  CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER: [
    ConvertIntoBlockBody.missingBody,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE: [
    RemoveConst.new,
    RemoveNew.new,
  ],
  CompileTimeErrorCode.CONST_INSTANCE_FIELD: [AddStatic.new],
  CompileTimeErrorCode.CONST_WITH_NON_CONST: [RemoveConst.new],
  CompileTimeErrorCode.CONST_WITH_NON_TYPE: [
    ChangeTo.classOrMixin,
    CreateClass.new,
  ],
  CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION: [
    AddConst.new,
  ],
  CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER: [
    RemoveDefaultValue.new,
    RemoveRequired.new,
  ],
  CompileTimeErrorCode.EMPTY_MAP_PATTERN: [
    ReplaceEmptyMapPattern.any,
    ReplaceEmptyMapPattern.empty,
  ],
  CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER: [
    ConvertIntoBlockBody.missingBody,
  ],
  CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.EXTENDS_NON_CLASS: [
    ChangeTo.classOrMixin,
    CreateClass.new,
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT: [
    RemoveMethodDeclaration.new,
  ],
  CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT: [
    RemoveMethodDeclaration.new,
  ],
  CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER: [
    ReplaceWithExtensionName.new,
  ],
  CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE: [
    ReplaceCascadeWithDot.new,
  ],
  CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER: [
    ConvertIntoBlockBody.missingBody,
  ],
  CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [CreateConstructor.new],
  CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
    CreateConstructor.new,
    ConvertToNamedArguments.new,
  ],
  CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.FINAL_NOT_INITIALIZED: [
    AddLate.new,
    CreateConstructorForFinalFields.requiredNamed,
    CreateConstructorForFinalFields.requiredPositional,
  ],
  CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1: [
    AddFieldFormalParameters.new,
  ],
  CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2: [
    AddFieldFormalParameters.new,
  ],
  CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS: [
    AddFieldFormalParameters.new,
  ],
  CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE: [
    ReplaceReturnTypeStream.new,
  ],
  CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE: [ReplaceReturnTypeFuture.new],
  CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE: [
    ReplaceReturnTypeIterable.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
    ChangeTo.classOrMixin,
    CreateClass.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_REPEATED: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS: [
    AddSuperParameter.new,
  ],
  CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY: [RemoveUnusedImport.new],
  CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY: [RemoveUnusedImport.new],
  CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD: [
    ChangeTo.field,
    CreateField.new,
  ],
  CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER: [
    ChangeToStaticAccess.new,
  ],
  CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE: [
    ChangeToNearestPreciseValue.new,
  ],
  CompileTimeErrorCode.INVALID_ANNOTATION: [
    ChangeTo.annotation,
    CreateClass.new,
  ],
  CompileTimeErrorCode.INVALID_ASSIGNMENT: [
    AddExplicitCast.new,
    AddNullCheck.new,
    ChangeTypeAnnotation.new,
    MakeVariableNullable.new,
    AddAwait.assignment,
  ],
  CompileTimeErrorCode.INVALID_CONSTANT: [RemoveConst.new],
  CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR: [RemoveLexeme.modifier],
  CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER: [RemoveLexeme.modifier],
  CompileTimeErrorCode.INVALID_USE_OF_COVARIANT: [RemoveLexeme.keyword],
  CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION: [
    RemoveParenthesesInGetterInvocation.new,
  ],
  CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED: [
    MakeVariableNotFinal.new,
  ],
  CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER: [
    AddRequiredKeyword.new,
    MakeVariableNullable.new,
  ],
  CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL: [
    MakeVariableNullable.new,
  ],
  CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION: [
    AddRequiredKeyword.new,
  ],
  CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT: [
    AddMissingRequiredArgument.new,
  ],
  CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE: [
    ExtendClassForMixin.new,
  ],
  CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT: [
    RemoveExtendsClause.new,
  ],
  CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE: [
    AddClassModifier.baseModifier,
  ],
  CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE: [
    AddClassModifier.baseModifier,
  ],
  CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
    ChangeTo.classOrMixin,
    CreateClass.new,
  ],
  CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE: [
    RemoveNameFromDeclarationClause.new,
  ],
  CompileTimeErrorCode.NEW_WITH_NON_TYPE: [
    ChangeTo.classOrMixin,
    CreateClass.new,
  ],
  CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR: [CreateConstructor.new],
  CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS: [
    AddEmptyArgumentList.new,
  ],
  CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  CompileTimeErrorCode.NON_BOOL_CONDITION: [AddNeNull.new, AddAwait.nonBool],
  CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR: [AddConst.new],
  CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY: [AddConst.new],
  CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION: [
    AddConst.new,
  ],
  CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION: [
    AddMissingSwitchCases.new,
  ],
  CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT: [
    AddMissingSwitchCases.new,
  ],
  CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM: [MakeFinal.new],
  CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT: [
    CreateClass.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.NOT_A_TYPE: [
    ChangeTo.classOrMixin,
    CreateClass.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD: [
    AddLate.new,
  ],
  CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE: [
    RemoveQuestionMark.new,
  ],
  CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE: [
    RemoveQuestionMark.new,
  ],
  CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE: [RemoveQuestionMark.new],
  CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE: [RemoveQuestionMark.new],
  CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE: [
    ReplaceColonWithEquals.new,
  ],
  CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA: [
    AddTrailingComma.new,
  ],
  CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE: [
    AddAsync.wrongReturnType,
  ],
  CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED:
      [RemoveTypeAnnotation.other],
  CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED: [
    ChangeTo.superFormalParameter,
  ],
  CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST: [MakeSuperInvocationLast.new],
  CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY: [AddSwitchCaseBreak.new],
  CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME: [
    ChangeTo.classOrMixin,
    CreateClass.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
  ],
  CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
  ],
  CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD: [
    AddNullCheck.new,
    ConvertToNullAwareSpread.new,
  ],
  CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH: [
    AddNullCheck.new,
  ],
  CompileTimeErrorCode.UNDEFINED_ANNOTATION: [
    ChangeTo.annotation,
    CreateClass.new,
  ],
  CompileTimeErrorCode.UNDEFINED_CLASS: [
    ChangeTo.classOrMixin,
    CreateClass.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN: [ReplaceBooleanWithBool.new],
  CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT: [
    AddEnumConstant.new,
    ChangeTo.getterOrSetter,
  ],
  CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED: [
    CreateConstructor.new,
  ],
  CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED: [
    CreateConstructor.new,
  ],
  CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
    ChangeTo.getterOrSetter,
    CreateGetter.new,
  ],
  CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD: [
    ChangeTo.method,
    CreateMethod.method,
  ],
  CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER: [
    ChangeTo.getterOrSetter,
    CreateSetter.new,
  ],
  CompileTimeErrorCode.UNDEFINED_FUNCTION: [
    ChangeTo.function,
    CreateClass.new,
    CreateFunction.new,
  ],
  CompileTimeErrorCode.UNDEFINED_GETTER: [
    ChangeTo.getterOrSetter,
    CreateClass.new,
    CreateExtensionGetter.new,
    CreateField.new,
    CreateGetter.new,
    CreateLocalVariable.new,
    CreateMethodOrFunction.new,
    CreateMixin.new,
  ],
  CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
    ChangeTo.getterOrSetter,
    CreateClass.new,
    CreateField.new,
    CreateGetter.new,
    CreateLocalVariable.new,
    CreateParameter.new,
    CreateMethodOrFunction.new,
    CreateMixin.new,
    CreateSetter.new,
  ],
  CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT: [AddAsync.new],
  CompileTimeErrorCode.UNDEFINED_METHOD: [
    ChangeTo.method,
    CreateClass.new,
    CreateExtensionMethod.new,
    CreateFunction.new,
    CreateMethod.method,
  ],
  CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
    AddMissingParameterNamed.new,
    ConvertFlutterChild.new,
    ConvertFlutterChildren.new,
  ],
  CompileTimeErrorCode.UNDEFINED_SETTER: [
    ChangeTo.getterOrSetter,
    CreateExtensionSetter.new,
    CreateField.new,
    CreateSetter.new,
  ],
  CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER: [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing _addFix methods would need to be
    //  updated so that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE:
      [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing producers would need to be updated so
    //  that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  CompileTimeErrorCode.URI_DOES_NOT_EXIST: [CreateFile.new],
  ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT: [
    RemoveVar.new,
  ],
  CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
    MoveTypeArgumentsToClass.new,
    RemoveTypeArguments.new,
  ],
  CompileTimeErrorCode.YIELD_OF_INVALID_TYPE: [MakeReturnTypeNullable.new],
  FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS: [
    RemoveNameFromDeclarationClause.new,
  ],
  FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS: [
    RemoveNameFromDeclarationClause.new,
  ],
  FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH: [
    RemoveNameFromDeclarationClause.new,
  ],
  HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE: [ReplaceColonWithEquals.new],
  HintCode.UNNECESSARY_IMPORT: [RemoveUnusedImport.new],
  ParserErrorCode.ABSTRACT_CLASS_MEMBER: [RemoveAbstract.bulkFixable],
  ParserErrorCode.ABSTRACT_STATIC_FIELD: [RemoveLexeme.modifier],
  ParserErrorCode.ABSTRACT_STATIC_METHOD: [RemoveLexeme.modifier],
  ParserErrorCode.COLON_IN_PLACE_OF_IN: [ReplaceColonWithIn.new],
  ParserErrorCode.CONST_CLASS: [RemoveConst.new],
  ParserErrorCode.CONST_FACTORY: [RemoveConst.new],
  ParserErrorCode.CONST_METHOD: [RemoveConst.new],
  ParserErrorCode.COVARIANT_MEMBER: [RemoveLexeme.modifier],
  ParserErrorCode.DEFAULT_IN_SWITCH_EXPRESSION: [ReplaceWithWildcard.new],
  ParserErrorCode.DUPLICATED_MODIFIER: [RemoveLexeme.modifier],
  ParserErrorCode.EMPTY_RECORD_LITERAL_WITH_COMMA: [
    RemoveComma.emptyRecordLiteral,
  ],
  ParserErrorCode.EMPTY_RECORD_TYPE_WITH_COMMA: [RemoveComma.emptyRecordType],
  ParserErrorCode.EXPECTED_CATCH_CLAUSE_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_CLASS_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_EXTENSION_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_EXTENSION_TYPE_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_FINALLY_CLAUSE_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_MIXIN_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_SWITCH_EXPRESSION_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_SWITCH_STATEMENT_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_TRY_STATEMENT_BODY: [InsertBody.new],
  ParserErrorCode.EXPECTED_TOKEN: [
    InsertSemicolon.new,
    ReplaceWithArrow.new,
    InsertOnKeyword.new,
  ],
  ParserErrorCode.EXTENSION_AUGMENTATION_HAS_ON_CLAUSE: [RemoveOnClause.new],
  ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR: [RemoveConstructor.new],
  ParserErrorCode.EXTERNAL_CLASS: [RemoveLexeme.modifier],
  ParserErrorCode.EXTERNAL_ENUM: [RemoveLexeme.modifier],
  ParserErrorCode.EXTERNAL_TYPEDEF: [RemoveLexeme.modifier],
  ParserErrorCode.EXTRANEOUS_MODIFIER: [RemoveLexeme.modifier],
  ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION: [RemoveLexeme.modifier],
  ParserErrorCode.FINAL_ENUM: [RemoveLexeme.modifier],
  ParserErrorCode.FINAL_CONSTRUCTOR: [RemoveLexeme.modifier],
  ParserErrorCode.FINAL_METHOD: [RemoveLexeme.modifier],
  ParserErrorCode.FINAL_MIXIN: [RemoveLexeme.modifier],
  ParserErrorCode.FINAL_MIXIN_CLASS: [RemoveLexeme.modifier],
  ParserErrorCode.GETTER_CONSTRUCTOR: [RemoveLexeme.keyword],
  ParserErrorCode.GETTER_WITH_PARAMETERS: [
    RemoveParametersInGetterDeclaration.new,
  ],
  ParserErrorCode.INTERFACE_MIXIN: [RemoveLexeme.modifier],
  ParserErrorCode.INTERFACE_MIXIN_CLASS: [RemoveLexeme.modifier],
  ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY: [AddConst.new],
  ParserErrorCode.INVALID_CONSTANT_PATTERN_GENERIC: [AddConst.new],
  ParserErrorCode.INVALID_CONSTANT_PATTERN_NEGATION: [AddConst.new],
  ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN: [SurroundWithParentheses.new],
  ParserErrorCode.INVALID_USE_OF_COVARIANT_IN_EXTENSION: [
    RemoveLexeme.modifier,
  ],
  ParserErrorCode.LATE_PATTERN_VARIABLE_DECLARATION: [RemoveLate.new],
  ParserErrorCode.LITERAL_WITH_NEW: [RemoveLexeme.keyword],
  ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE: [AddTypeAnnotation.new],
  ParserErrorCode.MISSING_ENUM_BODY: [InsertBody.new],
  ParserErrorCode.MISSING_FUNCTION_BODY: [ConvertIntoBlockBody.missingBody],
  ParserErrorCode.MISSING_TYPEDEF_PARAMETERS: [AddEmptyArgumentList.new],
  ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR: [RemoveConstructor.new],
  ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE: [RemoveVarKeyword.new],
  ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA: [
    AddTrailingComma.new,
  ],
  ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA: [
    AddTrailingComma.new,
  ],
  ParserErrorCode.REPRESENTATION_FIELD_TRAILING_COMMA: [
    RemoveComma.representationField,
  ],
  ParserErrorCode.SEALED_MIXIN: [RemoveLexeme.modifier],
  ParserErrorCode.SEALED_MIXIN_CLASS: [RemoveLexeme.modifier],
  ParserErrorCode.SETTER_CONSTRUCTOR: [RemoveLexeme.keyword],
  ParserErrorCode.STATIC_CONSTRUCTOR: [RemoveLexeme.keyword],
  ParserErrorCode.STATIC_GETTER_WITHOUT_BODY: [
    ConvertIntoBlockBody.missingBody,
  ],
  ParserErrorCode.STATIC_SETTER_WITHOUT_BODY: [
    ConvertIntoBlockBody.missingBody,
  ],
  ParserErrorCode.STATIC_OPERATOR: [RemoveLexeme.keyword],
  ParserErrorCode.VAR_AND_TYPE: [
    RemoveTypeAnnotation.fixVarAndType,
    RemoveVar.new,
  ],
  ParserErrorCode.VAR_AS_TYPE_NAME: [ReplaceVarWithDynamic.new],
  ParserErrorCode.VAR_RETURN_TYPE: [RemoveVar.new],
  ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER: [
    ReplaceColonWithEquals.new,
  ],
  ScannerErrorCode.UNEXPECTED_SEPARATOR_IN_NUMBER: [
    RemoveUnexpectedUnderscores.new,
  ],
  StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION: [RemoveDeadIfNull.new],
  StaticWarningCode.INVALID_NULL_AWARE_OPERATOR: [ReplaceWithNotNullAware.new],
  StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT: [
    ReplaceWithNotNullAware.new,
  ],
  StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH: [
    AddMissingEnumCaseClauses.new,
  ],
  StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION: [
    RemoveNonNullAssertion.new,
  ],
  StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN: [RemoveQuestionMark.new],
  StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN: [
    RemoveNonNullAssertion.new,
  ],
  WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE: [AddReturnNull.new],
  WarningCode.DEAD_CODE: [RemoveDeadCode.new],
  WarningCode.DEAD_CODE_CATCH_FOLLOWING_CATCH: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  WarningCode.DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER: [
    RemoveInitializer.notLate,
    RemoveLate.new,
  ],
  WarningCode.DEAD_CODE_ON_CATCH_SUBTYPE: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION: [
    RemoveNameFromDeclarationClause.new,
  ],
  WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE: [
    RemoveDeprecatedNewInCommentReference.new,
  ],
  WarningCode.DUPLICATE_HIDDEN_NAME: [RemoveNameFromCombinator.new],
  WarningCode.DUPLICATE_IMPORT: [RemoveUnusedImport.new],
  WarningCode.DUPLICATE_SHOWN_NAME: [RemoveNameFromCombinator.new],
  WarningCode.INVALID_ANNOTATION_TARGET: [RemoveAnnotation.new],
  WarningCode.INVALID_INTERNAL_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.INVALID_LITERAL_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.INVALID_NON_VIRTUAL_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.INVALID_REOPEN_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.INVALID_REQUIRED_NAMED_PARAM: [RemoveAnnotation.new],
  WarningCode.INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM: [
    RemoveAnnotation.new,
  ],
  WarningCode.INVALID_REQUIRED_POSITIONAL_PARAM: [RemoveAnnotation.new],
  WarningCode.INVALID_VISIBILITY_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION: [RemoveAnnotation.new],
  WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE: [
    CreateMissingOverrides.new,
  ],
  WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO: [
    CreateMissingOverrides.new,
  ],
  WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS: [
    CreateMissingOverrides.new,
  ],
  WarningCode.MISSING_REQUIRED_PARAM: [AddMissingRequiredArgument.new],
  WarningCode.MISSING_REQUIRED_PARAM_WITH_DETAILS: [
    AddMissingRequiredArgument.new,
  ],
  WarningCode.MUST_CALL_SUPER: [AddCallSuper.new],
  WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW: [
    ReplaceNewWithConst.new,
  ],
  WarningCode.NULL_CHECK_ALWAYS_FAILS: [RemoveNonNullAssertion.new],
  WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE: [RemoveQuestionMark.new],
  WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD: [RemoveAnnotation.new],
  WarningCode.OVERRIDE_ON_NON_OVERRIDING_GETTER: [RemoveAnnotation.new],
  WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [RemoveAnnotation.new],
  WarningCode.OVERRIDE_ON_NON_OVERRIDING_SETTER: [RemoveAnnotation.new],
  WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER: [RemoveAnnotation.new],
  WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR: [
    UpdateSdkConstraints.version_2_14_0,
  ],
  WarningCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  WarningCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  WarningCode.TYPE_CHECK_IS_NOT_NULL: [UseNotEqNull.new],
  WarningCode.TYPE_CHECK_IS_NULL: [UseEqEqNull.new],
  WarningCode.UNDEFINED_HIDDEN_NAME: [RemoveNameFromCombinator.new],
  WarningCode.UNDEFINED_SHOWN_NAME: [RemoveNameFromCombinator.new],
  WarningCode.UNNECESSARY_CAST: [RemoveUnnecessaryCast.new],
  WarningCode.UNNECESSARY_FINAL: [RemoveUnnecessaryFinal.new],
  WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_FALSE: [
    RemoveComparison.new,
  ],
  WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_TRUE: [
    RemoveComparison.new,
  ],
  WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE: [
    RemoveComparison.new,
  ],
  WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE: [
    RemoveComparison.new,
  ],
  WarningCode.UNNECESSARY_QUESTION_MARK: [RemoveQuestionMark.new],
  WarningCode.UNNECESSARY_SET_LITERAL: [ConvertIntoBlockBody.setLiteral],
  WarningCode.UNNECESSARY_TYPE_CHECK_FALSE: [RemoveComparison.typeCheck],
  WarningCode.UNNECESSARY_TYPE_CHECK_TRUE: [RemoveComparison.typeCheck],
  WarningCode.UNNECESSARY_WILDCARD_PATTERN: [
    RemoveUnnecessaryWildcardPattern.new,
  ],
  WarningCode.UNREACHABLE_SWITCH_CASE: [RemoveDeadCode.new],
  WarningCode.UNREACHABLE_SWITCH_DEFAULT: [RemoveDeadCode.new],
  WarningCode.UNUSED_CATCH_CLAUSE: [RemoveUnusedCatchClause.new],
  WarningCode.UNUSED_CATCH_STACK: [RemoveUnusedCatchStack.new],
  WarningCode.UNUSED_ELEMENT: [RemoveUnusedElement.new],
  WarningCode.UNUSED_ELEMENT_PARAMETER: [RemoveUnusedParameter.new],
  WarningCode.UNUSED_FIELD: [RemoveUnusedField.new],
  WarningCode.UNUSED_IMPORT: [RemoveUnusedImport.new],
  WarningCode.UNUSED_LABEL: [RemoveUnusedLabel.new],
  WarningCode.UNUSED_LOCAL_VARIABLE: [
    RemoveUnusedLocalVariable.new,
    ConvertToWildcardVariable.new,
  ],
  WarningCode.UNUSED_SHOWN_NAME: [
    OrganizeImports.new,
    RemoveNameFromCombinator.new,
  ],
};

final _builtInParseLintProducers = <LintCode, List<ProducerGenerator>>{
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

/// Registers each mapping of diagnostic -> list-of-producers with
/// [FixProcessor].
void registerBuiltInProducers() {
  // This function can be called many times during test runs so these statements
  // should not result in duplicate producers (i.e. they should only add to maps
  // or sets or otherwise ensure producers that already exist are not added).
  registeredFixGenerators.lintMultiProducers.addAll(_builtInLintMultiProducers);
  registeredFixGenerators.lintProducers.addAll(_builtInLintProducers);
  registeredFixGenerators.nonLintMultiProducers.addAll(
    _builtInNonLintMultiProducers,
  );
  registeredFixGenerators.nonLintProducers.addAll(_builtInNonLintProducers);
  registeredFixGenerators.parseLintProducers.addAll(_builtInParseLintProducers);
  registeredFixGenerators.ignoreProducerGenerators.addAll([
    IgnoreDiagnosticOnLine.new,
    IgnoreDiagnosticInFile.new,
    IgnoreDiagnosticInAnalysisOptionsFile.new,
  ]);
}
