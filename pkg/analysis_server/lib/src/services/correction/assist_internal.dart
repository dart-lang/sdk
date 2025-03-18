// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/assist_generators.dart';
import 'package:analysis_server/src/services/correction/assist_performance.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_digit_separators.dart';
import 'package:analysis_server/src/services/correction/dart/add_return_type.dart';
import 'package:analysis_server/src/services/correction/dart/add_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/assign_to_local_variable.dart';
import 'package:analysis_server/src/services/correction/dart/convert_add_all_to_spread.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_enum.dart';
import 'package:analysis_server/src/services/correction/dart/convert_class_to_mixin.dart';
import 'package:analysis_server/src/services/correction/dart/convert_conditional_expression_to_if_element.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_block.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
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
import 'package:analysis_server/src/services/correction/dart/convert_to_expression_function_body.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_field_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_generic_function_syntax.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_case_statement.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_if_case_statement_chain.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_int_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_map_literal.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_multiline_string.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_normal_parameter.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_null_aware.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_package_import.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_relative_import.dart';
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
import 'package:analysis_server/src/services/correction/dart/remove_digit_separators.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/replace_conditional_with_if_else.dart';
import 'package:analysis_server/src/services/correction/dart/replace_if_else_with_conditional.dart';
import 'package:analysis_server/src/services/correction/dart/replace_with_var.dart';
import 'package:analysis_server/src/services/correction/dart/shadow_field.dart';
import 'package:analysis_server/src/services/correction/dart/sort_child_property_last.dart';
import 'package:analysis_server/src/services/correction/dart/split_and_condition.dart';
import 'package:analysis_server/src/services/correction/dart/split_variable_declaration.dart';
import 'package:analysis_server/src/services/correction/dart/surround_with.dart';
import 'package:analysis_server/src/services/correction/dart/use_curly_braces.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart'
    hide AssistContributor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

/// The set of built-in generators used to produce assists.
const Set<ProducerGenerator> _builtInGenerators = {
  AddDiagnosticPropertyReference.new,
  AddDigitSeparatorEveryThreeDigits.new,
  AddDigitSeparatorEveryTwoDigits.new,
  AddReturnType.new,
  AddTypeAnnotation.bulkFixable,
  AssignToLocalVariable.new,
  ConvertAddAllToSpread.new,
  ConvertClassToEnum.new,
  ConvertClassToMixin.new,
  ConvertConditionalExpressionToIfElement.new,
  ConvertDocumentationIntoBlock.new,
  ConvertDocumentationIntoLine.new,
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
  ConvertToDoubleQuotes.new,
  ConvertToExpressionFunctionBody.new,
  ConvertToFieldParameter.new,
  ConvertToGenericFunctionSyntax.new,
  ConvertToIfCaseStatement.new,
  ConvertToIfCaseStatementChain.new,
  ConvertToIntLiteral.new,
  ConvertToMapLiteral.new,
  ConvertToMultilineString.new,
  ConvertToNormalParameter.new,
  ConvertToNullAware.new,
  ConvertToPackageImport.new,
  ConvertToRelativeImport.new,
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

/// The computer for Dart assists.
class AssistProcessor {
  final AssistPerformance? _performance;
  final DartAssistContext _assistContext;
  final Stopwatch _timer = Stopwatch();

  final List<Assist> _assists = [];

  AssistProcessor(this._assistContext, {AssistPerformance? performance})
    : _performance = performance;

  Future<List<Assist>> compute() async {
    _timer.start();
    await _addFromProducers();
    _timer.stop();
    _performance?.computeTime = _timer.elapsed;
    return _assists;
  }

  void _addAssistFromBuilder(
    ChangeBuilder builder,
    AssistKind kind, {
    List<Object>? args,
  }) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    _assists.add(Assist(kind, change));
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext.createResolved(
      libraryResult: _assistContext.libraryResult,
      unitResult: _assistContext.unitResult,
      selectionOffset: _assistContext.selectionOffset,
      selectionLength: _assistContext.selectionLength,
    );

    Future<void> compute(CorrectionProducer producer) async {
      var builder = ChangeBuilder(
        workspace: _assistContext.workspace,
        eol: producer.eol,
      );
      try {
        if (_performance != null) {
          var startTime = _timer.elapsedMilliseconds;
          await producer.compute(builder);
          _performance.producerTimings.add((
            className: producer.runtimeType.toString(),
            elapsedTime: _timer.elapsedMilliseconds - startTime,
          ));
        } else {
          await producer.compute(builder);
        }

        var assistKind = producer.assistKind;
        if (assistKind != null) {
          _addAssistFromBuilder(
            builder,
            assistKind,
            args: producer.assistArguments,
          );
        }
      } on ConflictingEditException catch (exception, stackTrace) {
        // Handle the exception by (a) not adding an assist based on the
        // producer and (b) logging the exception.
        _assistContext.instrumentationService.logException(
          exception,
          stackTrace,
        );
      }
    }

    for (var generator in registeredAssistGenerators.producerGenerators) {
      if (!_generatorAppliesToAnyLintRule(
        generator,
        registeredAssistGenerators.lintRuleMap[generator] ?? {},
      )) {
        var producer = generator(context: context);
        await compute(producer);
      }
    }
    for (var multiGenerator
        in registeredAssistGenerators.multiProducerGenerators) {
      var multiProducer = multiGenerator(context: context);
      for (var producer in await multiProducer.producers) {
        await compute(producer);
      }
    }
  }

  /// Returns whether [generator] applies to any enabled lint rule, among
  /// [errorCodes].
  bool _generatorAppliesToAnyLintRule(
    ProducerGenerator generator,
    Set<LintCode> errorCodes,
  ) {
    if (errorCodes.isEmpty) {
      return false;
    }

    var selectionEnd =
        _assistContext.selectionOffset + _assistContext.selectionLength;
    var locator = NodeLocator(_assistContext.selectionOffset, selectionEnd);
    var node = locator.searchWithin(_assistContext.unitResult.unit);
    if (node == null) {
      return false;
    }

    var fileOffset = node.offset;
    for (var error in _assistContext.unitResult.errors) {
      var errorSource = error.source;
      if (_assistContext.unitResult.path == errorSource.fullName) {
        if (fileOffset >= error.offset &&
            fileOffset <= error.offset + error.length) {
          if (errorCodes.contains(error.errorCode)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
