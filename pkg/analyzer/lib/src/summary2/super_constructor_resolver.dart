// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Resolves the explicit or implicit super-constructors invoked by
/// non-redirecting generative constructors.
class SuperConstructorResolver {
  final Linker _linker;

  SuperConstructorResolver(this._linker);

  void perform() {
    for (var builder in _linker.builders.values) {
      for (var classElement in builder.element.classes) {
        for (var constructorElement in classElement.constructors) {
          _constructor(classElement, constructorElement);
        }
      }
    }
  }

  void _constructor(
    ClassElementImpl classElement,
    ConstructorElementImpl element,
  ) {
    // Constructors of mixin applications are already configured.
    if (classElement.isMixinApplication) {
      return;
    }

    // We handle only generative constructors here.
    if (element.isFactory) {
      return;
    }

    var invokesDefaultSuperConstructor = true;
    for (var fragment in element.fragments) {
      var node = _linker.getLinkingNode2(fragment);
      if (node is ConstructorDeclaration) {
        for (var initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            invokesDefaultSuperConstructor = false;
          } else if (initializer is SuperConstructorInvocation) {
            invokesDefaultSuperConstructor = false;
            var name = initializer.constructorName?.name ?? 'new';
            element.superConstructor = classElement.supertype
                ?.getNamedConstructor(name);
          }
        }
      }
    }

    if (invokesDefaultSuperConstructor) {
      element.superConstructor = classElement.supertype?.getNamedConstructor(
        'new',
      );
    }
  }
}
