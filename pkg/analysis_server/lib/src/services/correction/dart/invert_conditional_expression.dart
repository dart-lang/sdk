// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class InvertConditionalExpression extends ResolvedCorrectionProducer {
  InvertConditionalExpression({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.INVERT_CONDITIONAL_EXPRESSION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var conditionalExpression = _getConditionalExpressionAncestor();
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
        range.node(conditionalExpression.thenExpression),
        elseCode,
      );
      builder.addSimpleReplacement(
        range.node(conditionalExpression.elseExpression),
        thenCode,
      );
    });
  }

  /// Finds the ConditionalExpression that is the ancestor of the node if it is
  /// close enough to the ConditionalExpression.
  ///
  /// This is not exhaustive, but should cover the most common cases.
  /// The intention is to make this assist callable from more places than the
  /// expression itself, while also keeping the assist close enough to the
  /// expression to be intuitive.
  ///
  /// E.g.:
  ///   - Calling the assist on any part of
  ///                                 `(await futureBool()) ? value() : (1 + 2)`
  ///
  /// This should prevent cases like calling the assist on `method` in
  /// `condition ? outer(method(args)) : null` since that is not a "close
  /// enough" child of the ConditionalExpression. This could be revisited if
  /// there is a need for it.
  ///
  /// It is also deliberately not allowing the assist to be called on inner
  /// lambdas since that would be unintuitive and not very useful.
  ConditionalExpression? _getConditionalExpressionAncestor() {
    var node = this.node;
    MethodInvocation? methodInvocation = _thisOrParentOfType(node);

    node = methodInvocation ?? node;
    AwaitExpression? awaitExp1 = _thisOrParentOfType(node);

    node = awaitExp1 ?? node;
    Expression? booleanExpression;
    if (node case IsExpression() || BinaryExpression() || BooleanLiteral()) {
      booleanExpression = node as Expression;
    } else if (node.parent
        case IsExpression() || BinaryExpression() || BooleanLiteral()) {
      booleanExpression = node.parent as Expression;
    } else if (_thisOrParentOfType<PrefixExpression>(node)
        case Expression exp) {
      booleanExpression = exp;
    }

    node = booleanExpression ?? node;
    ParenthesizedExpression? parenthesizedExpression = _thisOrParentOfType(
      node,
    );

    node = parenthesizedExpression ?? node;
    AwaitExpression? awaitExp2 = _thisOrParentOfType(node);

    node = awaitExp2 ?? node;
    return _thisOrParentOfType(node);
  }

  T? _thisOrParentOfType<T extends AstNode>(AstNode node) {
    T? result;
    if (node is T) {
      result = node;
    } else if (node.parent case T parent) {
      result = parent;
    }
    return result;
  }
}
