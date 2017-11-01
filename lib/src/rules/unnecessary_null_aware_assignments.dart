// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid null in null-aware assignment.';

const _details = r'''

**AVOID** `null` in null-aware assignment.

Using `null` on the right-hand side of a null-aware assignment effectively makes
the assignment redundant.

**GOOD:**
```
var x;
x ??= 1;
```

**BAD:**
```
var x;
x ??= null;
```

''';

class UnnecessaryNullAwareAssignments extends LintRule {
  UnnecessaryNullAwareAssignments()
      : super(
            name: 'unnecessary_null_aware_assignments',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ &&
        DartTypeUtilities.isNullLiteral(node.rightHandSide)) {
      rule.reportLint(node);
    }
  }
}
