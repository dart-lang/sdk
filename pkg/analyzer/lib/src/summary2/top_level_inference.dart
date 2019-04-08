// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

DartType _dynamicIfNull(DartType type) {
  if (type == null || type.isBottom || type.isDartCoreNull) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

/// TODO(scheglov) This is not a valid implementation of top-level inference.
/// See https://bit.ly/2HYfAKg
///
/// In general inference of constructor field formal parameters should be
/// interleaved with inference of fields. There are resynthesis tests that
/// fail because of this limitation.
class TopLevelInference {
  final Linker linker;
  LibraryElementImpl _libraryElement;

  Scope _libraryScope;
  Scope _nameScope;

  LinkedUnitContext _linkedContext;
  CompilationUnitElementImpl unitElement;

  TopLevelInference(this.linker, Reference libraryRef) {
    _libraryElement = linker.elementFactory.elementOfReference(libraryRef);
    _libraryScope = LibraryScope(_libraryElement);
    _nameScope = _libraryScope;
  }

  DynamicTypeImpl get _dynamicType {
    return DynamicTypeImpl.instance;
  }

  VoidTypeImpl get _voidType => VoidTypeImpl.instance;

  void infer() {
    _setOmittedReturnTypes();
    _inferFieldsTemporary();
    _inferConstructorFieldFormals();
  }

  void _inferConstructorFieldFormals() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      this.unitElement = unit;
      _linkedContext = unit.linkedContext;

      for (var class_ in unit.types) {
        var fields = <String, DartType>{};
        for (FieldElementImpl field in class_.fields) {
          if (field.isSynthetic) continue;

          var name = field.name;
          var type = field.type;
          if (type == null) {
            throw StateError('Field $name should have a type.');
          }
          fields[name] ??= type;
        }

        for (ConstructorElementImpl constructor in class_.constructors) {
          for (ParameterElementImpl parameter in constructor.parameters) {
            if (parameter is FieldFormalParameterElement) {
              FormalParameter node = parameter.linkedNode;
              if (node is DefaultFormalParameter) {
                var defaultParameter = node as DefaultFormalParameter;
                node = defaultParameter.parameter;
              }

              if (node is FieldFormalParameter &&
                  node.type == null &&
                  node.parameters == null) {
                var name = parameter.name;
                var type = fields[name] ?? _dynamicType;
                LazyAst.setType(node, type);
              }
            }
          }
        }
      }
    }
  }

  void _inferFieldsTemporary() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      this.unitElement = unit;
      _linkedContext = unit.linkedContext;

      for (var class_ in unit.types) {
        _inferFieldsTemporaryClass(class_);
      }

      for (var mixin_ in unit.mixins) {
        _inferFieldsTemporaryClass(mixin_);
      }

      for (TopLevelVariableElementImpl variable in unit.topLevelVariables) {
        if (variable.isSynthetic) continue;
        VariableDeclaration node = variable.linkedNode;
        VariableDeclarationList parent = node.parent;
        if (parent.type == null || _linkedContext.isConst(node)) {
          _inferVariableTypeFromInitializerTemporary(node);
        }
      }
    }
  }

  void _inferFieldsTemporaryClass(ClassElement class_) {
    var prevScope = _nameScope;

    _nameScope = TypeParameterScope(_nameScope, class_);
    _nameScope = ClassScope(_nameScope, class_);

    for (FieldElementImpl field in class_.fields) {
      if (field.isSynthetic) continue;
      VariableDeclaration node = field.linkedNode;
      VariableDeclarationList parent = node.parent;
      // TODO(scheglov) Use inheritance
      // TODO(scheglov) infer in the correct order
      if (parent.type == null || parent.isConst) {
        _inferVariableTypeFromInitializerTemporary(node);
      }
    }

    _nameScope = prevScope;
  }

  void _inferVariableTypeFromInitializerTemporary(VariableDeclaration node) {
    var initializer = node.initializer;

    if (initializer == null) {
      LazyAst.setType(node, _dynamicType);
      return;
    }

    var astResolver = AstResolver(linker, _libraryElement, _nameScope);
    astResolver.resolve(initializer);

    VariableDeclarationList parent = node.parent;
    if (parent.type == null) {
      var initializerType = initializer.staticType;
      initializerType = _dynamicIfNull(initializerType);
      LazyAst.setType(node, initializerType);
    }
  }

  void _setOmittedReturnTypes() {
    for (CompilationUnitElementImpl unit in _libraryElement.units) {
      this.unitElement = unit;
      _linkedContext = unit.linkedContext;

      for (var class_ in unit.types) {
        _setOmittedReturnTypesClass(class_);
      }

      for (var mixin_ in unit.mixins) {
        _setOmittedReturnTypesClass(mixin_);
      }

      for (FunctionElementImpl function in unit.functions) {
        FunctionDeclaration node = function.linkedNode;
        if (node.returnType == null) {
          LazyAst.setReturnType(node, _dynamicType);
        }
      }

      for (PropertyAccessorElementImpl accessor in unit.accessors) {
        if (accessor.isSynthetic) continue;
        if (accessor.isSetter) {
          LazyAst.setReturnType(accessor.linkedNode, _voidType);
        }
      }
    }
  }

  void _setOmittedReturnTypesClass(ClassElement class_) {
    for (MethodElementImpl method in class_.methods) {
      MethodDeclaration node = method.linkedNode;
      if (node.returnType == null) {
        LazyAst.setReturnType(node, _dynamicType);
      }
    }

    for (PropertyAccessorElementImpl accessor in class_.accessors) {
      if (accessor.isSynthetic) continue;

      MethodDeclaration node = accessor.linkedNode;
      if (node.returnType != null) continue;

      if (accessor.isSetter) {
        LazyAst.setReturnType(node, _voidType);
      } else {
        LazyAst.setReturnType(node, _dynamicType);
      }
    }
  }
}
