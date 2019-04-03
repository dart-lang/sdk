// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class DefaultValueResolver {
  Linker _linker;
  LibraryElementImpl _libraryElement;
  LinkedUnitContext _linkedContext;

  ClassElement _enclosingClassElement;
  ExecutableElement _enclosingExecutableElement;

  Scope _libraryScope;
  Scope _classScope;

  AstResolver _astResolver;

  DefaultValueResolver(this._linker, Reference libraryRef) {
    _libraryElement = _linker.elementFactory.elementOfReference(libraryRef);
    _libraryScope = LibraryScope(_libraryElement);
  }

  void resolve() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      _linkedContext = unit.linkedContext;

      for (var classElement in unit.types) {
        _enclosingClassElement = classElement;
        _classScope = TypeParameterScope(_libraryScope, classElement);

        for (var element in classElement.constructors) {
          _constructor(element);
        }

        for (var element in classElement.methods) {
          _method(element);
        }

        _enclosingClassElement = null;
        _classScope = null;
      }

      for (var element in unit.functions) {
        _function(element);
      }
    }
  }

  void _constructor(ConstructorElementImpl element) {
    if (element.isSynthetic) return;

    _astResolver = null;
    _enclosingExecutableElement = element;

    _parameters(element.parameters);
  }

  void _function(FunctionElementImpl element) {
    _astResolver = null;
    _enclosingExecutableElement = element;

    _parameters(element.parameters);
  }

  void _method(MethodElementImpl element) {
    _astResolver = null;
    _enclosingExecutableElement = element;

    _parameters(element.parameters);
  }

  void _parameter(ParameterElementImpl parameter) {
    if (parameter.isNotOptional) return;

    LinkedNodeBuilder node = parameter.linkedNode;
    var unresolvedNode = node.defaultFormalParameter_defaultValue;
    if (unresolvedNode == null) return;

    var reader = AstBinaryReader(_linkedContext);
    var unresolvedAst = reader.readNode(unresolvedNode);

    if (_astResolver == null) {
      var scope = FunctionScope(
        _classScope ?? _libraryScope,
        _enclosingExecutableElement,
      );
      _astResolver = AstResolver(_linker, _libraryElement, scope);
    }

    var contextType = TypeVariableEliminator(_linker.typeProvider)
        .substituteType(parameter.type);
    InferenceContext.setType(unresolvedAst, contextType);

    var resolvedNode = _astResolver.resolve(
      _linkedContext,
      unresolvedAst,
      enclosingClassElement: _enclosingClassElement,
      enclosingExecutableElement: _enclosingExecutableElement,
    );
    node.defaultFormalParameter_defaultValue = resolvedNode;
  }

  void _parameters(List<ParameterElement> parameters) {
    for (var parameter in parameters) {
      _parameter(parameter);
    }
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
