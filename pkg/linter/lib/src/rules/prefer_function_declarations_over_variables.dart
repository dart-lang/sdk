// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use a function declaration to bind a function to a name.';

const _details = r'''
**DO** use a function declaration to bind a function to a name.

As Dart allows local function declarations, it is a good practice to use them in
the place of function literals.

**BAD:**
```dart
void main() {
  var localFunction = () {
    ...
  };
}
```

**GOOD:**
```dart
void main() {
  localFunction() {
    ...
  }
}
```

''';

class PreferFunctionDeclarationsOverVariables extends LintRule {
  static const LintCode code = LintCode(
      'prefer_function_declarations_over_variables',
      'Use a function declaration rather than a variable assignment to bind a '
          'function to a name.',
      correctionMessage:
          'Try rewriting the closure assignment as a function declaration.');

  PreferFunctionDeclarationsOverVariables()
      : super(
            name: 'prefer_function_declarations_over_variables',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer is FunctionExpression) {
      var function = node.thisOrAncestorOfType<FunctionBody>();
      var declaredElement = node.declaredElement;
      if (function == null) {
        // When there is no enclosing function body, this is a variable
        // definition for a field or a top-level variable, which should only
        // be reported if final.
        if (node.isFinal) {
          rule.reportLint(node);
        }
      } else {
        if (declaredElement != null &&
            !function.isPotentiallyMutatedInScope(declaredElement)) {
          rule.reportLint(node);
        }
      }
    }
  }
}
