// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expression.dart';
import '../environment.dart';

final Expression T = new LogicExpression.and([]);
final Expression F = new LogicExpression.or([]);

// Token to combine left and right value of a comparison expression in a
// variable expression.
final String _comparisonToken = "__";

/// Transforms an [expression] to disjunctive normal form, which is a
/// standardization where all clauses are separated by `||` (or/disjunction).
/// All clauses must be conjunction (joined by &&) and have negation on
/// literals.
///
/// It computes the disjunctive normal form by computing a truth table with all
/// terms (truth assignment of variables) that make the [expression] become true
/// and then minimizes the terms.
///
/// The procedure is exponential so [expression] should not be too big.
Expression toDisjunctiveNormalForm(Expression expression) {
  var normalizedExpression = expression.normalize();
  var variableExpression =
      _comparisonExpressionsToVariableExpressions(normalizedExpression);
  var minTerms = _satisfiableMinTerms(variableExpression);
  if (minTerms == null) {
    return T;
  } else if (minTerms.isEmpty) {
    return F;
  }
  var disjunctiveNormalForm = new LogicExpression.or(minTerms);
  disjunctiveNormalForm = _minimizeByComplementation(disjunctiveNormalForm);
  return _recoverComparisonExpressions(disjunctiveNormalForm);
}

/// Complementation is a process that tries to combine the min terms above as
/// much as possible. In each iteration, two minsets can be combined if they
/// differ by only one assignment. Ex:
///
/// $a && $b can be combined with !$a && $b since they only differ by $a and
/// !$a. This is easier to see if we represent terms as bits. Let the following
/// min terms be defined:
///
/// m(1): $a && !$b && !$c && !$d -> 1000
/// m(2): $a && !$b && !$c && $d  -> 1001
/// m(3): $a && !$b && $c && !$d  -> 1010
/// m(4): $a && !$b && $c && $d   -> 1011
///
/// In the first iteration, m(1) can be combined with m(2) and m(3), m(2) can be
/// combined with m(4) and m(3) can be combined with m(4). We now have:
///
/// m(1,2): 100-
/// m(1,3): 10-0
/// m(2,4): 10-1
/// m(3,4): 101-
///
/// Let - be a third bit value, which also counts toward difference. Therefore,
/// m(1,2) cannot be combined with m(1,3), but m(1,2) can be combined with
/// m(3,4). We therefore get:
///
/// m(1,2,3,4): 10--
/// m(1,3,2,4): 10--
///
/// At this point, we have two similar minsets, which we also call implicants,
/// that only differ from the way they were added together. These cannot be
/// added together further, so we are left with only one (does not matter which
/// we pick):
///
/// m(1,2,3,4): 10--
///
/// The minimal disjunctive form is, for this example, $a && !$b.
///
/// It is often not the case we only have one implicant left, we may have
/// several.
///
/// m(4,12)
/// m(8,9,10,11)
/// m(8,10,12,14)
/// m(10,11,14,15)
///
/// From here, we can find the minimum form by simply computing a set cover. We
/// can prune the search space a bit though. In the above example, 4 and 15 is
/// only covered by a single implicant. This means, that those are primary, and
/// has to be included in the cover. We then just need to pick the best
/// solution.
///
/// More about this algorithm here:
/// https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm
LogicExpression _minimizeByComplementation(LogicExpression expression) {
  var clauses = expression.operands
      .map((e) => e is LogicExpression ? e.operands : [e])
      .toList();
  // All min terms should be sorted by amount of 1's
  clauses.sort((a, b) {
    var onesInA = a.where((e) => !_isNegatedExpression(e)).length;
    var onesInB = b.where((e) => !_isNegatedExpression(e)).length;
    return onesInA - onesInB;
  });
  var combinedMinSets = _combineMinSets(
      clauses.map((e) => [new LogicExpression.and(e)]).toList(), []);
  List<List<Expression>> minCover = _findMinCover(combinedMinSets, []);
  var finalOperands = minCover.map((minSet) => _reduceMinSet(minSet)).toList();
  return new LogicExpression.or(finalOperands).normalize();
}

