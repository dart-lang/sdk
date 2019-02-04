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
  typedefNode,
  memberNode,
  treeNode,
  typeParameterNode,
  dartType,
  dartTypeNode,
  sourceSpan,
  constant,
  import,
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
  futureOr,
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
    int index = functionTypeVariables.indexOf(type);
    if (index == -1) {
      // TODO(johnniwinther): Avoid free variables.
      _sink._writeDartType(const DynamicType(), functionTypeVariables);
    } else {
      _sink.writeEnum(DartTypeKind.functionTypeVariable);
      _sink.writeInt(index);
    }
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

/// Enum used for identifying [ir.DartType] subclasses in serialization.
enum DartTypeNodeKind {
  none,
  voidType,
  typeParameterType,
  functionType,
  functionTypeVariable,
  interfaceType,
  typedef,
  dynamicType,
  bottomType,
  invalidType,
  thisInterfaceType,
  exactInterfaceType,
  doesNotComplete,
}

const String functionTypeNodeTag = 'function-type-node';

class DartTypeNodeWriter
    extends ir.DartTypeVisitor1<void, List<ir.TypeParameter>> {
  final AbstractDataSink _sink;

  DartTypeNodeWriter(this._sink);

  void visitTypes(
      List<ir.DartType> types, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeInt(types.length);
    for (ir.DartType type in types) {
      _sink._writeDartTypeNode(type, functionTypeVariables);
    }
  }

  void defaultDartType(
      ir.DartType node, List<ir.TypeParameter> functionTypeVariables) {
    throw new UnsupportedError(
        "Unexpected ir.DartType $node (${node.runtimeType}).");
  }

  void visitInvalidType(
      ir.InvalidType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.invalidType);
  }

  void visitDynamicType(
      ir.DynamicType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.dynamicType);
  }

  void visitVoidType(
      ir.VoidType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.voidType);
  }

  void visitBottomType(
      ir.BottomType node, List<ir.TypeParameter> functionTypeVariables) {
    if (node == const DoesNotCompleteType()) {
      _sink.writeEnum(DartTypeNodeKind.doesNotComplete);
    } else {
      _sink.writeEnum(DartTypeNodeKind.bottomType);
    }
  }

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
    visitTypes(node.typeArguments, functionTypeVariables);
  }

  void visitFunctionType(
      ir.FunctionType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.functionType);
    _sink.begin(functionTypeNodeTag);
    functionTypeVariables =
        new List<ir.TypeParameter>.from(functionTypeVariables)
          ..addAll(node.typeParameters);
    _sink.writeInt(node.typeParameters.length);
    for (ir.TypeParameter parameter in node.typeParameters) {
      _sink.writeString(parameter.name);
      _sink._writeDartTypeNode(parameter.bound, functionTypeVariables);
      _sink._writeDartTypeNode(parameter.defaultType, functionTypeVariables);
    }
    _sink._writeDartTypeNode(node.returnType, functionTypeVariables);
    _sink.writeInt(node.requiredParameterCount);
    visitTypes(node.positionalParameters, functionTypeVariables);
    _sink.writeInt(node.namedParameters.length);
    for (ir.NamedType parameter in node.namedParameters) {
      _sink.writeString(parameter.name);
      _sink._writeDartTypeNode(parameter.type, functionTypeVariables);
    }
    _sink._writeDartTypeNode(node.typedefType, functionTypeVariables,
        allowNull: true);
    _sink.end(functionTypeNodeTag);
  }

  void visitTypeParameterType(
      ir.TypeParameterType node, List<ir.TypeParameter> functionTypeVariables) {
    int index = functionTypeVariables.indexOf(node.parameter);
    if (index != -1) {
      _sink.writeEnum(DartTypeNodeKind.functionTypeVariable);
      _sink.writeInt(index);
      _sink._writeDartTypeNode(node.promotedBound, functionTypeVariables,
          allowNull: true);
    } else {
      _sink.writeEnum(DartTypeNodeKind.typeParameterType);
      _sink.writeTypeParameterNode(node.parameter);
      _sink._writeDartTypeNode(node.promotedBound, functionTypeVariables,
          allowNull: true);
    }
  }

  void visitTypedefType(
      ir.TypedefType node, List<ir.TypeParameter> functionTypeVariables) {
    _sink.writeEnum(DartTypeNodeKind.typedef);
    _sink.writeTypedefNode(node.typedefNode);
    visitTypes(node.typeArguments, functionTypeVariables);
  }
}

/// Data sink helper that canonicalizes [E] values using indices.
class IndexedSink<E> {
  final AbstractDataSink _sink;
  final Map<E, int> _cache = {};

  IndexedSink(this._sink);

  /// Write a reference to [value] to the data sink.
  ///
  /// If [value] has not been canonicalized yet, [writeValue] is called to
  /// serialize the [value] itself.
  void write(E value, void writeValue(E value)) {
    int index = _cache[value];
    if (index == null) {
      index = _cache.length;
      _cache[value] = index;
      _sink._writeIntInternal(index);
      writeValue(value);
    } else {
      _sink._writeIntInternal(index);
    }
  }
}

/// Data source helper reads canonicalized [E] values through indices.
class IndexedSource<E> {
  final AbstractDataSource _source;
  final List<E> _cache = [];

  IndexedSource(this._source);

  /// Reads a reference to an [E] value from the data source.
  ///
  /// If the value hasn't yet been read, [readValue] is called to deserialize
  /// the value itself.
  E read(E readValue()) {
    int index = _source._readIntInternal();
    if (index >= _cache.length) {
      E value = readValue();
      _cache.add(value);
      return value;
    } else {
      return _cache[index];
    }
  }
}
