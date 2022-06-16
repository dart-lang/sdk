// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

part of 'serialization.dart';

/// Deserialization reader
///
/// To be used with [DataSinkWriter] to read and write serialized data.
/// Deserialization format is deferred to provided [DataSource].
class DataSourceReader implements migrated.DataSourceReader {
  // The active [DataSource] to read data from. This can be the base DataSource
  // for this reader or can be set to access data in a different serialized
  // input in the case of deferred indexed data.
  DataSource _sourceReader;

  static final List<ir.DartType> emptyListOfDartTypes =
      List<ir.DartType>.empty();

  final bool enableDeferredStrategy;
  final bool useDataKinds;
  final ValueInterner /*?*/ interner;
  DataSourceIndices importedIndices;
  EntityReader _entityReader = const EntityReader();
  ComponentLookup _componentLookup;
  EntityLookup _entityLookup;
  LocalLookup _localLookup;
  CodegenReader _codegenReader;

  IndexedSource<String> _stringIndex;
  IndexedSource<Uri> _uriIndex;
  IndexedSource<MemberData> _memberNodeIndex;
  IndexedSource<ImportEntity> _importIndex;
  IndexedSource<ConstantValue> _constantIndex;

  final Map<Type, IndexedSource> _generalCaches = {};

  ir.Member _currentMemberContext;
  MemberData _currentMemberData;

  @override
  int get length => _sourceReader.length;

  /// Defines the beginning of this block in the address space created by all
  /// instances of [DataSourceReader].
  ///
  /// The amount by which the offsets for indexed values read by this reader are
  /// shifted. That is the length of all the sources read before this one.
  ///
  /// See [UnorderedIndexedSource] for more info.
  @override
  int get startOffset => importedIndices.previousSourceReader.endOffset;

  /// Defines the end of this block in the address space created by all
  /// instances of [DataSourceReader].
  ///
  /// Indexed values read from this source will all have offsets less than this
  /// value.
  ///
  /// See [UnorderedIndexedSource] for more info.
  @override
  final int endOffset;

  IndexedSource<T> _createSource<T>() {
    if (importedIndices == null || !importedIndices.caches.containsKey(T)) {
      return OrderedIndexedSource<T>(this._sourceReader);
    } else {
      final source = importedIndices.caches[T].source as OrderedIndexedSource;
      List<T> cacheCopy = source.cache.toList();
      return OrderedIndexedSource<T>(this._sourceReader, cache: cacheCopy);
    }
  }

  UnorderedIndexedSource<T> /*?*/ _getPreviousUncreatedSource<T>() {
    final previousSourceReader = importedIndices?.previousSourceReader;
    if (previousSourceReader == null) return null;
    return UnorderedIndexedSource<T>(previousSourceReader,
        previousSource: previousSourceReader._getPreviousUncreatedSource<T>());
  }

  IndexedSource<T> _createUnorderedSource<T>() {
    if (importedIndices != null) {
      if (importedIndices.caches.containsKey(T)) {
        final index = importedIndices.caches.remove(T);
        return UnorderedIndexedSource<T>(this, previousSource: index.source);
      }
      final newPreviousSource = _getPreviousUncreatedSource<T>();
      if (newPreviousSource != null) {
        return UnorderedIndexedSource<T>(this,
            previousSource: newPreviousSource);
      }
    }
    return UnorderedIndexedSource<T>(this);
  }

  DataSourceReader(this._sourceReader, CompilerOptions options,
      {this.useDataKinds = false, this.importedIndices, this.interner})
      : enableDeferredStrategy =
            (options?.features?.deferredSerialization?.isEnabled ?? false),
        endOffset = (importedIndices?.previousSourceReader?.endOffset ?? 0) +
            _sourceReader.length {
    if (!enableDeferredStrategy) {
      _stringIndex = _createSource<String>();
      _uriIndex = _createSource<Uri>();
      _importIndex = _createSource<ImportEntity>();
      _memberNodeIndex = _createSource<MemberData>();
      _constantIndex = _createSource<ConstantValue>();
      return;
    }
    _stringIndex = _createUnorderedSource<String>();
    _uriIndex = _createUnorderedSource<Uri>();
    _importIndex = _createUnorderedSource<ImportEntity>();
    _memberNodeIndex = _createUnorderedSource<MemberData>();
    _constantIndex = _createUnorderedSource<ConstantValue>();
  }

  /// Exports [DataSourceIndices] for use in other [DataSourceReader]s and
  /// [DataSinkWriter]s.
  DataSourceIndices exportIndices() {
    final indices = DataSourceIndices(this);
    indices.caches[String] = DataSourceTypeIndices(_stringIndex);
    indices.caches[Uri] = DataSourceTypeIndices(_uriIndex);
    indices.caches[ImportEntity] = DataSourceTypeIndices(_importIndex);
    // _memberNodeIndex needs two entries depending on if the indices will be
    // consumed by a [DataSource] or [DataSink].
    indices.caches[MemberData] = DataSourceTypeIndices(_memberNodeIndex);
    indices.caches[ir.Member] = DataSourceTypeIndices<ir.Member, MemberData>(
        _memberNodeIndex, (MemberData data) => data?.node);
    indices.caches[ConstantValue] = DataSourceTypeIndices(_constantIndex);
    _generalCaches.forEach((type, indexedSource) {
      indices.caches[type] = DataSourceTypeIndices(indexedSource);
    });
    return indices;
  }

