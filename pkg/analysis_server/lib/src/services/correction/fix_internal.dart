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
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_name.dart';
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
import 'package:analysis_server/src/services/correction/dart/replace_with_is.dart';
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
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:linter/src/diagnostic.dart' as diag;

final _builtInLintGenerators = <DiagnosticCode, List<ProducerGenerator>>{
  diag.alwaysDeclareReturnTypesOfFunctions: [AddReturnType.new],
  diag.alwaysDeclareReturnTypesOfMethods: [AddReturnType.new],
  diag.alwaysPutControlBodyOnNewLine: [UseCurlyBraces.nonBulk],
  diag.alwaysPutRequiredNamedParametersFirst: [
    MakeRequiredNamedParametersFirst.new,
  ],
  diag.alwaysSpecifyTypesAddType: [AddTypeAnnotation.bulkFixable],
  diag.alwaysSpecifyTypesSpecifyType: [AddTypeAnnotation.bulkFixable],
  diag.alwaysSpecifyTypesReplaceKeyword: [AddTypeAnnotation.bulkFixable],
  diag.alwaysSpecifyTypesSplitToTypes: [AddTypeAnnotation.bulkFixable],
  diag.alwaysUsePackageImports: [ConvertToPackageImport.new],
  diag.annotateOverrides: [AddOverride.new],
  diag.annotateRedeclares: [AddRedeclare.new],
  diag.avoidAnnotatingWithDynamic: [RemoveTypeAnnotation.other],
  diag.avoidBoolLiteralsInConditionalExpressions: [
    ConvertToBooleanExpression.new,
  ],
  diag.avoidEmptyElse: [RemoveEmptyElse.new],
  diag.avoidEscapingInnerQuotes: [ConvertQuotes.new],
  diag.avoidFinalParameters: [RemoveLexeme.modifier],
  diag.avoidFunctionLiteralsInForeachCalls: [ConvertForEachToForLoop.new],
  diag.avoidInitToNull: [RemoveInitializer.bulkFixable],
  diag.avoidMultipleDeclarationsPerLine: [SplitMultipleDeclarations.new],
  diag.avoidNullChecksInEqualityOperators: [RemoveComparison.new],
  diag.avoidPrint: [MakeConditionalOnDebugMode.new, RemovePrint.new],
  diag.avoidPrivateTypedefFunctions: [InlineTypedef.new],
  diag.avoidRedundantArgumentValues: [RemoveArgument.new],
  diag.avoidRelativeLibImports: [ConvertToPackageImport.new],
  diag.avoidRenamingMethodParameters: [RenameMethodParameter.new],
  diag.avoidReturnTypesOnSetters: [RemoveTypeAnnotation.other],
  diag.avoidReturningNullForVoidFromFunction: [RemoveReturnedValue.new],
  diag.avoidReturningNullForVoidFromMethod: [RemoveReturnedValue.new],
  diag.avoidSingleCascadeInExpressionStatements: [
    // TODO(brianwilkerson): This fix should be applied to some non-lint
    //  diagnostics and should also be available as an assist.
    ReplaceCascadeWithDot.new,
  ],
  diag.avoidTypesAsParameterNamesFormalParameter: [ConvertToOnType.new],
  diag.avoidTypesOnClosureParameters: [
    ReplaceWithIdentifier.new,
    RemoveTypeAnnotation.other,
  ],
  diag.avoidUnusedConstructorParameters: [RemoveUnusedParameter.new],
  diag.avoidUnnecessaryContainers: [FlutterRemoveWidget.new],
  diag.avoidVoidAsync: [ReplaceReturnTypeFuture.new],
  diag.awaitOnlyFutures: [RemoveAwait.new],
  diag.cascadeInvocations: [ConvertToCascade.new, ConvertRelatedToCascade.new],
  diag.castNullableToNonNullable: [AddNullCheck.withoutAssignabilityCheck],
  diag.combinatorsOrdering: [SortCombinators.new],
  diag.constantIdentifierNames: [RenameToCamelCase.new],
  diag.curlyBracesInFlowControlStructures: [UseCurlyBraces.new],
  diag.danglingLibraryDocComments: [MoveDocCommentToLibraryDirective.new],
  diag.diagnosticDescribeAllProperties: [AddDiagnosticPropertyReference.new],
  diag.directivesOrderingDart: [OrganizeImports.new],
  diag.directivesOrderingAlphabetical: [OrganizeImports.new],
  diag.directivesOrderingExports: [OrganizeImports.new],
  diag.directivesOrderingPackageBeforeRelative: [OrganizeImports.new],
  diag.discardedFutures: [AddAsync.discardedFutures, WrapInUnawaited.new],
  diag.emptyCatches: [RemoveEmptyCatch.new],
  diag.emptyConstructorBodies: [RemoveEmptyConstructorBody.new],
  diag.emptyStatements: [RemoveEmptyStatement.new, ReplaceWithBrackets.new],
  diag.eolAtEndOfFile: [AddEolAtEndOfFile.new],
  diag.exhaustiveCases: [AddMissingEnumLikeCaseClauses.new],
  diag.flutterStyleTodos: [ConvertToFlutterStyleTodo.new],
  diag.hashAndEquals: [CreateMethod.equalityOrHashCode],
  diag.implicitCallTearoffs: [AddExplicitCall.new],
  diag.implicitReopen: [AddReopen.new],
  diag.invalidCasePatterns: [AddConst.new],
  diag.leadingNewlinesInMultilineStrings: [AddLeadingNewlineToString.new],
  diag.libraryAnnotations: [MoveAnnotationToLibraryDirective.new],
  diag.noDuplicateCaseValues: [RemoveDuplicateCase.new],
  diag.noLeadingUnderscoresForLibraryPrefixes: [RemoveLeadingUnderscore.new],
  diag.noLeadingUnderscoresForLocalIdentifiers: [RemoveLeadingUnderscore.new],
  diag.noLiteralBoolComparisons: [ConvertToBooleanExpression.new],
  diag.nonConstantIdentifierNames: [RenameToCamelCase.new],
  diag.noopPrimitiveOperations: [RemoveInvocation.new],
  diag.nullCheckOnNullableTypeParameter: [ReplaceNullCheckWithCast.new],
  diag.nullClosures: [ReplaceNullWithClosure.new],
  diag.omitLocalVariableTypes: [ReplaceWithVar.new, RemoveTypeAnnotation.other],
  diag.omitObviousLocalVariableTypes: [
    ReplaceWithVar.new,
    RemoveTypeAnnotation.other,
  ],
  diag.omitObviousPropertyTypes: [
    ReplaceWithVar.new,
    RemoveTypeAnnotation.other,
  ],
  diag.preferAdjacentStringConcatenation: [RemoveOperator.new],
  diag.preferCollectionLiterals: [
    ConvertToMapLiteral.new,
    ConvertToSetLiteral.new,
  ],
  diag.preferConditionalAssignment: [ReplaceWithConditionalAssignment.new],
  diag.preferConstConstructors: [AddConst.new, ReplaceNewWithConst.new],
  diag.preferConstConstructorsInImmutables: [AddConst.new],
  diag.preferConstDeclarations: [ReplaceFinalWithConst.new],
  diag.preferConstLiteralsToCreateImmutables: [AddConst.new],
  diag.preferContainsAlwaysFalse: [ConvertToContains.new],
  diag.preferContainsAlwaysTrue: [ConvertToContains.new],
  diag.preferContainsUseContains: [ConvertToContains.new],
  diag.preferDoubleQuotes: [ConvertToDoubleQuotes.new],
  diag.preferExpressionFunctionBodies: [ConvertToExpressionFunctionBody.new],
  diag.preferFinalFields: [MakeFinal.new],
  diag.preferFinalInForEachPattern: [MakeFinal.new],
  diag.preferFinalInForEachVariable: [MakeFinal.new],
  diag.preferFinalLocals: [MakeFinal.new],
  diag.preferFinalParameters: [MakeFinal.new],
  diag.preferForElementsToMapFromiterable: [
    ConvertMapFromIterableToForLiteral.new,
  ],
  diag.preferForeach: [ConvertToForEach.new],
  diag.preferFunctionDeclarationsOverVariables: [
    ConvertToFunctionDeclaration.new,
  ],
  diag.preferGenericFunctionTypeAliases: [ConvertToGenericFunctionSyntax.new],
  diag.preferIfElementsToConditionalExpressions: [
    ConvertConditionalExpressionToIfElement.new,
  ],
  diag.preferIfNullOperators: [ConvertToIfNull.preferIfNull],
  diag.preferInitializingFormals: [ConvertToInitializingFormal.new],
  diag.preferInlinedAddsSingle: [
    ConvertAddAllToSpread.new,
    InlineInvocation.new,
  ],
  diag.preferInlinedAddsMultiple: [
    ConvertAddAllToSpread.new,
    InlineInvocation.new,
  ],
  diag.preferIntLiterals: [ConvertToIntLiteral.new],
  diag.preferInterpolationToComposeStrings: [ReplaceWithInterpolation.new],
  diag.preferIsEmptyAlwaysFalse: [ReplaceWithIsEmpty.new],
  diag.preferIsEmptyAlwaysTrue: [ReplaceWithIsEmpty.new],
  diag.preferIsEmptyUseIsEmpty: [ReplaceWithIsEmpty.new],
  diag.preferIsEmptyUseIsNotEmpty: [ReplaceWithIsEmpty.new],
  diag.preferIsNotEmpty: [UseIsNotEmpty.new],
  diag.preferIsNotOperator: [ConvertIntoIsNot.new],
  diag.preferIterableWheretype: [ConvertToWhereType.new],
  diag.preferNullAwareOperators: [ConvertToNullAware.new],
  diag.preferRelativeImports: [ConvertToRelativeImport.new],
  diag.preferSingleQuotes: [ConvertToSingleQuotes.new],
  diag.preferSpreadCollections: [ConvertAddAllToSpread.new],
  diag.preferTypingUninitializedVariablesForField: [
    AddTypeAnnotation.bulkFixable,
  ],
  diag.preferTypingUninitializedVariablesForLocalVariable: [
    AddTypeAnnotation.bulkFixable,
  ],
  diag.preferVoidToNull: [ReplaceNullWithVoid.new],
  diag.requireTrailingCommas: [AddTrailingComma.new],
  diag.simplifyVariablePattern: [RemoveUnnecessaryName.new],
  diag.sizedBoxForWhitespace: [ReplaceContainerWithSizedBox.new],
  diag.slashForDocComments: [ConvertDocumentationIntoLine.new],
  diag.sortChildPropertiesLast: [SortChildPropertyLast.new],
  diag.sortConstructorsFirst: [SortConstructorFirst.new],
  diag.sortUnnamedConstructorsFirst: [SortUnnamedConstructorFirst.new],
  diag.specifyNonobviousLocalVariableTypes: [AddTypeAnnotation.bulkFixable],
  diag.specifyNonobviousPropertyTypes: [AddTypeAnnotation.bulkFixable],
  diag.strictTopLevelInferenceAddType: [AddReturnType.new],
  diag.typeAnnotatePublicApis: [AddTypeAnnotation.bulkFixable],
  diag.typeInitFormals: [RemoveTypeAnnotation.other],
  diag.typeLiteralInConstantPattern: [
    ConvertToConstantPattern.new,
    ConvertToWildcardPattern.new,
  ],
  diag.unawaitedFutures: [AddAwait.unawaited, WrapInUnawaited.new],
  diag.unnecessaryAsync: [RemoveAsync.unnecessary],
  diag.unnecessaryAwaitInReturn: [RemoveAwait.new],
  diag.unnecessaryBraceInStringInterps: [RemoveInterpolationBraces.new],
  diag.unnecessaryBreaks: [RemoveBreak.new],
  diag.unnecessaryConst: [RemoveUnnecessaryConst.new],
  diag.unnecessaryConstructorName: [RemoveConstructorName.new],
  diag.unnecessaryFinalWithType: [ReplaceFinalWithVar.new],
  diag.unnecessaryFinalWithoutType: [ReplaceFinalWithVar.new],
  diag.unnecessaryGettersSetters: [MakeFieldPublic.new],
  diag.unnecessaryIgnoreName: [RemoveIgnoredDiagnostic.new],
  diag.unnecessaryIgnoreNameFile: [RemoveIgnoredDiagnostic.new],
  diag.unnecessaryIgnore: [RemoveComment.ignore],
  diag.unnecessaryIgnoreFile: [RemoveComment.ignore],
  diag.unnecessaryLambdas: [ReplaceWithTearOff.new],
  diag.unnecessaryLate: [RemoveUnnecessaryLate.new],
  diag.unnecessaryLibraryDirective: [RemoveUnnecessaryLibraryDirective.new],
  diag.unnecessaryLibraryName: [RemoveLibraryName.new],
  diag.unnecessaryNew: [RemoveUnnecessaryNew.new],
  diag.unnecessaryNullAwareAssignments: [RemoveAssignment.new],
  diag.unnecessaryNullChecks: [RemoveNonNullAssertion.new],
  diag.unnecessaryNullInIfNullOperators: [RemoveIfNullOperator.new],
  diag.unnecessaryNullableForFinalVariableDeclarations: [
    RemoveQuestionMark.new,
  ],
  diag.unnecessaryOverrides: [RemoveMethodDeclaration.new],
  diag.unnecessaryParenthesis: [RemoveUnnecessaryParentheses.new],
  diag.unnecessaryRawStrings: [RemoveUnnecessaryRawString.new],
  diag.unnecessaryStringEscapes: [RemoveUnnecessaryStringEscape.new],
  diag.unnecessaryStringInterpolations: [
    RemoveUnnecessaryStringInterpolation.new,
  ],
  diag.unnecessaryToListInSpreads: [RemoveToList.new],
  diag.unnecessaryThis: [RemoveThisExpression.new],
  diag.unnecessaryUnawaited: [RemoveUnawaited.new],
  diag.unnecessaryUnderscores: [ConvertToWildcardVariable.automatically],
  diag.unreachableFromMain: [RemoveUnusedElement.new],
  diag.unrelatedTypeEqualityChecksInExpression: [ReplaceWithIs.new],
  diag.useColoredBox: [ReplaceContainerWithColoredBox.new],
  diag.useDecoratedBox: [ReplaceWithDecoratedBox.new],
  diag.useEnums: [ConvertClassToEnum.new],
  diag.useFullHexValuesForFlutterColors: [ReplaceWithEightDigitHex.new],
  diag.useFunctionTypeSyntaxForParameters: [ConvertToGenericFunctionSyntax.new],
  diag.useIfNullToConvertNullsToBools: [
    ConvertToIfNull.useToConvertNullsToBools,
  ],
  diag.useKeyInWidgetConstructors: [AddKeyToConstructors.new],
  diag.useNamedConstants: [ReplaceWithNamedConstant.new],
  diag.useNullAwareElements: [ConvertNullCheckToNullAwareElementOrEntry.new],
  diag.useRawStrings: [ConvertToRawString.new],
  diag.useRethrowWhenPossible: [UseRethrow.new],
  diag.useStringInPartOfDirectives: [ReplaceWithPartOrUriEmpty.new],
  diag.useSuperParametersSingle: [ConvertToSuperParameters.new],
  diag.useSuperParametersMultiple: [ConvertToSuperParameters.new],
  diag.useTruncatingDivision: [UseEffectiveIntegerDivision.new],
  diag.varWithNoTypeAnnotation: [RemoveLexeme.keyword],
};

