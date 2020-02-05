// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';

import '../analyzer.dart';

const _desc = r"Don't use more than one case with same value.";

const _details = r'''

**DON'T** use more than one case with same value.

This is usually a typo or changed value of constant.

**GOOD:**
```
const int A = 1;
switch (v) {
  case A:
  case 2:
}
```

**BAD:**
```
const int A = 1;
switch (v) {
  case 1:
  case 2:
  case A:
  case 2:
}
```

''';

String message(String value1, String value2) =>
    'Do not use more than one case with same value ($value1 and $value2)';

class NoDuplicateCaseValues extends LintRule implements NodeLintRule {
  NoDuplicateCaseValues()
      : super(
            name: 'no_duplicate_case_values',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addSwitchStatement(this, visitor);
  }

  void reportLintWithDescription(AstNode node, String description) {
    if (node != null) {
      reporter.reportErrorForNode(_LintCode(name, description), node, []);
    }
  }
}

class _LintCode extends LintCode {
  static final registry = <String, _LintCode>{};

  factory _LintCode(String name, String message) =>
      registry.putIfAbsent(name + message, () => _LintCode._(name, message));

  _LintCode._(String name, String message) : super(name, message);
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoDuplicateCaseValues rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var values = <DartObject, Expression>{};

    for (var member in node.members) {
      if (member is SwitchCase) {
        final expression = member.expression;

        final result = context.evaluateConstant(expression);
        final value = result.value;

        if (value == null || !value.hasKnownValue) {
          continue;
        }

        final duplicateValue = values[value];
        if (duplicateValue != null) {
          rule.reportLintWithDescription(member,
              message(duplicateValue.toString(), expression.toString()));
        } else {
          values[value] = expression;
        }
      }
    }
  }
}
