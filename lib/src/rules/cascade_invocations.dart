// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.cascade_invocations;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/lint/linter.dart';

const _desc = r'Cascade consecutive method invocations on the same reference.';

const _details = r'''

**DO** Use the cascading style when succesively invoking methods on the same
 reference.

**BAD:**
```
SomeClass someReference = new SomeClass();
someReference.firstMethod();
someReference.secondMethod();
```

**BAD:**
```
SomeClass someReference = new SomeClass();
...
someReference.firstMethod();
someReference.aProperty = value;
someReference.secondMethod();
```

**GOOD:**
```
SomeClass someReference = new SomeClass()
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

**GOOD:**
```
SomeClass someReference = new SomeClass();
...
someReference
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

''';

SimpleIdentifier _findTarget(AstNode node) {
  Expression expression;
  if (node is ExpressionStatement) {
    expression = node.expression;
  }

  if (expression is MethodInvocation &&
      expression.realTarget is SimpleIdentifier) {
    return expression.realTarget;
  }

  if (expression is PrefixedIdentifier &&
      expression.prefix is SimpleIdentifier) {
    return expression.prefix;
  }

  if (expression is AssignmentExpression &&
      expression.leftHandSide is PrefixedIdentifier) {
    return (expression.leftHandSide as PrefixedIdentifier).prefix;
  }

  return null;
}

/// Rule to lint consecutive invocations of methods or getters on the same
/// reference that could be done with the cascade operator.
class CascadeInvocations extends LintRule {
  _Visitor _visitor;

  /// Default constructor.
  CascadeInvocations()
      : super(
            name: 'cascade_invocations',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final prefixIdentifier = _findTarget(node);
    if (prefixIdentifier == null || node.parent is! Block) {
      return;
    }

    final Block body = node.parent;
    final previousNodes = body.statements.takeWhile((n) => n != node);
    if (previousNodes.isEmpty) {
      return;
    }

    final previousNode = previousNodes.last;
    final SimpleIdentifier previousIdentifier = _findTarget(previousNode);
    if (previousIdentifier != null &&
        previousIdentifier.staticElement == prefixIdentifier.staticElement) {
      rule.reportLint(node);
    }

    if (previousNode is VariableDeclarationStatement &&
        _isInvokedWithoutNullAwareOperator(node)) {
      _reportIfDeclarationFollowedByMethodInvocation(
          previousNode, prefixIdentifier, node);
    }
  }

  void _reportIfDeclarationFollowedByMethodInvocation(
      VariableDeclarationStatement variablesDeclaration,
      SimpleIdentifier simpleIdentifier,
      AstNode node) {
    final variables = variablesDeclaration.variables.variables;
    if (variables.length == 1 &&
        variables.first.name.staticElement == simpleIdentifier.staticElement) {
      rule.reportLint(node);
    }
  }
}

bool _isInvokedWithoutNullAwareOperator(AstNode node) {
  if (node is ExpressionStatement && node.expression is MethodInvocation) {
    final tokenType = (node.expression as MethodInvocation).operator.type;
    return tokenType == TokenType.PERIOD ||
        tokenType == TokenType.PERIOD_PERIOD;
  }

  return false;
}
