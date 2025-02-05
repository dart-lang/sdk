// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Prefer putting asserts in initializer lists.';

class PreferAssertsInInitializerLists extends LintRule {
  PreferAssertsInInitializerLists()
      : super(
          name: LintNames.prefer_asserts_in_initializer_lists,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_asserts_in_initializer_lists;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _AssertVisitor extends RecursiveAstVisitor<void> {
  final ConstructorElement2 constructorElement;
  final _ClassAndSuperClasses? classAndSuperClasses;

  bool needInstance = false;

  _AssertVisitor(this.constructorElement, this.classAndSuperClasses);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = getWriteOrReadElement(node);

    // use method
    needInstance = needInstance ||
        element is MethodElement2 && !element.isStatic && _hasMethod(element);

    // use property accessor not used as field formal parameter
    needInstance = needInstance ||
        (element is PropertyAccessorElement2) &&
            !element.isStatic &&
            _hasAccessor(element) &&
            !_paramMatchesField(element, constructorElement.formalParameters);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    needInstance = true;
  }

  bool _hasAccessor(PropertyAccessorElement2 element) {
    var classes = classAndSuperClasses?.classes;
    return classes != null && classes.contains(element.enclosingElement2);
  }

  bool _hasMethod(MethodElement2 element) {
    var classes = classAndSuperClasses?.classes;
    return classes != null && classes.contains(element.enclosingElement2);
  }

  bool _paramMatchesField(PropertyAccessorElement2 element,
      List<FormalParameterElement> parameters) {
    for (var p in parameters) {
      FormalParameterElement? parameterElement = p;
      if (parameterElement is SuperFormalParameterElement2) {
        parameterElement = parameterElement.superConstructorParameter2;
      }

      if (parameterElement is FieldFormalParameterElement2) {
        if (parameterElement.field2?.getter2 == element) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Lazy cache of elements.
class _ClassAndSuperClasses {
  final ClassElement2? element;
  final Set<InterfaceElement2> _classes = {};

  _ClassAndSuperClasses(this.element);

  /// The [element] and its super classes, including mixins.
  Set<InterfaceElement2> get classes {
    if (_classes.isEmpty) {
      void addRecursively(InterfaceElement2? element) {
        if (element != null && _classes.add(element)) {
          for (var t in element.mixins) {
            addRecursively(t.element3);
          }
          addRecursively(element.supertype?.element3);
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
    _classAndSuperClasses =
        _ClassAndSuperClasses(node.declaredFragment?.element);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
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