final _builtInLintMultiGenerators = {
  diag.commentReferences: [ImportLibrary.forType, ImportLibrary.forExtension],
  diag.deprecatedMemberUseFromSamePackageWithoutMessage: [DataDriven.new],
  diag.deprecatedMemberUseFromSamePackageWithMessage: [DataDriven.new],
};

final _builtInNonLintGenerators = <DiagnosticCode, List<ProducerGenerator>>{
  diag.abstractFieldInitializer: [RemoveAbstract.new, RemoveInitializer.new],
  diag.abstractFieldConstructorInitializer: [
    RemoveAbstract.new,
    RemoveInitializer.new,
  ],
  diag.assertInRedirectingConstructor: [RemoveAssertion.new],
  diag.assignmentToFinal: [MakeFieldNotFinal.new, AddLate.new],
  diag.assignmentToFinalLocal: [MakeVariableNotFinal.new],
  diag.argumentTypeNotAssignable: [
    AddExplicitCast.new,
    AddNullCheck.new,
    WrapInText.new,
    AddAwait.argumentType,
  ],
  diag.asyncForInWrongContext: [AddAsync.new],
  diag.augmentationModifierExtra: [RemoveLexeme.modifier],
  diag.awaitInLateLocalVariableInitializer: [RemoveLate.new],
  diag.awaitInWrongContext: [AddAsync.new],
  diag.bodyMightCompleteNormally: [AddAsync.missingReturn],
  diag.castToNonType: [ChangeTo.classOrMixin],
  diag.classInstantiationAccessToStaticMember: [RemoveTypeArguments.new],
  diag.concreteClassWithAbstractMember: [
    ConvertIntoBlockBody.missingBody,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.constEvalMethodInvocation: [RemoveConst.new],
  diag.constInitializedWithNonConstantValue: [RemoveConst.new, RemoveNew.new],
  diag.constInstanceField: [AddStatic.new],
  diag.constWithNonConst: [RemoveConst.new],
  diag.constWithNonType: [ChangeTo.classOrMixin],
  diag.constantPatternWithNonConstantExpression: [AddConst.new],
  diag.defaultValueOnRequiredParameter: [
    RemoveDefaultValue.new,
    RemoveRequired.new,
  ],
  diag.deprecatedFactoryMethod: [AddReturnType.new],
  diag.dotShorthandUndefinedGetter: [
    AddEnumConstant.new,
    ChangeTo.getterOrSetter,
    CreateGetter.new,
    CreateField.new,
  ],
  diag.dotShorthandUndefinedInvocation: [
    ChangeTo.method,
    CreateConstructor.new,
    CreateMethod.method,
  ],
  diag.emptyMapPattern: [
    ReplaceEmptyMapPattern.any,
    ReplaceEmptyMapPattern.empty,
  ],
  diag.enumWithAbstractMember: [ConvertIntoBlockBody.missingBody],
  diag.extendsDisallowedClass: [RemoveNameFromDeclarationClause.new],
  diag.extendsNonClass: [
    ChangeTo.classOrMixin,
    RemoveNameFromDeclarationClause.new,
  ],
  diag.extendsTypeAliasExpandsToTypeParameter: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.extensionDeclaresMemberOfObject: [RemoveMethodDeclaration.new],
  diag.extensionDeclaresInstanceField: [ConvertIntoGetter.new],
  diag.extensionTypeDeclaresMemberOfObject: [RemoveMethodDeclaration.new],
  diag.extensionTypeDeclaresInstanceField: [ConvertIntoGetter.new],
  diag.extensionOverrideAccessToStaticMember: [ReplaceWithExtensionName.new],
  diag.extensionOverrideWithCascade: [ReplaceCascadeWithDot.new],
  diag.extensionTypeWithAbstractMember: [ConvertIntoBlockBody.missingBody],
  diag.extraPositionalArguments: [CreateConstructor.new],
  diag.extraPositionalArgumentsCouldBeNamed: [
    CreateConstructor.new,
    ConvertToNamedArguments.new,
  ],
  diag.finalClassExtendedOutsideOfLibrary: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.finalClassImplementedOutsideOfLibrary: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.finalNotInitialized: [
    AddLate.new,
    CreateConstructorForFinalFields.requiredNamed,
    CreateConstructorForFinalFields.requiredPositional,
  ],
  diag.finalNotInitializedConstructor1: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  diag.finalNotInitializedConstructor2: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  diag.finalNotInitializedConstructor3Plus: [
    AddFieldFormalParameters.new,
    AddFieldFormalParameters.requiredNamed,
  ],
  diag.forInOfInvalidType: [AddAwait.forIn],
  diag.illegalAsyncGeneratorReturnType: [ReplaceReturnTypeStream.new],
  diag.illegalAsyncReturnType: [ReplaceReturnTypeFuture.new, RemoveAsync.new],
  diag.illegalSyncGeneratorReturnType: [ReplaceReturnTypeIterable.new],
  diag.implementsDisallowedClass: [RemoveNameFromDeclarationClause.new],
  diag.implementsNonClass: [ChangeTo.classOrMixin],
  diag.implementsRepeated: [RemoveNameFromDeclarationClause.new],
  diag.implementsSuperClass: [RemoveNameFromDeclarationClause.new],
  diag.implementsTypeAliasExpandsToTypeParameter: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.implicitSuperInitializerMissingArguments: [AddSuperParameter.new],
  diag.implicitThisReferenceInInitializer: [
    ConvertIntoGetter.implicitThis,
    AddLate.implicitThis,
  ],
  diag.importOfNonLibrary: [RemoveUnusedImport.new],
  diag.importInternalLibrary: [RemoveUnusedImport.new],
  diag.initializingFormalForNonExistentField: [ChangeTo.field, CreateField.new],
  diag.instanceAccessToStaticMember: [ChangeToStaticAccess.new],
  diag.integerLiteralImpreciseAsDouble: [ChangeToNearestPreciseValue.new],
  diag.invalidAnnotation: [ChangeTo.annotation],
  diag.invalidAssignment: [
    AddExplicitCast.new,
    AddNullCheck.new,
    ChangeTypeAnnotation.new,
    MakeVariableNullable.new,
    AddAwait.assignment,
  ],
  diag.invalidConstant: [RemoveConst.new],
  diag.invalidModifierOnConstructor: [RemoveLexeme.modifier],
  diag.invalidModifierOnSetter: [RemoveLexeme.modifier],
  diag.invalidUseOfCovariant: [RemoveLexeme.keyword],
  diag.invocationOfNonFunctionExpression: [
    RemoveParenthesesInGetterInvocation.new,
  ],
  diag.lateFinalLocalAlreadyAssigned: [MakeVariableNotFinal.new],
  diag.listElementTypeNotAssignableNullability: [
    ConvertToNullAwareListElement.new,
  ],
  diag.mapKeyTypeNotAssignableNullability: [ConvertToNullAwareMapEntryKey.new],
  diag.mapValueTypeNotAssignableNullability: [
    ConvertToNullAwareMapEntryValue.new,
  ],
  diag.missingDefaultValueForParameter: [
    AddRequiredKeyword.new,
    MakeVariableNullable.new,
  ],
  diag.missingDefaultValueForParameterPositional: [MakeVariableNullable.new],
  diag.missingDefaultValueForParameterWithAnnotation: [AddRequiredKeyword.new],
  diag.missingRequiredArgument: [AddMissingRequiredArgument.new],
  diag.mixinApplicationNotImplementedInterface: [ExtendClassForMixin.new],
  diag.mixinClassDeclarationExtendsNotObject: [RemoveExtendsClause.new],
  diag.mixinSubtypeOfBaseIsNotBase: [AddClassModifier.baseModifier],
  diag.mixinSubtypeOfFinalIsNotBase: [AddClassModifier.baseModifier],
  diag.mixinOfDisallowedClass: [RemoveNameFromDeclarationClause.new],
  diag.mixinOfNonClass: [ChangeTo.classOrMixin],
  diag.mixinSuperClassConstraintDisallowedClass: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.mixinSuperClassConstraintNonInterface: [
    RemoveNameFromDeclarationClause.new,
  ],
  diag.newWithNonType: [ChangeTo.classOrMixin],
  diag.newWithUndefinedConstructor: [CreateConstructor.new],
  diag.noAnnotationConstructorArguments: [AddEmptyArgumentList.new],
  diag.nonAbstractClassInheritsAbstractMemberFivePlus: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.nonAbstractClassInheritsAbstractMemberFour: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.nonAbstractClassInheritsAbstractMemberOne: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.nonAbstractClassInheritsAbstractMemberThree: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.nonAbstractClassInheritsAbstractMemberTwo: [
    CreateMissingOverrides.new,
    CreateNoSuchMethod.new,
    MakeClassAbstract.new,
  ],
  diag.nonBoolCondition: [AddNeNull.new, AddAwait.nonBool],
  diag.nonConstGenerativeEnumConstructor: [AddConst.new],
  diag.nonConstantListElement: [RemoveConst.new],
  diag.nonConstantListElementFromDeferredLibrary: [RemoveConst.new],
  diag.nonConstantMapElement: [RemoveConst.new],
  diag.nonConstantMapKey: [RemoveConst.new],
  diag.nonConstantMapKeyFromDeferredLibrary: [RemoveConst.new],
  diag.nonConstantMapPatternKey: [AddConst.new],
  diag.nonConstantMapValue: [RemoveConst.new],
  diag.nonConstantMapValueFromDeferredLibrary: [RemoveConst.new],
  diag.nonConstantRelationalPatternExpression: [AddConst.new],
  diag.nonConstantSetElement: [RemoveConst.new],
  diag.nonExhaustiveSwitchExpression: [AddMissingSwitchCases.new],
  diag.nonExhaustiveSwitchExpressionPrivate: [AddMissingSwitchCases.new],
  diag.nonExhaustiveSwitchStatement: [AddMissingSwitchCases.new],
  diag.nonExhaustiveSwitchStatementPrivate: [AddMissingSwitchCases.new],
  diag.nonFinalFieldInEnum: [MakeFinal.new],
  diag.notAType: [ChangeTo.classOrMixin],
  diag.notInitializedNonNullableInstanceField: [AddLate.new],
  diag.nullableTypeInExtendsClause: [RemoveQuestionMark.new],
  diag.nullableTypeInImplementsClause: [RemoveQuestionMark.new],
  diag.nullableTypeInOnClause: [RemoveQuestionMark.new],
  diag.nullableTypeInWithClause: [RemoveQuestionMark.new],
  diag.obsoleteColonForDefaultValue: [ReplaceColonWithEquals.new],
  diag.recordLiteralOnePositionalNoTrailingCommaByType: [AddTrailingComma.new],
  diag.returnOfInvalidTypeFromClosure: [AddAsync.wrongReturnType],
  diag.returnOfInvalidTypeFromFunction: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  diag.returnOfInvalidTypeFromMethod: [
    AddAsync.wrongReturnType,
    MakeReturnTypeNullable.new,
    ReplaceReturnType.new,
  ],
  diag.setElementFromDeferredLibrary: [RemoveConst.new],
  diag.setElementTypeNotAssignableNullability: [
    ConvertToNullAwareSetElement.new,
  ],
  diag.spreadExpressionFromDeferredLibrary: [RemoveConst.new],
  diag.subtypeOfBaseIsNotBaseFinalOrSealed: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  diag.subtypeOfFinalIsNotBaseFinalOrSealed: [
    AddClassModifier.baseModifier,
    AddClassModifier.finalModifier,
    AddClassModifier.sealedModifier,
  ],
  diag.superFormalParameterTypeIsNotSubtypeOfAssociated: [
    RemoveTypeAnnotation.other,
  ],
  diag.superFormalParameterWithoutAssociatedNamed: [
    ChangeTo.superFormalParameter,
    AddMissingParameterNamed.new,
  ],
  diag.superInvocationNotLast: [MakeSuperInvocationLast.new],
  diag.switchCaseCompletesNormally: [AddSwitchCaseBreak.new],
  diag.typeTestWithUndefinedName: [ChangeTo.classOrMixin],
  diag.uncheckedInvocationOfNullableValue: [
    AddNullCheck.new,
    ReplaceWithNullAware.single,
  ],
  diag.uncheckedMethodInvocationOfNullableValue: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
    CreateExtensionMethod.new,
  ],
  diag.uncheckedOperatorInvocationOfNullableValue: [
    AddNullCheck.new,
    CreateExtensionOperator.new,
    CreateOperator.new,
  ],
  diag.uncheckedPropertyAccessOfNullableValue: [
    AddNullCheck.new,
    ExtractLocalVariable.new,
    ReplaceWithNullAware.single,
    CreateExtensionGetter.new,
    CreateExtensionSetter.new,
  ],
  diag.uncheckedUseOfNullableValueAsCondition: [AddNullCheck.new],
  diag.uncheckedUseOfNullableValueAsIterator: [AddNullCheck.new],
  diag.uncheckedUseOfNullableValueInSpread: [
    AddNullCheck.new,
    ConvertToNullAwareSpread.new,
  ],
  diag.uncheckedUseOfNullableValueInYieldEach: [AddNullCheck.new],
  diag.undefinedAnnotation: [ChangeTo.annotation],
  diag.undefinedClass: [ChangeTo.classOrMixin],
  diag.undefinedClassBoolean: [ReplaceBooleanWithBool.new],
  diag.undefinedEnumConstant: [
    AddEnumConstant.new,
    ChangeTo.getterOrSetter,
    CreateMethodOrFunction.new,
  ],
  diag.undefinedEnumConstructorNamed: [CreateConstructor.new],
  diag.undefinedEnumConstructorUnnamed: [CreateConstructor.new],
  diag.undefinedExtensionGetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionGetter.new,
    CreateExtensionMethod.new,
  ],
  diag.undefinedExtensionMethod: [
    ChangeTo.method,
    CreateExtensionMethod.new,
    CreateMethod.method,
  ],
  diag.undefinedExtensionOperator: [CreateExtensionOperator.new],
  diag.undefinedExtensionSetter: [
    ChangeTo.getterOrSetter,
    CreateSetter.new,
    CreateExtensionSetter.new,
  ],
  diag.undefinedFunction: [ChangeTo.function, CreateFunction.new],
  diag.undefinedGetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionMethod.new,
    CreateExtensionGetter.new,
    CreateField.new,
    CreateGetter.new,
    CreateLocalVariable.new,
    CreateMethodOrFunction.new,
  ],
  diag.undefinedIdentifier: [
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
  diag.undefinedIdentifierAwait: [AddAsync.new],
  diag.undefinedMethod: [
    ChangeTo.method,
    CreateExtensionMethod.new,
    CreateFunction.new,
    CreateMethod.method,
  ],
  diag.undefinedNamedParameter: [
    AddMissingParameterNamed.new,
    ConvertFlutterChild.new,
    ConvertFlutterChildren.new,
  ],
  diag.undefinedOperator: [CreateExtensionOperator.new, CreateOperator.new],
  diag.undefinedSetter: [
    ChangeTo.getterOrSetter,
    CreateExtensionSetter.new,
    CreateField.new,
    CreateSetter.new,
  ],
  diag.unqualifiedReferenceToNonLocalStaticMember: [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing _addFix methods would need to be
    //  updated so that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  diag.unqualifiedReferenceToStaticMemberOfExtendedType: [
    // TODO(brianwilkerson): Consider adding fixes to create a field, getter,
    //  method or setter. The existing producers would need to be updated so
    //  that only the appropriate subset is generated.
    QualifyReference.new,
  ],
  diag.uriDoesNotExist: [CreateFile.new],
  diag.useOfPrivateParameterName: [AddMissingParameterNamed.new],
  diag.variablePatternKeywordInDeclarationContext: [RemoveVar.new],
  diag.wrongNumberOfTypeArgumentsConstructor: [
    MoveTypeArgumentsToClass.new,
    RemoveTypeArguments.new,
  ],
  diag.yieldOfInvalidType: [MakeReturnTypeNullable.new],
  diag.subtypeOfStructClassInExtends: [RemoveNameFromDeclarationClause.new],
  diag.subtypeOfStructClassInImplements: [RemoveNameFromDeclarationClause.new],
  diag.subtypeOfStructClassInWith: [RemoveNameFromDeclarationClause.new],
  diag.deprecatedColonForDefaultValue: [ReplaceColonWithEquals.new],
  diag.unnecessaryImport: [RemoveUnusedImport.new],
  diag.abstractClassMember: [RemoveAbstract.bulkFixable],
  diag.abstractStaticField: [RemoveLexeme.modifier],
  diag.abstractStaticMethod: [RemoveLexeme.modifier],
  diag.colonInPlaceOfIn: [ReplaceColonWithIn.new],
  diag.constClass: [RemoveConst.new],
  diag.constFactory: [RemoveConst.new],
  diag.constMethod: [RemoveConst.new],
  diag.covariantMember: [RemoveLexeme.modifier],
  diag.defaultInSwitchExpression: [ReplaceWithWildcard.new],
  diag.duplicatedModifier: [RemoveLexeme.modifier],
  diag.emptyRecordLiteralWithComma: [RemoveComma.emptyRecordLiteral],
  diag.emptyRecordTypeWithComma: [RemoveComma.emptyRecordType],
  diag.expectedCatchClauseBody: [InsertBody.new],
  diag.expectedClassBody: [InsertBody.new],
  diag.expectedExtensionBody: [InsertBody.new],
  diag.expectedExtensionTypeBody: [InsertBody.new],
  diag.expectedFinallyClauseBody: [InsertBody.new],
  diag.expectedMixinBody: [InsertBody.new],
  diag.expectedSwitchExpressionBody: [InsertBody.new],
  diag.expectedSwitchStatementBody: [InsertBody.new],
  diag.expectedTryStatementBody: [InsertBody.new],
  diag.expectedToken: [
    InsertSemicolon.new,
    ReplaceWithArrow.new,
    InsertOnKeyword.new,
  ],
  diag.extensionAugmentationHasOnClause: [RemoveOnClause.new],
  diag.extensionDeclaresConstructor: [RemoveConstructor.new],
  diag.externalClass: [RemoveLexeme.modifier],
  diag.externalEnum: [RemoveLexeme.modifier],
  diag.externalTypedef: [RemoveLexeme.modifier],
  diag.extraneousModifier: [RemoveLexeme.modifier],
  diag.factoryTopLevelDeclaration: [RemoveLexeme.modifier],
  diag.finalEnum: [RemoveLexeme.modifier],
  diag.finalConstructor: [RemoveLexeme.modifier],
  diag.finalMethod: [RemoveLexeme.modifier],
  diag.finalMixin: [RemoveLexeme.modifier],
  diag.finalMixinClass: [RemoveLexeme.modifier],
  diag.getterConstructor: [RemoveLexeme.keyword],
  diag.getterWithParameters: [RemoveParametersInGetterDeclaration.new],
  diag.interfaceMixin: [RemoveLexeme.modifier],
  diag.interfaceMixinClass: [RemoveLexeme.modifier],
  diag.invalidConstantPatternBinary: [AddConst.new],
  diag.invalidConstantPatternGeneric: [AddConst.new],
  diag.invalidConstantPatternNegation: [AddConst.new],
  diag.invalidInsideUnaryPattern: [SurroundWithParentheses.new],
  diag.invalidUseOfCovariantInExtension: [RemoveLexeme.modifier],
  diag.latePatternVariableDeclaration: [RemoveLate.new],
  diag.literalWithNew: [RemoveLexeme.keyword],
  diag.missingConstFinalVarOrType: [AddTypeAnnotation.new],
  diag.missingEnumBody: [InsertBody.new],
  diag.missingFunctionBody: [ConvertIntoBlockBody.missingBody],
  diag.missingTypedefParameters: [AddEmptyArgumentList.new],
  diag.mixinDeclaresConstructor: [RemoveConstructor.new],
  diag.patternAssignmentDeclaresVariable: [RemoveVarKeyword.new],
  diag.recordLiteralOnePositionalNoTrailingComma: [AddTrailingComma.new],
  diag.recordTypeOnePositionalNoTrailingComma: [AddTrailingComma.new],
  diag.representationFieldTrailingComma: [RemoveComma.representationField],
  diag.sealedMixin: [RemoveLexeme.modifier],
  diag.sealedMixinClass: [RemoveLexeme.modifier],
  diag.setterConstructor: [RemoveLexeme.keyword],
  diag.staticConstructor: [RemoveLexeme.keyword],
  diag.staticGetterWithoutBody: [ConvertIntoBlockBody.missingBody],
  diag.staticSetterWithoutBody: [ConvertIntoBlockBody.missingBody],
  diag.staticOperator: [RemoveLexeme.keyword],
  diag.varAndType: [RemoveTypeAnnotation.fixVarAndType, RemoveVar.new],
  diag.varAsTypeName: [ReplaceVarWithDynamic.new],
  diag.varReturnType: [RemoveVar.new],
  diag.wrongSeparatorForPositionalParameter: [ReplaceColonWithEquals.new],
  diag.unexpectedSeparatorInNumber: [RemoveUnexpectedUnderscores.new],
  diag.deadNullAwareExpression: [RemoveDeadIfNull.new],
  diag.invalidNullAwareElement: [ReplaceWithNotNullAwareElementOrEntry.entry],
  diag.invalidNullAwareMapEntryKey: [
    ReplaceWithNotNullAwareElementOrEntry.mapKey,
  ],
  diag.invalidNullAwareMapEntryValue: [
    ReplaceWithNotNullAwareElementOrEntry.mapValue,
  ],
  diag.invalidNullAwareOperator: [ReplaceWithNotNullAware.new],
  diag.invalidNullAwareOperatorAfterShortCircuit: [ReplaceWithNotNullAware.new],
  diag.missingEnumConstantInSwitch: [AddMissingEnumCaseClauses.new],
  diag.unnecessaryNonNullAssertion: [RemoveNonNullAssertion.new],
  diag.unnecessaryNullCheckPattern: [RemoveQuestionMark.new],
  diag.unnecessaryNullAssertPattern: [RemoveNonNullAssertion.new],
  diag.bodyMightCompleteNormallyNullable: [AddReturnNull.new],
  diag.deadCode: [RemoveDeadCode.new],
  diag.deadCodeCatchFollowingCatch: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  diag.deadCodeLateWildcardVariableInitializer: [
    RemoveInitializer.notLate,
    RemoveLate.new,
  ],
  diag.deadCodeOnCatchSubtype: [
    // TODO(brianwilkerson): Add a fix to move the unreachable catch clause to
    //  a place where it can be reached (when possible).
    RemoveDeadCode.new,
  ],
  diag.deprecatedExtend: [RemoveExtendsClause.new],
  diag.deprecatedImplement: [RemoveNameFromDeclarationClause.new],
  diag.deprecatedImplementsFunction: [RemoveNameFromDeclarationClause.new],
  diag.deprecatedNewInCommentReference: [
    RemoveDeprecatedNewInCommentReference.new,
  ],
  diag.deprecatedSubclass: [RemoveNameFromDeclarationClause.new],
  diag.duplicateHiddenName: [RemoveNameFromCombinator.new],
  diag.duplicateImport: [RemoveUnusedImport.new],
  diag.duplicateShownName: [RemoveNameFromCombinator.new],
  diag.invalidAnnotationTarget: [RemoveAnnotation.new],
  diag.invalidInternalAnnotation: [RemoveAnnotation.new],
  diag.invalidLiteralAnnotation: [RemoveAnnotation.new],
  diag.invalidNonVirtualAnnotation: [RemoveAnnotation.new],
  diag.invalidReopenAnnotation: [RemoveAnnotation.new],
  diag.invalidVisibilityAnnotation: [RemoveAnnotation.new],
  diag.missingOverrideOfMustBeOverriddenOne: [CreateMissingOverrides.new],
  diag.missingOverrideOfMustBeOverriddenTwo: [CreateMissingOverrides.new],
  diag.missingOverrideOfMustBeOverriddenThreePlus: [CreateMissingOverrides.new],
  diag.missingRequiredParam: [AddMissingRequiredArgument.new],
  diag.missingRequiredParamWithDetails: [AddMissingRequiredArgument.new],
  diag.mustCallSuper: [AddCallSuper.new],
  diag.nonConstCallToLiteralConstructorUsingNew: [ReplaceNewWithConst.new],
  diag.nullCheckAlwaysFails: [RemoveNonNullAssertion.new],
  diag.nullableTypeInCatchClause: [RemoveQuestionMark.new],
  diag.overrideOnNonOverridingField: [RemoveAnnotation.new],
  diag.overrideOnNonOverridingGetter: [RemoveAnnotation.new],
  diag.overrideOnNonOverridingMethod: [RemoveAnnotation.new],
  diag.overrideOnNonOverridingSetter: [RemoveAnnotation.new],
  diag.redeclareOnNonRedeclaringMember: [RemoveAnnotation.new],
  diag.sdkVersionGtGtGtOperator: [UpdateSdkConstraints.version_2_14_0],
  diag.textDirectionCodePointInComment: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  diag.textDirectionCodePointInLiteral: [
    RemoveCharacter.new,
    ReplaceWithUnicodeEscape.new,
  ],
  diag.typeCheckIsNotNull: [UseNotEqNull.new],
  diag.typeCheckIsNull: [UseEqEqNull.new],
  diag.undefinedHiddenName: [RemoveNameFromCombinator.new],
  diag.undefinedShownName: [RemoveNameFromCombinator.new],
  diag.unnecessaryCast: [RemoveUnnecessaryCast.new],
  diag.unnecessaryFinal: [RemoveUnnecessaryFinal.new],
  diag.unnecessaryNanComparisonFalse: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  diag.unnecessaryNanComparisonTrue: [
    RemoveComparison.new,
    ReplaceWithIsNan.new,
  ],
  diag.unnecessaryNullComparisonAlwaysNullFalse: [RemoveComparison.new],
  diag.unnecessaryNullComparisonAlwaysNullTrue: [RemoveComparison.new],
  diag.unnecessaryNullComparisonNeverNullFalse: [RemoveComparison.new],
  diag.unnecessaryNullComparisonNeverNullTrue: [RemoveComparison.new],
  diag.unnecessaryQuestionMark: [RemoveQuestionMark.new],
  diag.unnecessarySetLiteral: [ConvertIntoBlockBody.setLiteral],
  diag.unnecessaryTypeCheckFalse: [RemoveComparison.typeCheck],
  diag.unnecessaryTypeCheckTrue: [RemoveComparison.typeCheck],
  diag.unnecessaryWildcardPattern: [RemoveUnnecessaryWildcardPattern.new],
  diag.unreachableSwitchCase: [RemoveDeadCode.new],
  diag.unreachableSwitchDefault: [RemoveDeadCode.new],
  diag.unusedCatchClause: [RemoveUnusedCatchClause.new],
  diag.unusedCatchStack: [RemoveUnusedCatchStack.new],
  diag.unusedElement: [RemoveUnusedElement.new],
  diag.unusedElementParameter: [RemoveUnusedParameter.new],
  diag.unusedField: [RemoveUnusedField.new],
  diag.unusedImport: [RemoveUnusedImport.new],
  diag.unusedLabel: [RemoveUnusedLabel.new],
  diag.unusedLocalVariable: [
    RemoveUnusedLocalVariable.new,
    ConvertToWildcardVariable.new,
  ],
  diag.unusedShownName: [OrganizeImports.new, RemoveNameFromCombinator.new],
};

