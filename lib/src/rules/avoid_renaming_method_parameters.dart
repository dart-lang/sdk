// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r"Don't rename parameters of overrided methods.";

const _details = r'''

**DON'T** rename parameters of overrided methods.

**BAD:**
```
abstract class A {
  m(a);
}

abstract class B extends A {
  m(b);
}
```

**GOOD:**
```
abstract class A {
  m(a);
}

abstract class B extends A {
  m(a);
}
```

''';

class AvoidRenamingMethodParameters extends LintRule {
  AvoidRenamingMethodParameters()
      : super(
            name: 'avoid_renaming_method_parameters',
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
  visitMethodDeclaration(MethodDeclaration node) {
    ClassDeclaration clazz = node.parent;
    final parentMethod = clazz.element
        .lookUpInheritedMethod(node.name.name, clazz.element.library);

    if (parentMethod == null) return;

    for (var i = 0; i < node.parameters.parameterElements.length; i++) {
      if (node.parameters.parameters[i].identifier.name !=
          parentMethod.parameters[i].name) {
        rule.reportLint(node.parameters.parameters[i].identifier);
      }
    }
  }
}
