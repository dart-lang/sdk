// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Use truncating division.';

const _details = r'''
**DO** use truncating division, '~/', instead of regular division ('/') followed
by 'toInt()'.

Dart features a "truncating division" operator which is the same operation as
division followed by truncation, but which is more concise and expressive, and
may be more performant on some platforms, for certain inputs.

**BAD:**
```dart
var x = (2 / 3).toInt();
```

**GOOD:**
```dart
var x = 2 ~/ 3;
```

''';

class UseTruncatingDivision extends LintRule {
  UseTruncatingDivision()
      : super(
          name: 'use_truncating_division',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_truncating_division;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type != TokenType.SLASH) return;

    // Return if the two operands are not each `int`.
    var leftType = node.leftOperand.staticType;
    if (leftType == null || !leftType.isDartCoreInt) return;

    var rightType = node.rightOperand.staticType;
    if (rightType == null || !rightType.isDartCoreInt) return;

    // Return if the '/' operator is not defined in core, or if we don't know
    // its static type.
    var methodElement = node.staticElement;
    if (methodElement == null) return;

    var libraryElement = methodElement.library;
    if (!libraryElement.isDartCore) return;

    var parent = node.parent;
    if (parent is! ParenthesizedExpression) return;

    var outermostParentheses = parent.thisOrAncestorMatching(
            (e) => e.parent is! ParenthesizedExpression)!
        as ParenthesizedExpression;
    var grandParent = outermostParentheses.parent;
    if (grandParent is MethodInvocation &&
        grandParent.methodName.name == 'toInt' &&
        grandParent.argumentList.arguments.isEmpty) {
      rule.reportLint(grandParent);
    }
  }
}
