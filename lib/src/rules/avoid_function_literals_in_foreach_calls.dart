// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

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
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
            node.target.staticType, 'Iterable', 'dart.core') &&
        !_hasMethodChaining(node)) {
      rule.reportLint(node.function);
    }
  }
}

bool _hasMethodChaining(MethodInvocation node) {
  var exp = node.target;
  while (exp is PrefixedIdentifier ||
      exp is MethodInvocation ||
      exp is PropertyAccess) {
    if (exp is PrefixedIdentifier) {
      exp = (exp as PrefixedIdentifier).prefix;
    } else if (exp is MethodInvocation) {
      return true;
    } else if (exp is PropertyAccess) {
      exp = (exp as PropertyAccess).target;
    }
  }
  return false;
}
