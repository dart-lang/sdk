// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid using `forEach` with a function literal.';

const _details = r'''

**AVOID** using `forEach` with a function literal.

**BAD:**
```
people.forEach((person) {
  ...
});
```

**GOOD:**
```
for (var person in people) {
  ...
}

people.forEach(print);
```
''';

class AvoidFunctionLiteralInForeachMethod extends LintRule
    implements NodeLintRule {
  AvoidFunctionLiteralInForeachMethod()
      : super(
            name: 'avoid_function_literals_in_foreach_calls',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target != null &&
        node.methodName.token.value() == 'forEach' &&
        node.argumentList.arguments.isNotEmpty &&
        node.argumentList.arguments[0] is FunctionExpression &&
        DartTypeUtilities.implementsInterface(
            node.target.bestType, 'Iterable', 'dart.core')) {
      rule.reportLint(node.function);
    }
  }
}
