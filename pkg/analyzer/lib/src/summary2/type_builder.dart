// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';

/// Build types in a [TypesToBuild].
class TypeBuilder {
  final LinkingBundleContext bundleContext;

  TypeBuilder(this.bundleContext);

  DynamicTypeImpl get _dynamicType {
    return DynamicTypeImpl.instance;
  }

  void build(TypesToBuild typesToBuild) {
    for (var node in typesToBuild.typeAnnotations) {
      if (node is GenericFunctionType) {
        _buildGenericFunctionType(node);
      } else if (node is TypeName) {
        _buildTypeName(node);
      } else {
        throw StateError('${node.runtimeType}');
      }
//      var kind = node.kind;
//      if (kind == LinkedNodeKind.genericFunctionType) {
//        _buildGenericFunctionType(node);
//      } else if (kind == LinkedNodeKind.typeName) {
//        _buildTypeName(node);
//      } else {
//        throw StateError('$kind');
//      }
    }
    for (var node in typesToBuild.declarations) {
      _setTypesForDeclaration(node);
    }
  }

//  LinkedNodeTypeBuilder _buildFunctionType(
//    LinkedNode returnTypeNode,
//    LinkedNode parameterList,
//  ) {
//    var returnType = _getType(returnTypeNode);
//
//    var formalParameters = <LinkedNodeTypeFormalParameterBuilder>[];
//    for (var parameter in parameterList.formalParameterList_parameters) {
//      formalParameters.add(LinkedNodeTypeFormalParameterBuilder(
//        kind: parameter.formalParameter_kind,
//        type: _getFormalParameterType(parameter),
//      ));
//    }
//
//    return LinkedNodeTypeBuilder(
//      kind: LinkedNodeTypeKind.function,
//      functionFormalParameters: formalParameters,
//      functionReturnType: returnType,
//    );
//  }

  void _buildGenericFunctionType(GenericFunctionTypeImpl node) {
    // TODO(scheglov) Type parameters?
    var typeFormals = <TypeParameterElement>[];
    var parameters = node.parameters.parameters.map((p) {
      // TODO(scheglov) other types and kinds
      return ParameterElementImpl.synthetic(
        (p as SimpleFormalParameter).identifier.name,
        (p as SimpleFormalParameter).type.type,
        ParameterKind.REQUIRED,
      );
    }).toList();
    node.type = FunctionTypeImpl.synthetic(
      node.returnType?.type ?? _dynamicType,
      typeFormals,
      parameters,
    );
  }

