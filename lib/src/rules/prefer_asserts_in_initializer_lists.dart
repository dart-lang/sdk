// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Prefer putting asserts in initializer list.';

const _details = r'''
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

class PreferAssertsInInitializerLists extends LintRule implements NodeLintRule {
  PreferAssertsInInitializerLists()
      : super(
            name: 'prefer_asserts_in_initializer_lists',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _AssertVisitor extends RecursiveAstVisitor {
  final ConstructorElement constructorElement;
  final _ClassAndSuperClasses classAndSuperClasses;

  bool needInstance = false;

  _AssertVisitor(this.constructorElement, this.classAndSuperClasses);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
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
                .whereType<FieldFormalParameterElement>()
                .any((p) => p.field.getter == element);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    needInstance = true;
  }

  bool _hasAccessor(PropertyAccessorElement element) =>
      classAndSuperClasses.classes.contains(element.enclosingElement);

  bool _hasMethod(MethodElement element) =>
      classAndSuperClasses.classes.contains(element.enclosingElement);
}

/// Lazy cache of elements.
class _ClassAndSuperClasses {
  final ClassElement element;
  final Set<ClassElement> _classes = {};

  _ClassAndSuperClasses(this.element);

  /// The [element] and its super classes, including mixins.
  Set<ClassElement> get classes {
    if (_classes.isEmpty) {
      void addRecursively(ClassElement element) {
        if (element != null && _classes.add(element)) {
          element.mixins.forEach((t) => addRecursively(t.element));
          addRecursively(element.supertype?.element);
        }
      }

      addRecursively(element);
    }

    return _classes;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _ClassAndSuperClasses _classAndSuperClasses;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _classAndSuperClasses = _ClassAndSuperClasses(node.declaredElement);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.declaredElement.isFactory) return;

    final body = node.body;
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! AssertStatement) break;

        final assertVisitor =
            _AssertVisitor(node.declaredElement, _classAndSuperClasses);
        statement.visitChildren(assertVisitor);
        if (!assertVisitor.needInstance) {
          rule.reportLintForToken(statement.beginToken);
        }
      }
    }
  }
}
