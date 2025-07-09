// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class ConstructorInitializerResolver {
  final Linker _linker;
  final LibraryBuilder _libraryBuilder;

  ConstructorInitializerResolver(this._linker, this._libraryBuilder);

  void resolve() {
    var libraryElement = _libraryBuilder.element;
    var interfaceElements = <InterfaceElementImpl>[
      ...libraryElement.classes,
      ...libraryElement.enums,
      ...libraryElement.extensionTypes,
      ...libraryElement.mixins,
    ];

    for (var interfaceElement in interfaceElements) {
      for (var constructorElement in interfaceElement.constructors) {
        _constructorElement(interfaceElement, constructorElement);
      }
    }
  }

  void _constructorElement(
    InterfaceElementImpl interfaceElement,
    ConstructorElementImpl element,
  ) {
    if (element.isSynthetic) return;

    for (var fragment in element.fragments) {
      var node = _linker.getLinkingNode2(fragment);
      if (node is! ConstructorDeclarationImpl) return;

      var constructorScope = LinkingNodeContext.get(node).scope;
      var initializerScope = ConstructorInitializerScope(
        constructorScope,
        element,
      );

      var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
      var astResolver = AstResolver(
        _linker,
        fragment.libraryFragment,
        initializerScope,
        analysisOptions,
        enclosingClassElement: interfaceElement,
        enclosingExecutableElement: element,
      );

      var body = node.body;
      body.localVariableInfo = LocalVariableInfo();

      astResolver.resolveConstructorNode(node);

      if (node.factoryKeyword != null) {
        element.redirectedConstructor = node.redirectedConstructor?.element;
      } else {
        for (var initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocationImpl) {
            element.redirectedConstructor = initializer.element;
          }
        }
      }
    }
  }
}