/// Computes all assignments of literals that make the [expression] evaluate to
/// true.
List<Expression> _satisfiableMinTerms(Expression expression) {
  var variables = _getVariables(expression);
  bool hasNotSatisfiableAssignment = false;
  List<Expression> satisfiableTerms = <Expression>[];
  var environment = new TruthTableEnvironment(variables);
  for (int i = 0; i < 1 << variables.length; i++) {
    environment.setConfiguration(i);
    if (expression.evaluate(environment)) {
      var operands = <Expression>[];
      for (int j = 0; j < variables.length; j++) {
        if ((i >> j) % 2 == 0) {
          operands.add(negate(variables[j]));
        } else {
          operands.add(variables[j]);
        }
      }
      satisfiableTerms.add(new LogicExpression.and(operands));
    } else {
      hasNotSatisfiableAssignment = true;
    }
  }
  if (!hasNotSatisfiableAssignment) {
    return null;
  }
  return satisfiableTerms;
}

/// The [TruthTableEnvironment] simulates an entry in a truth table where the
/// [variables] are assigned a value bases on the [configuration]. This
/// environment can then be used to evaluate the corresponding expression from
/// which the [variables] was found.
class TruthTableEnvironment extends Environment {
  final List<Expression> variables;
  int configuration;

  TruthTableEnvironment(this.variables);

  void setConfiguration(int configuration) {
    this.configuration = configuration;
  }

  @override
  String lookUp(String name) {
    int index = -1;
    for (int i = 0; i < variables.length; i++) {
      if (variables[i] is VariableExpression &&
          variables[i].toString() == "\$$name") {
        index = i;
        break;
      }
    }
    assert(index > -1);
    var isTrue = (configuration >> index) % 2 == 1;
    return isTrue ? "true" : "false";
  }

  @override
  void validate(String name, String value, List<String> errors) {}
}

/// Combines [minSets] recursively as long as possible. Prime implicants (those
/// that cannot be reduced further) are kept track of in [primeImplicants]. When
/// finished the function returns all combined min sets.
List<List<Expression>> _combineMinSets(
    List<List<Expression>> minSets, List<List<Expression>> primeImplicants) {
  List<List<LogicExpression>> combined = <List<LogicExpression>>[];
  var addedInThisIteration = new Set<List<Expression>>();
  for (var i = 0; i < minSets.length; i++) {
    var minSet = minSets[i];
    var combinedMinSet = false;
    for (var j = i + 1; j < minSets.length; j++) {
      var otherMinSet = minSets[j];
      if (_canCombine(minSet, otherMinSet)) {
        combined.add(minSet.toList(growable: true)..addAll(otherMinSet));
        addedInThisIteration.add(otherMinSet);
        combinedMinSet = true;
      }
    }
    if (!combinedMinSet && !addedInThisIteration.contains(minSet)) {
      primeImplicants.add(minSet);
    }
  }
  if (combined.isNotEmpty) {
    // it is possible to add minsets that are identical:
    // ex: min(1,3), min(1,2) min(2,4) min(3,4) could combine to:
    // min(1,3,2,4) and min(1,2,3,4) which are identical.
    // It is better to reduce such now than to deal with them in an exponential
    // search.
    return _combineMinSets(_uniqueMinSets(combined), primeImplicants);
  }
  return primeImplicants;
}

/// Two min sets can be combined if they only differ by one. We reduce min sets
/// and find their difference based on variables.
bool _canCombine(List<LogicExpression> a, List<LogicExpression> b) {
  return _difference(_reduceMinSet(a).operands, _reduceMinSet(b).operands)
          .length ==
      1;
}

