// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import 'unnecessary_null_checks.dart';

const _desc = r"Don't use null check on a potentially nullable type parameter.";

const _details = r'''

Don't use null check on a potentially nullable type parameter.

Given a generic type parameter `T` which has a nullable bound (e.g. the default
bound of `Object?`), it is very easy to introduce erroneous null checks when
working with a variable of type `T?`. Specifically, it is not uncommon to have
`T? x;` and want to assert that `x` has been set to a valid value of type `T`.
A common mistake is to do so using `x!`. This is almost always incorrect, since
if `T` is a nullable type, `x` may validly hold `null` as a value of type `T`.

**BAD:**
```
T run<T>(T callback()) {
  T? result;
   (() { result = callback(); })();
  return result!;
}
```

**GOOD:**
```
T run<T>(T callback()) {
  T? result;
   (() { result = callback(); })();
  return result as T;
}
```

''';

class NullCheckOnNullableTypeParameter extends LintRule
    implements NodeLintRule {
  NullCheckOnNullableTypeParameter()
      : super(
          name: 'null_check_on_nullable_type_parameter',
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
    registry.addCompilationUnit(this, visitor);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    final expectedType = getExpectedType(node);
    final type = node.operand.staticType;
    if (type is TypeParameterType &&
        context.typeSystem.isNullable(type) &&
        expectedType != null &&
        context.typeSystem.isPotentiallyNullable(expectedType) &&
        context.typeSystem.promoteToNonNull(type) ==
            context.typeSystem.promoteToNonNull(expectedType)) {
      rule.reportLintForToken(node.operator);
    }
  }
}
