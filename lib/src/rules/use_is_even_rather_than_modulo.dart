// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer intValue.isOdd/isEven instead of checking the result of % 2.';

const _details = r'''

**PREFER** the use of intValue.isOdd/isEven to check for evenness.

**BAD:**
```
bool isEven = 1 % 2 == 0;
bool isOdd = 13 % 2 == 1;
```

**GOOD:**
```
bool isEven = 1.isEven;
bool isOdd = 13.isOdd;
```

''';

class UseIsEvenRatherThanModuloCheck extends LintRule implements NodeLintRule {
  UseIsEvenRatherThanModuloCheck()
      : super(
            name: 'use_is_even_rather_than_modulo',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // This lint error only happens when the operator is equality.
    if (node.operator.type != TokenType.EQ_EQ) {
      return;
    }
    var left = node.leftOperand;
    var leftType = left.staticType;
    var right = node.rightOperand;
    var rightType = right.staticType;
    // Both sides have to have static type of int
    if (!(right is IntegerLiteral &&
        leftType.isDartCoreInt == true &&
        rightType.isDartCoreInt == true)) {
      return;
    }
    // The left side expression has to be modulo by 2 type.
    if (left is BinaryExpression) {
      var rightChild = left.rightOperand;
      var rightChildType = rightChild.staticType;
      if (left.operator.type == TokenType.PERCENT &&
          rightChild is IntegerLiteral &&
          rightChild.value == 2 &&
          rightChildType.isDartCoreInt == true) {
        rule.reportLint(node);
      }
    }
  }
}