final _builtInNonLintMultiGenerators = {
  diag.ambiguousExtensionMemberAccessTwo: [AddExtensionOverride.new],
  diag.ambiguousExtensionMemberAccessThreeOrMore: [AddExtensionOverride.new],
  diag.ambiguousImport: [AmbiguousImportFix.new],
  diag.argumentTypeNotAssignable: [DataDriven.new],
  diag.castToNonType: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  diag.constWithNonType: [CreateClass.new, ImportLibrary.forType],
  diag.dotShorthandUndefinedGetter: [DataDriven.new],
  diag.dotShorthandUndefinedInvocation: [DataDriven.new],
  diag.extendsNonClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  diag.extraPositionalArguments: [AddMissingParameter.new, DataDriven.new],
  diag.extraPositionalArgumentsCouldBeNamed: [
    AddMissingParameter.new,
    DataDriven.new,
  ],
  diag.implementsNonClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  diag.implicitSuperInitializerMissingArguments: [
    AddSuperConstructorInvocation.new,
  ],
  diag.invalidAnnotation: [
    CreateClass.new,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  diag.invalidOverride: [DataDriven.new],
  diag.invalidOverrideSetter: [DataDriven.new],
  diag.missingRequiredArgument: [DataDriven.new],
  diag.mixinOfNonClass: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  diag.mixinWithNonClassSuperclass: [CreateClass.new, ImportLibrary.forType],
  diag.newWithNonType: [CreateClass.new, ImportLibrary.forType],
  diag.newWithUndefinedConstructorDefault: [DataDriven.new],
  diag.noDefaultSuperConstructorExplicit: [AddSuperConstructorInvocation.new],
  diag.noDefaultSuperConstructorImplicit: [
    AddSuperConstructorInvocation.new,
    CreateConstructorSuper.new,
  ],
  diag.nonTypeInCatchClause: [ImportLibrary.forType],
  diag.nonTypeAsTypeArgument: [
    CreateClass.new,
    CreateMixin.new,
    DataDriven.new,
    ImportLibrary.forType,
  ],
  diag.notAType: [CreateClass.new, ImportLibrary.forType, CreateMixin.new],
  diag.notEnoughPositionalArgumentsNamePlural: [DataDriven.new],
  diag.notEnoughPositionalArgumentsNameSingular: [DataDriven.new],
  diag.notEnoughPositionalArgumentsPlural: [DataDriven.new],
  diag.notEnoughPositionalArgumentsSingular: [DataDriven.new],
  diag.typeTestWithUndefinedName: [
    CreateClass.new,
    CreateMixin.new,
    ImportLibrary.forType,
  ],
  diag.positionalSuperFormalParameterWithPositionalArgument: [
    AddMissingParameter.new,
  ],
  diag.superFormalParameterWithoutAssociatedPositional: [
    AddMissingParameter.new,
  ],
  diag.uncheckedMethodInvocationOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  diag.uncheckedOperatorInvocationOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  diag.uncheckedPropertyAccessOfNullableValue: [
    ImportLibrary.forExtensionMember,
  ],
  diag.undefinedAnnotation: [
    CreateClass.new,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
  ],
  diag.undefinedClass: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  diag.undefinedConstructorInInitializerDefault: [
    AddSuperConstructorInvocation.new,
  ],
  diag.undefinedExtensionGetter: [DataDriven.new],
  diag.undefinedFunction: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionType,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  diag.undefinedGetter: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  diag.undefinedIdentifier: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtension,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forTopLevelVariable,
    ImportLibrary.forType,
    CreateMixin.new,
  ],
  diag.undefinedMethod: [
    CreateClass.new,
    DataDriven.new,
    ImportLibrary.forExtensionMember,
    ImportLibrary.forFunction,
    ImportLibrary.forType,
  ],
  diag.undefinedNamedParameter: [ChangeArgumentName.new, DataDriven.new],
  diag.undefinedOperator: [
    ImportLibrary.forExtensionMember,
    UseDifferentDivisionOperator.new,
  ],
  diag.undefinedPrefixedName: [DataDriven.new],
  diag.undefinedSetter: [
    DataDriven.new,
    // TODO(brianwilkerson): Support ImportLibrary for non-extension members.
    ImportLibrary.forExtensionMember,
  ],
  diag.useOfPrivateParameterName: [ChangeArgumentName.new],
  diag.wrongNumberOfTypeArguments: [DataDriven.new],
  diag.wrongNumberOfTypeArgumentsConstructor: [DataDriven.new],
  diag.wrongNumberOfTypeArgumentsExtension: [DataDriven.new],
  diag.wrongNumberOfTypeArgumentsElement: [DataDriven.new],
  diag.deprecatedMemberUse: [DataDriven.new],
  diag.deprecatedMemberUseWithMessage: [DataDriven.new],
  diag.deprecatedExportUse: [DataDriven.new],
  diag.multipleCombinators: [MergeCombinators.new],
  diag.overrideOnNonOverridingMethod: [DataDriven.new],
};

final _builtInParseLintGenerators = <DiagnosticCode, List<ProducerGenerator>>{
  diag.preferGenericFunctionTypeAliases: [ConvertToGenericFunctionSyntax.new],
  diag.slashForDocComments: [ConvertDocumentationIntoLine.new],
  diag.unnecessaryConst: [RemoveUnnecessaryConst.new],
  diag.unnecessaryNew: [RemoveUnnecessaryNew.new],
  diag.unnecessaryStringEscapes: [RemoveUnnecessaryStringEscape.new],
  diag.useFunctionTypeSyntaxForParameters: [ConvertToGenericFunctionSyntax.new],
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
  registeredFixGenerators.warningMultiProducers.addAll(
    _builtInNonLintMultiGenerators,
  );
  registeredFixGenerators.warningProducers.addAll(_builtInNonLintGenerators);
  registeredFixGenerators.parseLintProducers.addAll(
    _builtInParseLintGenerators,
  );
  registeredFixGenerators.ignoreProducerGenerators.addAll([
    IgnoreDiagnosticOnLine.new,
    IgnoreDiagnosticInFile.new,
    IgnoreDiagnosticInAnalysisOptionsFile.new,
  ]);
}
