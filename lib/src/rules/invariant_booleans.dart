// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.invariant_booleans;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/boolean_expression_utilities.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/tested_expressions.dart';

const _desc =
    r'Conditions should not unconditionally evaluate to "TRUE" or to "FALSE"';

const _details = r'''

**DON'T** test for conditions that can be inferred at compile time or test the
same condition twice.
Conditional statements using a condition which cannot be anything but FALSE have
the effect of making blocks of code non-functional. If the condition cannot
evaluate to anything but TRUE, the conditional statement is completely
redundant, and makes the code less readable.
It is quite likely that the code does not match the programmer's intent.
Either the condition should be removed or it should be updated so that it does
not always evaluate to TRUE or FALSE and does not perform redundant tests.
This rule will hint to the test conflicting with the linted one.

**BAD:**
```
//foo can't be both equal and not equal to bar in the same expression
if(foo == bar && something && foo != bar) {...}
```

**BAD:**
```
void compute(int foo) {
  if (foo == 4) {
    doSomething();
    // We know foo is equal to 4 at this point, so the next condition is always false
    if (foo > 4) {...}
    ...
  }
  ...
}
```

**BAD:**
```
void compute(bool foo) {
  if (foo) {
    return;
  }
  doSomething();
  // foo is always false here
  if (foo){...}
  ...
}
```

**GOOD:**
```
void nestedOK() {
  if (foo == bar) {
    foo = baz;
    if (foo != bar) {...}
  }
}
```

**GOOD:**
```
void nestedOk2() {
  if (foo == bar) {
    return;
  }

  foo = baz;
  if (foo == bar) {...} // OK
}
```

**GOOD:**
```
void nestedOk5() {
  if (foo != null) {
    if (bar != null) {
      return;
    }
  }

  if (bar != null) {...} // OK
}
```
''';

Set<Expression> _findConditionsCausingReturns(
        Expression node, Iterable<AstNode> nodesInDFS) =>
    nodesInDFS
        .where(_isAnalyzedNode)
        .where(_isConditionalStatementWithReturn(nodesInDFS))
        .takeWhile((n) => n != node.parent)
        .where((_noFurtherAssignmentInvalidatingCondition(node, nodesInDFS)))
        .fold(<Expression>[], (List<Expression> previous, AstNode statement) {
      previous.add(_getCondition(statement));
      return previous;
    }).toSet();

Set<Expression> _findConditionsOfElseStatementAncestor(
    Statement statement, Iterable<AstNode> nodesInDFS) {
  return _findConditionsUnderStatementBranch(
      statement,
      (n) =>
          n is IfStatement &&
          statement.getAncestor((a) => a == n.elseStatement) != null,
      nodesInDFS);
}

Set<Expression> _findConditionsOfStatementAncestor(
    Statement statement, Iterable<AstNode> nodesInDFS) {
  return _findConditionsUnderStatementBranch(
      statement,
      (n) =>
          _isAnalyzedNode(n) &&
          (n is! IfStatement ||
              statement.getAncestor(
                      (a) => a == (n as IfStatement).thenStatement) !=
                  null),
      nodesInDFS);
}

Set<Expression> _findConditionsUnderStatementBranch(Statement statement,
    AstNodePredicate predicate, Iterable<AstNode> nodesInDFS) {
  Expression condition = _getCondition(statement);
  AstNodePredicate noFurtherAssignmentInvalidatingCondition =
      _noFurtherAssignmentInvalidatingCondition(condition, nodesInDFS);
  return nodesInDFS
      .where((n) => n == statement.getAncestor((a) => a == n && a != statement))
      .where(_isAnalyzedNode)
      .where(predicate)
      .where(noFurtherAssignmentInvalidatingCondition)
      .fold(<Expression>[], (List<Expression> previous, AstNode statement) {
    previous.add(_getCondition(statement));
    return previous;
  }).toSet();
}

TestedExpressions _findPreviousTestedExpressions(Expression node) {
  Block block = node.getAncestor((a) => a is Block && a.parent is FunctionBody);
  Iterable<AstNode> nodesInDFS = DartTypeUtilities.traverseNodesInDFS(block,
      excludeCriteria: (n) => n is FunctionDeclarationStatement);
  Iterable<Expression> conjunctions =
      _findConditionsOfStatementAncestor(node.parent, nodesInDFS)
          .map(_splitConjunctions)
          .expand((iterable) => iterable)
          .toSet();
  Iterable<Expression> negations = (_findConditionsCausingReturns(
          node, nodesInDFS)
        ..addAll(
            _findConditionsOfElseStatementAncestor(node.parent, nodesInDFS)))
      .toSet();
  return new TestedExpressions(node, conjunctions, negations);
}

