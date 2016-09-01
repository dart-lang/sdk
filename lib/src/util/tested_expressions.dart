// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util.tested_expressions;

import 'dart:collection';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:linter/src/util/boolean_expression_utilities.dart';

typedef void _recurseCallback(Expression expression);

class TestedExpressions {
  final BinaryExpression testingExpression;
  final LinkedHashSet<Expression> truths;
  final LinkedHashSet<Expression> negations;
  LinkedHashSet<ContradictoryComparisons> _contradictions;

  TestedExpressions(this.testingExpression, this.truths, this.negations);

  LinkedHashSet<ContradictoryComparisons> evaluateInvariant() {
    if (_contradictions != null) {
      return _contradictions;
    }

    _contradictions = _findContradictoryComparisons(
        new LinkedHashSet.from(
            [testingExpression.leftOperand, testingExpression.rightOperand]),
        testingExpression.operator.type);

    if (_contradictions.isEmpty) {
      HashSet<Expression> set = _extractComparisons(testingExpression)
        ..addAll(truths)..addAll(negations);
      // Here and in several places we proceed only for
      // TokenType.AMPERSAND_AMPERSAND because we then know that all comparisons
      // must be true.
      _contradictions.addAll(
          _findContradictoryComparisons(set, TokenType.AMPERSAND_AMPERSAND));
    }

    return _contradictions;
  }

  /// TODO: A truly smart implementation would detect
  /// (ref.prop && other.otherProp) && (!ref.prop || !other.otherProp)
  /// assuming properties are pure computations. i.e. dealing with De Morgan's
  /// laws https://en.wikipedia.org/wiki/De_Morgan%27s_laws
  LinkedHashSet<ContradictoryComparisons> _findContradictoryComparisons
      (HashSet<Expression> comparisons,
      TokenType tokenType) {
    final Iterable<Expression> binaryExpressions = comparisons
        .where((e) => e is BinaryExpression).toSet();

    LinkedHashSet<ContradictoryComparisons> contradictions =
        new LinkedHashSet.identity();
    binaryExpressions.forEach((Expression ex) {
      if (contradictions.isNotEmpty) {
        return;
      }

      BinaryExpression e = ex as BinaryExpression;
      final String eLeftOperand = e.leftOperand.toString();
      final String eRightOperand = e.rightOperand.toString();
      TokenType eOperatorType = e.operator.type;
      comparisons
          .where((c) => c.offset < e.offset && c is BinaryExpression)
          .forEach((Expression c) {
        if (contradictions.isNotEmpty) {
          return;
        }

        BinaryExpression bc = c;
        TokenType cOperatorType = negations.contains(c)
            ? BooleanExpressionUtilities.NEGATIONS[bc.operator.type]
            : bc.operator.type;
        final String bcLeftOperand = bc.leftOperand.toString();
        final String bcRightOperand = bc.rightOperand.toString();
        final bool sameOperands =
            eLeftOperand == bcLeftOperand && eRightOperand == bcRightOperand;
        final bool sameOperandsInverted =
            eRightOperand == bcLeftOperand && eLeftOperand == bcRightOperand;
        final bool isNegationOperation =
            cOperatorType ==
                BooleanExpressionUtilities.NEGATIONS[eOperatorType] ||
                BooleanExpressionUtilities.IMPLICATIONS[cOperatorType] ==
                    BooleanExpressionUtilities.NEGATIONS[eOperatorType];
        final bool isTrichotomyConjunction =
            BooleanExpressionUtilities.
            TRICHOTOMY_OPERATORS.contains(eOperatorType) &&
                BooleanExpressionUtilities.
                TRICHOTOMY_OPERATORS.contains(cOperatorType) &&
                tokenType == TokenType.AMPERSAND_AMPERSAND;
        if ((isNegationOperation || isTrichotomyConjunction) &&
            (sameOperands || sameOperandsInverted)) {
          contradictions.add(new ContradictoryComparisons(c, ex));
        }
      });
    });

    if (contradictions.isEmpty) {
      binaryExpressions.forEach(_recurseOnChildNodes(contradictions));
    }

    return contradictions;
  }

  _recurseCallback _recurseOnChildNodes(
      LinkedHashSet<ContradictoryComparisons> expressions) =>
          (Expression e) {
            BinaryExpression ex = e as BinaryExpression;
            if (ex.operator.type != TokenType.AMPERSAND_AMPERSAND) {
              return;
            }

            LinkedHashSet<ContradictoryComparisons> set =
            _findContradictoryComparisons(
                new HashSet.from([ex.leftOperand, ex.rightOperand]),
                ex.operator.type);
            expressions.addAll(set);
          };
}

class ContradictoryComparisons {
  final BinaryExpression first;
  final BinaryExpression second;

  ContradictoryComparisons(this.first, this.second);
}

HashSet<Expression> _extractComparisons(BinaryExpression node) {
  final HashSet<Expression> comparisons = new HashSet<Expression>.identity();
  if (_isComparison(node)) {
    comparisons.add(node);
  }
  if (node.operator.type != TokenType.AMPERSAND_AMPERSAND) {
    return comparisons;
  }

  _addNodeComparisons(node.leftOperand, comparisons);
  _addNodeComparisons(node.rightOperand, comparisons);

  return comparisons;
}

void _addNodeComparisons(Expression node, HashSet<Expression> comparisons) {
  if (_isComparison(node)) {
    comparisons.add(node);
  } else if (_isBooleanOperation(node)) {
    comparisons.addAll(_extractComparisons(node));
  }
}

bool _isComparison(Expression expression) => expression is BinaryExpression &&
    BooleanExpressionUtilities.COMPARISONS.contains(expression.operator.type);

bool _isBooleanOperation(Expression expression) =>
    expression is BinaryExpression &&
        BooleanExpressionUtilities.BOOLEAN_OPERATIONS.
        contains(expression.operator.type);
