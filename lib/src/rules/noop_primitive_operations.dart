// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

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

'string with ${x.toString()}';
```
''';

class NoopPrimitiveOperations extends LintRule {
  static const LintCode code = LintCode('noop_primitive_operations',
      'The expression has no effect and can be removed.',
      correctionMessage: 'Try removing the expression.');

  NoopPrimitiveOperations()
      : super(
          name: 'noop_primitive_operations',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addAdjacentStrings(this, visitor);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    for (var literal in node.strings) {
      if (literal.stringValue?.isEmpty ?? false) {
        rule.reportLint(literal);
      }
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    _checkToStringInvocation(node.expression);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var type = node.realTarget?.staticType;
    if (type == null) {
      // print(xxx.toString())
      if (node.methodName.staticElement.isDartCorePrint &&
          node.argumentList.arguments.length == 1) {
        _checkToStringInvocation(node.argumentList.arguments.first);
      }
      return;
    }

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

  void _checkToStringInvocation(Expression expression) {
    if (expression is MethodInvocation &&
        expression.realTarget != null &&
        expression.realTarget is! SuperExpression &&
        expression.methodName.name == 'toString' &&
        expression.argumentList.arguments.isEmpty) {
      rule.reportLint(expression.methodName);
    }
  }
}
