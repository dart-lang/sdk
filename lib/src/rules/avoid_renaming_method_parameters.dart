// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r"Don't rename parameters of overridden methods.";

const _details = r'''**DON'T** rename parameters of overridden methods.

Methods that override another method, but do not have their own documentation
comment, will inherit the overridden method's comment when dartdoc produces
documentation. If the inherited method contains the name of the parameter (in
square brackets), then dartdoc cannot link it correctly.

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
    if (node.isStatic) return;
    if (node.documentationComment != null) return;

    ClassDeclaration clazz = node.parent;

    if (clazz.element.isPrivate) return;
    if (!isDefinedInLib(getCompilationUnit(node))) return;

    final parentMethod = clazz.element
        .lookUpInheritedMethod(node.name.name, clazz.element.library);

    if (parentMethod == null) return;

    final parameters =
        node.parameters.parameters.where((p) => !p.isNamed).toList();
    final parentParameters =
        parentMethod.parameters.where((p) => !p.isNamed).toList();
    int count = math.min(parameters.length, parentParameters.length);
    for (var i = 0; i < count; i++) {
      if (parentParameters.length <= i) break;
      if (parameters[i].identifier.name != parentParameters[i].name) {
        rule.reportLint(parameters[i].identifier);
      }
    }
  }
}
