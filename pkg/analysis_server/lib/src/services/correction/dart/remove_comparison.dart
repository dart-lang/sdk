// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveComparison extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_COMPARISON;

  /// Return `true` if the null comparison will always return `false`.
  bool get _conditionIsFalse =>
      (diagnostic as AnalysisError).errorCode ==
      HintCode.UNNECESSARY_NULL_COMPARISON_FALSE;

  /// Return `true` if the null comparison will always return `true`.
  bool get _conditionIsTrue =>
      (diagnostic as AnalysisError).errorCode ==
      HintCode.UNNECESSARY_NULL_COMPARISON_TRUE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! BinaryExpression) {
      return;
    }
    var binaryExpression = node as BinaryExpression;
    var parent = binaryExpression.parent;
    if (parent is AssertInitializer && _conditionIsTrue) {
      var constructor = parent.parent as ConstructorDeclaration;
      var list = constructor.initializers;
      if (list.length == 1) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.endEnd(constructor.parameters, parent));
        });
      } else {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.nodeInList(list, parent));
        });
      }
    } else if (parent is AssertStatement && _conditionIsTrue) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(utils.getLinesRange(range.node(parent)));
      });
    } else if (parent is BinaryExpression) {
      if (parent.operator.type == TokenType.AMPERSAND_AMPERSAND &&
          _conditionIsTrue) {
        await _removeOperatorAndOperand(builder, parent, node);
      } else if (parent.operator.type == TokenType.BAR_BAR &&
          _conditionIsFalse) {
        await _removeOperatorAndOperand(builder, parent, node);
      }
    } else if (parent is IfStatement) {
      if (parent.elseStatement == null && _conditionIsTrue) {
        var body = _extractBody(parent);
        body = utils.indentSourceLeftRight(body);
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(
              range.startOffsetEndOffset(
                  parent.offset, utils.getLineContentEnd(parent.end)),
              body);
        });
      }
    }
  }

  String _extractBody(IfStatement statement) {
    var body = statement.thenStatement;
    if (body is Block) {
      var statements = body.statements;
      return utils.getRangeText(range.startOffsetEndOffset(
          statements.first.offset,
          utils.getLineContentEnd(statements.last.end)));
    }
    return utils.getNodeText(body);
  }

  /// Use the [builder] to add an edit to delete the operator and given
  /// [operand] from the [binary] expression.
  Future<void> _removeOperatorAndOperand(ChangeBuilder builder,
      BinaryExpression binary, Expression operand) async {
    SourceRange operatorAndOperand;
    if (binary.leftOperand == node) {
      operatorAndOperand = range.startStart(node, binary.rightOperand);
    } else {
      operatorAndOperand = range.endEnd(binary.leftOperand, node);
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(operatorAndOperand);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveComparison newInstance() => RemoveComparison();
}