  /// Registers that the section [tag] starts.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  @override
  void begin(String tag) {
    if (useDataKinds) _sourceReader.begin(tag);
  }

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  @override
  void end(String tag) {
    if (useDataKinds) _sourceReader.end(tag);
  }

  /// Registers a [ComponentLookup] object with this data source to support
  /// deserialization of references to kernel nodes.
  void registerComponentLookup(ComponentLookup componentLookup) {
    assert(_componentLookup == null);
    _componentLookup = componentLookup;
  }

  ComponentLookup get componentLookup {
    assert(_componentLookup != null);
    return _componentLookup /*!*/;
  }

  /// Registers an [EntityLookup] object with this data source to support
  /// deserialization of references to indexed entities.
  void registerEntityLookup(EntityLookup entityLookup) {
    assert(_entityLookup == null);
    _entityLookup = entityLookup;
  }

  EntityLookup get entityLookup {
    assert(_entityLookup != null);
    return _entityLookup /*!*/;
  }

  /// Registers an [EntityReader] with this data source for non-default encoding
  /// of entity references.
  void registerEntityReader(EntityReader reader) {
    assert(reader != null);
    _entityReader = reader;
  }

  /// Registers a [LocalLookup] object with this data source to support
  void registerLocalLookup(LocalLookup localLookup) {
    assert(_localLookup == null);
    _localLookup = localLookup;
  }

  LocalLookup get localLookup {
    assert(_localLookup != null);
    return _localLookup /*!*/;
  }

  /// Registers a [CodegenReader] with this data source to support
  /// deserialization of codegen only data.
  void registerCodegenReader(CodegenReader reader) {
    assert(reader != null);
    assert(_codegenReader == null);
    _codegenReader = reader;
  }

  /// Unregisters the [CodegenReader] from this data source to remove support
  /// for deserialization of codegen only data.
  void deregisterCodegenReader(CodegenReader reader) {
    assert(_codegenReader == reader);
    _codegenReader = null;
  }

  /// Evaluates [f] with [DataSource] for the provided [source] as the
  /// temporary [DataSource] for this object. Allows deferred data to be read
  /// from a file other than the one currently being read from.
  // TODO(48820): Remove covariant when sound.
  @override
  E readWithSource<E>(covariant DataSourceReader source, E f()) {
    final lastSource = _sourceReader;
    _sourceReader = source._sourceReader;
    final value = f();
    _sourceReader = lastSource;
    return value;
  }

  @override
  E readWithOffset<E>(int offset, E f()) {
    return _sourceReader.readAtOffset(offset, f);
  }

  /// Invoke [f] in the context of [member]. This sets up support for
  /// deserialization of `ir.TreeNode`s using the `readTreeNode*InContext`
  /// methods.
  @override
  T inMemberContext<T>(ir.Member context, T f()) {
    ir.Member oldMemberContext = _currentMemberContext;
    MemberData oldMemberData = _currentMemberData;
    _currentMemberContext = context;
    _currentMemberData = null;
    T result = f();
    _currentMemberData = oldMemberData;
    _currentMemberContext = oldMemberContext;
    return result;
  }

  MemberData get currentMemberData {
    assert(_currentMemberContext != null,
        "DataSink has no current member context.");
    return _currentMemberData ??= _getMemberData(_currentMemberContext);
  }

  /// Reads a reference to an [E] value from this data source. If the value has
  /// not yet been deserialized, [f] is called to deserialize the value itself.
  @override
  E readCached<E>(E f()) {
    E /*?*/ value = readCachedOrNull(f);
    if (value == null) throw StateError("Unexpected 'null' for $E");
    return value;
  }

  /// Reads a reference to an [E] value from this data source. If the value has
  /// not yet been deserialized, [f] is called to deserialize the value itself.
  @override
  E /*?*/ readCachedOrNull<E>(E f()) {
    IndexedSource<E> source = _generalCaches[E] ??= (enableDeferredStrategy
        ? _createUnorderedSource<E>()
        : _createSource<E>());
    return source.read(f);
  }

  /// Reads a potentially `null` [E] value from this data source, calling [f] to
  /// read the non-null value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeValueOrNull].
  @override
  E readValueOrNull<E>(E f()) {
    bool hasValue = readBool();
    if (hasValue) {
      return f();
    }
    return null;
  }

  /// Reads a list of [E] values from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeList].
  @override
  List<E> readList<E>(E f()) {
    return readListOrNull<E>(f) ?? List<E>.empty();
  }

  /// Reads a list of [E] values from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeList].
  @override
  List<E> /*?*/ readListOrNull<E>(E f()) {
    int count = readInt();
    if (count == 0) return null;
    final first = f();
    List<E> list = List<E>.filled(count, first);
    for (int i = 1; i < count; i++) {
      list[i] = f();
    }
    return list;
  }

  @override
  bool readBool() {
    _checkDataKind(DataKind.bool);
    return _readBool();
  }

  /// Reads a boolean value from this data source.
  bool _readBool() {
    int value = _sourceReader.readInt();
    assert(value == 0 || value == 1);
    return value == 1;
  }

  /// Reads a non-negative 30 bit integer value from this data source.
  @override
  int readInt() {
    _checkDataKind(DataKind.uint30);
    return _sourceReader.readInt();
  }

