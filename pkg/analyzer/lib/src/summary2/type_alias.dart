// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/link.dart';

class TypeAliasSelfReferenceFinder {
  NullabilitySuffix _unitNullability;

  /// Check typedefs and mark the ones having self references.
  void perform(Linker linker) {
    for (var builder in linker.builders.values) {
      for (var unitContext in builder.context.units) {
        _unitNullability =
            unitContext.unit.featureSet.isEnabled(Feature.non_nullable)
                ? NullabilitySuffix.none
                : NullabilitySuffix.star;
        for (var node in unitContext.unit.declarations) {
          if (node is FunctionTypeAlias) {
            var finder = _Finder(node);
            finder.functionTypeAlias(node);
            LazyFunctionTypeAlias.setHasSelfReference(
              node,
              finder.hasSelfReference,
            );
          } else if (node is GenericTypeAlias) {
            var finder = _Finder(node);
            finder.genericTypeAlias(node);
            LazyGenericTypeAlias.setHasSelfReference(
              node,
              finder.hasSelfReference,
            );
            if (finder.hasSelfReference) {
              _sanitizeGenericTypeAlias(node);
            }
          }
        }
      }
    }
  }

  void _sanitizeGenericTypeAlias(GenericTypeAlias node) {
    var typeParameterList = node.typeParameters;
    if (typeParameterList != null) {
      for (var typeParameter in typeParameterList.typeParameters) {
        typeParameter.bound = null;
      }
    }
    node.functionType.returnType = null;
    node.functionType.parameters.parameters.clear();
    (node.functionType as GenericFunctionTypeImpl).type = FunctionTypeImpl(
      typeFormals: const [],
      parameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: _unitNullability,
    );
  }
}

class _Finder {
  final AstNode self;
  final Set<AstNode> visited = Set.identity();
  bool hasSelfReference = false;

  _Finder(this.self);

  void functionTypeAlias(FunctionTypeAlias node) {
    _typeParameterList(node.typeParameters);
    _formalParameterList(node.parameters);
    _visit(node.returnType);
  }

  void genericTypeAlias(GenericTypeAlias node) {
    var functionType = node.functionType;
    if (functionType != null) {
      _typeParameterList(functionType.typeParameters);
      _formalParameterList(functionType.parameters);
      _visit(functionType.returnType);
    }
  }

  void _argumentList(TypeArgumentList node) {
    if (node != null) {
      for (var argument in node.arguments) {
        _visit(argument);
      }
    }
  }

  void _formalParameter(FormalParameter node) {
    if (node is DefaultFormalParameter) {
      _formalParameter(node.parameter);
    } else if (node is FunctionTypedFormalParameter) {
      _visit(node.returnType);
      _formalParameterList(node.parameters);
    } else if (node is SimpleFormalParameter) {
      _visit(node.type);
    }
  }

  void _formalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      _formalParameter(parameter);
    }
  }

  void _typeParameterList(TypeParameterList node) {
    if (node != null) {
      for (var parameter in node.typeParameters) {
        _visit(parameter.bound);
      }
    }
  }

  void _visit(TypeAnnotation node) {
    if (hasSelfReference) return;
    if (node == null) return;

    if (node is TypeName) {
      var element = node.name.staticElement;
      if (element is ElementImpl &&
          element.enclosingElement != null &&
          element.linkedContext.isLinking) {
        var typeNode = element.linkedNode;
        if (typeNode == self) {
          hasSelfReference = true;
          return;
        }
        if (typeNode is ClassDeclaration) {
          if (visited.add(typeNode)) {
            _typeParameterList(typeNode.typeParameters);
          }
        } else if (typeNode is ClassTypeAlias) {
          if (visited.add(typeNode)) {
            _typeParameterList(typeNode.typeParameters);
          }
        } else if (typeNode is FunctionTypeAlias) {
          if (visited.add(typeNode)) {
            functionTypeAlias(typeNode);
          }
        } else if (typeNode is GenericTypeAlias) {
          if (visited.add(typeNode)) {
            genericTypeAlias(typeNode);
          }
        } else if (typeNode is MixinDeclaration) {
          if (visited.add(typeNode)) {
            _typeParameterList(typeNode.typeParameters);
          }
        }
      }
      _argumentList(node.typeArguments);
    } else if (node is GenericFunctionType) {
      _typeParameterList(node.typeParameters);
      _formalParameterList(node.parameters);
      _visit(node.returnType);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }
}
