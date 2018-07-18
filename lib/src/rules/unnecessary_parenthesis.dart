// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Unnecessary parenthesis can be removed.';

const _details = r'''

**AVOID** using parenthesis when not needed.

**GOOD:**
```
a = b;
```

**BAD:**
```
a = (b);
```

''';

class UnnecessaryParenthesis extends LintRule implements NodeLintRule {
  UnnecessaryParenthesis()
      : super(
            name: 'unnecessary_parenthesis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addParenthesizedExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (node.expression is SimpleIdentifier) {
      rule.reportLint(node);
      return;
    }

    final parent = node.parent;

    if (parent is ParenthesizedExpression) {
      rule.reportLint(node);
      return;
    }

    // a..b=(c..d) is OK
    if (node.expression is CascadeExpression &&
        node.getAncestor((n) => n is Statement || n is CascadeExpression)
            is CascadeExpression) {
      return;
    }

    if (parent is Expression) {
      if (parent is BinaryExpression) return;
      if (parent is ConditionalExpression) return;
      if (parent is CascadeExpression) return;
      if (parent.precedence < node.expression.precedence) {
        rule.reportLint(node);
        return;
      }
    } else {
      rule.reportLint(node);
      return;
    }
  }
}
