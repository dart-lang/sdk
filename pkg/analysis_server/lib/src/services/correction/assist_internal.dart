// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_diagnostic_property_reference.dart';
import 'package:analysis_server/src/services/correction/dart/add_not_null_assert.dart';
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
import 'package:analysis_server/src/services/correction/dart/flutter_wrap_stream_builder.dart';
import 'package:analysis_server/src/services/correction/dart/import_add_show.dart';
import 'package:analysis_server/src/services/correction/dart/inline_invocation.dart';
import 'package:analysis_server/src/services/correction/dart/invert_if_statement.dart';
import 'package:analysis_server/src/services/correction/dart/join_if_with_inner.dart';
import 'package:analysis_server/src/services/correction/dart/join_if_with_outer.dart';
import 'package:analysis_server/src/services/correction/dart/join_variable_declaration.dart';
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
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart'
    hide AssistContributor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

/// The computer for Dart assists.
class AssistProcessor extends BaseProcessor {
  /// A map that can be used to look up the names of the lints for which a given
  /// [CorrectionProducer] will be used.
  static final Map<ProducerGenerator, Set<String>> lintRuleMap =
      createLintRuleMap();

  /// A list of the generators used to produce assists.
  static const List<ProducerGenerator> generators = [
    AddDiagnosticPropertyReference.new,
    AddNotNullAssert.new,
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
    ConvertIntoBlockBody.new,
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
    FlutterWrapBuilder.new,
    FlutterWrapGeneric.new,
    FlutterWrapStreamBuilder.new,
    ImportAddShow.new,
    InlineInvocation.new,
    InvertIfStatement.new,
    JoinIfWithInner.new,
    JoinIfWithOuter.new,
    JoinVariableDeclaration.new,
    RemoveTypeAnnotation.other,
    ReplaceConditionalWithIfElse.new,
    ReplaceIfElseWithConditional.new,
    ReplaceWithVar.new,
    ShadowField.new,
    SortChildPropertyLast.new,
    SplitAndCondition.new,
    SplitVariableDeclaration.new,
    UseCurlyBraces.new,
  ];

  /// A list of the multi-generators used to produce assists.
  static const List<MultiProducerGenerator> multiGenerators = [
    FlutterWrap.new,
    SurroundWith.new,
  ];

  final DartAssistContext assistContext;

  final List<Assist> assists = <Assist>[];

  AssistProcessor(this.assistContext)
      : super(
          selectionOffset: assistContext.selectionOffset,
          selectionLength: assistContext.selectionLength,
          resolvedResult: assistContext.resolveResult,
          workspace: assistContext.workspace,
        );

  Future<List<Assist>> compute() async {
    await _addFromProducers();
    return assists;
  }

  void _addAssistFromBuilder(ChangeBuilder builder, AssistKind kind,
      {List<Object>? args}) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    assists.add(Assist(kind, change));
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext.create(
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
      resolvedResult: resolvedResult,
      workspace: workspace,
    );
    if (context == null) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      var builder = ChangeBuilder(
          workspace: context.workspace, eol: context.utils.endOfLine);
      try {
        await producer.compute(builder);
        var assistKind = producer.assistKind;
        if (assistKind != null) {
          _addAssistFromBuilder(builder, assistKind,
              args: producer.assistArguments);
        }
      } on ConflictingEditException catch (exception, stackTrace) {
        // Handle the exception by (a) not adding an assist based on the
        // producer and (b) logging the exception.
        assistContext.instrumentationService
            .logException(exception, stackTrace);
      }
    }

    for (var generator in generators) {
      var ruleNames = lintRuleMap[generator] ?? {};
      if (!_containsErrorCode(ruleNames)) {
        var producer = generator();
        await compute(producer);
      }
    }
    for (var multiGenerator in multiGenerators) {
      var multiProducer = multiGenerator();
      multiProducer.configure(context);
      for (var producer in await multiProducer.producers) {
        await compute(producer);
      }
    }
  }

  bool _containsErrorCode(Set<String> errorCodes) {
    final node = findSelectedNode();
    if (node == null) {
      return false;
    }

    final fileOffset = node.offset;
    for (var error in assistContext.resolveResult.errors) {
      final errorSource = error.source;
      if (file == errorSource.fullName) {
        if (fileOffset >= error.offset &&
            fileOffset <= error.offset + error.length) {
          if (errorCodes.contains(error.errorCode.name)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Create and return a map that can be used to look up the names of the lints
  /// for which a given `CorrectionProducer` will be used. This allows us to
  /// ensure that we do not also offer the change as an assist when it's already
  /// being offered as a fix.
  static Map<ProducerGenerator, Set<String>> createLintRuleMap() {
    var map = <ProducerGenerator, Set<String>>{};
    for (var entry in FixProcessor.lintProducerMap.entries) {
      var lintName = entry.key;
      for (var generator in entry.value) {
        map.putIfAbsent(generator, () => <String>{}).add(lintName);
      }
    }
    return map;
  }
}
