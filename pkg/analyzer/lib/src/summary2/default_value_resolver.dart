// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryBuilder _libraryBuilder;
  final TypeSystemImpl _typeSystem;

  new(this._linker, this._libraryBuilder)
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
        var enclosingInterfaceElement = instanceElement
            .tryCast<InterfaceElementImpl>();
        var executableElementListList = <List<ExecutableElementImpl>>[
          instanceElement.getters,
          instanceElement.setters,
          instanceElement.methods,
          ?enclosingInterfaceElement?.constructors,
        ];
        for (var executableElementList in executableElementListList) {
          for (var executableElement in executableElementList) {
            _executableElement(
              executableElement,
              enclosingInterfaceElement: enclosingInterfaceElement,
            );
          }
        }
      }
    }

    var executableElementListList = <List<ExecutableElementImpl>>[
      libraryElement.getters,
      libraryElement.setters,
      libraryElement.topLevelFunctions,
    ];
    for (var executableElementList in executableElementListList) {
      for (var executableElement in executableElementList) {
        _executableElement(executableElement, enclosingInterfaceElement: null);
      }
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

  /// Resolves default values in all fragments of [element].
  ///
  /// The default value of every formal parameter fragment is written into
  /// the bundle, including fragments of augmentations and recovered formal
  /// parameters of getters and setters, so each of them must be resolved.
  void _executableElement(
    ExecutableElementImpl element, {
    required InterfaceElementImpl? enclosingInterfaceElement,
  }) {
    for (var fragment in element.fragments) {
      for (var formalParameter in fragment.formalParameters) {
        _formalParameterFragment(
          formalParameter,
          enclosingInterfaceElement: enclosingInterfaceElement,
          enclosingExecutableElement: element,
        );
      }
    }
  }

  void _formalParameterFragment(
    FormalParameterFragmentImpl fragment, {
    required InterfaceElementImpl? enclosingInterfaceElement,
    required ExecutableElementImpl enclosingExecutableElement,
  }) {
    var node = _defaultParameterNode(fragment);
    if (node == null) {
      return;
    }

    var formalParameter = fragment.element;
    var contextType = _typeSystem.eliminateTypeVariables(formalParameter.type);

    var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
    var astResolver = AstResolver.forLinking(
      inheritance: _linker.inheritance,
      libraryFragment: fragment.libraryFragment!,
      nameScope: node.scope!,
      analysisOptions: analysisOptions,
      enclosingClassElement: enclosingInterfaceElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );
    fragment.constantInitializer2 = astResolver.resolveDefaultValue(
      node.defaultClause!,
      contextType: contextType,
    );
    formalParameter.resetConstantInitializer();
  }
}
