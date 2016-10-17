// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.parameter_assignments;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/linter.dart';

const _desc =
    r"Don't reassign references to parameters of functions or methods.";

const _details = r'''

**DO NOT** assign new values to parameters of methods or functions.

**BAD:**
```
void badFunction(int parameter) { // LINT
  parameter = 4;
}
```

**BAD:**
```
class A {
    void badMethod(int parameter) { // LINT
    parameter = 4;
  }
}
```

**GOOD:**
```
void ok(String parameter) {
  print(parameter);
}
```

**GOOD:**
```
class A {
  void ok(String parameter) {
    print(parameter);
  }
}
```
''';

class ParameterAssignments extends LintRule {
  _Visitor _visitor;
  ParameterAssignments()
      : super(
            name: 'parameter_assignments',
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
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FormalParameterList parameters = node.functionExpression.parameters;
    if (parameters != null) {
      // Getter do not have formal parameters.
      parameters.parameters.forEach((e) {
        if (node.functionExpression.body
            .isPotentiallyMutatedInScope(e.element)) {
          rule.reportLint(e);
        }
      });
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    FormalParameterList parameterList = node.parameters;
    if (parameterList != null) {
      // Getters don't have parameters.
      parameterList.parameters.forEach((e) {
        if (node.body.isPotentiallyMutatedInScope(e.element)) {
          rule.reportLint(e);
        }
      });
    }
  }
}
