// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Noop primitive operations.';

const _details = r'''

Some operations on primitive types are idempotent and can be removed.

**BAD:**

```dart
doubleValue.toDouble();

intValue.toInt();
intValue.round();
intValue.ceil();
intValue.floor();
intValue.truncate();

string.toString();
string = 'hello\n'
    'world\n'
    ''; // useless empty string
```
''';

class NoopPrimitiveOperations extends LintRule {
  NoopPrimitiveOperations()
      : super(
          name: 'noop_primitive_operations',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addAdjacentStrings(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    for (var literal in node.strings) {
      if (literal.stringValue?.isEmpty ?? false) {
        rule.reportLint(literal);
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.realTarget?.staticType;
    if (type == null) return;

    // string.toString()
    if (type.isDartCoreString &&
        node.methodName.name == 'toString' &&
        context.typeSystem.isNonNullable(type)) {
      rule.reportLint(node.methodName);
      return;
    }

    // int invariant methods
    if (type.isDartCoreInt &&
        ['toInt', 'round', 'ceil', 'floor', 'truncate']
            .contains(node.methodName.name)) {
      rule.reportLint(node.methodName);
      return;
    }

    // double.toDouble()
    if (type.isDartCoreDouble && node.methodName.name == 'toDouble') {
      rule.reportLint(node.methodName);
      return;
    }
  }
}
