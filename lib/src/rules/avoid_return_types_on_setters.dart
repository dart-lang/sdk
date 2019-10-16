// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid return types on setters.';

const _details = r'''

**AVOID** return types on setters.

As setters do not return a value, declaring the return type of one is redundant.

**GOOD:**
```
set speed(int ms);
```

**BAD:**
```
void set speed(int ms);
```

''';

class AvoidReturnTypesOnSetters extends LintRule implements NodeLintRule {
  AvoidReturnTypesOnSetters()
      : super(
            name: 'avoid_return_types_on_setters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportLint(node.returnType);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportLint(node.returnType);
      }
    }
  }
}
