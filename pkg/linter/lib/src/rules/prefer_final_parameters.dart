// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer final for parameter declarations if they are not reassigned.';

const _details = r'''
**DO** prefer declaring parameters as final if they are not reassigned in
the function body.

Declaring parameters as final when possible is a good practice because it helps
avoid accidental reassignments.

**BAD:**
```dart
void badParameter(String label) { // LINT
  print(label);
}
```

**GOOD:**
```dart
void goodParameter(final String label) { // OK
  print(label);
}
```

**BAD:**
```dart
void badExpression(int value) => print(value); // LINT
```

**GOOD:**
```dart
void goodExpression(final int value) => print(value); // OK
```

**BAD:**
```dart
[1, 4, 6, 8].forEach((value) => print(value + 2)); // LINT
```

**GOOD:**
```dart
[1, 4, 6, 8].forEach((final value) => print(value + 2)); // OK
```

**GOOD:**
```dart
void mutableParameter(String label) { // OK
  print(label);
  label = 'Hello Linter!';
  print(label);
}
```

''';

class PreferFinalParameters extends LintRule {
  static const LintCode code = LintCode(
      'prefer_final_parameters', "The parameter '{0}' should be final.",
      correctionMessage: 'Try making the parameter final.');

  PreferFinalParameters()
      : super(
            name: 'prefer_final_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules =>
      const ['unnecessary_final', 'avoid_final_parameters'];

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

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _reportApplicableParameters(node.parameters, node.body);

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _reportApplicableParameters(node.parameters, node.body);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _reportApplicableParameters(node.parameters, node.body);

  /// Report the lint for parameters in the [parameters] list that are not
  /// const or final already and not potentially mutated in the function [body].
  void _reportApplicableParameters(
      FormalParameterList? parameters, FunctionBody body) {
    if (parameters != null) {
      for (var param in parameters.parameters) {
        if (param is DefaultFormalParameter) {
          param = param.parameter;
        }
        if (param.isFinal ||
            param.isConst ||
            // A field formal parameter is final even without the `final`
            // modifier.
            param is FieldFormalParameter ||
            // A super formal parameter is final even without the `final`
            // modifier.
            param is SuperFormalParameter) {
          continue;
        }
        var declaredElement = param.declaredElement;
        if (declaredElement != null &&
            !declaredElement.isInitializingFormal &&
            !body.isPotentiallyMutatedInScope(declaredElement)) {
          rule.reportLint(param, arguments: [param.name!.lexeme]);
        }
      }
    }
  }
}
