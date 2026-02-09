// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_digit_separators.dart';
import 'package:analysis_server/src/services/correction/dart/add_late.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/assign_to_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/bind_all_to_fields.dart';
import 'package:analysis_server/src/services/correction/dart/bind_to_field.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_enum.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_block.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_field_formal_to_normal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_async_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_block_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_final_field.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_for_index.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_getter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not.dart';
import 'package:analysis_server/src/services/correction/dart/convert_into_is_not_empty.dart';
import 'package:analysis_server/src/services/correction/dart/convert_map_from_iterable_to_for_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_part_of_to_uri.dart';
import 'package:analysis_server/src/services/correction/dart/convert_quotes.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_dot_shorthand.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_case_statement.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_case_statement_chain.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_initializing_formal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_multiline_string.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_primary_constructor.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_secondary_constructor.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_set_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_super_parameters.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_switch_expression.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_switch_statement.dart';
import 'package:analysis_server/src/services/correction/dart/destructure_local_variable_assignment.dart';
import 'package:analysis_server/src/services/correction/dart/encapsulate_field.dart';
import 'package:analysis_server/src/services/correction/dart/exchange_operands.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_convert_to_children.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_convert_to_stateful_widget.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_convert_to_stateless_widget.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_move_down.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_move_up.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_remove_widget.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_swap_with_child.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_swap_with_parent.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_wrap.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_wrap_builder.dart';
import 'package:analysis_server/src/services/correction/dart/flutter_wrap_generic.dart';
import 'package:analysis_server/src/services/correction/dart/import_add_show.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/invert_conditional_expression.dart';
import 'package:analysis_server/src/services/correction/dart/invert_if_statement.dart';
import 'package:analysis_server/src/services/correction/dart/join_else_with_if.dart';
import 'package:analysis_server/src/services/correction/dart/join_if_with_inner.dart';
import 'package:analysis_server/src/services/correction/dart/join_if_with_outer.dart';
import 'package:analysis_server/src/services/correction/dart/join_variable_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/remove_async.dart';
import 'package:analysis_server/src/services/correction/dart/remove_digit_separators.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_name.dart';
import 'package:analysis_server/src/services/correction/dart/replace_conditional_with_if_else.dart';
import 'package:analysis_server/src/services/correction/dart/replace_if_else_with_conditional.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/shadow_field.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/split_and_condition.dart';
import 'package:analysis_server/src/services/correction/dart/split_variable_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/surround_with.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server_plugin/src/correction/assist_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';

/// The set of built-in generators used to produce assists.
const Set<ProducerGenerator> _builtInGenerators = {
  AddDiagnosticPropertyReference.new,
  AddDigitSeparatorEveryThreeDigits.new,
  AddDigitSeparatorEveryTwoDigits.new,
  AddLate.new,
  AddReturnType.new,
  AddTypeAnnotation.bulkFixable,
  AssignToLocalVariable.new,
  BindAllToFields.new,
  BindToField.new,
  ConvertAddAllToSpread.new,
  ConvertClassToEnum.new,
  ConvertClassToMixin.new,
  ConvertConditionalExpressionToIfElement.new,
  ConvertDocumentationIntoBlock.new,
  ConvertDocumentationIntoLine.new,
  ConvertFieldFormalToNormal.new,
  ConvertIfStatementToSwitchStatement.new,
  ConvertIntoAsyncBody.new,
  ConvertIntoBlockBody.missingBody,
  ConvertIntoFinalField.new,
  ConvertIntoForIndex.new,
  ConvertIntoGetter.new,
  ConvertIntoIsNot.new,
  ConvertIntoIsNotEmpty.new,
  ConvertMapFromIterableToForLiteral.new,
  ConvertPartOfToUri.new,
  ConvertSwitchExpressionToSwitchStatement.new,
  ConvertToDotShorthand.new,
  ConvertToDoubleQuotes.new,
  ConvertToExpressionFunctionBody.new,
  ConvertToGenericFunctionSyntax.new,
  ConvertToIfCaseStatement.new,
  ConvertToIfCaseStatementChain.new,
  ConvertToInitializingFormal.new,
  ConvertToIntLiteral.new,
  ConvertToMapLiteral.new,
  ConvertToMultilineString.new,
  ConvertToNullAware.new,
  ConvertToPackageImport.new,
  ConvertToPrimaryConstructor.new,
  ConvertToRelativeImport.new,
  ConvertToSecondaryConstructor.new,
  ConvertToSetLiteral.new,
  ConvertToSingleQuotes.new,
  ConvertToSuperParameters.new,
  ConvertToSwitchExpression.new,
  DestructureLocalVariableAssignment.new,
  EncapsulateField.new,
  ExchangeOperands.new,
  FlutterConvertToChildren.new,
  FlutterConvertToStatefulWidget.new,
  FlutterConvertToStatelessWidget.new,
  FlutterMoveDown.new,
  FlutterMoveUp.new,
  FlutterRemoveWidget.new,
  FlutterSwapWithChild.new,
  FlutterSwapWithParent.new,
  FlutterWrapGeneric.new,
  ImportAddShow.new,
  InlineInvocation.new,
  InvertConditionalExpression.new,
  InvertIfStatement.new,
  JoinElseWithIf.new,
  JoinIfWithElse.new,
  JoinIfWithInner.new,
  JoinIfWithOuter.new,
  JoinVariableDeclaration.new,
  RemoveAsync.new,
  RemoveUnnecessaryName.new,
  RemoveDigitSeparators.new,
  RemoveTypeAnnotation.other,
  ReplaceConditionalWithIfElse.new,
  ReplaceIfElseWithConditional.new,
  ReplaceWithVar.new,
  ShadowField.new,
  SortChildPropertyLast.new,
  SplitAndCondition.new,
  SplitVariableDeclaration.new,
  UseCurlyBraces.new,
};

/// The set of built-in multi-generators used to produce assists.
const Set<MultiProducerGenerator> _builtInMultiGenerators = {
  FlutterWrap.new,
  FlutterWrapBuilders.new,
  SurroundWith.new,
};

/// Registers each list of producer generators with [AssistProcessor].
void registerBuiltInAssistGenerators() {
  // This function can be called many times during test runs so these statements
  // should not result in duplicate producers (i.e. they should only add to maps
  // or sets or otherwise ensure producers that already exist are not added).
  _builtInGenerators.forEach(registeredAssistGenerators.registerGenerator);
  _builtInMultiGenerators.forEach(
    registeredAssistGenerators.registerMultiGenerator,
  );
}
