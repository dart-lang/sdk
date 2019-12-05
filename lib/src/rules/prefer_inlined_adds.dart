// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Inline list item declarations where possible.';

const _details = r'''
Declare elements in list literals inline, rather than using `add` and 
`addAll` methods where possible.


**BAD:**
```
var l = ['a']..add('b')..add('c');
var l2 = ['a']..addAll(['b', 'c'])
```

**GOOD:**
```
var l = ['a', 'b', 'c'];
var 2 = ['a', 'b', 'c'];
```
''';

class PreferInlinedAdds extends LintRule implements NodeLintRule {
  PreferInlinedAdds()
      : super(
            name: 'prefer_inlined_adds',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation invocation) {
    final addAll = invocation.methodName.name == 'addAll';
    if ((invocation.methodName.name != 'add' && !addAll) ||
        !invocation.isCascaded ||
        invocation.argumentList.arguments.length != 1) {
      return;
    }

    final cascade = invocation.thisOrAncestorOfType<CascadeExpression>();
    final sections = cascade.cascadeSections;
    final target = cascade.target;
    if (target is! ListLiteral || sections[0] != invocation) {
      // todo (pq): consider extending to handle set literals.
      return;
    }

    if (addAll && invocation.argumentList.arguments[0] is! ListLiteral) {
      // Handled by: prefer_spread_collections
      return;
    }

    rule.reportLint(invocation.methodName);
  }
}
