// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc =
    r'Unnecessary null aware operator on extension on a nullable type.';

const _details = r'''
Avoid null aware operators for members defined in an extension on a nullable
type.

**BAD:**

```dart
extension E on int? {
  int m() => 1;
}
f(int? i) => i?.m();
```

**GOOD:**

```dart
extension E on int? {
  int m() => 1;
}
f(int? i) => i.m();
```

''';

class UnnecessaryNullAwareOperatorOnExtensionOnNullable extends LintRule {
  UnnecessaryNullAwareOperatorOnExtensionOnNullable()
      : super(
          name: 'unnecessary_null_aware_operator_on_extension_on_nullable',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.unnecessary_null_aware_operator_on_extension_on_nullable;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addIndexExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;
  _Visitor(this.rule, this.context);

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware &&
        _isExtensionOnNullableType(node.inSetterContext()
            ? node
                .thisOrAncestorOfType<AssignmentExpression>()
                ?.writeElement
                ?.enclosingElement3
            : node.staticElement?.enclosingElement3)) {
      rule.reportLintForToken(node.question);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isNullAware &&
        _isExtensionOnNullableType(
            node.methodName.staticElement?.enclosingElement3)) {
      rule.reportLintForToken(node.operator);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware) {
      var realParent = node.thisOrAncestorMatching(
          (p) => p != node && p is! ParenthesizedExpression);
      if (_isExtensionOnNullableType(realParent is AssignmentExpression
          ? realParent.writeElement?.enclosingElement3
          : node.propertyName.staticElement?.enclosingElement3)) {
        rule.reportLintForToken(node.operator);
      }
    }
  }

  bool _isExtensionOnNullableType(Element? enclosingElement) =>
      enclosingElement is ExtensionElement &&
      context.typeSystem.isNullable(enclosingElement.extendedType);
}
