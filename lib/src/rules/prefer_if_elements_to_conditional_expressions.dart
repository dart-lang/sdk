// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer if elements to conditional expressions where possible.';

const _details = r'''
When building collections, it is preferable to use `if` elements rather than
conditionals.

**BAD:**
```dart
var list = ['a', 'b', condition ? 'c' : null].where((e) => e != null).toList();
```

**GOOD:**
```dart
var list = ['a', 'b', if (condition) 'c'];
```
''';

class PreferIfElementsToConditionalExpressions extends LintRule {
  static const LintCode code = LintCode(
      'prefer_if_elements_to_conditional_expressions',
      "Use an 'if' element to conditionally add elements.",
      correctionMessage:
          "Try using an 'if' element rather than a conditional expression.");

  PreferIfElementsToConditionalExpressions()
      : super(
            name: 'prefer_if_elements_to_conditional_expressions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    AstNode nodeToReplace = node;
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      nodeToReplace = parent;
      parent = parent.parent;
    }
    if (parent is ListLiteral || (parent is SetOrMapLiteral && parent.isSet)) {
      rule.reportLint(nodeToReplace);
    }
  }
}