  void _buildTypeName(TypeName node) {
    var element = node.name.staticElement;

    List<DartType> typeArguments;
    var typeArgumentList = node.typeArguments;
    if (typeArgumentList != null) {
      typeArguments = typeArgumentList.arguments.map((a) => a.type).toList();
    }

    if (element is ClassElement) {
      if (element.isEnum) {
        node.type = InterfaceTypeImpl.explicit(element, const []);
      } else {
        // TODO(scheglov) Use instantiate to bounds.
        var typeParametersLength = element.typeParameters.length;
        if (typeArguments == null ||
            typeArguments.length != typeParametersLength) {
          typeArguments = List<DartType>.filled(
            typeParametersLength,
            DynamicTypeImpl.instance,
          );
        }
        node.type = InterfaceTypeImpl.explicit(element, typeArguments);
      }
    } else if (element is GenericTypeAliasElement) {
      // TODO(scheglov) Use instantiate to bounds.
      var typeParametersLength = element.typeParameters.length;
      if (typeArguments == null ||
          typeArguments.length != typeParametersLength) {
        typeArguments = List<DartType>.filled(
          typeParametersLength,
          DynamicTypeImpl.instance,
        );
      }

      var substitution = Substitution.fromPairs(
        element.typeParameters,
        typeArguments,
      );

      // TODO(scheglov) Not sure if I like this.
      var type = substitution.substituteType(element.function.type);
      node.type = type;
    } else if (element is TypeParameterElement) {
      node.type = TypeParameterTypeImpl(element);
    } else {
//      throw UnimplementedError('${element.runtimeType}');
      // TODO(scheglov) implement
      node.type = DynamicTypeImpl.instance;
    }

//    var referenceIndex = typeNameElementIndex(node.typeName_name);
//    var reference = bundleContext.referenceOfIndex(referenceIndex);
//
//    List<LinkedNodeTypeBuilder> typeArguments;
//    var typeArgumentList = node.typeName_typeArguments;
//    if (typeArgumentList != null) {
//      typeArguments = typeArgumentList.typeArgumentList_arguments
//          .map((node) => _getType(node))
//          .toList();
//    }
//
//    if (reference.isClass) {
//      // TODO(scheglov) Use instantiate to bounds.
//      var typeParametersLength = _typeParametersLength(reference);
//      if (typeArguments == null ||
//          typeArguments.length != typeParametersLength) {
//        typeArguments = List<LinkedNodeTypeBuilder>.filled(
//          typeParametersLength,
//          _dynamicType,
//        );
//      }
//      node.typeName_type = LinkedNodeTypeBuilder(
//        kind: LinkedNodeTypeKind.interface,
//        interfaceClass: referenceIndex,
//        interfaceTypeArguments: typeArguments,
//      );
//    } else if (reference.isDynamic) {
//      node.typeName_type = LinkedNodeTypeBuilder(
//        kind: LinkedNodeTypeKind.dynamic_,
//      );
//    } else if (reference.isTypeAlias) {
//      // TODO(scheglov) Use instantiate to bounds.
//      var typeParametersLength = _typeParametersLength(reference);
//      if (typeArguments == null ||
//          typeArguments.length != typeParametersLength) {
//        typeArguments = List<LinkedNodeTypeBuilder>.filled(
//          typeParametersLength,
//          _dynamicType,
//        );
//      }
//      node.typeName_type = LinkedNodeTypeBuilder(
//        kind: LinkedNodeTypeKind.genericTypeAlias,
//        genericTypeAliasReference: referenceIndex,
//        genericTypeAliasTypeArguments: typeArguments,
//      );
//    } else if (reference.isEnum) {
//      node.typeName_type = LinkedNodeTypeBuilder(
//        kind: LinkedNodeTypeKind.interface,
//        interfaceClass: referenceIndex,
//      );
//    } else if (reference.isTypeParameter) {
//      node.typeName_type = LinkedNodeTypeBuilder(
//        kind: LinkedNodeTypeKind.typeParameter,
//        typeParameterParameter: referenceIndex,
//      );
//    } else {
//      node.typeName_type = _dynamicType;
//    }
  }

//  void _fieldFormalParameter(LinkedNodeBuilder node) {
//    var parameterList = node.fieldFormalParameter_formalParameters;
//    if (parameterList != null) {
//      node.fieldFormalParameter_type2 = _buildFunctionType(
//        node.fieldFormalParameter_type,
//        parameterList,
//      );
//    } else {
//      var type = _getType(node.fieldFormalParameter_type);
//      node.fieldFormalParameter_type2 = type;
//    }
//  }
//
//  void _functionTypedFormalParameter(LinkedNodeBuilder node) {
//    node.functionTypedFormalParameter_type2 = _buildFunctionType(
//      node.functionTypedFormalParameter_returnType,
//      node.functionTypedFormalParameter_formalParameters,
//    );
//  }

//  LinkedNodeTypeBuilder _getFormalParameterType(LinkedNode node) {
//    var kind = node.kind;
//    if (kind == LinkedNodeKind.defaultFormalParameter) {
//      return _getFormalParameterType(node.defaultFormalParameter_parameter);
//    }
//    if (kind == LinkedNodeKind.functionTypedFormalParameter) {
//      return node.functionTypedFormalParameter_type2;
//    }
//    if (kind == LinkedNodeKind.simpleFormalParameter) {
//      return _getType(node.simpleFormalParameter_type);
//    }
//    throw UnimplementedError('$kind');
//  }

//  LinkedNodeTypeBuilder _getType(LinkedNodeBuilder node) {
//    if (node == null) return _dynamicType;
//
//    var kind = node.kind;
//    if (kind == LinkedNodeKind.genericFunctionType) {
//      return node.genericFunctionType_type;
//    } else if (kind == LinkedNodeKind.typeName) {
//      return node.typeName_type;
//    } else {
//      throw UnimplementedError('$kind');
//    }
//  }

