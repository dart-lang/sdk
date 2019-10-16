// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Use => for short members whose body is a single return statement.';

const _details = r'''

**CONSIDER** using => for short members whose body is a single return statement.

**BAD:**
```
get width {
  return right - left;
}
```

**BAD:**
```
bool ready(num time) {
  return minTime == null || minTime <= time;
}
```

**BAD:**
```
containsValue(String value) {
  return getValues().contains(value);
}
```

**GOOD:**
```
get width => right - left;
```

**GOOD:**
```
bool ready(num time) => minTime == null || minTime <= time;
```

**GOOD:**
```
containsValue(String value) => getValues().contains(value);
```

''';

class PreferExpressionFunctionBodies extends LintRule implements NodeLintRule {
  PreferExpressionFunctionBodies()
      : super(
            name: 'prefer_expression_function_bodies',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addBlockFunctionBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    final statements = node.block.statements;
    if (statements.length != 1) {
      return;
    }
    final uniqueStatement = node.block.statements.single;
    if (uniqueStatement is! ReturnStatement) {
      return;
    }
    rule.reportLint(node);
  }
}
