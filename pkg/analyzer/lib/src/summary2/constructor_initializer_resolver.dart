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

  late CompilationUnitElementImpl _unitElement;
  late ClassElement _classElement;
  late ConstructorElement _constructorElement;
  late ConstructorDeclarationImpl _constructorNode;
  late AstResolver _astResolver;

  ConstructorInitializerResolver(this._linker, this._libraryElement);

  void resolve() {
    for (var unit in _libraryElement.units) {
      _unitElement = unit as CompilationUnitElementImpl;
      for (var classElement in unit.types) {
        _classElement = classElement;
        for (var constructorElement in classElement.constructors) {
          _constructor(constructorElement as ConstructorElementImpl);
        }
      }
    }
  }

  void _constructor(ConstructorElementImpl constructorElement) {
    if (constructorElement.isSynthetic) return;

    _constructorElement = constructorElement;
    _constructorNode =
        constructorElement.linkedNode as ConstructorDeclarationImpl;

    var functionScope = LinkingNodeContext.get(_constructorNode).scope;
    var initializerScope = ConstructorInitializerScope(
      functionScope,
      constructorElement,
    );

    _astResolver = AstResolver(
        _linker, _unitElement, initializerScope, _constructorNode,
        enclosingClassElement: _classElement,
        enclosingExecutableElement: _constructorElement);

    var body = _constructorNode.body;
    body.localVariableInfo = LocalVariableInfo();

    _astResolver.resolveConstructorNode(_constructorNode);
  }
}
