// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Prefer putting asserts in initializer lists.';

const _details = r'''
**DO** put asserts in initializer lists.

**BAD:**
```dart
class A {
  A(int a) {
    assert(a != 0);
  }
}
```

**GOOD:**
```dart
class A {
  A(int a) : assert(a != 0);
}
```

''';

class PreferAssertsInInitializerLists extends LintRule {
  static const LintCode code = LintCode('prefer_asserts_in_initializer_lists',
      'Assert should be in the initializer list.',
      correctionMessage: 'Try moving the assert to the initializer list.');

  PreferAssertsInInitializerLists()
      : super(
            name: 'prefer_asserts_in_initializer_lists',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _AssertVisitor extends RecursiveAstVisitor {
  final ConstructorElement constructorElement;
  final _ClassAndSuperClasses? classAndSuperClasses;

  bool needInstance = false;

  _AssertVisitor(this.constructorElement, this.classAndSuperClasses);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = getWriteOrReadElement(node);

    // use method
    needInstance = needInstance ||
        element is MethodElement && !element.isStatic && _hasMethod(element);

    // use property accessor not used as field formal parameter
    needInstance = needInstance ||
        element is PropertyAccessorElement &&
            !element.isStatic &&
            _hasAccessor(element) &&
            !_paramMatchesField(element, constructorElement.parameters);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    needInstance = true;
  }

  bool _hasAccessor(PropertyAccessorElement element) {
    var classes = classAndSuperClasses?.classes;
    return classes != null && classes.contains(element.enclosingElement);
  }

  bool _hasMethod(MethodElement element) {
    var classes = classAndSuperClasses?.classes;
    return classes != null && classes.contains(element.enclosingElement);
  }

  bool _paramMatchesField(
      PropertyAccessorElement element, List<ParameterElement> parameters) {
    for (var p in parameters) {
      ParameterElement? parameterElement = p;
      if (parameterElement is SuperFormalParameterElement) {
        parameterElement = parameterElement.superConstructorParameter;
      }

      if (parameterElement is FieldFormalParameterElement) {
        if (parameterElement.field?.getter == element) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Lazy cache of elements.
class _ClassAndSuperClasses {
  final ClassElement? element;
  final Set<InterfaceElement> _classes = {};

  _ClassAndSuperClasses(this.element);

  /// The [element] and its super classes, including mixins.
  Set<InterfaceElement> get classes {
    if (_classes.isEmpty) {
      void addRecursively(InterfaceElement? element) {
        if (element != null && _classes.add(element)) {
          for (var t in element.mixins) {
            addRecursively(t.element);
          }
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

  _ClassAndSuperClasses? _classAndSuperClasses;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _classAndSuperClasses = _ClassAndSuperClasses(node.declaredElement);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null || declaredElement.isFactory) return;

    var body = node.body;
    if (body is BlockFunctionBody) {
      for (var statement in body.block.statements) {
        if (statement is! AssertStatement) break;

        var assertVisitor =
            _AssertVisitor(declaredElement, _classAndSuperClasses);
        statement.visitChildren(assertVisitor);
        if (!assertVisitor.needInstance) {
          rule.reportLintForToken(statement.beginToken);
        }
      }
    }
  }
}
