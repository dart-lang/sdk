// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Avoid double and int checks.';

const _details = r'''

**AVOID** to check if type is double or int.

When compiled to JS, integer values are represented as floats. That can lead to
some unexpected behavior when using either `is` or `is!` where the type is
either `int` or `double`.

**BAD:**
```
f(dynamic x) {
  if (x is double) {
    ...
  } else if (x is int) {
    ...
  } else {
    ...
  }
}
```

**GOOD:**
```
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
  AvoidDoubleAndIntChecks()
      : super(
            name: 'avoid_double_and_int_checks',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement is IfStatement) {
      final ifCondition = node.condition;
      final elseCondition = elseStatement.condition;
      if (ifCondition is IsExpression && elseCondition is IsExpression) {
        final typeProvider =
            getCompilationUnit(node).element.context.typeProvider;
        final ifExpression = ifCondition.expression;
        final elseIsExpression = elseCondition.expression;
        if (ifExpression is SimpleIdentifier &&
            elseIsExpression is SimpleIdentifier &&
            ifExpression.name == elseIsExpression.name &&
            ifCondition.type.type == typeProvider.doubleType &&
            elseCondition.type.type == typeProvider.intType &&
            (ifExpression.bestElement is ParameterElement ||
                ifExpression.bestElement is LocalVariableElement)) {
          rule.reportLint(elseCondition);
        }
      }
    }
  }
}
