// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

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

class PreferFunctionDeclarationsOverVariables extends LintRule {
  _Visitor _visitor;
  PreferFunctionDeclarationsOverVariables()
      : super(
            name: 'prefer_function_declarations_over_variables',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer is FunctionExpression) {
      FunctionBody function = node.getAncestor((a) => a is FunctionBody);
      if (function == null ||
          !function.isPotentiallyMutatedInScope(node.element)) {
        rule.reportLint(node);
      }
    }
  }
}
