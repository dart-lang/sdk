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
**DON'T** use null check on a potentially nullable type parameter.

Given a generic type parameter `T` which has a nullable bound (e.g. the default
bound of `Object?`), it is very easy to introduce erroneous null checks when
working with a variable of type `T?`. Specifically, it is not uncommon to have
`T? x;` and want to assert that `x` has been set to a valid value of type `T`.
A common mistake is to do so using `x!`. This is almost always incorrect, since
if `T` is a nullable type, `x` may validly hold `null` as a value of type `T`.

**BAD:**
```dart
T run<T>(T callback()) {
  T? result;
   (() { result = callback(); })();
  return result!;
}
```

**GOOD:**
```dart
T run<T>(T callback()) {
  T? result;
   (() { result = callback(); })();
  return result as T;
}
```

''';

class NullCheckOnNullableTypeParameter extends LintRule {
  static const LintCode code = LintCode(
      'null_check_on_nullable_type_parameter',
      "The null check operator shouldn't be used on a variable whose type is a "
          'potentially nullable type parameter.',
      correctionMessage: "Try explicitly testing for 'null'.");

  NullCheckOnNullableTypeParameter()
      : super(
          name: 'null_check_on_nullable_type_parameter',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) {
      return;
    }

    var visitor = _Visitor(this, context);
    registry.addPostfixExpression(this, visitor);
    registry.addNullAssertPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  bool isNullableTypeParameterType(DartType? type) =>
      type is TypeParameterType && context.typeSystem.isNullable(type);

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    if (isNullableTypeParameterType(node.matchedValueType)) {
      rule.reportLintForToken(node.operator);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var expectedType = getExpectedType(node);
    var type = node.operand.staticType;
    if (isNullableTypeParameterType(type) &&
        expectedType != null &&
        context.typeSystem.isPotentiallyNullable(expectedType) &&
        context.typeSystem.promoteToNonNull(type!) ==
            context.typeSystem.promoteToNonNull(expectedType)) {
      rule.reportLintForToken(node.operator);
    }
  }
}
