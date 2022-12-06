// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid final for parameter declarations.';

const _details = r'''
**AVOID** declaring parameters as final.

Declaring parameters as final can lead to unnecessarily verbose code, especially
when using the "parameter_assignments" rule.

**BAD:**
```dart
void goodParameter(final String label) { // LINT
  print(label);
}
```

**GOOD:**
```dart
void badParameter(String label) { // OK
  print(label);
}
```

**BAD:**
```dart
void goodExpression(final int value) => print(value); // LINT
```

**GOOD:**
```dart
void badExpression(int value) => print(value); // OK
```

**BAD:**
```dart
[1, 4, 6, 8].forEach((final value) => print(value + 2)); // LINT
```

**GOOD:**
```dart
[1, 4, 6, 8].forEach((value) => print(value + 2)); // OK
```

''';

class AvoidFinalParameters extends LintRule {
  static const LintCode code = LintCode(
      'avoid_final_parameters', "Parameters should not be marked as 'final'.",
      correctionMessage: "Try removing the keyword 'final'.");

  AvoidFinalParameters()
      : super(
            name: 'avoid_final_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['prefer_final_parameters'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _reportApplicableParameters(node.parameters);

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _reportApplicableParameters(node.parameters);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _reportApplicableParameters(node.parameters);

  /// Report the lint for parameters in the [parameters] list that are final.
  void _reportApplicableParameters(FormalParameterList? parameters) {
    if (parameters != null) {
      for (var param in parameters.parameters) {
        if (param.isFinal) {
          rule.reportLint(param);
        }
      }
    }
  }
}
