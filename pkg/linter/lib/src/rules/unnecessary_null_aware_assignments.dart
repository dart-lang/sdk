// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid null in null-aware assignment.';

const _details = r'''
**AVOID** `null` in null-aware assignment.

Using `null` on the right-hand side of a null-aware assignment effectively makes
the assignment redundant.

**BAD:**
```dart
var x;
x ??= null;
```

**GOOD:**
```dart
var x;
x ??= 1;
```

''';

class UnnecessaryNullAwareAssignments extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_null_aware_assignments', "Unnecessary assignment of 'null'.",
      correctionMessage: 'Try removing the assignment.');

  UnnecessaryNullAwareAssignments()
      : super(
            name: 'unnecessary_null_aware_assignments',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAssignmentExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.readElement is PropertyAccessorElement) return;
    if (node.writeElement is PropertyAccessorElement) return;

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ &&
        node.rightHandSide.isNullLiteral) {
      rule.reportLint(node);
    }
  }
}
