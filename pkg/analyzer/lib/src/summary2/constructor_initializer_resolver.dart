// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class ConstructorInitializerResolver {
  Linker _linker;
  LibraryElementImpl _libraryElement;

  Scope _libraryScope;
  Scope _classScope;

  LinkedUnitContext _linkedContext;

  ConstructorElement _constructorElement;
  LinkedNodeBuilder _constructorNode;
  AstResolver _astResolver;

  ConstructorInitializerResolver(this._linker, Reference libraryRef) {
    _libraryElement = _linker.elementFactory.elementOfReference(libraryRef);
    _libraryScope = LibraryScope(_libraryElement);
  }

  void resolve() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      _linkedContext = unit.linkedContext;
      for (var classElement in unit.types) {
        _classScope = ClassScope(_libraryScope, classElement);
        for (var constructorElement in classElement.constructors) {
          _constructor(constructorElement);
        }
      }
    }
  }

  void _constructor(ConstructorElementImpl constructorElement) {
    if (constructorElement.isSynthetic) return;

//    _constructorElement = constructorElement;
//    _constructorNode = constructorElement.linkedNode;
//
//    var functionScope = FunctionScope(_classScope, constructorElement);
//    functionScope.defineParameters();
//
//    var nameScope = ConstructorInitializerScope(
//      functionScope,
//      constructorElement,
//    );
//
//    _astResolver = AstResolver(_linker, _libraryElement, nameScope);
//
//    _initializers();
//    _redirectedConstructor();
  }

  void _initializers() {
    throw UnimplementedError();

//    bool isConst = _constructorNode.constructorDeclaration_constKeyword != 0;
//
//    var initializers = _constructorNode.constructorDeclaration_initializers;
//    var resolvedList = List<LinkedNodeBuilder>();
//    for (var i = 0; i < initializers.length; ++i) {
//      var unresolvedNode = initializers[i];
//
//      // Keep only initializers of constant constructors; or redirects.
//      if (!isConst &&
//          unresolvedNode.kind !=
//              LinkedNodeKind.redirectingConstructorInvocation) {
//        continue;
//      }
//
//      var reader = AstBinaryReader(_linkedContext);
//      var unresolvedAst = reader.readNode(unresolvedNode);
//
//      var resolvedNode = _astResolver.resolve(
//        _linkedContext,
//        unresolvedAst,
//        enclosingClassElement: _constructorElement.enclosingElement,
//        enclosingExecutableElement: _constructorElement,
//      );
//      resolvedList.add(resolvedNode);
//    }
//    _constructorNode.constructorDeclaration_initializers = resolvedList;
  }

  void _redirectedConstructor() {
    throw UnimplementedError();

//    var redirectedConstructorNode =
//        _constructorNode.constructorDeclaration_redirectedConstructor;
//    if (redirectedConstructorNode == null) return;
//
//    var reader = AstBinaryReader(_linkedContext);
//    var unresolvedAst = reader.readNode(redirectedConstructorNode);
//    var resolvedNode = _astResolver.resolve(
//      _linkedContext,
//      unresolvedAst,
//      enclosingClassElement: _constructorElement.enclosingElement,
//      enclosingExecutableElement: _constructorElement,
//    );
//    _constructorNode.constructorDeclaration_redirectedConstructor =
//        resolvedNode;
  }
}
