// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't use constant patterns with type literals.";

const _details = r'''
If you meant to test if the object has type `Foo`, instead write `Foo _`.

**BAD:**
```dart
void f(Object? x) {
  if (x case num) {
    print('int or double');
  }
}
```

**GOOD:**
```dart
void f(Object? x) {
  if (x case num _) {
    print('int or double');
  }
}
```

If you do mean to test that the matched value (which you expect to have the
type `Type`) is equal to the type literal `Foo`, then this lint can be
silenced using `const (Foo)`.

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
  if (x case const (int)) {
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
    // `const (MyType)` is fine.
    if (node.constKeyword != null) {
      return;
    }

    var expressionType = node.expression.staticType;
    if (expressionType != null && expressionType.isDartCoreType) {
      rule.reportLint(node);
    }
  }
}