Set<Identifier> _findStatementIdentifiers(Statement statement) =>
    DartTypeUtilities
        .traverseNodesInDFS(statement)
        .where((n) => n is Identifier)
        .toSet();

Expression _getCondition(Statement statement) {
  if (statement is IfStatement) {
    return statement.condition;
  }

  if (statement is DoStatement) {
    return statement.condition;
  }

  if (statement is ForStatement) {
    return statement.condition;
  }

  if (statement is WhileStatement) {
    return statement.condition;
  }

  return null;
}

bool _isAnalyzedNode(AstNode node) =>
    node is IfStatement ||
    node is DoStatement ||
    node is ForStatement ||
    node is WhileStatement;

AstNodePredicate _isConditionalStatementWithReturn(
        Iterable<AstNode> blockNodes) =>
    (AstNode node) {
      Block block =
          node.getAncestor((a) => a is Block && a.parent is BlockFunctionBody);
      Iterable<AstNode> nodesInDFS = DartTypeUtilities.traverseNodesInDFS(node);
      return nodesInDFS.any((n) => n is ReturnStatement) &&
          // Ignore nested if statements.
          !nodesInDFS.any(_isAnalyzedNode) &&
          node.getAncestor((n) =>
                  n != node &&
                  _isAnalyzedNode(n) &&
                  n.getAncestor((a) => a == block) == block) ==
              null;
    };

AstNodePredicate _noFurtherAssignmentInvalidatingCondition(
    Expression node, Iterable<AstNode> nodesInDFS) {
  Set<Identifier> identifiers = _findStatementIdentifiers(node.parent);
  return (AstNode statement) =>
      nodesInDFS
          .skipWhile((n) => n != statement)
          .takeWhile((n) => n != node)
          .where((n) =>
              n is AssignmentExpression &&
              !identifiers.contains(n.leftHandSide))
          .length ==
      0;
}

List<Expression> _splitConjunctions(Expression expression) {
  if (expression is BinaryExpression &&
      expression.operator.type == TokenType.AMPERSAND_AMPERSAND) {
    return _splitConjunctions(expression.leftOperand)
      ..addAll(_splitConjunctions(expression.rightOperand));
  }

  return [expression];
}

class InvariantBooleans extends LintRule {
  _Visitor _visitor;

  InvariantBooleans()
      : super(
            name: 'invariant_booleans',
            description: _desc,
            details: _details,
            group: Group.errors,
            maturity: Maturity.stable) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

/// The only purpose of this rule is to report the second node on a contradictory
/// comparison indicating the first node as the cause of the inconsistency.
class _ContradictionReportRule extends LintRule {
  _ContradictionReportRule(ContradictoryComparisons comparisons)
      : super(
            name: 'invariant_booleans',
            description: _desc + ' verify: ${comparisons.first}.',
            details: _details,
            group: Group.errors,
            maturity: Maturity.stable);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitDoStatement(DoStatement node) {
    _reportExpressionIfConstantValue(node.condition);
  }

  @override
  visitForStatement(ForStatement node) {
    _reportExpressionIfConstantValue(node.condition);
  }

  @override
  visitIfStatement(IfStatement node) {
    _reportExpressionIfConstantValue(node.condition);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    _reportExpressionIfConstantValue(node.condition);
  }

  _reportExpressionIfConstantValue(Expression node) {
    // Right part discards reporting a subexpression already reported.
    if (resolutionMap.bestTypeForExpression(node).name != 'bool' ||
        !_isAnalyzedNode(node.parent)) {
      return;
    }

    TestedExpressions testedNodes = _findPreviousTestedExpressions(node);
    testedNodes.evaluateInvariant().forEach((ContradictoryComparisons e) {
      _ContradictionReportRule reportRule = new _ContradictionReportRule(e);
      reportRule.reporter = rule.reporter;
      reportRule.reportLint(e.second);
    });

    // In dart booleanVariable == true is a valid comparison since the variable
    // can be null.
    final BinaryExpression binaryExpression =
        node is BinaryExpression ? node : null;
    if (binaryExpression != null &&
        !BooleanExpressionUtilities.EQUALITY_OPERATIONS
            .contains(binaryExpression.operator.type) &&
        (binaryExpression.leftOperand is BooleanLiteral ||
            binaryExpression.rightOperand is BooleanLiteral) &&
        binaryExpression.operator.type != TokenType.QUESTION_QUESTION) {
      rule.reportLint(node);
    }
  }
}
