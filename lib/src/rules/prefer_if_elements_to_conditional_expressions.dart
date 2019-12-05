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
```
Widget build(BuildContext context) {
  return Row(
    children: [
      IconButton(icon: Icon(Icons.menu)),
      Expanded(child: title),
      isAndroid ? IconButton(icon: Icon(Icons.search)) : null,
    ].where((child) => child != null).toList(),
  );
}
```

**GOOD:**
```
Widget build(BuildContext context) {
  return Row(
    children: [
      IconButton(icon: Icon(Icons.menu)),
      Expanded(child: title),
      if (isAndroid) IconButton(icon: Icon(Icons.search)),
    ]
  );
}
''';

class PreferIfElementsToConditionalExpressions extends LintRule
    implements NodeLintRule {
  PreferIfElementsToConditionalExpressions()
      : super(
            name: 'prefer_if_elements_to_conditional_expressions',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
