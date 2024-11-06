// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToCascade extends ResolvedCorrectionProducer {
  ConvertToCascade({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_CASCADE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! ExpressionStatement) return;

    var block = node.parent;
    if (block is! Block) return;

    var previous = _getPrevious(block, node);
    Token? previousOperator;
    Token? semicolon;
    if (previous is ExpressionStatement) {
      semicolon = previous.semicolon;
      previousOperator = _getTargetAndOperator(previous.expression)?.operator;
    } else if (previous is VariableDeclarationStatement) {
      // Single variable declaration.
      if (previous.variables.variables.length != 1) {
        return;
      }
      semicolon = previous.endToken;
    } else {
      return;
    }

    var expression = node.expression;
    var target = _getTargetAndOperator(expression)?.target;
    if (target == null) return;

    var targetReplacement = expression is CascadeExpression ? '' : '.';

    await builder.addDartFileEdit(file, (builder) {
      if (previousOperator != null) {
        builder.addSimpleInsertion(previousOperator.offset, '.');
      }
      if (semicolon != null) {
        builder.addDeletion(range.token(semicolon));
      }
      builder.addSimpleReplacement(range.node(target), targetReplacement);
    });
  }

  Statement? _getPrevious(Block block, Statement statement) {
    var statements = block.statements;
    var index = statements.indexOf(statement);
    return index > 0 ? statements[index - 1] : null;
  }

  _TargetAndOperator? _getTargetAndOperator(Expression expression) {
    if (expression is AssignmentExpression) {
      var lhs = expression.leftHandSide;
      if (lhs is PrefixedIdentifier) {
        return _TargetAndOperator(lhs.prefix, lhs.period);
      }
    } else if (expression is MethodInvocation) {
      return _TargetAndOperator(expression.target, expression.operator);
    } else if (expression is CascadeExpression) {
      return _TargetAndOperator(expression.target, null);
    }
    return null;
  }
}

class _TargetAndOperator {
  final AstNode? target;
  final Token? operator;
  _TargetAndOperator(this.target, this.operator);
}
