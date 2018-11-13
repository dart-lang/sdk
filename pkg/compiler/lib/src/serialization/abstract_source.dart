// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Base implementation of [DataSource] using [DataSourceMixin] to implement
/// convenience methods.
abstract class AbstractDataSource extends DataSourceMixin
    implements DataSource {
  final bool useDataKinds;
  ComponentLookup _componentLookup;
  EntityLookup _entityLookup;
  LocalLookup _localLookup;

  AbstractDataSource({this.useDataKinds: false});

  void begin(String tag) {
    if (useDataKinds) _begin(tag);
  }

  void end(String tag) {
    if (useDataKinds) _end(tag);
  }

  void registerComponentLookup(ComponentLookup componentLookup) {
    assert(_componentLookup == null);
    _componentLookup = componentLookup;
  }

  ComponentLookup get componentLookup {
    assert(_componentLookup != null);
    return _componentLookup;
  }

  void registerEntityLookup(EntityLookup entityLookup) {
    assert(_entityLookup == null);
    _entityLookup = entityLookup;
  }

  EntityLookup get entityLookup {
    assert(_entityLookup != null);
    return _entityLookup;
  }

  void registerLocalLookup(LocalLookup localLookup) {
    assert(_localLookup == null);
    _localLookup = localLookup;
  }

  LocalLookup get localLookup {
    assert(_localLookup != null);
    return _localLookup;
  }

  IndexedLibrary readLibrary() {
    return getIndexedLibrary(readInt());
  }

  IndexedClass readClass() {
    return getIndexedClass(readInt());
  }

  IndexedTypedef readTypedef() {
    return getIndexedTypedef(readInt());
  }

  IndexedMember readMember() {
    return getIndexedMember(readInt());
  }

  IndexedLibrary getIndexedLibrary(int libraryIndex) =>
      entityLookup.getLibraryByIndex(libraryIndex);

  IndexedClass getIndexedClass(int classIndex) =>
      entityLookup.getClassByIndex(classIndex);

  IndexedTypedef getIndexedTypedef(int typedefIndex) =>
      entityLookup.getTypedefByIndex(typedefIndex);

  IndexedMember getIndexedMember(int memberIndex) =>
      entityLookup.getMemberByIndex(memberIndex);

  IndexedTypeVariable getIndexedTypeVariable(int typeVariableIndex) =>
      entityLookup.getTypeVariableByIndex(typeVariableIndex);

  List<DartType> _readDartTypes(
      List<FunctionTypeVariable> functionTypeVariables) {
    int count = readInt();
    List<DartType> types = new List<DartType>(count);
    for (int index = 0; index < count; index++) {
      types[index] = _readDartType(functionTypeVariables);
    }
    return types;
  }

  @override
  SourceSpan readSourceSpan() {
    _checkDataKind(DataKind.sourceSpan);
    Uri uri = _readUri();
    int begin = _readInt();
    int end = _readInt();
    return new SourceSpan(uri, begin, end);
  }

  @override
  DartType readDartType({bool allowNull: false}) {
    _checkDataKind(DataKind.dartType);
    DartType type = _readDartType([]);
    assert(type != null || allowNull);
    return type;
  }

  DartType _readDartType(List<FunctionTypeVariable> functionTypeVariables) {
    DartTypeKind kind = readEnum(DartTypeKind.values);
    switch (kind) {
      case DartTypeKind.none:
        return null;
      case DartTypeKind.voidType:
        return const VoidType();
      case DartTypeKind.typeVariable:
        return new TypeVariableType(getIndexedTypeVariable(readInt()));
      case DartTypeKind.functionTypeVariable:
        int index = readInt();
        assert(0 <= index && index < functionTypeVariables.length);
        return functionTypeVariables[index];
      case DartTypeKind.functionType:
        int typeVariableCount = readInt();
        List<FunctionTypeVariable> typeVariables =
            new List<FunctionTypeVariable>.generate(typeVariableCount,
                (int index) => new FunctionTypeVariable(index));
        functionTypeVariables =
            new List<FunctionTypeVariable>.from(functionTypeVariables)
              ..addAll(typeVariables);
        for (int index = 0; index < typeVariableCount; index++) {
          typeVariables[index].bound = _readDartType(functionTypeVariables);
        }
        DartType returnType = _readDartType(functionTypeVariables);
        List<DartType> parameterTypes = _readDartTypes(functionTypeVariables);
        List<DartType> optionalParameterTypes =
            _readDartTypes(functionTypeVariables);
        List<DartType> namedParameterTypes =
            _readDartTypes(functionTypeVariables);
        List<String> namedParameters =
            new List<String>(namedParameterTypes.length);
        for (int i = 0; i < namedParameters.length; i++) {
          namedParameters[i] = readString();
        }
        return new FunctionType(
            returnType,
            parameterTypes,
            optionalParameterTypes,
            namedParameters,
            namedParameterTypes,
            typeVariables);

      case DartTypeKind.interfaceType:
        IndexedClass cls = getIndexedClass(readInt());
        List<DartType> typeArguments = _readDartTypes(functionTypeVariables);
        return new InterfaceType(cls, typeArguments);
      case DartTypeKind.typedef:
        IndexedTypedef typedef = getIndexedTypedef(readInt());
        List<DartType> typeArguments = _readDartTypes(functionTypeVariables);
        DartType unaliased = _readDartType(functionTypeVariables);
        return new TypedefType(typedef, typeArguments, unaliased);
      case DartTypeKind.dynamicType:
        return const DynamicType();
      case DartTypeKind.futureOr:
        DartType typeArgument = _readDartType(functionTypeVariables);
        return new FutureOrType(typeArgument);
    }
    throw new UnsupportedError("Unexpected DartTypeKind $kind");
  }

  _MemberData _readMemberData() {
    MemberContextKind kind = _readEnum(MemberContextKind.values);
    switch (kind) {
      case MemberContextKind.cls:
        _ClassData cls = _readClassData();
        String name = _readString();
        return cls.lookupMember(name);
      case MemberContextKind.library:
        _LibraryData library = _readLibraryData();
        String name = _readString();
        return library.lookupMember(name);
    }
    throw new UnsupportedError("Unsupported _MemberKind $kind");
  }

  @override
  ir.Member readMemberNode() {
    _checkDataKind(DataKind.memberNode);
    return _readMemberData().node;
  }

  _ClassData _readClassData() {
    _LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupClass(name);
  }

  @override
  ir.Class readClassNode() {
    _checkDataKind(DataKind.classNode);
    return _readClassData().node;
  }

  _LibraryData _readLibraryData() {
    Uri canonicalUri = _readUri();
    return componentLookup.getLibraryDataByUri(canonicalUri);
  }

  @override
  ir.Library readLibraryNode() {
    _checkDataKind(DataKind.libraryNode);
    return _readLibraryData().node;
  }

  @override
  E readEnum<E>(List<E> values) {
    _checkDataKind(DataKind.enumValue);
    return _readEnum(values);
  }

  @override
  Uri readUri() {
    _checkDataKind(DataKind.uri);
    return _readUri();
  }

  @override
  bool readBool() {
    _checkDataKind(DataKind.bool);
    int value = _readInt();
    assert(value == 0 || value == 1);
    return value == 1;
  }

  @override
  String readString() {
    _checkDataKind(DataKind.string);
    return _readString();
  }

  @override
  int readInt() {
    _checkDataKind(DataKind.int);
    return _readInt();
  }

  @override
  ir.TreeNode readTreeNode() {
    _checkDataKind(DataKind.treeNode);
    return _readTreeNode();
  }

  @override
  ConstantValue readConstant() {
    _checkDataKind(DataKind.constant);
    return _readConstant();
  }

  ConstantValue _readConstant() {
    ConstantValueKind kind = _readEnum(ConstantValueKind.values);
    ConstantValue constant;
    switch (kind) {
      case ConstantValueKind.BOOL:
        bool value = readBool();
        constant = new BoolConstantValue(value);
        break;
      case ConstantValueKind.INT:
        BigInt value = BigInt.parse(readString());
        constant = new IntConstantValue(value);
        break;
      case ConstantValueKind.DOUBLE:
        ByteData data = new ByteData(8);
        data.setUint16(0, readInt());
        data.setUint16(2, readInt());
        data.setUint16(4, readInt());
        data.setUint16(6, readInt());
        double value = data.getFloat64(0);
        constant = new DoubleConstantValue(value);
        break;
      case ConstantValueKind.STRING:
        String value = readString();
        constant = new StringConstantValue(value);
        break;
      case ConstantValueKind.NULL:
        constant = const NullConstantValue();
        break;
      default:
        // TODO(johnniwinther): Support remaining constant values.
        throw new UnsupportedError("Unexpected constant value kind ${kind}.");
    }
    return constant;
  }

  ir.TreeNode _readTreeNode() {
    _TreeNodeKind kind = _readEnum(_TreeNodeKind.values);
    switch (kind) {
      case _TreeNodeKind.cls:
        return _readClassData().node;
      case _TreeNodeKind.member:
        return _readMemberData().node;
      case _TreeNodeKind.functionDeclarationVariable:
        ir.FunctionDeclaration functionDeclaration = _readTreeNode();
        return functionDeclaration.variable;
      case _TreeNodeKind.functionNode:
        return _readFunctionNode();
      case _TreeNodeKind.typeParameter:
        return _readTypeParameter();
      case _TreeNodeKind.node:
        _MemberData data = _readMemberData();
        int index = _readInt();
        ir.TreeNode treeNode = data.getTreeNodeByIndex(index);
        assert(treeNode != null,
            "No TreeNode found for index $index in ${data.node}.$_errorContext");
        return treeNode;
    }
    throw new UnsupportedError("Unexpected _TreeNodeKind $kind");
  }

  ir.FunctionNode _readFunctionNode() {
    _FunctionNodeKind kind = _readEnum(_FunctionNodeKind.values);
    switch (kind) {
      case _FunctionNodeKind.procedure:
        ir.Procedure procedure = _readMemberData().node;
        return procedure.function;
      case _FunctionNodeKind.constructor:
        ir.Constructor constructor = _readMemberData().node;
        return constructor.function;
      case _FunctionNodeKind.functionExpression:
        ir.FunctionExpression functionExpression = _readTreeNode();
        return functionExpression.function;
      case _FunctionNodeKind.functionDeclaration:
        ir.FunctionDeclaration functionDeclaration = _readTreeNode();
        return functionDeclaration.function;
    }
    throw new UnsupportedError("Unexpected _FunctionNodeKind $kind");
  }

  @override
  ir.TypeParameter readTypeParameterNode() {
    _checkDataKind(DataKind.typeParameterNode);
    return _readTypeParameter();
  }

  ir.TypeParameter _readTypeParameter() {
    _TypeParameterKind kind = _readEnum(_TypeParameterKind.values);
    switch (kind) {
      case _TypeParameterKind.cls:
        ir.Class cls = _readClassData().node;
        return cls.typeParameters[_readInt()];
      case _TypeParameterKind.functionNode:
        ir.FunctionNode functionNode = _readFunctionNode();
        return functionNode.typeParameters[_readInt()];
    }
    throw new UnsupportedError("Unexpected _TypeParameterKind kind $kind");
  }

  void _checkDataKind(DataKind expectedKind) {
    if (!useDataKinds) return;
    DataKind actualKind = _readEnum(DataKind.values);
    assert(
        actualKind == expectedKind,
        "Invalid data kind. "
        "Expected $expectedKind, found $actualKind.$_errorContext");
  }

  @override
  Local readLocal() {
    LocalKind kind = readEnum(LocalKind.values);
    switch (kind) {
      case LocalKind.jLocal:
        MemberEntity memberContext = readMember();
        int localIndex = readInt();
        return localLookup.getLocalByIndex(memberContext, localIndex);
      case LocalKind.thisLocal:
        ClassEntity cls = readClass();
        return new ThisLocal(cls);
      case LocalKind.boxLocal:
        ClassEntity cls = readClass();
        return new BoxLocal(cls);
      case LocalKind.anonymousClosureLocal:
        ClassEntity cls = readClass();
        return new AnonymousClosureLocal(cls);
      case LocalKind.typeVariableLocal:
        TypeVariableType typeVariable = readDartType();
        return new TypeVariableLocal(typeVariable);
    }
    throw new UnsupportedError("Unexpected local kind $kind");
  }

  /// Actual deserialization of a section begin tag, implemented by subclasses.
  void _begin(String tag);

  /// Actual deserialization of a section end tag, implemented by subclasses.
  void _end(String tag);

  /// Actual deserialization of a string value, implemented by subclasses.
  String _readString();

  /// Actual deserialization of a non-negative integer value, implemented by
  /// subclasses.
  int _readInt();

  /// Actual deserialization of a URI value, implemented by subclasses.
  Uri _readUri();

  /// Actual deserialization of an enum value in [values], implemented by
  /// subclasses.
  E _readEnum<E>(List<E> values);

  /// Returns a string representation of the current state of the data source
  /// useful for debugging in consistencies between serialization and
  /// deserialization.
  String get _errorContext;
}
