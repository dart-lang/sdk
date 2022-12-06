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
  Set<Expression> comparisons = HashSet<Expression>.identity();
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
  var isNegationOperation =
      cOperatorType == BooleanExpressionUtilities.NEGATIONS[eOperatorType] ||
          BooleanExpressionUtilities.IMPLICATIONS[cOperatorType] ==
              BooleanExpressionUtilities.NEGATIONS[eOperatorType];

  var isTrichotomyConjunction = BooleanExpressionUtilities.TRICHOTOMY_OPERATORS
          .contains(eOperatorType) &&
      BooleanExpressionUtilities.TRICHOTOMY_OPERATORS.contains(cOperatorType) &&
      tokenType == TokenType.AMPERSAND_AMPERSAND;
  var isNegationOrComparison = isNegationOperation || isTrichotomyConjunction;
  return isNegationOrComparison;
}

bool _sameOperands(String eLeftOperand, String bcLeftOperand,
    String eRightOperand, String bcRightOperand) {
  var sameOperandsSameOrder =
      eLeftOperand == bcLeftOperand && eRightOperand == bcRightOperand;
  var sameOperandsInverted =
      eRightOperand == bcLeftOperand && eLeftOperand == bcRightOperand;
  return sameOperandsSameOrder || sameOperandsInverted;
}

typedef _RecurseCallback = void Function(Expression expression);

class ContradictoryComparisons {
  final Expression? first;
  final Expression second;

  ContradictoryComparisons(this.first, this.second);
}

class TestedExpressions {
  final Expression testingExpression;
  final Set<Expression> truths;
  final Set<Expression> negations;
  LinkedHashSet<ContradictoryComparisons>? _contradictions;

  TestedExpressions(this.testingExpression, this.truths, this.negations);

  LinkedHashSet<ContradictoryComparisons>? evaluateInvariant() {
    if (_contradictions != null) {
      return _contradictions;
    }

    var testingExpression = this.testingExpression;

    var binaryExpression =
        testingExpression is BinaryExpression ? testingExpression : null;

    Iterable<Expression> facts;
    if (testingExpression is BinaryExpression) {
      facts = [testingExpression.leftOperand, testingExpression.rightOperand];
    } else {
      facts = [testingExpression];
    }

    _contradictions = _findContradictoryComparisons(
        LinkedHashSet.of(facts),
        binaryExpression != null
            ? binaryExpression.operator.type
            : TokenType.AMPERSAND_AMPERSAND);

    if (_contradictions?.isEmpty ?? false) {
      var set = (binaryExpression != null
          ? _extractComparisons(testingExpression as BinaryExpression)
          : {testingExpression})
        ..addAll(truths.whereType<Expression>())
        ..addAll(negations.whereType<Expression>());
      // Here and in several places we proceed only for
      // TokenType.AMPERSAND_AMPERSAND because we then know that all comparisons
      // must be true.
      _contradictions?.addAll(
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
    Iterable<Expression> binaryExpressions =
        comparisons.whereType<BinaryExpression>().toSet();
    var contradictions = LinkedHashSet<ContradictoryComparisons>.identity();

    var testingExpression = this.testingExpression;
    if (testingExpression is SimpleIdentifier) {
      bool sameIdentifier(n) =>
          n is SimpleIdentifier &&
          testingExpression.staticElement == n.staticElement;
      if (negations.any(sameIdentifier)) {
        var otherIdentifier =
            negations.firstWhere(sameIdentifier) as SimpleIdentifier?;
        contradictions
            .add(ContradictoryComparisons(otherIdentifier, testingExpression));
      }
    }

    for (var ex in binaryExpressions) {
      if (contradictions.isNotEmpty) {
        break;
      }

      var expression = ex as BinaryExpression;
      var eLeftOperand = expression.leftOperand.toString();
      var eRightOperand = expression.rightOperand.toString();
      var eOperatorType = expression.operator.type;
      comparisons
          .where((comparison) =>
              comparison.offset < expression.offset &&
              comparison is BinaryExpression)
          .forEach((Expression c) {
        if (contradictions.isNotEmpty) {
          return;
        }

        var otherExpression = c as BinaryExpression;

        var bcLeftOperand = otherExpression.leftOperand.toString();
        var bcRightOperand = otherExpression.rightOperand.toString();
        var sameOperands = _sameOperands(
            eLeftOperand, bcLeftOperand, eRightOperand, bcRightOperand);

        var cOperatorType = negations.contains(c)
            ? BooleanExpressionUtilities
                .NEGATIONS[otherExpression.operator.type]
            : otherExpression.operator.type;
        if (cOperatorType != null) {
          var isNegationOrComparison =
              _isNegationOrComparison(cOperatorType, eOperatorType, tokenType);
          if (isNegationOrComparison && sameOperands) {
            contradictions
                .add(ContradictoryComparisons(otherExpression, expression));
          }
        }
      });
    }

    if (contradictions.isEmpty) {
      binaryExpressions.forEach(_recurseOnChildNodes(contradictions));
    }

    return contradictions;
  }

  _RecurseCallback _recurseOnChildNodes(
          LinkedHashSet<ContradictoryComparisons> expressions) =>
      (Expression e) {
        var ex = e as BinaryExpression;
        if (ex.operator.type != TokenType.AMPERSAND_AMPERSAND) {
          return;
        }

        var set = _findContradictoryComparisons(
            HashSet.of([ex.leftOperand, ex.rightOperand]), ex.operator.type);
        expressions.addAll(set);
      };
}
