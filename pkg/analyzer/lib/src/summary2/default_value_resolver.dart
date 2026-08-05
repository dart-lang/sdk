// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryBuilder _libraryBuilder;
  final TypeSystemImpl _typeSystem;

  DefaultValueResolver(this._linker, this._libraryBuilder)
    : _typeSystem = _libraryBuilder.element.typeSystem;

  void resolve() {
    var libraryElement = _libraryBuilder.element;
    var instanceElementListList = [
      libraryElement.classes,
      libraryElement.enums,
      libraryElement.extensions,
      libraryElement.extensionTypes,
      libraryElement.mixins,
    ];
    for (var instanceElementList in instanceElementListList) {
      for (var instanceElement in instanceElementList) {
        for (var method in instanceElement.methods) {
          _executableElement(
            method,
            enclosingInterfaceElement: instanceElement.tryCast(),
          );
        }
        if (instanceElement case InterfaceElementImpl interfaceElement) {
          for (var constructor in interfaceElement.constructors) {
            _executableElement(
              constructor,
              enclosingInterfaceElement: interfaceElement,
            );
          }
        }
      }
    }

    for (var topLevelFunction in libraryElement.topLevelFunctions) {
      _executableElement(topLevelFunction, enclosingInterfaceElement: null);
    }
  }

  FormalParameterImpl? _defaultParameterNode(
    FormalParameterFragmentImpl fragment,
  ) {
    if (_linker.getLinkingNode(fragment) case FormalParameterImpl node) {
      if (node.defaultClause != null) {
        return node;
      }
    }
    return null;
  }

  void _executableElement(
    ExecutableElementImpl element, {
    required InterfaceElementImpl? enclosingInterfaceElement,
  }) {
    for (var formalParameter in element.formalParameters) {
      _formalParameterElement(
        formalParameter,
        enclosingInterfaceElement: enclosingInterfaceElement,
        enclosingExecutableElement: element,
      );
    }
  }

  void _formalParameterElement(
    FormalParameterElementImpl formalParameter, {
    required InterfaceElementImpl? enclosingInterfaceElement,
    required ExecutableElementImpl enclosingExecutableElement,
  }) {
    var firstFragment = formalParameter.firstFragment;
    var firstNode = _defaultParameterNode(firstFragment);
    if (firstNode == null) {
      return;
    }

    var contextType = _typeSystem.eliminateTypeVariables(formalParameter.type);

    var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
    var astResolver = AstResolver(
      _linker,
      firstFragment.libraryFragment as LibraryFragmentImpl,
      firstNode.scope!,
      analysisOptions,
      enclosingClassElement: enclosingInterfaceElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );
    astResolver.resolveExpression(
      () => firstNode.defaultClause!.value,
      contextType: contextType,
    );
    firstFragment.constantInitializer = firstNode.defaultClause!.value;
  }
}
