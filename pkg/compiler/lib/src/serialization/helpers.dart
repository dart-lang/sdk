// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Enum used for identifying [ir.TreeNode] subclasses in serialization.
enum _TreeNodeKind {
  cls,
  member,
  node,
  functionNode,
  typeParameter,
  functionDeclarationVariable,
  constant,
}

/// Enum used for identifying [ir.FunctionNode] context in serialization.
enum _FunctionNodeKind {
  procedure,
  constructor,
  functionExpression,
  functionDeclaration,
}

/// Enum used for identifying [ir.TypeParameter] context in serialization.
enum _TypeParameterKind {
  cls,
  functionNode,
}

class DartTypeNodeWriter
    extends ir.DartTypeVisitor1<void, List<ir.TypeParameter>> {
  final DataSinkWriter _sink;

  DartTypeNodeWriter(this._sink);

  void visitTypes(
      List<ir.DartType> types, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeInt(types.length);
    for (ir.DartType type in types) {
      _sink._writeDartTypeNode(type, functionTypeVariables);
    }
  }

  @override
  void defaultDartType(
      ir.DartType node, List<ir.TypeParameter> functionTypeVariables) {
    throw UnsupportedError(
        "Unexpected ir.DartType $node (${node.runtimeType}).");
  }

  @override
  void visitInvalidType(
      ir.InvalidType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.invalidType);
  }

  @override
  void visitDynamicType(
      ir.DynamicType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.dynamicType);
  }

  @override
  void visitVoidType(
      ir.VoidType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.voidType);
  }

  @override
  void visitNeverType(
      ir.NeverType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.neverType);
    _sink.writeEnum(node.nullability);
  }

  @override
  void visitNullType(
      ir.NullType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.nullType);
  }

  @override
  void visitInterfaceType(
      ir.InterfaceType node, List<ir.TypeParameter> functionTypeVariables) {
    if (node is ThisInterfaceType) {
      _sink.writeEnum(DartTypeNodeKind.thisInterfaceType);
    } else if (node is ExactInterfaceType) {
      _sink.writeEnum(DartTypeNodeKind.exactInterfaceType);
    } else {
      _sink.writeEnum(DartTypeNodeKind.interfaceType);
    }
    _sink.writeClassNode(node.classNode);
    _sink.writeEnum(node.nullability);
    visitTypes(node.typeArguments, functionTypeVariables);
  }

  @override
  void visitRecordType(
      ir.RecordType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.recordType);
    _sink.writeEnum(node.declaredNullability);
    visitTypes(node.positional, functionTypeVariables);
    _visitNamedTypes(node.named, functionTypeVariables);
  }

  @override
  void visitFutureOrType(
      ir.FutureOrType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.futureOrType);
    _sink.writeEnum(node.declaredNullability);
    _sink._writeDartTypeNode(node.typeArgument, functionTypeVariables);
  }

  @override
  void visitFunctionType(
      ir.FunctionType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.functionType);
    _sink.begin(functionTypeNodeTag);
    functionTypeVariables = List<ir.TypeParameter>.from(functionTypeVariables)
      ..addAll(node.typeParameters);
    _sink.writeInt(node.typeParameters.length);
    for (ir.TypeParameter parameter in node.typeParameters) {
      _sink.writeString(parameter.name!);
      _sink._writeDartTypeNode(parameter.bound, functionTypeVariables);
      _sink._writeDartTypeNode(parameter.defaultType, functionTypeVariables);
    }
    _sink._writeDartTypeNode(node.returnType, functionTypeVariables);
    _sink.writeEnum(node.nullability);
    _sink.writeInt(node.requiredParameterCount);
    visitTypes(node.positionalParameters, functionTypeVariables);
    _visitNamedTypes(node.namedParameters, functionTypeVariables);
    _sink.end(functionTypeNodeTag);
  }

  void _visitNamedTypes(
      List<ir.NamedType> named, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeInt(named.length);
    for (ir.NamedType parameter in named) {
      _sink.writeString(parameter.name);
      _sink.writeBool(parameter.isRequired);
      _sink._writeDartTypeNode(parameter.type, functionTypeVariables);
    }
  }

  @override
  void visitTypeParameterType(
      ir.TypeParameterType node, List<ir.TypeParameter> functionTypeVariables) {
    int index = functionTypeVariables.indexOf(node.parameter);
    if (index != -1) {
      _sink.writeEnum(DartTypeNodeKind.functionTypeVariable);
      _sink.writeInt(index);
      _sink.writeEnum(node.declaredNullability);
      _sink._writeDartTypeNode(null, functionTypeVariables, allowNull: true);
    } else {
      _sink.writeEnum(DartTypeNodeKind.typeParameterType);
      _sink.writeTypeParameterNode(node.parameter);
      _sink.writeEnum(node.declaredNullability);
      _sink._writeDartTypeNode(null, functionTypeVariables, allowNull: true);
    }
  }

  @override
  void visitIntersectionType(
      ir.IntersectionType node, List<ir.TypeParameter> functionTypeVariables) {
    int index = functionTypeVariables.indexOf(node.left.parameter);
    if (index != -1) {
      _sink.writeEnum(DartTypeNodeKind.functionTypeVariable);
      _sink.writeInt(index);
      _sink.writeEnum(node.declaredNullability);
      _sink._writeDartTypeNode(node.right, functionTypeVariables,
          allowNull: false);
    } else {
      _sink.writeEnum(DartTypeNodeKind.typeParameterType);
      _sink.writeTypeParameterNode(node.left.parameter);
      _sink.writeEnum(node.declaredNullability);
      _sink._writeDartTypeNode(node.right, functionTypeVariables,
          allowNull: false);
    }
  }

  @override
  void visitTypedefType(
      ir.TypedefType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.typedef);
    _sink.writeTypedefNode(node.typedefNode);
    _sink.writeEnum(node.nullability);
    visitTypes(node.typeArguments, functionTypeVariables);
  }

  @override
  void visitExtensionType(
      ir.ExtensionType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.extensionType);
    _sink.writeExtensionTypeDeclarationNode(node.extensionTypeDeclaration);
    _sink.writeEnum(node.nullability);
    visitTypes(node.typeArguments, functionTypeVariables);
  }
}
