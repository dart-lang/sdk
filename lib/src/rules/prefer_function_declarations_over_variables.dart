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
```
void main() {
  var localFunction = () {
    ...
  };
}
```

**GOOD:**
```
void main() {
  localFunction() {
    ...
  }
}
```

''';

class PreferFunctionDeclarationsOverVariables extends LintRule
    implements NodeLintRule {
  PreferFunctionDeclarationsOverVariables()
      : super(
            name: 'prefer_function_declarations_over_variables',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer is FunctionExpression) {
      final function = node.thisOrAncestorOfType<FunctionBody>();
      if (function == null ||
          !function.isPotentiallyMutatedInScope(node.declaredElement)) {
        rule.reportLint(node);
      }
    }
  }
}
