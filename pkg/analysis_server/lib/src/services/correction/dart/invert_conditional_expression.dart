// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InvertConditionalExpression extends ResolvedCorrectionProducer {
  InvertConditionalExpression({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.INVERT_CONDITIONAL_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    MethodInvocation? methodInvocation = thisOrParentOfType(node);

    node = methodInvocation ?? node;
    AwaitExpression? awaitExp1 = thisOrParentOfType(node);

    node = awaitExp1 ?? node;
    Expression? booleanExpression;
    if (node case IsExpression() || BinaryExpression() || BooleanLiteral()) {
      booleanExpression = node as Expression;
    } else if (node.parent
        case IsExpression() || BinaryExpression() || BooleanLiteral()) {
      booleanExpression = node.parent as Expression;
    } else if (thisOrParentOfType<PrefixExpression>(node)
        case PrefixExpression exp) {
      if (exp.operator.type == TokenType.BANG) {
        booleanExpression = exp;
      }
    }

    node = booleanExpression ?? node;
    ParenthesizedExpression? parenthesizedExpression = thisOrParentOfType(node);

    node = parenthesizedExpression ?? node;
    AwaitExpression? awaitExp2 = thisOrParentOfType(node);

    node = awaitExp2 ?? node;
    ConditionalExpression? conditionalExpression = thisOrParentOfType(node);
    if (conditionalExpression == null) {
      return;
    }

    var condition = conditionalExpression.condition;
    var invertedCondition = utils.invertCondition(condition);

    var thenCode = utils.getNodeText(conditionalExpression.thenExpression);
    var elseCode = utils.getNodeText(conditionalExpression.elseExpression);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(condition), invertedCondition);
      builder.addSimpleReplacement(
          range.node(conditionalExpression.thenExpression), elseCode);
      builder.addSimpleReplacement(
          range.node(conditionalExpression.elseExpression), thenCode);
    });
  }

  T? thisOrParentOfType<T extends AstNode>(AstNode node) {
    T? result;
    if (node is T) {
      result = node;
    } else if (node.parent case T parent) {
      result = parent;
    }
    return result;
  }
}