/// This function finds the fixed variables for a collection of implicants in
/// the [minSet]. Unlike the numbering scheme above, ie 10-1 etc. we look
/// directly at variables and count positive and negative occurrences. If we
/// find an implicant with less variables than others, we add the variable to
/// both the positive and negative set, which is effectively setting the value
/// - to that variable.
LogicExpression _reduceMinSet(List<LogicExpression> minSet) {
  var variables = <Expression>[];
  var positive = <Expression>[];
  var negative = <Expression>[];
  for (var implicant in minSet) {
    for (var expression in implicant.operands) {
      assert(expression is! LogicExpression);
      var variable = expression;
      if (_isNegatedExpression(expression)) {
        _addIfNotPresent(expression, negative);
        variable = _getVariables(expression)[0];
      } else {
        _addIfNotPresent(expression, positive);
      }
      _addIfNotPresent(variable, variables);
    }
  }
  for (var implicant in minSet) {
    for (var variable in variables) {
      bool isFree = implicant.operands.where((literal) {
        if (_isNegatedExpression(literal)) {
          return negate(literal).compareTo(variable) == 0;
        } else {
          return literal.compareTo(variable) == 0;
        }
      }).isEmpty;
      if (isFree) {
        _addIfNotPresent(variable, positive);
        _addIfNotPresent(negate(variable), negative);
      }
    }
  }
  for (var neg in negative.toList()) {
    var pos = _findFirst(negate(neg), positive);
    if (pos != null) {
      positive.remove(pos);
      negative.remove(neg);
    }
  }
  return new LogicExpression.and(positive..addAll(negative));
}

/// [_findMinCover] finds the minimum cover of [primaryImplicants]. Finding a
/// minimum set cover is NP-hard, and we are not trying to be really cleaver
/// here. The implicants that cover only a single truth assignment can be
/// directly added to [cover].
List<List<Expression>> _findMinCover(
    List<List<Expression>> primaryImplicants, List<List<Expression>> cover) {
  var minCover = primaryImplicants.toList()..addAll(cover);
  if (cover.isEmpty) {
    var allImplicants = primaryImplicants.toList();
    for (var implicant in allImplicants) {
      for (var exp in implicant) {
        bool found = false;
        for (var otherImplicant in allImplicants) {
          if (implicant != otherImplicant &&
              _findFirst(exp, otherImplicant) != null) {
            found = true;
          }
        }
        if (!found) {
          cover.add(implicant);
          primaryImplicants.remove(implicant);
          break;
        }
      }
    }
    if (_isCover(cover, primaryImplicants)) {
      return cover;
    }
  }
  for (var implicant in primaryImplicants) {
    var newCover = cover.toList()..add(implicant);
    if (!_isCover(newCover, primaryImplicants)) {
      var newPrimaryList =
          primaryImplicants.where((i) => i != implicant).toList();
      newCover = _findMinCover(newPrimaryList, newCover);
    }
    if (newCover.length < minCover.length) {
      minCover = newCover;
    }
  }
  return minCover;
}

/// Checks if [cover] is a set cover of [implicants] by searching through all
/// expressions in each implicant, to see if the cover has the same expression.
bool _isCover(List<List<Expression>> cover, List<List<Expression>> implicants) {
  for (var implicant in implicants) {
    for (var exp in implicant) {
      if (cover.where((i) => _findFirst(exp, i) != null).isEmpty) {
        return false;
      }
    }
  }
  return true;
}

// Computes the difference between two sets of expressions in disjunctive normal
// form. if the difference is a negation, the difference is only counted once.
List<Expression> _difference(List<Expression> As, List<Expression> Bs) {
  var difference = <Expression>[]
    ..addAll(As.where((a) => _findFirst(a, Bs) == null))
    ..addAll(Bs.where((b) => _findFirst(b, As) == null));
  for (var expression in difference.toList()) {
    if (_isNegatedExpression(expression)) {
      if (_findFirst(negate(expression), difference) != null) {
        difference.remove(expression);
      }
    }
  }
  return difference;
}

/// Finds the first occurrence of [expressionToFind] in [expressions] or
/// returns null.
Expression _findFirst<Expression>(
    expressionToFind, List<Expression> expressions) {
  return expressions.firstWhere(
      (otherExpression) => expressionToFind.compareTo(otherExpression) == 0,
      orElse: () => null);
}

