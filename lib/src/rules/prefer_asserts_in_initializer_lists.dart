// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_asserts_in_initializer_lists;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Prefer put asserts in initializer list.';

const details = '''
**WARNING** Putting asserts in initializer lists is only possible using an
experimental language feature that might be removed.

**DO** put asserts in initializer list for constructors with only asserts in
their body.

**GOOD:**
```
class A {
  A(int a) : assert(a != null);
}
```

**BAD:**
```
class A {
  A(int a) {
    assert(a != null);
  }
}
```
''';

class PreferAssertsInInitializerLists extends LintRule {
  PreferAssertsInInitializerLists()
      : super(
            name: 'prefer_asserts_in_initializer_lists',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.element.isFactory) return;

    final body = node.body;
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! AssertStatement) break;

        final assertVisitor = new _AssertVisitor(node.element);
        statement.visitChildren(assertVisitor);
        if (!assertVisitor.needInstance) {
          rule.reportLintForToken(statement.beginToken);
        }
      }
    }
  }
}

class _AssertVisitor extends RecursiveAstVisitor {
  _AssertVisitor(this.constructorElement);

  final ConstructorElement constructorElement;
  bool needInstance = false;

  ClassElement get classElement => constructorElement.enclosingElement;

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.staticElement;

    // use method
    needInstance = needInstance ||
        element is MethodElement && !element.isStatic && _hasMethod(element);

    // use property accessor not used as field formal parameter
    needInstance = needInstance ||
        element is PropertyAccessorElement &&
            !element.isStatic &&
            _hasAccessor(element) &&
            !constructorElement.parameters
                .where((p) => p is FieldFormalParameterElement)
                .any((p) =>
                    (p as FieldFormalParameterElement).field.getter == element);
  }

  bool _hasMethod(MethodElement element) {
    final type = classElement.type;
    final name = element.name;
    return type.lookUpMethod(name, element.library) == element ||
        type.lookUpInheritedMethod(name) == element;
  }

  bool _hasAccessor(PropertyAccessorElement element) {
    final type = classElement.type;
    final name = element.name;
    if (element.isGetter) {
      return type.lookUpGetter(name, element.library) == element ||
          type.lookUpInheritedGetter(name) == element;
    } else {
      return type.lookUpSetter(name, element.library) == element ||
          type.lookUpInheritedSetter(name) == element;
    }
  }

  @override
  visitThisExpression(ThisExpression node) {
    needInstance = true;
  }
}
