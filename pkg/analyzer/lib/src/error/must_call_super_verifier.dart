// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';

class MustCallSuperVerifier {
  final ErrorReporter _errorReporter;

  MustCallSuperVerifier(this._errorReporter);

  void checkMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic || node.isAbstract) {
      return;
    }
    var element = node.declaredElement!;
    var overridden = _findOverriddenMemberWithMustCallSuper(element);
    if (overridden == null) {
      return;
    }

    if (element is MethodElement && _hasConcreteSuperMethod(element)) {
      _verifySuperIsCalled(
          node, overridden.name, overridden.enclosingElement.name);
      return;
    }

    var enclosingElement = element.enclosingElement as ClassElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      var inheritedConcreteGetter = enclosingElement
          .lookUpInheritedConcreteGetter(element.name, element.library);
      if (inheritedConcreteGetter != null) {
        _verifySuperIsCalled(
            node, overridden.name, overridden.enclosingElement.name);
      }
      return;
    }

    if (element is PropertyAccessorElement && element.isSetter) {
      var inheritedConcreteSetter = enclosingElement
          .lookUpInheritedConcreteSetter(element.name, element.library);
      if (inheritedConcreteSetter != null) {
        var name = overridden.name;
        // For a setter, give the name without the trailing '=' to the verifier,
        // in order to check against property access.
        if (name.endsWith('=')) {
          name = name.substring(0, name.length - 1);
        }
        _verifySuperIsCalled(node, name, overridden.enclosingElement.name);
      }
    }
  }

  /// Find a method which is overridden by [node] and which is annotated with
  /// `@mustCallSuper`.
  ///
  /// As per the definition of `mustCallSuper` [1], every method which overrides
  /// a method annotated with `@mustCallSuper` is implicitly annotated with
  /// `@mustCallSuper`.
  ///
  /// [1]: https://pub.dev/documentation/meta/latest/meta/mustCallSuper-constant.html
  ExecutableElement? _findOverriddenMemberWithMustCallSuper(
      ExecutableElement element) {
    //Element member = node.declaredElement;
    if (element.enclosingElement is! ClassElement) {
      return null;
    }
    var classElement = element.enclosingElement as ClassElement;
    String name = element.name;

    // Walk up the type hierarchy from [classElement], ignoring direct
    // interfaces.
    Queue<ClassElement?> superclasses =
        Queue.of(classElement.mixins.map((i) => i.element))
          ..addAll(classElement.superclassConstraints.map((i) => i.element))
          ..add(classElement.supertype?.element);
    var visitedClasses = <ClassElement>{};
    while (superclasses.isNotEmpty) {
      var ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }
      var member = ancestor.getMethod(name) ??
          ancestor.getGetter(name) ??
          ancestor.getSetter(name);
      if (member is MethodElement && member.hasMustCallSuper) {
        return member;
      }
      if (member is PropertyAccessorElement && member.hasMustCallSuper) {
        // TODO(srawlins): What about a field annotated with `@mustCallSuper`?
        // This might seem a legitimate case, but is not called out in the
        // documentation of [mustCallSuper].
        return member;
      }
      superclasses
        ..addAll(ancestor.mixins.map((i) => i.element))
        ..addAll(ancestor.superclassConstraints.map((i) => i.element))
        ..add(ancestor.supertype?.element);
    }
    return null;
  }

  /// Returns whether [node] overrides a concrete method.
  bool _hasConcreteSuperMethod(ExecutableElement element) {
    var classElement = element.enclosingElement as ClassElement;
    String name = element.name;

    bool isConcrete(ClassElement element) =>
        element.lookUpConcreteMethod(name, element.library) != null;

    if (classElement.mixins.map((i) => i.element).any(isConcrete)) {
      return true;
    }
    if (classElement.superclassConstraints
        .map((i) => i.element)
        .any(isConcrete)) {
      return true;
    }

    var supertype = classElement.supertype;
    if (supertype != null && isConcrete(supertype.element)) {
      return true;
    }

    return false;
  }

  void _verifySuperIsCalled(MethodDeclaration node, String methodName,
      String? overriddenEnclosingName) {
    _SuperCallVerifier verifier = _SuperCallVerifier(methodName);
    node.accept(verifier);
    if (!verifier.superIsCalled) {
      _errorReporter.reportErrorForNode(
          HintCode.MUST_CALL_SUPER, node.name, [overriddenEnclosingName]);
    }
    return;
  }
}

/// Recursively visits an AST, looking for method invocations.
class _SuperCallVerifier extends RecursiveAstVisitor<void> {
  bool superIsCalled = false;

  final String name;

  _SuperCallVerifier(this.name);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var lhs = node.leftHandSide;
    if (lhs is PropertyAccess) {
      if (lhs.target is SuperExpression && lhs.propertyName.name == name) {
        superIsCalled = true;
        return;
      }
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.leftOperand is SuperExpression && node.operator.lexeme == name) {
      superIsCalled = true;
      return;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target is SuperExpression && node.methodName.name == name) {
      superIsCalled = true;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target is SuperExpression && node.propertyName.name == name) {
      superIsCalled = true;
      return;
    }
    super.visitPropertyAccess(node);
  }
}
