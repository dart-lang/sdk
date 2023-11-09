// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Use contains for `List` and `String` instances.';
const _details = r'''
**DON'T** use `indexOf` to see if a collection contains an element.

Calling `indexOf` to see if a collection contains something is difficult to read
and may have poor performance.

Instead, prefer `contains`.

**BAD:**
```dart
if (lunchBox.indexOf('sandwich') == -1) return 'so hungry...';
```

**GOOD:**
```dart
if (!lunchBox.contains('sandwich')) return 'so hungry...';
```

''';

class PreferContains extends LintRule {
  // TODO(brianwilkerson): Both `alwaysFalse` and `alwaysTrue` should be warnings
  //  rather than lints because they represent a bug rather than a style
  //  preference.
  static const LintCode alwaysFalse = LintCode('prefer_contains',
      'Always false because indexOf is always greater or equal -1.');

  static const LintCode alwaysTrue = LintCode('prefer_contains',
      'Always true because indexOf is always greater or equal -1.');

  static const LintCode useContains = LintCode('prefer_contains',
      "Unnecessary use of 'indexOf' to test for containment.",
      correctionMessage: "Try using 'contains'.");

  PreferContains()
      : super(
            name: 'prefer_contains',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<LintCode> get lintCodes => [alwaysFalse, alwaysTrue, useContains];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferContains rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // This lint rule is only concerned with these operators.
    if (!node.operator.matchesAny([
      TokenType.EQ_EQ,
      TokenType.BANG_EQ,
      TokenType.GT,
      TokenType.GT_EQ,
      TokenType.LT,
      TokenType.LT_EQ,
    ])) {
      return;
    }
    var value = getIntValue(node.rightOperand, context);
    if (value is int) {
      if (value <= 0 && _isUnassignedIndexOf(node.leftOperand)) {
        _checkConstant(node, value, node.operator.type);
      }
    } else {
      value = getIntValue(node.leftOperand, context);
      if (value is int) {
        if (value <= 0 && _isUnassignedIndexOf(node.rightOperand)) {
          _checkConstant(node, value, node.operator.type.inverted);
        }
      }
    }
  }

  void _checkConstant(Expression expression, int value, TokenType type) {
    if (value == -1) {
      if (type == TokenType.EQ_EQ ||
          type == TokenType.BANG_EQ ||
          type == TokenType.LT_EQ ||
          type == TokenType.GT) {
        rule.reportLint(expression, errorCode: PreferContains.useContains);
      } else if (type == TokenType.LT) {
        // indexOf < -1 is always false
        rule.reportLint(expression, errorCode: PreferContains.alwaysFalse);
      } else if (type == TokenType.GT_EQ) {
        // indexOf >= -1 is always true
        rule.reportLint(expression, errorCode: PreferContains.alwaysTrue);
      }
    } else if (value == 0) {
      // 'indexOf >= 0' is same as 'contains',
      // and 'indexOf < 0' is same as '!contains'
      if (type == TokenType.GT_EQ || type == TokenType.LT) {
        rule.reportLint(expression, errorCode: PreferContains.useContains);
      }
    } else if (value < -1) {
      // 'indexOf' is always >= -1, so comparing with lesser values makes
      // no sense.
      if (type == TokenType.EQ_EQ ||
          type == TokenType.LT_EQ ||
          type == TokenType.LT) {
        rule.reportLint(expression, errorCode: PreferContains.alwaysFalse);
      } else if (type == TokenType.BANG_EQ ||
          type == TokenType.GT_EQ ||
          type == TokenType.GT) {
        rule.reportLint(expression, errorCode: PreferContains.alwaysTrue);
      }
    }
  }

  /// Returns whether [expression] is an invocation of `Iterable.indexOf` or
  /// `String.indexOf`, which is not assigned to a value.
  bool _isUnassignedIndexOf(Expression expression) {
    // Unwrap parens and `as` expressions.
    var invocation = expression.unParenthesized;
    while (invocation is AsExpression) {
      invocation = invocation.expression;
    }
    invocation = invocation.unParenthesized;

    if (invocation is! MethodInvocation) return false;

    // The result of `indexOf` is being assigned before being compared, so
    // it's important. E.g.  `(next = list.indexOf('{')) != -1)`.
    if (invocation.parent is AssignmentExpression) return false;
    if (invocation.methodName.name != 'indexOf') return false;

    var parentType = invocation.target?.staticType;
    if (parentType == null) return false;
    if (!parentType.implementsAnyInterface([
      InterfaceTypeDefinition('Iterable', 'dart.core'),
      InterfaceTypeDefinition('String', 'dart.core'),
    ])) {
      return false;
    }

    var args = invocation.argumentList.arguments;
    if (args.length == 2) {
      var start = args[1];
      if (getIntValue(start, context) != 0) return false;
    }

    return true;
  }
}
