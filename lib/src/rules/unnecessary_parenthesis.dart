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

class UnnecessaryParenthesis extends LintRule {
  UnnecessaryParenthesis()
      : super(
            name: 'unnecessary_parenthesis',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    if (node.expression is SimpleIdentifier) {
      rule.reportLint(node);
      return;
    }

    final parent = node.parent;

    if (parent is ParenthesizedExpression) {
      rule.reportLint(node);
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
