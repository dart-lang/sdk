// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

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

class AvoidReturnTypesOnSetters extends LintRule {
  AvoidReturnTypesOnSetters()
      : super(
            name: 'avoid_return_types_on_setters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportLint(node.returnType);
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter) {
      if (node.returnType != null) {
        rule.reportLint(node.returnType);
      }
    }
  }
}
