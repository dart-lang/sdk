// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class ConstructorInitializerResolver {
  final Linker _linker;
  final LibraryElementImpl _libraryElement;

  CompilationUnitElement _unitElement;
  ClassElement _classElement;
  ConstructorElement _constructorElement;
  ConstructorDeclarationImpl _constructorNode;
  AstResolver _astResolver;

  ConstructorInitializerResolver(this._linker, this._libraryElement);

  void resolve() {
    for (var unit in _libraryElement.units) {
      _unitElement = unit;
      for (var classElement in unit.types) {
        _classElement = classElement;
        for (var constructorElement in classElement.constructors) {
          _constructor(constructorElement);
        }
      }
    }
  }

  void _constructor(ConstructorElementImpl constructorElement) {
    if (constructorElement.isSynthetic) return;

    _constructorElement = constructorElement;
    _constructorNode = constructorElement.linkedNode;

    var functionScope = LinkingNodeContext.get(_constructorNode).scope;
    var initializerScope = ConstructorInitializerScope(
      functionScope,
      constructorElement,
    );

    _astResolver = AstResolver(_linker, _unitElement, initializerScope);

    FunctionBodyImpl body = _constructorNode.body;
    body.localVariableInfo = LocalVariableInfo();

    _initializers();
    _redirectedConstructor();
  }

  void _initializers() {
    var isConst = _constructorNode.constKeyword != null;
    if (!isConst) {
      return;
    }

    for (var initializer in _constructorNode.initializers) {
      _astResolver.resolve(
        initializer,
        () => initializer,
        enclosingClassElement: _classElement,
        enclosingExecutableElement: _constructorElement,
        enclosingFunctionBody: _constructorNode.body,
      );
    }
  }

  void _redirectedConstructor() {
    var redirected = _constructorNode.redirectedConstructor;
    if (redirected != null) {
      _astResolver.resolve(
        redirected,
        () => redirected,
        enclosingClassElement: _classElement,
        enclosingExecutableElement: _constructorElement,
      );
    }
  }
}
