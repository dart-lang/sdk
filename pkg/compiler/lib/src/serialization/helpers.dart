// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Enum values used for identifying different kinds of serialized data.
///
/// This is used to for debugging data inconsistencies between serialization
/// and deserialization.
enum DataKind {
  bool,
  int,
  string,
  enumValue,
  uri,
  libraryNode,
  classNode,
  memberNode,
  treeNode,
  typeParameterNode,
  dartType,
  sourceSpan,
  constant,
}

/// Enum used for identifying the enclosing entity of a member in serialization.
enum MemberContextKind { library, cls }

/// Enum used for identifying [Local] subclasses in serialization.
enum LocalKind {
  jLocal,
  thisLocal,
  boxLocal,
  anonymousClosureLocal,
  typeVariableLocal,
}

/// Enum used for identifying [ir.TreeNode] subclasses in serialization.
enum _TreeNodeKind {
  cls,
  member,
  node,
  functionNode,
  typeParameter,
  functionDeclarationVariable
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

/// Class used for encoding tags in [ObjectSink] and [ObjectSource].
class Tag {
  final String value;

  Tag(this.value);

  int get hashCode => value.hashCode * 13;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Tag) return false;
    return value == other.value;
  }

  String toString() => 'Tag($value)';
}

/// Enum used for identifying [DartType] subclasses in serialization.
enum DartTypeKind {
  none,
  voidType,
  typeVariable,
  functionTypeVariable,
  functionType,
  interfaceType,
  typedef,
  dynamicType,
  futureOr
}

/// Visitor that serializes [DartType] object together with [AbstractDataSink].
class DartTypeWriter
    implements DartTypeVisitor<void, List<FunctionTypeVariable>> {
  final AbstractDataSink _sink;

  DartTypeWriter(this._sink);

  void visit(covariant DartType type,
          List<FunctionTypeVariable> functionTypeVariables) =>
      type.accept(this, functionTypeVariables);

  void visitTypes(
      List<DartType> types, List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeInt(types.length);
    for (DartType type in types) {
      _sink._writeDartType(type, functionTypeVariables);
    }
  }

  void visitVoidType(covariant VoidType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.voidType);
  }

  void visitTypeVariableType(covariant TypeVariableType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.typeVariable);
    IndexedTypeVariable typeVariable = type.element;
    _sink.writeInt(typeVariable.typeVariableIndex);
  }

  void visitFunctionTypeVariable(covariant FunctionTypeVariable type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.functionTypeVariable);
    int index = functionTypeVariables.indexOf(type);
    assert(index != -1);
    _sink.writeInt(index);
  }

  void visitFunctionType(covariant FunctionType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.functionType);
    functionTypeVariables =
        new List<FunctionTypeVariable>.from(functionTypeVariables)
          ..addAll(type.typeVariables);
    _sink.writeInt(type.typeVariables.length);
    for (FunctionTypeVariable variable in type.typeVariables) {
      _sink._writeDartType(variable.bound, functionTypeVariables);
    }
    _sink._writeDartType(type.returnType, functionTypeVariables);
    visitTypes(type.parameterTypes, functionTypeVariables);
    visitTypes(type.optionalParameterTypes, functionTypeVariables);
    visitTypes(type.namedParameterTypes, functionTypeVariables);
    for (String namedParameter in type.namedParameters) {
      _sink.writeString(namedParameter);
    }
  }

  void visitInterfaceType(covariant InterfaceType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.interfaceType);
    _sink.writeClass(type.element);
    visitTypes(type.typeArguments, functionTypeVariables);
  }

  void visitTypedefType(covariant TypedefType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.typedef);
    _sink.writeTypedef(type.element);
    visitTypes(type.typeArguments, functionTypeVariables);
    _sink._writeDartType(type.unaliased, functionTypeVariables);
  }

  void visitDynamicType(covariant DynamicType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.dynamicType);
  }

  void visitFutureOrType(covariant FutureOrType type,
      List<FunctionTypeVariable> functionTypeVariables) {
    _sink.writeEnum(DartTypeKind.futureOr);
    _sink._writeDartType(type.typeArgument, functionTypeVariables);
  }
}
