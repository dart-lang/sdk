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
```dart
const int A = 1;
switch (v) {
  case A:
  case 2:
}
```

**BAD:**
```dart
const int A = 1;
switch (v) {
  case 1:
  case 2:
  case A:
  case 2:
}
```

''';

class NoDuplicateCaseValues extends LintRule {
  static const LintCode code = LintCode('no_duplicate_case_values',
      'Do not use more than one case with same value ({0} and {1}');

  NoDuplicateCaseValues()
      : super(
            name: 'no_duplicate_case_values',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addSwitchStatement(this, visitor);
  }
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
        var expression = member.expression;

        var result = context.evaluateConstant(expression);
        var value = result.value;

        if (value == null || !value.hasKnownValue) {
          continue;
        }

        var duplicateValue = values[value];
        if (duplicateValue != null) {
          rule.reportLint(member,
              errorCode: NoDuplicateCaseValues.code,
              arguments: [duplicateValue.toString(), expression.toString()]);
        } else {
          values[value] = expression;
        }
      }
    }
  }
}
