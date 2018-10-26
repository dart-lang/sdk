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

  IndexedSource<String> _stringIndex;
  IndexedSource<Uri> _uriIndex;
  IndexedSource<_MemberData> _memberNodeIndex;
  IndexedSource<ImportEntity> _importIndex;

  Map<Type, IndexedSource> _generalCaches = {};

  AbstractDataSource({this.useDataKinds: false}) {
    _stringIndex = new IndexedSource<String>(this);
    _uriIndex = new IndexedSource<Uri>(this);
    _memberNodeIndex = new IndexedSource<_MemberData>(this);
    _importIndex = new IndexedSource<ImportEntity>(this);
  }

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

  @override
  E readCached<E>(E f()) {
    IndexedSource source = _generalCaches[E] ??= new IndexedSource<E>(this);
    return source.read(f);
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
    int begin = _readIntInternal();
    int end = _readIntInternal();
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
    return _memberNodeIndex.read(_readMemberDataInternal);
  }

  _MemberData _readMemberDataInternal() {
    MemberContextKind kind = _readEnumInternal(MemberContextKind.values);
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

  ir.Typedef _readTypedefNode() {
    _LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupTypedef(name);
  }

  @override
  ir.Typedef readTypedefNode() {
    _checkDataKind(DataKind.typedefNode);
    return _readTypedefNode();
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
    return _readEnumInternal(values);
  }

  @override
  Uri readUri() {
    _checkDataKind(DataKind.uri);
    return _readUri();
  }

  Uri _readUri() {
    return _uriIndex.read(_readUriInternal);
  }

  @override
  bool readBool() {
    _checkDataKind(DataKind.bool);
    return _readBool();
  }

  bool _readBool() {
    int value = _readIntInternal();
    assert(value == 0 || value == 1);
    return value == 1;
  }

  @override
  String readString() {
    _checkDataKind(DataKind.string);
    return _readString();
  }

  String _readString() {
    return _stringIndex.read(_readStringInternal);
  }

  @override
  int readInt() {
    _checkDataKind(DataKind.int);
    return _readIntInternal();
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
    ConstantValueKind kind = _readEnumInternal(ConstantValueKind.values);
    switch (kind) {
      case ConstantValueKind.BOOL:
        bool value = readBool();
        return new BoolConstantValue(value);
      case ConstantValueKind.INT:
        BigInt value = BigInt.parse(readString());
        return new IntConstantValue(value);
      case ConstantValueKind.DOUBLE:
        ByteData data = new ByteData(8);
        data.setUint16(0, readInt());
        data.setUint16(2, readInt());
        data.setUint16(4, readInt());
        data.setUint16(6, readInt());
        double value = data.getFloat64(0);
        return new DoubleConstantValue(value);
      case ConstantValueKind.STRING:
        String value = readString();
        return new StringConstantValue(value);
      case ConstantValueKind.NULL:
        return const NullConstantValue();
      case ConstantValueKind.FUNCTION:
        IndexedFunction function = readMember();
        DartType type = readDartType();
        return new FunctionConstantValue(function, type);
      case ConstantValueKind.LIST:
        DartType type = readDartType();
        List<ConstantValue> entries = readConstants();
        return new ListConstantValue(type, entries);
      case ConstantValueKind.MAP:
        DartType type = readDartType();
        List<ConstantValue> keys = readConstants();
        List<ConstantValue> values = readConstants();
        return new MapConstantValue(type, keys, values);
      case ConstantValueKind.CONSTRUCTED:
        InterfaceType type = readDartType();
        Map<FieldEntity, ConstantValue> fields =
            readMemberMap<FieldEntity, ConstantValue>(() => readConstant());
        return new ConstructedConstantValue(type, fields);
      case ConstantValueKind.TYPE:
        DartType representedType = readDartType();
        DartType type = readDartType();
        return new TypeConstantValue(representedType, type);
      case ConstantValueKind.INSTANTIATION:
        List<DartType> typeArguments = readDartTypes();
        ConstantValue function = readConstant();
        return new InstantiationConstantValue(typeArguments, function);
      case ConstantValueKind.NON_CONSTANT:
        return new NonConstantValue();
      case ConstantValueKind.DEFERRED_GLOBAL:
      case ConstantValueKind.INTERCEPTOR:
      case ConstantValueKind.SYNTHETIC:
        // These are only created in the SSA graph builder.
        throw new UnsupportedError("Unsupported constant value kind ${kind}.");
    }
    throw new UnsupportedError("Unexpexted constant value kind ${kind}.");
  }

  ir.TreeNode _readTreeNode() {
    _TreeNodeKind kind = _readEnumInternal(_TreeNodeKind.values);
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
        int index = _readIntInternal();
        ir.TreeNode treeNode = data.getTreeNodeByIndex(index);
        assert(treeNode != null,
            "No TreeNode found for index $index in ${data.node}.$_errorContext");
        return treeNode;
    }
    throw new UnsupportedError("Unexpected _TreeNodeKind $kind");
  }

  ir.FunctionNode _readFunctionNode() {
    _FunctionNodeKind kind = _readEnumInternal(_FunctionNodeKind.values);
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
    _TypeParameterKind kind = _readEnumInternal(_TypeParameterKind.values);
    switch (kind) {
      case _TypeParameterKind.cls:
        ir.Class cls = _readClassData().node;
        return cls.typeParameters[_readIntInternal()];
      case _TypeParameterKind.functionNode:
        ir.FunctionNode functionNode = _readFunctionNode();
        return functionNode.typeParameters[_readIntInternal()];
    }
    throw new UnsupportedError("Unexpected _TypeParameterKind kind $kind");
  }

  void _checkDataKind(DataKind expectedKind) {
    if (!useDataKinds) return;
    DataKind actualKind = _readEnumInternal(DataKind.values);
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

  @override
  ImportEntity readImport() {
    _checkDataKind(DataKind.import);
    return _readImport();
  }

  ImportEntity _readImport() {
    return _importIndex.read(_readImportInternal);
  }

  ImportEntity _readImportInternal() {
    String name = readStringOrNull();
    Uri uri = _readUri();
    Uri enclosingLibraryUri = _readUri();
    bool isDeferred = _readBool();
    return new ImportEntity(isDeferred, name, uri, enclosingLibraryUri);
  }

  /// Actual deserialization of a section begin tag, implemented by subclasses.
  void _begin(String tag);

  /// Actual deserialization of a section end tag, implemented by subclasses.
  void _end(String tag);

  /// Actual deserialization of a string value, implemented by subclasses.
  String _readStringInternal();

  /// Actual deserialization of a non-negative integer value, implemented by
  /// subclasses.
  int _readIntInternal();

  /// Actual deserialization of a URI value, implemented by subclasses.
  Uri _readUriInternal();

  /// Actual deserialization of an enum value in [values], implemented by
  /// subclasses.
  E _readEnumInternal<E>(List<E> values);

  /// Returns a string representation of the current state of the data source
  /// useful for debugging in consistencies between serialization and
  /// deserialization.
  String get _errorContext;
}
