// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:linter/src/util/boolean_expression_utilities.dart';

void _addNodeComparisons(Expression node, HashSet<Expression> comparisons) {
  if (_isComparison(node)) {
    comparisons.add(node);
  } else if (_isBooleanOperation(node)) {
    comparisons.addAll(_extractComparisons(node));
  }
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

bool _isBooleanOperation(Expression expression) =>
    expression is BinaryExpression &&
    BooleanExpressionUtilities.BOOLEAN_OPERATIONS
        .contains(expression.operator.type);

bool _isComparison(Expression expression) =>
    expression is BinaryExpression &&
    BooleanExpressionUtilities.COMPARISONS.contains(expression.operator.type);

bool _isNegationOrComparison(
    TokenType cOperatorType, TokenType eOperatorType, TokenType tokenType) {
  final bool isNegationOperation =
      cOperatorType == BooleanExpressionUtilities.NEGATIONS[eOperatorType] ||
          BooleanExpressionUtilities.IMPLICATIONS[cOperatorType] ==
              BooleanExpressionUtilities.NEGATIONS[eOperatorType];

  final bool isTrichotomyConjunction = BooleanExpressionUtilities
          .TRICHOTOMY_OPERATORS
          .contains(eOperatorType) &&
      BooleanExpressionUtilities.TRICHOTOMY_OPERATORS.contains(cOperatorType) &&
      tokenType == TokenType.AMPERSAND_AMPERSAND;
  final isNegationOrComparison = isNegationOperation || isTrichotomyConjunction;
  return isNegationOrComparison;
}

bool _sameOperands(String eLeftOperand, String bcLeftOperand,
    String eRightOperand, String bcRightOperand) {
  final bool sameOperandsSameOrder =
      eLeftOperand == bcLeftOperand && eRightOperand == bcRightOperand;
  final bool sameOperandsInverted =
      eRightOperand == bcLeftOperand && eLeftOperand == bcRightOperand;
  return sameOperandsSameOrder || sameOperandsInverted;
}

typedef void _RecurseCallback(Expression expression);

class ContradictoryComparisons {
  final Expression first;
  final Expression second;

  ContradictoryComparisons(this.first, this.second);
}

class TestedExpressions {
  final Expression testingExpression;
  final LinkedHashSet<Expression> truths;
  final LinkedHashSet<Expression> negations;
  LinkedHashSet<ContradictoryComparisons> _contradictions;

  TestedExpressions(this.testingExpression, this.truths, this.negations);

  LinkedHashSet<ContradictoryComparisons> evaluateInvariant() {
    if (_contradictions != null) {
      return _contradictions;
    }

    final binaryExpression = testingExpression is BinaryExpression
        ? testingExpression as BinaryExpression
        : null;
    var facts = binaryExpression != null
        ? [binaryExpression.leftOperand, binaryExpression.rightOperand]
        : [testingExpression];
    _contradictions = _findContradictoryComparisons(
        new LinkedHashSet.from(facts),
        binaryExpression != null
            ? binaryExpression.operator.type
            : TokenType.AMPERSAND_AMPERSAND);

    if (_contradictions.isEmpty) {
      HashSet<Expression> set = (binaryExpression != null
          ? _extractComparisons(testingExpression)
          : [testingExpression].toSet())
        ..addAll(truths)
        ..addAll(negations);
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
  LinkedHashSet<ContradictoryComparisons> _findContradictoryComparisons(
      HashSet<Expression> comparisons, TokenType tokenType) {
    final Iterable<Expression> binaryExpressions =
        comparisons.where((e) => e is BinaryExpression).toSet();
    LinkedHashSet<ContradictoryComparisons> contradictions =
        new LinkedHashSet.identity();

    if (testingExpression is SimpleIdentifier) {
      SimpleIdentifier identifier = testingExpression;
      bool sameIdentifier(n) =>
          n is SimpleIdentifier && identifier.bestElement == n.bestElement;
      if (negations.any(sameIdentifier)) {
        SimpleIdentifier otherIdentifier = negations.firstWhere(sameIdentifier);
        contradictions
            .add(new ContradictoryComparisons(otherIdentifier, identifier));
      }
    }

    binaryExpressions.forEach((Expression ex) {
      if (contradictions.isNotEmpty) {
        return;
      }

      BinaryExpression expression = ex as BinaryExpression;
      final String eLeftOperand = expression.leftOperand.toString();
      final String eRightOperand = expression.rightOperand.toString();
      final TokenType eOperatorType = expression.operator.type;
      comparisons
          .where((comparison) =>
              comparison != null &&
              comparison.offset < expression.offset &&
              comparison is BinaryExpression)
          .forEach((Expression c) {
        if (contradictions.isNotEmpty) {
          return;
        }

        final BinaryExpression otherExpression = c;

        final String bcLeftOperand = otherExpression.leftOperand.toString();
        final String bcRightOperand = otherExpression.rightOperand.toString();
        final bool sameOperands = _sameOperands(
            eLeftOperand, bcLeftOperand, eRightOperand, bcRightOperand);

        final TokenType cOperatorType = negations.contains(c)
            ? BooleanExpressionUtilities
                .NEGATIONS[otherExpression.operator.type]
            : otherExpression.operator.type;
        final bool isNegationOrComparison =
            _isNegationOrComparison(cOperatorType, eOperatorType, tokenType);

        if (isNegationOrComparison && sameOperands) {
          contradictions
              .add(new ContradictoryComparisons(otherExpression, expression));
        }
      });
    });

    if (contradictions.isEmpty) {
      binaryExpressions.forEach(_recurseOnChildNodes(contradictions));
    }

    return contradictions;
  }

  _RecurseCallback _recurseOnChildNodes(
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
