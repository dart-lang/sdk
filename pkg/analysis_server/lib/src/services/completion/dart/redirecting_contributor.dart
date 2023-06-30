// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions for constructors that are being
/// redirected to. More concretely, this class produces suggestions for
/// expressions of the form `this.^` or `super.^` in a constructor's initializer
/// list or after an `=` in a factory constructor.
class RedirectingContributor extends DartCompletionContributor {
  RedirectingContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var entity = request.target.entity;
    if (entity is SimpleIdentifier) {
      var parent = entity.parent;
      if (parent is PropertyAccess &&
          parent.parent is ConstructorFieldInitializer) {
        // C() : this.^
        var containingConstructor =
            parent.thisOrAncestorOfType<ConstructorDeclaration>();
        var constructorElement = containingConstructor?.declaredElement;
        var classElement = constructorElement?.enclosingElement2;
        if (classElement != null) {
          for (var constructor in classElement.constructors) {
            if (constructor != constructorElement) {
              builder.suggestConstructor(constructor, hasClassName: true);
            }
          }
        }
      } else if (parent is SuperConstructorInvocation) {
        // C() : super.^
        var superclassElement =
            parent.enclosingInterfaceElement?.supertype?.element;
        if (superclassElement != null) {
          for (var constructor in superclassElement.constructors) {
            if (constructor.isAccessibleIn(request.libraryElement)) {
              builder.suggestConstructor(constructor, hasClassName: true);
            }
          }
        }
      }
    } else if (entity is ConstructorName) {
      var parent = entity.parent;
      if (parent is ConstructorDeclaration &&
          parent.redirectedConstructor == entity) {
        // factory C() = ^
        var containingConstructor =
            parent.thisOrAncestorOfType<ConstructorDeclaration>();
        var constructorElement = containingConstructor?.declaredElement;
        var classElement = constructorElement?.enclosingElement2;
        var libraryElement = request.libraryElement;
        if (classElement == null) {
          return;
        }
        var typeSystem = libraryElement.typeSystem;
        for (var unit in libraryElement.units) {
          for (var class_ in unit.classes) {
            if (typeSystem.isSubtypeOf(
                class_.thisType, classElement.thisType)) {
              for (var constructor in class_.constructors) {
                if (constructor != constructorElement &&
                    constructor.isAccessibleIn(request.libraryElement)) {
                  builder.suggestConstructor(constructor);
                }
              }
            }
          }
        }
      }
    }
  }
}
