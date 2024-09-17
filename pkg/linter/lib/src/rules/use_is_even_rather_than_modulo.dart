// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc =
    r'Prefer intValue.isOdd/isEven instead of checking the result of % 2.';

const _details = r'''
**PREFER** the use of intValue.isOdd/isEven to check for evenness.

**BAD:**
```dart
bool isEven = 1 % 2 == 0;
bool isOdd = 13 % 2 == 1;
```

**GOOD:**
```dart
bool isEven = 1.isEven;
bool isOdd = 13.isOdd;
```

''';

class UseIsEvenRatherThanModulo extends LintRule {
  UseIsEvenRatherThanModulo()
      : super(
          name: 'use_is_even_rather_than_modulo',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_is_even_rather_than_modulo;

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
    // This lint error only happens when the operator is equality.
    if (node.operator.type != TokenType.EQ_EQ) return;
    if (node.inConstantContext) return;

    var left = node.leftOperand;
    var leftType = left.staticType;
    var right = node.rightOperand;
    var rightType = right.staticType;
    // Both sides have to have static type of int
    if (!(right is IntegerLiteral &&
        (leftType?.isDartCoreInt ?? false) &&
        (rightType?.isDartCoreInt ?? false))) {
      return;
    }
    // The left side expression has to be modulo by 2 type.
    if (left is! BinaryExpression) return;
    if (left.operator.type != TokenType.PERCENT) return;

    var rightChild = left.rightOperand;

    if (rightChild is! IntegerLiteral) return;
    if (rightChild.value != 2) return;

    // Now we have `x % 2 == y`.
    var rightChildType = rightChild.staticType;
    if (rightChildType == null) return;
    if (!rightChildType.isDartCoreInt) return;

    var value = right.value;
    if (value == null) return;
    var parentAssertInitializer =
        node.thisOrAncestorOfType<AssertInitializer>();
    if (parentAssertInitializer != null) {
      var constructor = parentAssertInitializer.parent;
      // `isEven` is not allowed in a const constructor assert initializer.
      if (constructor is ConstructorDeclaration &&
          constructor.constKeyword != null) {
        return;
      }
    }

    rule.reportLint(node, arguments: [value == 0 ? 'isEven' : 'isOdd']);
  }
}