/// Adds [expressionToAdd] to [expressions] if is not present.
void _addIfNotPresent(
    Expression expressionToAdd, List<Expression> expressions) {
  if (_findFirst(expressionToAdd, expressions) == null) {
    expressions.add(expressionToAdd);
  }
}

/// Computes all unique min sets, thereby disregarding the order for which they
/// were combined.
List<List<LogicExpression>> _uniqueMinSets(
    List<List<LogicExpression>> minSets) {
  var uniqueMinSets = <List<LogicExpression>>[];
  for (int i = 0; i < minSets.length; i++) {
    bool foundEqual = false;
    for (var j = i - 1; j >= 0; j--) {
      if (_areMinSetsEqual(minSets[i], minSets[j])) {
        foundEqual = true;
        break;
      }
    }
    if (!foundEqual) {
      uniqueMinSets.add(minSets[i]);
    }
  }
  return uniqueMinSets;
}

/// Measures if two min sets are equal by checking that [minSet1] c [minSet2]
/// and minSet1.length == minSet2.length.
bool _areMinSetsEqual(
    List<LogicExpression> minSet1, List<LogicExpression> minSet2) {
  int found = 0;
  for (var expression in minSet1) {
    if (_findFirst(expression, minSet2) != null) {
      found += 1;
    }
  }
  return found == minSet2.length;
}

bool _isNegatedExpression(Expression expression) {
  return expression is VariableExpression && expression.negate ||
      expression is ComparisonExpression && expression.negate;
}

/// Gets all variables occurring in the [expression].
List<Expression> _getVariables(Expression expression) {
  if (expression is LogicExpression) {
    var variables = <Expression>[];
    expression.operands.forEach(
        (e) => _getVariables(e).forEach((v) => _addIfNotPresent(v, variables)));
    return variables;
  }
  if (expression is VariableExpression) {
    return [new VariableExpression(expression.variable)];
  }
  if (expression is ComparisonExpression) {
    throw new Exception("Cannot use ComparisonExpression for variables");
  }
  return [];
}

Expression negate(Expression expression, {bool positive: false}) {
  if (expression is LogicExpression && expression.isOr) {
    return new LogicExpression.and(expression.operands
        .map((e) => negate(e, positive: !positive))
        .toList());
  }
  if (expression is LogicExpression && expression.isAnd) {
    return new LogicExpression.or(expression.operands
        .map((e) => negate(e, positive: !positive))
        .toList());
  }
  if (expression is ComparisonExpression) {
    return new ComparisonExpression(
        expression.left, expression.right, !expression.negate);
  }
  if (expression is VariableExpression) {
    return new VariableExpression(expression.variable,
        negate: !expression.negate);
  }
  return expression;
}

// Convert ComparisonExpressions to VariableExpression to make sure looking
// we can se individual variables truthiness in the [TruthTableEnvironment].
Expression _comparisonExpressionsToVariableExpressions(Expression expression) {
  if (expression is LogicExpression) {
    return new LogicExpression(
        expression.op,
        expression.operands
            .map((exp) => _comparisonExpressionsToVariableExpressions(exp))
            .toList());
  }
  if (expression is ComparisonExpression) {
    return new VariableExpression(
        new Variable(
            expression.left.name + _comparisonToken + expression.right),
        negate: expression.negate);
  }
  return expression;
}

Expression _recoverComparisonExpressions(Expression expression) {
  if (expression is LogicExpression) {
    return new LogicExpression(
        expression.op,
        expression.operands
            .map((exp) => _recoverComparisonExpressions(exp))
            .toList());
  }
  if (expression is VariableExpression &&
      expression.variable.name.contains(_comparisonToken)) {
    int tokenIndex = expression.variable.name.indexOf(_comparisonToken);
    return new ComparisonExpression(
        new Variable(expression.variable.name.substring(0, tokenIndex)),
        expression.variable.name
            .substring(tokenIndex + _comparisonToken.length),
        expression.negate);
  }
  return expression;
}
