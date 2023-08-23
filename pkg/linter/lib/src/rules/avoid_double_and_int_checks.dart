// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid double and int checks.';

const _details = r'''
**AVOID** to check if type is double or int.

When compiled to JS, integer values are represented as floats. That can lead to
some unexpected behavior when using either `is` or `is!` where the type is
either `int` or `double`.

**BAD:**
```dart
f(num x) {
  if (x is double) {
    ...
  } else if (x is int) {
    ...
  }
}
```

**GOOD:**
```dart
f(dynamic x) {
  if (x is num) {
    ...
  } else {
    ...
  }
}
```

''';

class AvoidDoubleAndIntChecks extends LintRule {
  static const LintCode code = LintCode(
      'avoid_double_and_int_checks', 'Explicit check for double or int.',
      correctionMessage: 'Try removing the check.');

  AvoidDoubleAndIntChecks()
      : super(
            name: 'avoid_double_and_int_checks',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement is IfStatement) {
      var ifCondition = node.expression;
      var elseCondition = elseStatement.expression;
      if (ifCondition is IsExpression && elseCondition is IsExpression) {
        var typeProvider = context.typeProvider;
        var ifExpression = ifCondition.expression;
        var elseIsExpression = elseCondition.expression;
        if (ifExpression is SimpleIdentifier &&
            elseIsExpression is SimpleIdentifier &&
            ifExpression.name == elseIsExpression.name &&
            ifCondition.type.type == typeProvider.doubleType &&
            elseCondition.type.type == typeProvider.intType &&
            (ifExpression.staticElement is ParameterElement ||
                ifExpression.staticElement is LocalVariableElement)) {
          rule.reportLint(elseCondition);
        }
      }
    }
  }
}
