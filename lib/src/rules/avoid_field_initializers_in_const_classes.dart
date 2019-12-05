// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid field initializers in const classes.';

const _details = r'''

**AVOID** field initializers in const classes.

Instead of `final x = const expr;`, you should write `get x => const expr;` and
not allocate a useless field. As of April 2018 this is true for the VM, but not
for code that will be compiled to JS.

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

class AvoidFieldInitializersInConstClasses extends LintRule
    implements NodeLintRule {
  AvoidFieldInitializersInConstClasses()
      : super(
            name: 'avoid_field_initializers_in_const_classes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addConstructorFieldInitializer(this, visitor);
  }
}

class HasParameterReferenceVisitor extends RecursiveAstVisitor {
  Iterable<ParameterElement> parameters;

  bool useParameter = false;

  HasParameterReferenceVisitor(this.parameters);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (parameters.contains(node.staticElement)) {
      useParameter = true;
    } else {
      super.visitSimpleIdentifier(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    final constructor = node.parent as ConstructorDeclaration;
    if (constructor.constKeyword == null) return;
    // no lint if several constructors
    final constructorCount = constructor
        .thisOrAncestorOfType<ClassDeclaration>()
        .members
        .whereType<ConstructorDeclaration>()
        .length;
    if (constructorCount > 1) return;

    final visitor =
        HasParameterReferenceVisitor(constructor.parameters.parameterElements);
    node.expression.accept(visitor);
    if (!visitor.useParameter) {
      rule.reportLint(node);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) return;
    if (!node.fields.isFinal) return;
    // only const class
    final parent = node.parent;
    if (parent is ClassDeclaration) {
      if (parent.declaredElement.constructors.every((e) => !e.isConst)) {
        return;
      }
      for (final variable in node.fields.variables) {
        if (variable.initializer != null) {
          rule.reportLint(variable);
        }
      }
    }
  }
}
