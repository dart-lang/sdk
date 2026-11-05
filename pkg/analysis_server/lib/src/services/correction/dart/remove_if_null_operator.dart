// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveIfNullOperator extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeIfNullOperator;

  @override
  FixKind get multiFixKind => DartFixKind.removeIfNullOperatorMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var expression = node.thisOrAncestorOfType<BinaryExpression>();
    if (expression == null) {
      return;
    }

    if (applyingBulkFixes) {
      var operatorType = expression.operator.type;

      // Include the whole chain so that adjacent null operands are removed in
      // the same edit.
      var chain = expression;
      while (true) {
        var parent = chain.parent;
        if (parent is! BinaryExpression ||
            parent.operator.type != operatorType) {
          break;
        }
        chain = parent;
      }

      // Let the first diagnostic in the chain compose all of its deletions.
      var diagnostic = this.diagnostic;
      if (diagnostic == null) return;
      var diagnostics = unitResult.diagnostics.where(
        (candidate) =>
            candidate.diagnosticCode == diagnostic.diagnosticCode &&
            chain.offset <= candidate.offset &&
            candidate.offset + candidate.length <= chain.end,
      );
      if (diagnostics.firstOrNull?.offset != diagnostic.offset) return;

      var operands = <Expression>[];
      void addOperands(Expression operand) {
        if (operand is BinaryExpression &&
            operand.operator.type == operatorType) {
          addOperands(operand.leftOperand);
          addOperands(operand.rightOperand);
        } else {
          operands.add(operand);
        }
      }

      addOperands(chain);

      // Keep the last operand when the chain consists entirely of nulls.
      var nullOperandIndexes = <int>{
        for (var index = 0; index < operands.length; index++)
          if (operands[index].unParenthesized is NullLiteral) index,
      };
      if (nullOperandIndexes.length == operands.length) {
        nullOperandIndexes.remove(operands.length - 1);
      }

      await builder.addDartFileEdit(file, (builder) {
        var hasRetainedOperand = false;
        for (var index = 0; index < operands.length; index++) {
          var operand = operands[index];
          if (!nullOperandIndexes.contains(index)) {
            hasRetainedOperand = true;
            continue;
          }

          var sourceRange = hasRetainedOperand
              ? range.endEnd(operands[index - 1], operand)
              : range.startStart(operand, operands[index + 1]);
          builder.addDeletion(sourceRange);
        }
      });
      return;
    }

    SourceRange sourceRange;
    if (expression.leftOperand.unParenthesized is NullLiteral) {
      sourceRange = range.startStart(
        expression.leftOperand,
        expression.rightOperand,
      );
    } else if (expression.rightOperand.unParenthesized is NullLiteral) {
      sourceRange = range.endEnd(
        expression.leftOperand,
        expression.rightOperand,
      );
    } else {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(sourceRange);
    });
  }
}
