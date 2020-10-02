// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't cast a nullable value to a non nullable type.";

const _details = r'''

Don't cast a nullable value to a non nullable type. This hides a null check
and most of the time it is not what is expected.

**BAD:**
```
class A {}
class B extends A {}

A? a;
var v = a as B;
var v = a as A;
```

**GOOD:**
```
class A {}
class B extends A {}

A? a;
var v = a! as B;
var v = a!;
```

''';

class CastNullableToNonNullable extends LintRule implements NodeLintRule {
  CastNullableToNonNullable()
      : super(
          name: 'cast_nullable_to_non_nullable',
          description: _desc,
          details: _details,
          maturity: Maturity.experimental,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) {
      return;
    }

    final visitor = _Visitor(this, context);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitAsExpression(AsExpression node) {
    final expressionType = node.expression.staticType;
    final type = node.type.type;
    if (!expressionType.isDynamic &&
        context.typeSystem.isNullable(expressionType) &&
        context.typeSystem.isNonNullable(type)) {
      rule.reportLint(node);
    }
  }
}
