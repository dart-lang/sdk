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
    ExecutableElement overridden =
        _findOverriddenMemberWithMustCallSuper(node.declaredElement);
    if (overridden != null && _hasConcreteSuperMethod(node.declaredElement)) {
      _SuperCallVerifier verifier = _SuperCallVerifier(overridden.name);
      node.accept(verifier);
      if (!verifier.superIsCalled) {
        _errorReporter.reportErrorForNode(HintCode.MUST_CALL_SUPER, node.name,
            [overridden.enclosingElement.name]);
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
  ExecutableElement _findOverriddenMemberWithMustCallSuper(
      ExecutableElement element) {
    //Element member = node.declaredElement;
    if (element.enclosingElement is! ClassElement) {
      return null;
    }
    ClassElement classElement = element.enclosingElement;
    String name = element.name;

    // Walk up the type hierarchy from [classElement], ignoring direct
    // interfaces.
    Queue<ClassElement> superclasses =
        Queue.of(classElement.mixins.map((i) => i.element))
          ..addAll(classElement.superclassConstraints.map((i) => i.element))
          ..add(classElement.supertype?.element);
    var visitedClasses = <ClassElement>{};
    while (superclasses.isNotEmpty) {
      ClassElement ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }
      ExecutableElement member = ancestor.getMethod(name) ??
          ancestor.getGetter(name) ??
          ancestor.getSetter(name);
      if (member is MethodElement && member.hasMustCallSuper) {
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
  bool _hasConcreteSuperMethod(MethodElement element) {
    ClassElement classElement = element.enclosingElement;
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
    if (classElement.supertype != null &&
        isConcrete(classElement.supertype.element)) {
      return true;
    }

    return false;
  }
}

/// Recursively visits an AST, looking for method invocations.
class _SuperCallVerifier extends RecursiveAstVisitor<void> {
  bool superIsCalled = false;

  final String name;

  _SuperCallVerifier(this.name);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.leftOperand is SuperExpression && node.operator.lexeme == name) {
      superIsCalled = true;
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target is SuperExpression && node.methodName.name == name) {
      superIsCalled = true;
    }
    super.visitMethodInvocation(node);
  }
}
