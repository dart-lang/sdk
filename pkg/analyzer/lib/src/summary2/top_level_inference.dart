// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
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
        var fields = <String, LinkedNodeType>{};
        for (FieldElementImpl field in class_.fields) {
          if (field.isSynthetic) continue;

          var name = field.name;
          var type = field.linkedNode.variableDeclaration_type2;
          if (type == null) {
            throw StateError('Field $name should have a type.');
          }
          fields[name] ??= type;
        }

        for (ConstructorElementImpl constructor in class_.constructors) {
          for (ParameterElementImpl parameter in constructor.parameters) {
            if (parameter is FieldFormalParameterElement) {
              LinkedNodeBuilder parameterNode = parameter.linkedNode;
              if (parameterNode.kind == LinkedNodeKind.defaultFormalParameter) {
                parameterNode = parameterNode.defaultFormalParameter_parameter;
              }

              if (parameterNode.fieldFormalParameter_type2 == null) {
                var name = parameter.name;
                var type = fields[name];
                if (type == null) {
                  type = LinkedNodeTypeBuilder(
                    kind: LinkedNodeTypeKind.dynamic_,
                  );
                }
                parameterNode.fieldFormalParameter_type2 = type;
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
        LinkedNodeBuilder variableNode = variable.linkedNode;
        if (variableNode.variableDeclaration_type2 == null ||
            _linkedContext.isConst(variableNode)) {
          _inferVariableTypeFromInitializerTemporary(variableNode);
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
      var fieldNode = field.linkedNode;

      // TODO(scheglov) Use inheritance
      // TODO(scheglov) infer in the correct order
      if (fieldNode.variableDeclaration_type2 == null) {
        _inferVariableTypeFromInitializerTemporary(fieldNode);
      }
    }

    _nameScope = prevScope;
  }

  void _inferVariableTypeFromInitializerTemporary(LinkedNodeBuilder node) {
    var unresolvedNode = node.variableDeclaration_initializer;

    if (unresolvedNode == null) {
      node.variableDeclaration_type2 = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
      return;
    }

    var expression = _linkedContext.readInitializer(unitElement, node);
    astFactory.expressionFunctionBody(null, null, expression, null);

    var astResolver = AstResolver(linker, _libraryElement, _nameScope);
    var resolvedNode = astResolver.resolve(_linkedContext, expression);
    node.variableDeclaration_initializer = resolvedNode;

    if (node.variableDeclaration_type2 == null) {
      var initializerType = expression.staticType;
      initializerType = _dynamicIfNull(initializerType);

      throw UnimplementedError();
//      var linkingBundleContext = linker.linkingBundleContext;
//      node.variableDeclaration_type2 = linkingBundleContext.writeType(
//        initializerType,
//      );
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
        LinkedNodeBuilder functionNode = function.linkedNode;
        if (functionNode.functionDeclaration_returnType == null) {
          functionNode.functionDeclaration_returnType2 = LinkedNodeTypeBuilder(
            kind: LinkedNodeTypeKind.dynamic_,
          );
        }
      }

      for (PropertyAccessorElementImpl accessor in unit.accessors) {
        if (accessor.isSynthetic) continue;
        if (accessor.isSetter) {
          LinkedNodeBuilder node = accessor.linkedNode;
          if (node.functionDeclaration_returnType == null) {
            node.functionDeclaration_returnType2 = LinkedNodeTypeBuilder(
              kind: LinkedNodeTypeKind.void_,
            );
          }
        }
      }
    }
  }

  void _setOmittedReturnTypesClass(ClassElement class_) {
    for (MethodElementImpl method in class_.methods) {
      LinkedNodeBuilder methodNode = method.linkedNode;
      if (methodNode.methodDeclaration_returnType == null) {
        methodNode.methodDeclaration_returnType2 = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.dynamic_,
        );
      }
    }

    for (PropertyAccessorElementImpl accessor in class_.accessors) {
      if (accessor.isSynthetic) continue;

      LinkedNodeBuilder accessorNode = accessor.linkedNode;
      if (accessorNode.methodDeclaration_returnType != null) continue;

      if (accessor.isSetter) {
        accessorNode.methodDeclaration_returnType2 = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.void_,
        );
      } else {
        accessorNode.methodDeclaration_returnType2 = LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.dynamic_,
        );
      }
    }
  }
}
