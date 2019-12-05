// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import '../util/boolean_expression_utilities.dart';

void _addNodeComparisons(Expression node, Set<Expression> comparisons) {
  if (_isComparison(node)) {
    comparisons.add(node);
  } else if (_isBooleanOperation(node)) {
    comparisons.addAll(_extractComparisons(node as BinaryExpression));
  }
}

Set<Expression> _extractComparisons(BinaryExpression node) {
  final Set<Expression> comparisons = HashSet<Expression>.identity();
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
  final isNegationOperation =
      cOperatorType == BooleanExpressionUtilities.NEGATIONS[eOperatorType] ||
          BooleanExpressionUtilities.IMPLICATIONS[cOperatorType] ==
              BooleanExpressionUtilities.NEGATIONS[eOperatorType];

  final isTrichotomyConjunction = BooleanExpressionUtilities
          .TRICHOTOMY_OPERATORS
          .contains(eOperatorType) &&
      BooleanExpressionUtilities.TRICHOTOMY_OPERATORS.contains(cOperatorType) &&
      tokenType == TokenType.AMPERSAND_AMPERSAND;
  final isNegationOrComparison = isNegationOperation || isTrichotomyConjunction;
  return isNegationOrComparison;
}

bool _sameOperands(String eLeftOperand, String bcLeftOperand,
    String eRightOperand, String bcRightOperand) {
  final sameOperandsSameOrder =
      eLeftOperand == bcLeftOperand && eRightOperand == bcRightOperand;
  final sameOperandsInverted =
      eRightOperand == bcLeftOperand && eLeftOperand == bcRightOperand;
  return sameOperandsSameOrder || sameOperandsInverted;
}

typedef _RecurseCallback = void Function(Expression expression);

class ContradictoryComparisons {
  final Expression first;
  final Expression second;

  ContradictoryComparisons(this.first, this.second);
}

class TestedExpressions {
  final Expression testingExpression;
  final Set<Expression> truths;
  final Set<Expression> negations;
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
        LinkedHashSet.from(facts),
        binaryExpression != null
            ? binaryExpression.operator.type
            : TokenType.AMPERSAND_AMPERSAND);

    if (_contradictions.isEmpty) {
      final set = (binaryExpression != null
          ? _extractComparisons(testingExpression as BinaryExpression)
          : {testingExpression})
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
      Set<Expression> comparisons, TokenType tokenType) {
    final Iterable<Expression> binaryExpressions =
        comparisons.whereType<BinaryExpression>().toSet();
    final contradictions = LinkedHashSet<ContradictoryComparisons>.identity();

    if (testingExpression is SimpleIdentifier) {
      final identifier = testingExpression as SimpleIdentifier;
      bool sameIdentifier(n) =>
          n is SimpleIdentifier && identifier.staticElement == n.staticElement;
      if (negations.any(sameIdentifier)) {
        final otherIdentifier =
            negations.firstWhere(sameIdentifier) as SimpleIdentifier;
        contradictions
            .add(ContradictoryComparisons(otherIdentifier, identifier));
      }
    }

    binaryExpressions.forEach((Expression ex) {
      if (contradictions.isNotEmpty) {
        return;
      }

      final expression = ex as BinaryExpression;
      final eLeftOperand = expression.leftOperand.toString();
      final eRightOperand = expression.rightOperand.toString();
      final eOperatorType = expression.operator.type;
      comparisons
          .where((comparison) =>
              comparison != null &&
              comparison.offset < expression.offset &&
              comparison is BinaryExpression)
          .forEach((Expression c) {
        if (contradictions.isNotEmpty) {
          return;
        }

        final otherExpression = c as BinaryExpression;

        final bcLeftOperand = otherExpression.leftOperand.toString();
        final bcRightOperand = otherExpression.rightOperand.toString();
        final sameOperands = _sameOperands(
            eLeftOperand, bcLeftOperand, eRightOperand, bcRightOperand);

        final cOperatorType = negations.contains(c)
            ? BooleanExpressionUtilities
                .NEGATIONS[otherExpression.operator.type]
            : otherExpression.operator.type;
        final isNegationOrComparison =
            _isNegationOrComparison(cOperatorType, eOperatorType, tokenType);

        if (isNegationOrComparison && sameOperands) {
          contradictions
              .add(ContradictoryComparisons(otherExpression, expression));
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
        final ex = e as BinaryExpression;
        if (ex.operator.type != TokenType.AMPERSAND_AMPERSAND) {
          return;
        }

        final set = _findContradictoryComparisons(
            HashSet.from([ex.leftOperand, ex.rightOperand]), ex.operator.type);
        expressions.addAll(set);
      };
}
