// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Boolean expression composed only with literals.';

const _details = r'''

**DON'T** test for conditions composed only by literals, since the value can be
inferred at compile time.

Conditional statements using a condition which cannot be anything but FALSE have
the effect of making blocks of code non-functional.  If the condition cannot
evaluate to anything but `true`, the conditional statement is completely
redundant, and makes the code less readable.
It is quite likely that the code does not match the programmer's intent.
Either the condition should be removed or it should be updated so that it does
not always evaluate to `true` or `false`.

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

bool _onlyLiterals(Expression rawExpression) {
  final expression = rawExpression?.unParenthesized;
  if (expression is Literal) {
    return true;
  }
  if (expression is PrefixExpression) {
    return _onlyLiterals(expression.operand);
  }
  if (expression is BinaryExpression) {
    if (expression.operator.type == TokenType.QUESTION_QUESTION) {
      return _onlyLiterals(expression.leftOperand);
    }
    return _onlyLiterals(expression.leftOperand) &&
        _onlyLiterals(expression.rightOperand);
  }
  return false;
}

class LiteralOnlyBooleanExpressions extends LintRule implements NodeLintRule {
  LiteralOnlyBooleanExpressions()
      : super(
            name: 'literal_only_boolean_expressions',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    final loopParts = node.forLoopParts;
    if (loopParts is ForParts) {
      if (_onlyLiterals(loopParts.condition)) {
        rule.reportLint(node);
      }
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    if (_onlyLiterals(node.condition)) {
      rule.reportLint(node);
    }
  }
}
