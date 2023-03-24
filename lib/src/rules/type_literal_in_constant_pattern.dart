// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't use constant patterns with type literals.";

const _details = r'''
Use `== TypeName` or `TypeName _` instead of type literals in patterns.

**BAD:**
```dart
void f(Type x) {
  if (x case int) {
    print('int');
  }
}
```

**GOOD:**
```dart
void f(Type x) {
  if (x case == int) {
    print('int');
  }
}
```

**BAD:**
```dart
void f(Object? x) {
  if (x case int) {
    print('int');
  }
}
```

**GOOD:**
```dart
void f(Object? x) {
  if (x case int _) {
    print('int');
  }
}
```

''';

class TypeLiteralInConstantPattern extends LintRule {
  static const String lintName = 'type_literal_in_constant_pattern';

  static const LintCode code = LintCode(
    lintName,
    "Use 'TypeName _' instead of a type literal.",
    correctionMessage: "Replace with 'TypeName _'.",
  );

  TypeLiteralInConstantPattern()
      : super(
          name: lintName,
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstantPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  visitConstantPattern(ConstantPattern node) {
    var expressionType = node.expression.staticType;
    if (expressionType != null && expressionType.isDartCoreType) {
      var matchedValueType = node.matchedValueType;
      if (matchedValueType != null) {
        var typeSystem = context.typeSystem;
        matchedValueType = typeSystem.resolveToBound(matchedValueType);
        if (!matchedValueType.isDartCoreType) {
          if (typeSystem.isSubtypeOf(expressionType, matchedValueType)) {
            rule.reportLint(node);
          }
        }
      }
    }
  }
}
