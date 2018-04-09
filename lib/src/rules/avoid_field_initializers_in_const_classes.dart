// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid field initializers in const classes.';

const _details = r'''

**AVOID** field initializers in const classes.

Instead of `final x = const expr;`, you should write `get x => const expr;` and
not allocate a useless field.

**BAD:**
```
class A {
  final a = const [];
  const A();
}
```

**GOOD:**
```
class A {
  get a => const [];
  const A();
}
```

''';

class AvoidFieldInitializersInConstClasses extends LintRule {
  AvoidFieldInitializersInConstClasses()
      : super(
            name: 'avoid_field_initializers_in_const_classes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) return;
    if (!node.fields.isFinal) return;
    // only const class
    if (node
        .getAncestor<ClassDeclaration>((e) => e is ClassDeclaration)
        .element
        .constructors
        .every((e) => !e.isConst)) {
      return;
    }

    for (final variable in node.fields.variables) {
      if (variable.initializer != null) {
        rule.reportLint(variable);
      }
    }
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    final ConstructorDeclaration constructor = node.parent;
    if (constructor.constKeyword == null) return;
    // no lint if several constructors
    final constructorCount = constructor
        .getAncestor<ClassDeclaration>((e) => e is ClassDeclaration)
        .members
        .where((e) => e is ConstructorDeclaration)
        .length;
    if (constructorCount > 1) return;

    final visitor = new HasParameterReferenceVisitor(constructor
        .parameters.parameters
        .map((e) => e.identifier.name)
        .toList());
    visitor.visitConstructorFieldInitializer(node);
    if (!visitor.useParameter) {
      rule.reportLint(node);
    }
  }
}

class HasParameterReferenceVisitor extends RecursiveAstVisitor {
  HasParameterReferenceVisitor(this.parameters);

  List<String> parameters;

  bool useParameter = false;

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (parameters.contains(node.name)) {
      useParameter = true;
    } else {
      super.visitSimpleIdentifier(node);
    }
  }
}