  /// Reads a potentially `null` non-negative integer value from this data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeIntOrNull].
  @override
  int readIntOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readInt();
    }
    return null;
  }

  /// Reads a string value from this data source.
  @override
  String readString() {
    _checkDataKind(DataKind.string);
    return _readString();
  }

  String /*!*/ _readString() {
    return _stringIndex.read(() => _sourceReader.readString());
  }

  /// Reads a potentially `null` string value from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStringOrNull].
  @override
  String readStringOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readString();
    }
    return null;
  }

  /// Reads a list of string values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStrings].
  @override
  List<String> readStrings({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<String> list = List<String>.filled(count, '');
    for (int i = 0; i < count; i++) {
      list[i] = readString();
    }
    return list;
  }

  /// Reads a map from string values to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStringMap].
  @override
  Map<String, V> readStringMap<V>(V f(), {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<String, V> map = {};
    for (int i = 0; i < count; i++) {
      String key = readString();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  /// Reads an enum value from the list of enum [values] from this data source.
  ///
  /// The [values] argument is intended to be the static `.values` field on
  /// enum classes, for instance:
  ///
  ///    enum Foo { bar, baz }
  ///    ...
  ///    Foo foo = source.readEnum(Foo.values);
  ///
  @override
  E readEnum<E>(List<E> values) {
    _checkDataKind(DataKind.enumValue);
    return _sourceReader.readEnum(values);
  }

  /// Reads a URI value from this data source.
  @override
  Uri readUri() {
    _checkDataKind(DataKind.uri);
    return _readUri();
  }

  Uri _readUri() {
    return _uriIndex.read(_doReadUri);
  }

  Uri _doReadUri() {
    return Uri.parse(_readString());
  }

  /// Reads a reference to a kernel library node from this data source.
  ir.Library readLibraryNode() {
    _checkDataKind(DataKind.libraryNode);
    return _readLibraryData().node;
  }

  LibraryData _readLibraryData() {
    Uri canonicalUri = _readUri();
    return componentLookup.getLibraryDataByUri(canonicalUri);
  }

  /// Reads a reference to a kernel class node from this data source.
  ir.Class readClassNode() {
    _checkDataKind(DataKind.classNode);
    return _readClassData().node;
  }

  ClassData _readClassData() {
    LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupClassByName(name);
  }

  /// Reads a reference to a kernel class node from this data source.
  ir.Typedef readTypedefNode() {
    _checkDataKind(DataKind.typedefNode);
    return _readTypedefNode();
  }

  ir.Typedef _readTypedefNode() {
    LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupTypedef(name);
  }

  /// Reads a reference to a kernel member node from this data source.
  ir.Member readMemberNode() {
    _checkDataKind(DataKind.memberNode);
    return _readMemberData().node;
  }

  MemberData _readMemberData() {
    return _memberNodeIndex.read(_readMemberDataInternal);
  }

  MemberData _readMemberDataInternal() {
    MemberContextKind kind = _sourceReader.readEnum(MemberContextKind.values);
    switch (kind) {
      case MemberContextKind.cls:
        ClassData cls = _readClassData();
        String name = _readString();
        return cls.lookupMemberDataByName(name);
      case MemberContextKind.library:
        LibraryData library = _readLibraryData();
        String name = _readString();
        return library.lookupMemberDataByName(name);
    }
    throw UnsupportedError("Unsupported _MemberKind $kind");
  }

  /// Reads a list of references to kernel member nodes from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodes].
  List<E> readMemberNodes<E extends ir.Member>({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ir.Member value = readMemberNode();
      list[i] = value;
    }
    return list;
  }

  /// Reads a map from kernel member nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodeMap].
  Map<K, V> readMemberNodeMap<K extends ir.Member, V>(V f(),
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ir.Member node = readMemberNode();
      V value = f();
      map[node] = value;
    }
    return map;
  }

  /// Reads a kernel name node from this data source.
  ir.Name readName() {
    String text = readString();
    ir.Library library = readValueOrNull(readLibraryNode);
    return ir.Name(text, library);
  }

  /// Reads a kernel library dependency node from this data source.
  ir.LibraryDependency readLibraryDependencyNode() {
    ir.Library library = readLibraryNode();
    int index = readInt();
    return library.dependencies[index];
  }

  /// Reads a potentially `null` kernel library dependency node from this data
  /// source.
  ir.LibraryDependency readLibraryDependencyNodeOrNull() {
    return readValueOrNull(readLibraryDependencyNode);
  }

  /// Reads a reference to a kernel tree node from this data source.
  ir.TreeNode readTreeNode() {
    _checkDataKind(DataKind.treeNode);
    return _readTreeNode(null);
  }

  ir.TreeNode _readTreeNode(MemberData memberData) {
    _TreeNodeKind kind = _sourceReader.readEnum(_TreeNodeKind.values);
    switch (kind) {
      case _TreeNodeKind.cls:
        return _readClassData().node;
      case _TreeNodeKind.member:
        return _readMemberData().node;
      case _TreeNodeKind.functionDeclarationVariable:
        ir.FunctionDeclaration functionDeclaration = _readTreeNode(memberData);
        return functionDeclaration.variable;
      case _TreeNodeKind.functionNode:
        return _readFunctionNode(memberData);
      case _TreeNodeKind.typeParameter:
        return _readTypeParameter(memberData);
      case _TreeNodeKind.constant:
        memberData ??= _readMemberData();
        ir.ConstantExpression expression = _readTreeNode(memberData);
        ir.Constant constant =
            memberData.getConstantByIndex(expression, _sourceReader.readInt());
        return ConstantReference(expression, constant);
      case _TreeNodeKind.node:
        memberData ??= _readMemberData();
        int index = _sourceReader.readInt();
        ir.TreeNode treeNode = memberData.getTreeNodeByIndex(index);
        assert(
            treeNode != null,
            "No TreeNode found for index $index in "
            "${memberData.node}.${_sourceReader.errorContext}");
        return treeNode;
    }
    throw UnsupportedError("Unexpected _TreeNodeKind $kind");
  }

  /// Reads a reference to a potentially `null` kernel tree node from this data
  /// source.
  ir.TreeNode readTreeNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readTreeNode();
    }
    return null;
  }

  /// Reads a list of references to kernel tree nodes from this data source.
  /// If [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodes].
  List<E> readTreeNodes<E extends ir.TreeNode>({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNode();
      list[i] = node;
    }
    return list;
  }

  /// Reads a map from kernel tree nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMap].
  Map<K, V> readTreeNodeMap<K extends ir.TreeNode, V>(V f(),
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNode();
      V value = f();
      map[node] = value;
    }
    return map;
  }

  /// Reads a reference to a kernel tree node in the known [context] from this
  /// data source.
  ir.TreeNode readTreeNodeInContext() {
    return readTreeNodeInContextInternal(currentMemberData);
  }

  ir.TreeNode readTreeNodeInContextInternal(MemberData memberData) {
    _checkDataKind(DataKind.treeNode);
    return _readTreeNode(memberData);
  }

  /// Reads a reference to a potentially `null` kernel tree node in the known
  /// [context] from this data source.
  ir.TreeNode readTreeNodeOrNullInContext() {
    bool hasValue = readBool();
    if (hasValue) {
      return readTreeNodeInContextInternal(currentMemberData);
    }
    return null;
  }

  /// Reads a list of references to kernel tree nodes in the known [context]
  /// from this data source. If [emptyAsNull] is `true`, `null` is returned
  /// instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodesInContext].
  List<E> readTreeNodesInContext<E extends ir.TreeNode>(
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNodeInContextInternal(currentMemberData);
      list[i] = node;
    }
    return list;
  }

  /// Reads a map from kernel tree nodes to [V] values in the known [context]
  /// from this data source, calling [f] to read each value from the data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMapInContext].
  @override
  Map<K, V> readTreeNodeMapInContext<K extends ir.TreeNode, V>(V f()) {
    return readTreeNodeMapInContextOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from kernel tree nodes to [V] values in the known [context]
  /// from this data source, calling [f] to read each value from the data
  /// source. `null` is returned for an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMapInContext].
  @override
  Map<K, V> /*?*/ readTreeNodeMapInContextOrNull<K extends ir.TreeNode, V>(
      V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ir.TreeNode node = readTreeNodeInContextInternal(currentMemberData);
      V value = f();
      map[node] = value;
    }
    return map;
  }

  /// Reads a reference to a kernel type parameter node from this data source.
  ir.TypeParameter readTypeParameterNode() {
    _checkDataKind(DataKind.typeParameterNode);
    return _readTypeParameter(null);
  }

  ir.TypeParameter _readTypeParameter(MemberData memberData) {
    _TypeParameterKind kind = _sourceReader.readEnum(_TypeParameterKind.values);
    switch (kind) {
      case _TypeParameterKind.cls:
        ir.Class cls = _readClassData().node;
        return cls.typeParameters[_sourceReader.readInt()];
      case _TypeParameterKind.functionNode:
        ir.FunctionNode functionNode = _readFunctionNode(memberData);
        return functionNode.typeParameters[_sourceReader.readInt()];
    }
    throw UnsupportedError("Unexpected _TypeParameterKind kind $kind");
  }

  /// Reads a list of references to kernel type parameter nodes from this data
  /// source. If [emptyAsNull] is `true`, `null` is returned instead of an empty
  /// list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTypeParameterNodes].
  List<ir.TypeParameter> readTypeParameterNodes({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<ir.TypeParameter> list = List<ir.TypeParameter>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readTypeParameterNode();
    }
    return list;
  }

  /// Reads a type from this data source.
  @override
  DartType /*!*/ readDartType() {
    _checkDataKind(DataKind.dartType);
    final type = DartType.readFromDataSource(this, []);
    return interner?.internDartType(type) ?? type;
  }

  /// Reads a nullable type from this data source.
  @override
  DartType /*?*/ readDartTypeOrNull() {
    _checkDataKind(DataKind.dartType);
    return DartType.readFromDataSourceOrNull(this, []);
  }

  /// Reads a list of types from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypes].
  @override
  List<DartType> readDartTypes() {
    // Share the list when empty.
    return readDartTypesOrNull() ?? const [];
  }

  /// Reads a list of types from this data source. Returns `null` instead of an
  /// empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypes].
  @override
  List<DartType> /*?*/ readDartTypesOrNull() {
    int count = readInt();
    if (count == 0) return null;
    return List.generate(count, (_) => readDartType(), growable: false);
  }

  /// Reads a kernel type node from this data source. If [allowNull], the
  /// returned type is allowed to be `null`.
  @override
  ir.DartType /*!*/ readDartTypeNode() {
    _checkDataKind(DataKind.dartTypeNode);
    ir.DartType type = readDartTypeNodeOrNull();
    if (type == null) throw UnsupportedError('Unexpected `null` DartTypeNode');
    return type;
  }

  /// Reads a kernel type node from this data source. The returned type is
  /// allowed to be `null`.
  @override
  ir.DartType /*?*/ readDartTypeNodeOrNull() {
    _checkDataKind(DataKind.dartTypeNode);
    final type = _readDartTypeNode([]);
    return interner?.internDartTypeNode(type) ?? type;
  }

  ir.DartType _readDartTypeNode(List<ir.TypeParameter> functionTypeVariables) {
    DartTypeNodeKind kind = readEnum(DartTypeNodeKind.values);
    switch (kind) {
      case DartTypeNodeKind.none:
        return null;
      case DartTypeNodeKind.voidType:
        return const ir.VoidType();
      case DartTypeNodeKind.invalidType:
        return const ir.InvalidType();
      case DartTypeNodeKind.doesNotComplete:
        return const DoesNotCompleteType();
      case DartTypeNodeKind.neverType:
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        return ir.NeverType.fromNullability(nullability);
      case DartTypeNodeKind.typeParameterType:
        ir.TypeParameter typeParameter = readTypeParameterNode();
        ir.Nullability typeParameterTypeNullability =
            readEnum(ir.Nullability.values);
        ir.DartType promotedBound = _readDartTypeNode(functionTypeVariables);
        return ir.TypeParameterType(
            typeParameter, typeParameterTypeNullability, promotedBound);
      case DartTypeNodeKind.functionTypeVariable:
        int index = readInt();
        assert(0 <= index && index < functionTypeVariables.length);
        ir.Nullability typeParameterTypeNullability =
            readEnum(ir.Nullability.values);
        ir.DartType promotedBound = _readDartTypeNode(functionTypeVariables);
        return ir.TypeParameterType(functionTypeVariables[index],
            typeParameterTypeNullability, promotedBound);
      case DartTypeNodeKind.functionType:
        begin(functionTypeNodeTag);
        int typeParameterCount = readInt();
        List<ir.TypeParameter> typeParameters = List<ir.TypeParameter>.generate(
            typeParameterCount, (int index) => ir.TypeParameter());
        functionTypeVariables =
            List<ir.TypeParameter>.from(functionTypeVariables)
              ..addAll(typeParameters);
        for (int index = 0; index < typeParameterCount; index++) {
          typeParameters[index].name = readString();
          typeParameters[index].bound =
              _readDartTypeNode(functionTypeVariables);
          typeParameters[index].defaultType =
              _readDartTypeNode(functionTypeVariables);
        }
        ir.DartType returnType = _readDartTypeNode(functionTypeVariables);
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        int requiredParameterCount = readInt();
        List<ir.DartType> positionalParameters =
            _readDartTypeNodes(functionTypeVariables);
        int namedParameterCount = readInt();
        List<ir.NamedType> namedParameters =
            List<ir.NamedType>.filled(namedParameterCount, null);
        for (int index = 0; index < namedParameterCount; index++) {
          String name = readString();
          bool isRequired = readBool();
          ir.DartType type = _readDartTypeNode(functionTypeVariables);
          namedParameters[index] =
              ir.NamedType(name, type, isRequired: isRequired);
        }
        end(functionTypeNodeTag);
        return ir.FunctionType(positionalParameters, returnType, nullability,
            namedParameters: namedParameters,
            typeParameters: typeParameters,
            requiredParameterCount: requiredParameterCount);

      case DartTypeNodeKind.interfaceType:
        ir.Class cls = readClassNode();
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> typeArguments =
            _readDartTypeNodes(functionTypeVariables);
        return ir.InterfaceType(cls, nullability, typeArguments);
      case DartTypeNodeKind.thisInterfaceType:
        ir.Class cls = readClassNode();
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> typeArguments =
            _readDartTypeNodes(functionTypeVariables);
        return ThisInterfaceType(cls, nullability, typeArguments);
      case DartTypeNodeKind.exactInterfaceType:
        ir.Class cls = readClassNode();
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> typeArguments =
            _readDartTypeNodes(functionTypeVariables);
        return ExactInterfaceType(cls, nullability, typeArguments);
      case DartTypeNodeKind.typedef:
        ir.Typedef typedef = readTypedefNode();
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> typeArguments =
            _readDartTypeNodes(functionTypeVariables);
        return ir.TypedefType(typedef, nullability, typeArguments);
      case DartTypeNodeKind.dynamicType:
        return const ir.DynamicType();
      case DartTypeNodeKind.futureOrType:
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        ir.DartType typeArgument = _readDartTypeNode(functionTypeVariables);
        return ir.FutureOrType(typeArgument, nullability);
      case DartTypeNodeKind.nullType:
        return const ir.NullType();
    }
    throw UnsupportedError("Unexpected DartTypeKind $kind");
  }

  /// Reads a list of kernel type nodes from this data source. If [emptyAsNull]
  /// is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypeNodes].
  List<ir.DartType> readDartTypeNodes({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<ir.DartType> list = List<ir.DartType>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readDartTypeNode();
    }
    return list;
  }

  List<ir.DartType> _readDartTypeNodes(
      List<ir.TypeParameter> functionTypeVariables) {
    int count = readInt();
    if (count == 0) return emptyListOfDartTypes;
    List<ir.DartType> types =
        List<ir.DartType>.filled(count, const ir.InvalidType());
    for (int index = 0; index < count; index++) {
      types[index] = _readDartTypeNode(functionTypeVariables);
    }
    return types;
  }

  /// Reads a source span from this data source.
  SourceSpan readSourceSpan() {
    _checkDataKind(DataKind.sourceSpan);
    Uri uri = _readUri();
    int begin = _sourceReader.readInt();
    int end = _sourceReader.readInt();
    return SourceSpan(uri, begin, end);
  }

  /// Reads a reference to an indexed library from this data source.
  @override
  IndexedLibrary readLibrary() {
    return _entityReader.readLibraryFromDataSource(this, entityLookup);
  }

  /// Reads a reference to a potentially `null` indexed library from this data
  /// source.
  @override
  IndexedLibrary readLibraryOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLibrary();
    }
    return null;
  }

  /// Reads a library from library entities to [V] values
  /// from this data source, calling [f] to read each value from the data
  /// source. If [emptyAsNull] is `true`, `null` is returned instead of an empty
  /// map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLibraryMap].
  Map<K, V> readLibraryMap<K extends LibraryEntity, V>(V f(),
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      LibraryEntity library = readLibrary();
      V value = f();
      map[library] = value;
    }
    return map;
  }

  /// Reads a reference to an indexed class from this data source.
  @override
  IndexedClass readClass() {
    return _entityReader.readClassFromDataSource(this, entityLookup);
  }

  /// Reads a reference to a potentially `null` indexed class from this data
  /// source.
  @override
  IndexedClass readClassOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readClass();
    }
    return null;
  }

  /// Reads a list of references to indexed classes from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClasses].
  @override
  List<E> readClasses<E extends ClassEntity>() {
    return readClassesOrNull<E>() ?? List.empty();
  }

  /// Reads a list of references to indexed classes from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClasses].
  @override
  List<E> readClassesOrNull<E extends ClassEntity>() {
    int count = readInt();
    if (count == 0) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ClassEntity cls = readClass();
      list[i] = cls;
    }
    return list;
  }

  /// Reads a map from indexed classes to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClassMap].
  @override
  Map<K, V> readClassMap<K extends ClassEntity, V>(V f()) {
    return readClassMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from indexed classes to [V] values from this data source,
  /// calling [f] to read each value from the data source. `null` is returned if
  /// the map is empty.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClassMap].
  @override
  Map<K, V> /*?*/ readClassMapOrNull<K extends ClassEntity, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ClassEntity cls = readClass();
      V value = f();
      map[cls] = value;
    }
    return map;
  }

  /// Reads a reference to an indexed member from this data source.
  @override
  IndexedMember /*!*/ readMember() {
    return _entityReader.readMemberFromDataSource(this, entityLookup);
  }

  /// Reads a reference to a potentially `null` indexed member from this data
  /// source.
  @override
  IndexedMember readMemberOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readMember();
    }
    return null;
  }

  /// Reads a list of references to indexed members from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMembers].
  @override
  List<E /*!*/ > readMembers<E extends MemberEntity /*!*/ >() {
    return readMembersOrNull() ?? List.empty();
  }

  /// Reads a list of references to indexed members from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMembers].
  @override
  List<E /*!*/ > readMembersOrNull<E extends MemberEntity /*!*/ >() {
    int count = readInt();
    if (count == 0) return null;
    MemberEntity firstMember = readMember();
    List<E> list = List<E>.filled(count, firstMember);
    for (int i = 1; i < count; i++) {
      MemberEntity member = readMember();
      list[i] = member;
    }
    return list;
  }

  /// Reads a map from indexed members to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberMap].
  @override
  Map<K, V> readMemberMap<K extends MemberEntity, V>(V f(MemberEntity member)) {
    return readMemberMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from indexed members to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  /// `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberMap].
  @override
  Map<K, V> readMemberMapOrNull<K extends MemberEntity, V>(
      V f(MemberEntity member)) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      MemberEntity member = readMember();
      V value = f(member);
      map[member] = value;
    }
    return map;
  }

  /// Reads a reference to an indexed type variable from this data source.
  @override
  IndexedTypeVariable readTypeVariable() {
    return _entityReader.readTypeVariableFromDataSource(this, entityLookup);
  }

  /// Reads a map from indexed type variable to [V] values from this data
  /// source, calling [f] to read each value from the data source. If
  /// [emptyAsNull] is `true`, `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTypeVariableMap].
  Map<K, V> readTypeVariableMap<K extends IndexedTypeVariable, V>(V f(),
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      IndexedTypeVariable node = readTypeVariable();
      V value = f();
      map[node] = value;
    }
    return map;
  }

  /// Reads a reference to a local from this data source.
  Local readLocal() {
    LocalKind kind = readEnum(LocalKind.values);
    switch (kind) {
      case LocalKind.jLocal:
        MemberEntity memberContext = readMember();
        int localIndex = readInt();
        return localLookup.getLocalByIndex(memberContext, localIndex);
      case LocalKind.thisLocal:
        ClassEntity cls = readClass();
        return ThisLocal(cls);
      case LocalKind.boxLocal:
        ClassEntity cls = readClass();
        return BoxLocal(cls);
      case LocalKind.anonymousClosureLocal:
        ClassEntity cls = readClass();
        return AnonymousClosureLocal(cls);
      case LocalKind.typeVariableLocal:
        TypeVariableEntity typeVariable = readTypeVariable();
        return TypeVariableLocal(typeVariable);
    }
    throw UnsupportedError("Unexpected local kind $kind");
  }

  /// Reads a reference to a potentially `null` local from this data source.
  Local readLocalOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLocal();
    }
    return null;
  }

  /// Reads a list of references to locals from this data source. If
  /// [emptyAsNull] is `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLocals].
  List<E> readLocals<E extends Local>({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      Local local = readLocal();
      list[i] = local;
    }
    return list;
  }

  /// Reads a map from locals to [V] values from this data source, calling [f]
  /// to read each value from the data source. If [emptyAsNull] is `true`,
  /// `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLocalMap].
  Map<K, V> readLocalMap<K extends Local, V>(V f(),
      {bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      Local local = readLocal();
      V value = f();
      map[local] = value;
    }
    return map;
  }

  /// Reads a constant value from this data source.
  @override
  ConstantValue readConstant() {
    _checkDataKind(DataKind.constant);
    return _readConstant();
  }

  ConstantValue _readConstant() {
    return _constantIndex.read(_readConstantInternal);
  }

  ConstantValue _readConstantInternal() {
    ConstantValueKind kind = _sourceReader.readEnum(ConstantValueKind.values);
    switch (kind) {
      case ConstantValueKind.BOOL:
        bool value = readBool();
        return BoolConstantValue(value);
      case ConstantValueKind.INT:
        BigInt value = _readBigInt();
        return IntConstantValue(value);
      case ConstantValueKind.DOUBLE:
        double value = _readDoubleValue();
        return DoubleConstantValue(value);
      case ConstantValueKind.STRING:
        String value = readString();
        return StringConstantValue(value);
      case ConstantValueKind.NULL:
        return const NullConstantValue();
      case ConstantValueKind.FUNCTION:
        IndexedFunction function = readMember();
        DartType type = readDartType();
        return FunctionConstantValue(function, type);
      case ConstantValueKind.LIST:
        DartType type = readDartType();
        List<ConstantValue> entries = readConstants();
        return ListConstantValue(type, entries);
      case ConstantValueKind.SET:
        DartType type = readDartType();
        MapConstantValue entries = readConstant();
        return constant_system.JavaScriptSetConstant(type, entries);
      case ConstantValueKind.MAP:
        DartType type = readDartType();
        ListConstantValue keyList = readConstant();
        List<ConstantValue> values = readConstants();
        bool onlyStringKeys = readBool();
        return constant_system.JavaScriptMapConstant(
            type, keyList, values, onlyStringKeys);
      case ConstantValueKind.CONSTRUCTED:
        InterfaceType type = readDartType();
        Map<FieldEntity, ConstantValue> fields =
            readMemberMap<FieldEntity, ConstantValue>(
                (MemberEntity member) => readConstant());
        return ConstructedConstantValue(type, fields);
      case ConstantValueKind.TYPE:
        DartType representedType = readDartType();
        DartType type = readDartType();
        return TypeConstantValue(representedType, type);
      case ConstantValueKind.INSTANTIATION:
        List<DartType> typeArguments = readDartTypes();
        ConstantValue function = readConstant();
        return InstantiationConstantValue(typeArguments, function);
      case ConstantValueKind.NON_CONSTANT:
        return NonConstantValue();
      case ConstantValueKind.INTERCEPTOR:
        ClassEntity cls = readClass();
        return InterceptorConstantValue(cls);
      case ConstantValueKind.DEFERRED_GLOBAL:
        ConstantValue constant = readConstant();
        OutputUnit unit = readOutputUnitReference();
        return DeferredGlobalConstantValue(constant, unit);
      case ConstantValueKind.DUMMY_INTERCEPTOR:
        return DummyInterceptorConstantValue();
      case ConstantValueKind.LATE_SENTINEL:
        return LateSentinelConstantValue();
      case ConstantValueKind.UNREACHABLE:
        return UnreachableConstantValue();
      case ConstantValueKind.JS_NAME:
        js.LiteralString name = readJsNode();
        return JsNameConstantValue(name);
    }
    throw UnsupportedError("Unexpected constant value kind ${kind}.");
  }

  /// Reads a potentially `null` constant value from this data source.
  @override
  ConstantValue readConstantOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readConstant();
    }
    return null;
  }

  /// Reads a list of constant values from this data source. If [emptyAsNull] is
  /// `true`, `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstants].
  List<E> readConstants<E extends ConstantValue>({bool emptyAsNull = false}) {
    int count = readInt();
    if (count == 0 && emptyAsNull) return null;
    List<E> list = List<E>.filled(count, null);
    for (int i = 0; i < count; i++) {
      ConstantValue value = readConstant();
      list[i] = value;
    }
    return list;
  }

  /// Reads a map from constant values to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstantMap].
  @override
  Map<K, V> readConstantMap<K extends ConstantValue, V>(V f()) {
    return readConstantMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from constant values to [V] values from this data source,
  /// calling [f] to read each value from the data source. `null` is returned
  /// instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstantMap].
  @override
  Map<K, V> /*?*/ readConstantMapOrNull<K extends ConstantValue, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      ConstantValue key = readConstant();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  /// Reads a double value from this data source.
  double readDoubleValue() {
    _checkDataKind(DataKind.double);
    return _readDoubleValue();
  }

  double _readDoubleValue() {
    ByteData data = ByteData(8);
    data.setUint16(0, readInt());
    data.setUint16(2, readInt());
    data.setUint16(4, readInt());
    data.setUint16(6, readInt());
    return data.getFloat64(0);
  }

  /// Reads an integer of arbitrary value from this data source.
  ///
  /// This is should only when the value is not known to be a non-negative
  /// 30 bit integer. Otherwise [readInt] should be used.
  int readIntegerValue() {
    _checkDataKind(DataKind.int);
    return _readBigInt().toInt();
  }

  BigInt _readBigInt() {
    return BigInt.parse(readString());
  }

  @override
  ImportEntity readImport() {
    _checkDataKind(DataKind.import);
    return _readImport();
  }

  /// Reads a import from this data source.
  ImportEntity _readImport() {
    return _importIndex.read(_readImportInternal);
  }

  ImportEntity _readImportInternal() {
    String name = readStringOrNull();
    Uri uri = _readUri();
    Uri enclosingLibraryUri = _readUri();
    bool isDeferred = _readBool();
    return ImportEntity(isDeferred, name, uri, enclosingLibraryUri);
  }

  /// Reads a potentially `null` import from this data source.
  @override
  ImportEntity readImportOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readImport();
    }
    return null;
  }

  /// Reads a list of imports from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImports].
  @override
  List<ImportEntity> readImports() {
    return readImportsOrNull() ?? const [];
  }

  /// Reads a list of imports from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImports].
  @override
  List<ImportEntity> /*?*/ readImportsOrNull() {
    int count = readInt();
    if (count == 0) return null;
    List<ImportEntity> list = List<ImportEntity>.filled(count, null);
    for (int i = 0; i < count; i++) {
      list[i] = readImport();
    }
    return list;
  }

  /// Reads a map from imports to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImportMap].
  @override
  Map<ImportEntity, V> readImportMap<V>(V f()) {
    return readImportMapOrNull<V>(f) ?? {};
  }

  /// Reads a map from imports to [V] values from this data source, calling [f]
  /// to read each value from the data source. `null` is returned if the map is
  /// empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImportMap].
  @override
  Map<ImportEntity, V> /*?*/ readImportMapOrNull<V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<ImportEntity, V> map = {};
    for (int i = 0; i < count; i++) {
      ImportEntity key = readImport();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  /// Reads an [AbstractValue] from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  @override
  AbstractValue readAbstractValue() {
    assert(
        _codegenReader != null,
        "Can not deserialize an AbstractValue "
        "without a registered codegen reader.");
    return _codegenReader.readAbstractValue(this);
  }

  /// Reads a reference to an [OutputUnit] from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  OutputUnit readOutputUnitReference() {
    assert(
        _codegenReader != null,
        "Can not deserialize an OutputUnit reference "
        "without a registered codegen reader.");
    return _codegenReader.readOutputUnitReference(this);
  }

  /// Reads a [js.Node] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  js.Node readJsNode() {
    assert(_codegenReader != null,
        "Can not deserialize a JS node without a registered codegen reader.");
    return _codegenReader.readJsNode(this);
  }

  /// Reads a potentially `null` [js.Node] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  js.Node readJsNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readJsNode();
    }
    return null;
  }

  /// Reads a [TypeRecipe] value from this data source.
  ///
  /// This feature is only available a [CodegenReader] has been registered.
  TypeRecipe readTypeRecipe() {
    assert(_codegenReader != null,
        "Can not deserialize a TypeRecipe without a registered codegen reader.");
    return _codegenReader.readTypeRecipe(this);
  }

  MemberData _getMemberData(ir.Member node) {
    LibraryData libraryData =
        componentLookup.getLibraryDataByUri(node.enclosingLibrary.importUri);
    if (node.enclosingClass != null) {
      ClassData classData = libraryData.lookupClassByNode(node.enclosingClass);
      return classData.lookupMemberDataByNode(node);
    } else {
      return libraryData.lookupMemberDataByNode(node);
    }
  }

  ir.FunctionNode _readFunctionNode(MemberData memberData) {
    _FunctionNodeKind kind = _sourceReader.readEnum(_FunctionNodeKind.values);
    switch (kind) {
      case _FunctionNodeKind.procedure:
        ir.Procedure procedure = _readMemberData().node;
        return procedure.function;
      case _FunctionNodeKind.constructor:
        ir.Constructor constructor = _readMemberData().node;
        return constructor.function;
      case _FunctionNodeKind.functionExpression:
        ir.FunctionExpression functionExpression = _readTreeNode(memberData);
        return functionExpression.function;
      case _FunctionNodeKind.functionDeclaration:
        ir.FunctionDeclaration functionDeclaration = _readTreeNode(memberData);
        return functionDeclaration.function;
    }
    throw UnsupportedError("Unexpected _FunctionNodeKind $kind");
  }

  void _checkDataKind(DataKind expectedKind) {
    if (!useDataKinds) return;
    DataKind actualKind = _sourceReader.readEnum(DataKind.values);
    assert(
        actualKind == expectedKind,
        "Invalid data kind. "
        "Expected $expectedKind, "
        "found $actualKind.${_sourceReader.errorContext}");
  }
}
