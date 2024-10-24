// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/lint_names.dart';

class ConvertRelatedToCascade extends ResolvedCorrectionProducer {
  final CorrectionProducerContext _context;

  ConvertRelatedToCascade({required super.context}) : _context = context;

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_RELATED_TO_CASCADE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! ExpressionStatement) return;

    var block = node.parent;
    if (block is! Block) return;

    var errors = _context.dartFixContext?.resolvedResult.errors
        .where((error) => error.errorCode.name == LintNames.cascade_invocations)
        .whereNot((error) =>
            error.offset == node.offset && error.length == node.length);

    if (errors == null || errors.isEmpty) return;

    var previous = _getPrevious(block, node);
    var next = _getNext(block, node);

    // Skip if no error has the offset and length of previous or next.
    if (errors.none((error) =>
            error.offset == previous?.offset &&
            error.length == previous?.length) &&
        errors.none((error) =>
            error.offset == next?.offset && error.length == next?.length)) {
      return;
    }

    // Get the full list of statements with errors that are related to this.
    List<ExpressionStatement> relatedStatements = [node];
    while (previous != null && previous is ExpressionStatement) {
      if (errors.any((error) =>
          error.offset == previous!.offset &&
          error.length == previous.length)) {
        relatedStatements.insert(0, previous);
      }
      previous = _getPrevious(block, previous);
    }
    while (next != null && next is ExpressionStatement) {
      if (errors.any((error) =>
          error.offset == next!.offset && error.length == next.length)) {
        relatedStatements.add(next);
      }
      next = _getNext(block, next);
    }

    for (var (index, statement) in relatedStatements.indexed) {
      Token? previousOperator;
      Token? semicolon;
      var previous = index > 0
          ? relatedStatements[index - 1]
          : _getPrevious(block, statement);
      if (previous is ExpressionStatement) {
        semicolon = previous.semicolon;
        previousOperator = (index == 0)
            ? _getTargetAndOperator(previous.expression)?.operator
            : null;
      } else if (previous is VariableDeclarationStatement) {
        // Single variable declaration.
        if (previous.variables.variables.length != 1) {
          return;
        }
        semicolon = previous.endToken;
      } else {
        // TODO(fmorschel): Refactor this to collect all changes and apply them
        // at once.
        // One unfortunate consequence of this approach is that we might have
        // already used [builder.addDartFileEdit], and so we could stop with
        // incomplete changes.
        // In the future there could be other cases for triggering this fix
        // other than `ExpressionStatement` and `VariableDeclarationStatement`.
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

  Statement? _getNext(Block block, Statement statement) {
    var statements = block.statements;
    var index = statements.indexOf(statement);
    return index < (statements.length - 1) ? statements[index + 1] : null;
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