  void _setTypesForDeclaration(AstNode node) {
    if (node is FieldFormalParameter) {
      LazyAst.setType(node, node.type?.type ?? _dynamicType);
    } else if (node is FunctionDeclaration) {
      LazyAst.setReturnType(node, node.returnType?.type ?? _dynamicType);
    } else if (node is FunctionTypeAlias) {
      LazyAst.setReturnType(node, node.returnType?.type ?? _dynamicType);
    } else if (node is GenericFunctionType) {
      LazyAst.setReturnType(node, node.returnType?.type ?? _dynamicType);
    } else if (node is MethodDeclaration) {
      if (node.returnType != null) {
        LazyAst.setReturnType(node, node.returnType.type);
      }
    } else if (node is SimpleFormalParameter) {
      // TODO(scheglov) use top-level inference
      LazyAst.setType(node, node.type?.type ?? _dynamicType);
    } else if (node is VariableDeclarationList) {
      var type = node.type?.type;
      if (type != null) {
        for (var variable in node.variables) {
          LazyAst.setType(variable, type);
        }
      }
    } else {
      throw UnimplementedError('${node.runtimeType}');
    }
//    var kind = node.kind;
//    if (kind == LinkedNodeKind.fieldFormalParameter) {
//      _fieldFormalParameter(node);
//    } else if (kind == LinkedNodeKind.functionDeclaration) {
//      node.functionDeclaration_returnType2 = _getType(
//        node.functionDeclaration_returnType,
//      );
//    } else if (kind == LinkedNodeKind.functionTypeAlias) {
//      node.functionTypeAlias_returnType2 = _getType(
//        node.functionTypeAlias_returnType,
//      );
//    } else if (kind == LinkedNodeKind.functionTypedFormalParameter) {
//      _functionTypedFormalParameter(node);
//    } else if (kind == LinkedNodeKind.genericFunctionType) {
//      node.genericFunctionType_returnType2 = _getType(
//        node.genericFunctionType_returnType,
//      );
//    } else if (kind == LinkedNodeKind.methodDeclaration) {
//      node.methodDeclaration_returnType2 = _getType(
//        node.methodDeclaration_returnType,
//      );
//    } else if (kind == LinkedNodeKind.simpleFormalParameter) {
//      node.simpleFormalParameter_type2 = _getType(
//        node.simpleFormalParameter_type,
//      );
//    } else if (kind == LinkedNodeKind.variableDeclarationList) {
//      var typeNode = node.variableDeclarationList_type;
//      for (var variable in node.variableDeclarationList_variables) {
//        variable.variableDeclaration_type2 = _getType(typeNode);
//      }
//    } else {
//      throw UnimplementedError('$kind');
//    }
  }

//  int _typeParametersLength(Reference reference) {
//    var node = bundleContext.elementFactory.nodeOfReference(reference);
//    return LinkedUnitContext.getTypeParameters(node)?.length ?? 0;
//  }

  static int typeNameElementIndex(LinkedNode name) {
    if (name.kind == LinkedNodeKind.simpleIdentifier) {
      return name.simpleIdentifier_element;
    } else {
      var identifier = name.prefixedIdentifier_identifier;
      return identifier.simpleIdentifier_element;
    }
  }
}
