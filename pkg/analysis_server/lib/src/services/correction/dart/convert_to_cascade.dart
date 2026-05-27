// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
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
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.convertToCascade;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) return;

    var diagnosticOffset = diagnostic.problemMessage.offset;
    var diagnosticLength = diagnostic.problemMessage.length;
    var diagnosticEnd = diagnosticOffset + diagnosticLength;

    var startNode = unit
        .select(offset: diagnosticOffset, length: 1)
        ?.coveringNode;
    var firstStatement = startNode?.thisOrAncestorOfType<Statement>();
    if (firstStatement == null) return;

    var parent = firstStatement.parent;
    List<Statement> statements;
    if (parent is Block) {
      statements = parent.statements;
    } else if (parent is SwitchCase) {
      statements = parent.statements;
    } else if (parent is SwitchDefault) {
      statements = parent.statements;
    } else if (parent is SwitchPatternCase) {
      statements = parent.statements;
    } else {
      return;
    }

    var cascadeStatements = statements
        .where((s) => s.offset >= diagnosticOffset && s.end <= diagnosticEnd)
        .toList();
    if (cascadeStatements.isEmpty) return;

    var firstCascadeStatement = cascadeStatements.first;
    var indexInParent = statements.indexOf(firstCascadeStatement);
    if (indexInParent > 0) {
      cascadeStatements.insert(0, statements[indexInParent - 1]);
    }
    if (cascadeStatements.length < 2) return;

    for (var index = 1; index < cascadeStatements.length; index++) {
      var statement = cascadeStatements[index];
      if (statement is! ExpressionStatement) return;

      Token? previousOperator;
      Token? semicolon;
      var previous = cascadeStatements[index - 1];
      if (previous is ExpressionStatement) {
        semicolon = previous.semicolon;
        previousOperator = (index == 1)
            ? _getTargetAndOperator(previous.expression)?.operator
            : null;
      } else if (previous is VariableDeclarationStatement) {
        // Single variable declaration.
        if (previous.variables.variables.length != 1) {
          return;
        }
        semicolon = previous.endToken;
      } else {
        return;
      }

      var expression = statement.expression;
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
