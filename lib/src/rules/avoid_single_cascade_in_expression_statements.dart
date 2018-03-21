// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid single cascade in expression statements.';

const _details = r'''

**AVOID** single cascade in expression statements.

**BAD:**
```
o..m();
```

**GOOD:**
```
o.m();
```

''';

class AvoidSingleCascadeInExpressionStatements extends LintRule {
  AvoidSingleCascadeInExpressionStatements() : super(
          name: 'avoid_single_cascade_in_expression_statements',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitCascadeExpression(CascadeExpression node) {
    if (node.cascadeSections.length == 1 && node.parent is ExpressionStatement) {
      rule.reportLint(node);
    }
  }
}
