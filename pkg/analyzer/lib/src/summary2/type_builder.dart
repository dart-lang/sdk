// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';

/// Build types in a [TypesToBuild].
class TypeBuilder {
  final LinkedBundleContext bundleContext;

  TypeBuilder(this.bundleContext);

  LinkedNodeTypeBuilder get _dynamicType {
    return LinkedNodeTypeBuilder(
      kind: LinkedNodeTypeKind.dynamic_,
    );
  }

  void build(TypesToBuild typesToBuild) {
    for (var node in typesToBuild.typeAnnotations) {
      var kind = node.kind;
      if (kind == LinkedNodeKind.genericFunctionType) {
        _buildGenericFunctionType(node);
      } else if (kind == LinkedNodeKind.typeName) {
        _buildTypeName(node);
      } else {
        throw StateError('$kind');
      }
    }
    for (var node in typesToBuild.declarations) {
      _setTypesForDeclaration(node);
    }
  }

  LinkedNodeTypeBuilder _buildFunctionType(
    LinkedNode returnTypeNode,
    LinkedNode parameterList,
  ) {
    var returnType = _getType(returnTypeNode);

    var formalParameters = <LinkedNodeTypeFormalParameterBuilder>[];
    for (var parameter in parameterList.formalParameterList_parameters) {
      formalParameters.add(LinkedNodeTypeFormalParameterBuilder(
        kind: parameter.formalParameter_kind,
        type: _getFormalParameterType(parameter),
      ));
    }

    return LinkedNodeTypeBuilder(
      kind: LinkedNodeTypeKind.function,
      functionFormalParameters: formalParameters,
      functionReturnType: returnType,
    );
  }

  void _buildGenericFunctionType(LinkedNodeBuilder node) {
    // TODO(scheglov) Type parameters?
    node.genericFunctionType_type = _buildFunctionType(
      node.genericFunctionType_returnType,
      node.genericFunctionType_formalParameters,
    );
  }

  void _buildTypeName(LinkedNodeBuilder node) {
    var referenceIndex = typeNameElementIndex(node.typeName_name);
    var reference = bundleContext.referenceOfIndex(referenceIndex);

    List<LinkedNodeTypeBuilder> typeArguments;
    var typeArgumentList = node.typeName_typeArguments;
    if (typeArgumentList != null) {
      typeArguments = typeArgumentList.typeArgumentList_arguments
          .map((node) => _getType(node))
          .toList();
    }

    if (reference.isClass) {
      // TODO(scheglov) Use instantiate to bounds.
      var typeParametersLength = _typeParametersLength(reference);
      if (typeArguments == null ||
          typeArguments.length != typeParametersLength) {
        typeArguments = List<LinkedNodeTypeBuilder>.filled(
          typeParametersLength,
          _dynamicType,
        );
      }
      node.typeName_type = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: referenceIndex,
        interfaceTypeArguments: typeArguments,
      );
    } else if (reference.isDynamic) {
      node.typeName_type = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
    } else if (reference.isTypeAlias) {
      // TODO(scheglov) Use instantiate to bounds.
      var typeParametersLength = _typeParametersLength(reference);
      if (typeArguments == null ||
          typeArguments.length != typeParametersLength) {
        typeArguments = List<LinkedNodeTypeBuilder>.filled(
          typeParametersLength,
          _dynamicType,
        );
      }
      node.typeName_type = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.genericTypeAlias,
        genericTypeAliasReference: referenceIndex,
        genericTypeAliasTypeArguments: typeArguments,
      );
    } else if (reference.isEnum) {
      node.typeName_type = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: referenceIndex,
      );
    } else if (reference.isTypeParameter) {
      node.typeName_type = LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.typeParameter,
        typeParameterParameter: referenceIndex,
      );
    } else {
      node.typeName_type = _dynamicType;
    }
  }

  void _fieldFormalParameter(LinkedNodeBuilder node) {
    var parameterList = node.fieldFormalParameter_formalParameters;
    if (parameterList != null) {
      node.fieldFormalParameter_type2 = _buildFunctionType(
        node.fieldFormalParameter_type,
        parameterList,
      );
    } else {
      var type = _getType(node.fieldFormalParameter_type);
      node.fieldFormalParameter_type2 = type;
    }
  }

  void _functionTypedFormalParameter(LinkedNodeBuilder node) {
    node.functionTypedFormalParameter_type2 = _buildFunctionType(
      node.functionTypedFormalParameter_returnType,
      node.functionTypedFormalParameter_formalParameters,
    );
  }

  LinkedNodeTypeBuilder _getFormalParameterType(LinkedNode node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.defaultFormalParameter) {
      return _getFormalParameterType(node.defaultFormalParameter_parameter);
    }
    if (kind == LinkedNodeKind.functionTypedFormalParameter) {
      return node.functionTypedFormalParameter_type2;
    }
    if (kind == LinkedNodeKind.simpleFormalParameter) {
      return _getType(node.simpleFormalParameter_type);
    }
    throw UnimplementedError('$kind');
  }

  LinkedNodeTypeBuilder _getType(LinkedNodeBuilder node) {
    if (node == null) return _dynamicType;

    var kind = node.kind;
    if (kind == LinkedNodeKind.genericFunctionType) {
      return node.genericFunctionType_type;
    } else if (kind == LinkedNodeKind.typeName) {
      return node.typeName_type;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  void _setTypesForDeclaration(LinkedNodeBuilder node) {
    var kind = node.kind;
    if (kind == LinkedNodeKind.fieldFormalParameter) {
      _fieldFormalParameter(node);
    } else if (kind == LinkedNodeKind.functionDeclaration) {
      node.functionDeclaration_returnType2 = _getType(
        node.functionDeclaration_returnType,
      );
    } else if (kind == LinkedNodeKind.functionTypeAlias) {
      node.functionTypeAlias_returnType2 = _getType(
        node.functionTypeAlias_returnType,
      );
    } else if (kind == LinkedNodeKind.functionTypedFormalParameter) {
      _functionTypedFormalParameter(node);
    } else if (kind == LinkedNodeKind.genericFunctionType) {
      node.genericFunctionType_returnType2 = _getType(
        node.genericFunctionType_returnType,
      );
    } else if (kind == LinkedNodeKind.methodDeclaration) {
      node.methodDeclaration_returnType2 = _getType(
        node.methodDeclaration_returnType,
      );
    } else if (kind == LinkedNodeKind.simpleFormalParameter) {
      node.simpleFormalParameter_type2 = _getType(
        node.simpleFormalParameter_type,
      );
    } else if (kind == LinkedNodeKind.variableDeclarationList) {
      var typeNode = node.variableDeclarationList_type;
      for (var variable in node.variableDeclarationList_variables) {
        variable.variableDeclaration_type2 = _getType(typeNode);
      }
    } else {
      throw UnimplementedError('$kind');
    }
  }

  int _typeParametersLength(Reference reference) {
    var node = bundleContext.elementFactory.nodeOfReference(reference);
    return LinkedUnitContext.getTypeParameters(node)?.length ?? 0;
  }

  static int typeNameElementIndex(LinkedNode name) {
    if (name.kind == LinkedNodeKind.simpleIdentifier) {
      return name.simpleIdentifier_element;
    } else {
      var identifier = name.prefixedIdentifier_identifier;
      return identifier.simpleIdentifier_element;
    }
  }
}
