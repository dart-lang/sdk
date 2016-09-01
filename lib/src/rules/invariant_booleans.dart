// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.invariant_booleans;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/util/boolean_expression_utilities.dart';
import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/tested_expressions.dart';

const _desc = r'Conditions should not unconditionally evaluate to "TRUE" or to "FALSE"';

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
void compute(boolean foo) {
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


class InvariantBooleans extends LintRule {
  _Visitor _visitor;

  InvariantBooleans() : super(
      name: 'invariant_booleans',
      description: _desc,
      details: _details,
      group: Group.errors,
      maturity: Maturity.experimental) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  _reportBinaryExpressionIfConstantValue(BinaryExpression node) {
    // Right part discards reporting a subexpression already reported.
    if (node.bestType.name != 'bool' || node.parent is! IfStatement) {
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
    if (!BooleanExpressionUtilities.EQUALITY_OPERATIONS
        .contains(node.operator.type) &&
        (node.leftOperand is BooleanLiteral ||
            node.rightOperand is BooleanLiteral)) {
      rule.reportLint(node);
    }
  }

  @override
  visitForStatement(ForStatement node) {
    if (node.condition is BinaryExpression) {
      _reportBinaryExpressionIfConstantValue(node.condition);
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    if (node.condition is BinaryExpression) {
      _reportBinaryExpressionIfConstantValue(node.condition);
    }
  }

  @override
  visitIfStatement(IfStatement node) {
    if (node.condition is BinaryExpression) {
      _reportBinaryExpressionIfConstantValue(node.condition);
    }
  }

  @override
  visitWhileStatement(WhileStatement node) {
    if (node.condition is BinaryExpression) {
      _reportBinaryExpressionIfConstantValue(node.condition);
    }
  }


}

/// The only purpose of this rule is to report the second node on a cotradictory
/// comparison indicating the first node as the cause of the inconsistency.
class _ContradictionReportRule extends LintRule {
  _ContradictionReportRule(ContradictoryComparisons comparisons) : super(
      name: 'invariant_boolean',
      description: _desc + ' verify: ${comparisons.first}.',
      details: _details,
      group: Group.errors,
      maturity: Maturity.experimental);
}

TestedExpressions _findPreviousTestedExpressions(BinaryExpression node) {
  Block block = node
      .getAncestor((a) => a is Block && a.parent is BlockFunctionBody);
  Iterable<AstNode> nodesInDFS = DartTypeUtilities.traverseNodesInDFS(block);
  Iterable<Expression> conjunctions =
  _findConditionsOfIfStatementAncestor(node.parent, nodesInDFS).toSet();
  Iterable<Expression> negations =
  (_findConditionsCausingReturns(node, nodesInDFS)
    ..addAll(_findConditionsOfElseStatementAncestor(node.parent, nodesInDFS)))
      .toSet();
  return new TestedExpressions(node, conjunctions, negations);
}

Set<Expression> _findConditionsOfIfStatementAncestor(IfStatement statement,
    Iterable<AstNode> nodesInDFS) {
  return _findConditionsUnderIfStatementBranch(statement,
      (n) =>
  n is IfStatement &&
      statement.getAncestor((a) => a == n.thenStatement) != null, nodesInDFS);
}

Set<Expression> _findConditionsOfElseStatementAncestor(IfStatement statement,
    Iterable<AstNode> nodesInDFS) {
  return _findConditionsUnderIfStatementBranch(statement,
      (n) =>
  n is IfStatement &&
      statement.getAncestor((a) => a == n.elseStatement) != null, nodesInDFS);
}

Set<Expression> _findConditionsUnderIfStatementBranch(IfStatement statement,
    AstNodePredicate predicate, Iterable<AstNode> nodesInDFS) {
  AstNodePredicate noFurtherAssignmentInvalidatingCondition =
  _noFurtherAssignmentInvalidatingCondition(statement.condition, nodesInDFS);
  return nodesInDFS
      .where((n) => n == statement.getAncestor((a) => a == n && a != statement))
      .where((n) => n is IfStatement)
      .where(predicate)
      .where(noFurtherAssignmentInvalidatingCondition)
      .fold(<Expression>[],
      (List<Expression> previous, AstNode statement) {
    if (statement is IfStatement) {
      previous.add(statement.condition);
    }
    return previous;
  }).toSet();
}

Set<Identifier> _findStatementIdentifiers(IfStatement statement) =>
    DartTypeUtilities.traverseNodesInDFS(statement)
        .where((n) => n is Identifier).toSet();

Set<Expression> _findConditionsCausingReturns(BinaryExpression node,
    Iterable<AstNode> nodesInDFS) =>
    nodesInDFS
        .takeWhile((n) => n != node.parent)
        .where(_isIfStatementWithReturn(nodesInDFS))
        .where((_noFurtherAssignmentInvalidatingCondition(node, nodesInDFS)))
        .fold(<Expression>[],
        (List<Expression> previous, AstNode statement) {
      if (statement is IfStatement) {
        previous.add(statement.condition);
      }
      return previous;
    }).toSet();

AstNodePredicate _isIfStatementWithReturn(Iterable<AstNode> blockNodes) =>
        (AstNode node) {
      Block block = node
          .getAncestor((a) => a is Block && a.parent is BlockFunctionBody);
      Iterable<AstNode> nodesInDFS = DartTypeUtilities.traverseNodesInDFS(node);
      return node is IfStatement
          && nodesInDFS.any((n) => n is ReturnStatement)
          // Ignore nested if statements.
          && !nodesInDFS.any((n) => n is IfStatement)
          && node.getAncestor((n) =>
          n != node && n is IfStatement &&
              n.getAncestor((a) => a == block) == block) == null;
    };

AstNodePredicate _noFurtherAssignmentInvalidatingCondition(
    BinaryExpression node,
    Iterable<AstNode> nodesInDFS) {
  Set<Identifier> identifiers = _findStatementIdentifiers(node.parent);
  return (AstNode statement) =>
  nodesInDFS
      .skipWhile((n) => n != statement)
      .takeWhile((n) => n != node)
      .where((n) =>
  n is AssignmentExpression &&
      !identifiers.contains(n.leftHandSide))
      .length == 0;
}
