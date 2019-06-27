// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid `print` calls in production code.';

const _details = r'''
**DO** avoid `print` calls in production code.

**BAD:**
```
void f(int x) {
  print('debug: $x');
  ...
}
```
''';

class AvoidPrint extends LintRule implements NodeLintRule {
  AvoidPrint()
      : super(
            name: 'avoid_print',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitMethodInvocation(MethodInvocation node) {
    bool isDartCore(MethodInvocation node) =>
        node.staticInvokeType?.element?.library?.name == 'dart.core';

    if (node.methodName.name == 'print' && isDartCore(node)) {
      rule.reportLint(node.methodName);
    }
  }
}
