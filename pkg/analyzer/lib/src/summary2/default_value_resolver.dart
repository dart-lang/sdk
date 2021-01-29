// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/resolver.dart' show InferenceContext;
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryElementImpl _libraryElement;
  final TypeSystemImpl _typeSystem;

  ClassElement _classElement;
  CompilationUnitElement _unitElement;
  ExecutableElement _executableElement;
  Scope _scope;

  AstResolver _astResolver;

  DefaultValueResolver(this._linker, this._libraryElement)
      : _typeSystem = _libraryElement.typeSystem;

  void resolve() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      _unitElement = unit;

      for (var extensionElement in unit.extensions) {
        _extension(extensionElement);
      }

      for (var classElement in unit.mixins) {
        _class(classElement);
      }

      for (var classElement in unit.types) {
        _class(classElement);
      }

      for (var element in unit.functions) {
        _function(element);
      }
    }
  }

  void _class(ClassElement classElement) {
    _classElement = classElement;

    for (var element in classElement.constructors) {
      _constructor(element);
    }

    for (var element in classElement.methods) {
      _setScopeFromElement(element);
      _method(element);
    }

    _classElement = null;
  }

  void _constructor(ConstructorElementImpl element) {
    if (element.isSynthetic) return;

    _astResolver = null;
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  void _extension(ExtensionElement extensionElement) {
    for (var element in extensionElement.methods) {
      _setScopeFromElement(element);
      _method(element);
    }
  }

  void _function(FunctionElementImpl element) {
    _astResolver = null;
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  void _method(MethodElementImpl element) {
    _astResolver = null;
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
  }

  void _parameter(ParameterElementImpl parameter) {
    // If a function typed parameter, process nested parameters.
    for (var localParameter in parameter.parameters) {
      _parameter(localParameter);
    }

    var node = _defaultParameter(parameter);
    if (node == null) return;

    var contextType = _typeSystem.eliminateTypeVariables(parameter.type);

    _astResolver ??= AstResolver(_linker, _unitElement, _scope);
    _astResolver.resolve(
      node.defaultValue,
      () {
        var defaultValue = node.defaultValue;
        InferenceContext.setType(defaultValue, contextType);
        return defaultValue;
      },
      enclosingClassElement: _classElement,
      enclosingExecutableElement: _executableElement,
    );
  }

  void _parameters(List<ParameterElement> parameters) {
    for (var parameter in parameters) {
      _parameter(parameter);
    }
  }

  void _setScopeFromElement(Element element) {
    _scope = LinkingNodeContext.get((element as ElementImpl).linkedNode).scope;
  }

  static DefaultFormalParameter _defaultParameter(
      ParameterElementImpl element) {
    var node = element.linkedNode;
    if (node is DefaultFormalParameter && node.defaultValue != null) {
      return node;
    } else {
      return null;
    }
  }
}
