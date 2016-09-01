// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.literal_only_boolean_expressions;

import 'package:analyzer/dart/ast/token.dart';
import 'package:linter/src/linter.dart';
import 'package:analyzer/analyzer.dart';

const _desc = r'Conditions should not unconditionally evaluate to "TRUE" or to "FALSE"';

const _details = r'''

**DON'T** test for conditions composed only by literals, since the value can be
inferred at compile time.
Conditional statements using a condition which cannot be anything but FALSE have
the effect of making blocks of code non-functional. If the condition cannot
evaluate to anything but TRUE, the conditional statement is completely
redundant, and makes the code less readable.
It is quite likely that the code does not match the programmer's intent.
Either the condition should be removed or it should be updated so that it does
not always evaluate to TRUE or FALSE.

**BAD:**
```
void bad() {
  if (true) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (true && 1 != 0) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (1 != 0 && true) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (1 < 0 && true) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (true && false) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (1 != 0) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (true && 1 != 0 || 3 < 4) {} // LINT
}
```

**BAD:**
```
void bad() {
  if (1 != 0 || 3 < 4 && true) {} // LINT
}
```

''';

class LiteralOnlyBooleanExpressions extends LintRule {
  _Visitor _visitor;

  LiteralOnlyBooleanExpressions() : super(
      name: 'literal_only_boolean_expressions',
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

  @override
  visitWhileStatement(WhileStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  visitIfStatement(IfStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  visitForStatement(ForStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }
}

bool _onlyLiterals(Expression expression) {
  final literalsOnBothSides = expression is BinaryExpression &&
      (_onlyLiterals(expression.leftOperand) &&
          _onlyLiterals(expression.rightOperand));
  final ifNullOperatorWithLiteral = expression is BinaryExpression &&
      (_onlyLiterals(expression.leftOperand) ||
          _onlyLiterals(expression.rightOperand)) &&
      expression.operator.type == TokenType.QUESTION_QUESTION;
  final literalNegation = expression is PrefixExpression &&
      _onlyLiterals(expression.operand);
  final parenthesizedLiteral = expression is ParenthesizedExpression &&
      _onlyLiterals(expression.expression);
  return expression is Literal || literalsOnBothSides ||
      ifNullOperatorWithLiteral || literalNegation || parenthesizedLiteral;
}
