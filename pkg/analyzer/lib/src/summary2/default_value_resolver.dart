// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class DefaultValueResolver {
  final Linker _linker;
  final LibraryElementImpl _libraryElement;

  ClassElement _classElement;
  ExecutableElement _executableElement;
  Scope _scope;

  AstResolver _astResolver;

  DefaultValueResolver(this._linker, this._libraryElement);

  void resolve() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      for (var classElement in unit.types) {
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

      for (var element in unit.functions) {
        _function(element);
      }
    }
  }

  void _constructor(ConstructorElementImpl element) {
    if (element.isSynthetic) return;

    _astResolver = null;
    _executableElement = element;
    _setScopeFromElement(element);

    _parameters(element.parameters);
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
    Expression defaultValue;
    var node = parameter.linkedNode;
    if (node is DefaultFormalParameter) {
      defaultValue = node.defaultValue;
    }
    if (defaultValue == null) return;

    var contextType = TypeVariableEliminator(_linker.typeProvider)
        .substituteType(parameter.type);
    InferenceContext.setType(defaultValue, contextType);

    _astResolver ??= AstResolver(_linker, _libraryElement, _scope);
    _astResolver.resolve(
      defaultValue,
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
}

class TypeVariableEliminator extends Substitution {
  final TypeProvider _typeProvider;

  TypeVariableEliminator(this._typeProvider);

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return upperBound ? _typeProvider.nullType : _typeProvider.objectType;
  }
}
