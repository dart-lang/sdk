// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';

class MustCallSuperVerifier {
  final DiagnosticReporter _diagnosticReporter;

  MustCallSuperVerifier(this._diagnosticReporter);

  void checkMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic || node.isAbstract) {
      return;
    }
    var element = node.declaredFragment!.element;

    var overridden = _findOverriddenMemberWithMustCallSuper(element);
    if (overridden == null) {
      return;
    }

    var overriddenName = overridden.name;
    if (overriddenName == null) {
      return;
    }

    if (element is MethodElement && _hasConcreteSuperMethod(element)) {
      _verifySuperIsCalled(
        node,
        overriddenName,
        overridden.enclosingElement?.name,
      );
      return;
    }

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) {
      return;
    }

    if (element is GetterElement) {
      var inheritedConcreteGetter = enclosingElement
          .lookupInheritedConcreteMember(element);
      if (inheritedConcreteGetter is GetterElement) {
        _verifySuperIsCalled(
          node,
          overriddenName,
          overridden.enclosingElement?.name,
        );
      }
      return;
    }

    if (element is SetterElement) {
      var inheritedConcreteSetter = enclosingElement
          .lookupInheritedConcreteMember(element);
      if (inheritedConcreteSetter is SetterElement) {
        var name = overriddenName;
        // For a setter, give the name without the trailing '=' to the verifier,
        // in order to check against property access.
        if (name.endsWith('=')) {
          name = name.substring(0, name.length - 1);
        }
        _verifySuperIsCalled(node, name, overridden.enclosingElement?.name);
      }
    }
  }

  /// Finds a method which is overridden by [element] and which is annotated
  /// with `@mustCallSuper`.
  ///
  /// As per the definition of `mustCallSuper` [1], every method which overrides
  /// a method annotated with `@mustCallSuper` is implicitly annotated with
  /// `@mustCallSuper`.
  ///
  /// [1]: https://pub.dev/documentation/meta/latest/meta/mustCallSuper-constant.html
  ExecutableElement? _findOverriddenMemberWithMustCallSuper(
    ExecutableElement element,
  ) {
    var classElement = element.enclosingElement;
    if (classElement is! InterfaceElement) {
      return null;
    }

    var name = element.name;
    if (name == null) {
      return null;
    }

    // Walk up the type hierarchy from [classElement], ignoring direct
    // interfaces.
    var superclasses = Queue<InterfaceElement?>();

    void addToQueue(InterfaceElement element) {
      superclasses.addAll(element.mixins.map((i) => i.element));
      superclasses.add(element.supertype?.element);
      if (element is MixinElement) {
        superclasses.addAll(
          element.superclassConstraints.map((i) => i.element),
        );
      }
    }

    var visitedClasses = <InterfaceElement>{};
    addToQueue(classElement);
    while (superclasses.isNotEmpty) {
      var ancestor = superclasses.removeFirst();
      if (ancestor == null || !visitedClasses.add(ancestor)) {
        continue;
      }

      ExecutableElement? member;
      switch (element) {
        case MethodElement():
          member = ancestor.getMethod(name);
        case GetterElement():
          member = ancestor.getMethod(name) ?? ancestor.getGetter(name);
        case SetterElement():
          member = ancestor.getSetter(name);
      }

      if (member is MethodElement && member.metadata.hasMustCallSuper) {
        return member;
      }
      if (member is PropertyAccessorElement &&
          member.metadata.hasMustCallSuper) {
        return member;
      }
      // TODO(srawlins): What about a field annotated with `@mustCallSuper`?
      // This might seem a legitimate case, but is not called out in the
      // documentation of [mustCallSuper].
      addToQueue(ancestor);
    }
    return null;
  }

  /// Returns whether [element] overrides a concrete method.
  bool _hasConcreteSuperMethod(ExecutableElement element) {
    var classElement = element.enclosingElement as InterfaceElement;

    var name = element.name;
    if (name == null) {
      return true;
    }

    if (classElement.supertype.isConcrete(name)) {
      return true;
    }

    if (classElement.mixins.any((m) => m.isConcrete(name))) {
      return true;
    }

    if (classElement is MixinElement &&
        classElement.superclassConstraints.any((c) => c.isConcrete(name))) {
      return true;
    }

    return false;
  }

  void _verifySuperIsCalled(
    MethodDeclaration node,
    String? methodName,
    String? overriddenEnclosingName,
  ) {
    var declaredFragment = node.declaredFragment!;
    var declaredElement = declaredFragment.element as ExecutableElementImpl;
    if (!declaredElement.invokesSuperSelf) {
      // Overridable elements are always enclosed in named elements, so it is
      // safe to assume [overriddenEnclosingName] is non-`null`.
      _diagnosticReporter.atToken(
        node.name,
        WarningCode.mustCallSuper,
        arguments: [overriddenEnclosingName!],
      );
    }
    return;
  }
}

extension on InterfaceElement {
  ExecutableElement? lookupInheritedConcreteMember(ExecutableElement element) {
    var nameObj = Name.forElement(element);
    if (nameObj == null) {
      return null;
    }

    var library = element.library as LibraryElementImpl;
    var inheritanceManager = library.session.inheritanceManager;
    return inheritanceManager.getMember(this, nameObj, forSuper: true);
  }
}

extension on InterfaceType? {
  bool isConcrete(String name) {
    var self = this;
    if (self == null) return false;
    var element = self.element;

    var library = element.library as LibraryElementImpl;
    var inheritanceManager = library.internal.inheritanceManager;

    var concrete = inheritanceManager.getMember(
      element,
      Name.forLibrary(library, name),
      concrete: true,
    );

    return concrete != null;
  }
}
