// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Interface handling [DataSourceReader] low-level data deserialization.
///
/// Each implementation of [DataSource] should have a corresponding
/// [DataSink] for which it deserializes data.
abstract class DataSource {
  /// Deserialization of a section begin tag.
  void begin(String tag);

  /// Deserialization of a section end tag.
  void end(String tag);

  /// Deserialization of a string value.
  String readString();

  /// Deserialization of a non-negative integer value.
  int readInt();

  /// Deserialization of an enum value in [values].
  E readEnum<E>(List<E> values);

  /// Returns the offset for a deferred entity and skips it in the read queue.
  /// The offset can later be passed to [readAtOffset] to get the value.
  int readDeferred();

  /// Eagerly reads and returns the value for a deferred entity.
  E readDeferredAsEager<E>(E reader());

  /// Calls [reader] to read a value at the provided offset in the underlying
  /// data stream. Use with [readDeferred] to read a deferred value.
  E readAtOffset<E>(int offset, E reader());

  /// The length of the underlying data source.
  int get length;

  /// The current offset being read from.
  int get currentOffset;

  /// Returns a string representation of the current state of the data source
  /// useful for debugging in consistencies between serialization and
  /// deserialization.
  String get errorContext;
}

/// Deserialization reader
///
/// To be used with [DataSinkWriter] to read and write serialized data.
/// Deserialization format is deferred to provided [DataSource].
class DataSourceReader {
  // The active [DataSource] to read data from. This can be the base DataSource
  // for this reader or can be set to access data in a different serialized
  // input in the case of deferred indexed data.
  DataSource _sourceReader;

  static final List<ir.DartType> emptyListOfDartTypes =
      List<ir.DartType>.empty();

  final bool useDeferredStrategy;
  final bool useDataKinds;
  final ValueInterner? interner;
  final SerializationIndices importedIndices;
  ComponentLookup? _componentLookup;
  AbstractValueDomain? _abstractValueDomain;
  SourceLookup? _sourceLookup;

  late final IndexedSource<String> _stringIndex;
  late final IndexedSource<Uri> _uriIndex;
  late final IndexedSource<MemberData> _memberNodeIndex;
  late final IndexedSource<ImportEntity> _importIndex;
  late final IndexedSource<ConstantValue> _constantIndex;

  final Map<Type, IndexedSource> _generalCaches = {};

  ir.Member? _currentMemberContext;
  MemberData? _currentMemberData;

  int get currentOffset => _sourceReader.currentOffset;
  int get length => _sourceReader.length;

  /// Defines the beginning of this block in the address space created by all
  /// instances of [DataSourceReader].
  ///
  /// The amount by which the offsets for indexed values read by this reader are
  /// shifted. That is the length of all the sources read before this one.
  ///
  /// See [UnorderedIndexedSource] for more info.
  late int startOffset;

  DataSourceReader(
      this._sourceReader, CompilerOptions options, this.importedIndices,
      {this.useDataKinds = false,
      this.interner,
      this.useDeferredStrategy = false}) {
    startOffset = importedIndices.registerSource(this);
    _stringIndex = importedIndices.getIndexedSource<String>();
    _uriIndex = importedIndices.getIndexedSource<Uri>();
    _importIndex = importedIndices.getIndexedSource<ImportEntity>();
    _memberNodeIndex = importedIndices.getIndexedSource<MemberData>();
    _constantIndex = importedIndices.getIndexedSource<ConstantValue>();
  }

  /// Registers that the section [tag] starts.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void begin(String tag) {
    if (useDataKinds) _sourceReader.begin(tag);
  }

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
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
    return _componentLookup!;
  }

  void registerSourceLookup(SourceLookup sourceLookup) {
    assert(_sourceLookup == null);
    _sourceLookup = sourceLookup;
  }

  SourceLookup get sourceLookup => _sourceLookup!;

  /// Registers a [AbstractValueDomain] with this data source to support
  /// deserialization of abstract values.
  void registerAbstractValueDomain(AbstractValueDomain domain) {
    _abstractValueDomain = domain;
  }

  /// Evaluates [f] with [DataSource] for the provided [source] as the
  /// temporary [DataSource] for this object. Allows deferred data to be read
  /// from a file other than the one currently being read from.
  E readWithSource<E>(DataSourceReader source, E f()) {
    final lastSource = _sourceReader;
    final lastComponentLookup = _componentLookup;
    final lastStartOffset = startOffset;
    final lastAbstractValueDomain = _abstractValueDomain;
    _sourceReader = source._sourceReader;
    _componentLookup = source._componentLookup;
    startOffset = source.startOffset;
    _abstractValueDomain = source._abstractValueDomain;
    final value = f();
    _sourceReader = lastSource;
    _componentLookup = lastComponentLookup;
    startOffset = lastStartOffset;
    _abstractValueDomain = lastAbstractValueDomain;
    return value;
  }

  E readWithOffset<E>(int offset, E f()) {
    return _sourceReader.readAtOffset(offset, f);
  }

  Deferrable<E> readDeferrable<E>(E f(DataSourceReader source),
      {bool cacheData = true}) {
    return useDeferredStrategy
        ? Deferrable<E>.deferred(this, f, _sourceReader.readDeferred(),
            cacheData: cacheData)
        : Deferrable<E>.eager(_sourceReader.readDeferredAsEager(() => f(this)));
  }

  Deferrable<E> readDeferrableWithArg<E, A>(
      E f(DataSourceReader source, A arg), A arg,
      {bool cacheData = true}) {
    return useDeferredStrategy
        ? Deferrable.deferredWithArg<E, A>(
            this, f, arg, _sourceReader.readDeferred(), cacheData: cacheData)
        : Deferrable<E>.eager(
            _sourceReader.readDeferredAsEager(() => f(this, arg)));
  }

  /// Invoke [f] in the context of [member]. This sets up support for
  /// deserialization of `ir.TreeNode`s using the `readTreeNode*InContext`
  /// methods.
  T inMemberContext<T>(ir.Member? context, T f()) {
    ir.Member? oldMemberContext = _currentMemberContext;
    MemberData? oldMemberData = _currentMemberData;
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
    return _currentMemberData ??= _getMemberData(_currentMemberContext!);
  }

  /// Reads a reference to an [E] value from this data source. If the value has
  /// not yet been deserialized, [f] is called to deserialize the value itself.
  E readIndexed<E extends Object>(E f()) {
    E? value = readIndexedOrNull(f);
    if (value == null) throw StateError("Unexpected 'null' for $E");
    return value;
  }

  /// Reads a reference to an [E] value from this data source. [f] is called to
  /// deserialize the value at the relevant index. Use [readIndexed] if the value
  /// should be cached and all reads of the index should return the same object.
  E readIndexedNoCache<E extends Object>(E f()) {
    E? value = readIndexedOrNullNoCache(f);
    if (value == null) throw StateError("Unexpected 'null' for $E");
    return value;
  }

  /// Reads a reference to a nullable [E] value from this data source. If the
  /// value has not yet been deserialized, [f] is called to deserialize the
  /// value itself.
  E? readIndexedOrNull<E extends Object>(E f()) {
    IndexedSource<E> source = (_generalCaches[E] ??=
        importedIndices.getIndexedSource<E>()) as IndexedSource<E>;
    return source.read(this, f);
  }

  /// Reads a reference to a nullable [E] value from this data source. [f] is
  /// called to deserialize the value at the relevant index. Use
  /// [readIndexedOrNull] if the value should be cached and all reads of the
  /// index should return the same object.
  E? readIndexedOrNullNoCache<E extends Object>(E f()) {
    IndexedSource<E> source = (_generalCaches[E] ??=
        importedIndices.getIndexedSource<E>()) as IndexedSource<E>;
    return source.readWithoutCache(this, f);
  }

  /// Reads a potentially `null` [E] value from this data source, calling [f] to
  /// read the non-null value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeValueOrNull].
  E? readValueOrNull<E>(E f()) {
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
  List<E> readList<E>(E f()) {
    return readListOrNull<E>(f) ?? List<E>.empty();
  }

  /// Reads a list of [E] values from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeList].
  List<E>? readListOrNull<E>(E f()) {
    int count = readInt();
    if (count == 0) return null;
    return List<E>.generate(count, (_) => f(), growable: false);
  }

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
  int readInt() {
    _checkDataKind(DataKind.uint30);
    return _sourceReader.readInt();
  }

  /// Reads a potentially `null` non-negative integer value from this data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeIntOrNull].
  int? readIntOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readInt();
    }
    return null;
  }

  /// Reads a string value from this data source.
  String readString() {
    _checkDataKind(DataKind.string);
    return _readString();
  }

  String _readString() {
    // Cannot use a tear-off for `_sourceReader.readString` because the data
    // source may be different at the time of reading.
    return _stringIndex.read(this, () => _sourceReader.readString())!;
  }

  /// Reads a potentially `null` string value from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStringOrNull].
  String? readStringOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readString();
    }
    return null;
  }

  /// Reads a list of string values from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStrings].
  List<String> readStrings() {
    return readStringsOrNull() ?? const <String>[];
  }

  /// Reads a list of string values from this data source. If the list would be
  /// empty returns `null` instead.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStrings].
  List<String>? readStringsOrNull() {
    int count = readInt();
    if (count == 0) return null;
    return List.generate(count, (_) => readString(), growable: false);
  }

  /// Reads a map from [Name] values to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeNameMap].
  Map<Name, V> readNameMap<V>(V f()) {
    int count = readInt();
    Map<Name, V> map = {};
    for (int i = 0; i < count; i++) {
      Name key = readMemberName();
      V value = f();
      map[key] = value;
    }
    return map;
  }

  /// Reads a map from string values to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeStringMap].
  Map<String, V> readStringMap<V>(V f()) {
    int count = readInt();
    if (count == 0) return {};
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
  E readEnum<E>(List<E> values) {
    _checkDataKind(DataKind.enumValue);
    return _sourceReader.readEnum(values);
  }

  /// Reads a URI value from this data source.
  Uri readUri() {
    _checkDataKind(DataKind.uri);
    return _readUri();
  }

  Uri _readUri() {
    return _uriIndex.read(this, _doReadUri)!;
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
    return library.lookupClassByName(name)!;
  }

  /// Reads a reference to a kernel extension type declaration node from this
  /// data source.
  ir.ExtensionTypeDeclaration readExtensionTypeDeclarationNode() {
    _checkDataKind(DataKind.extensionTypeDeclarationNode);
    return _readExtensionTypeDeclarationNode();
  }

  ir.ExtensionTypeDeclaration _readExtensionTypeDeclarationNode() {
    LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupExtensionTypeDeclaration(name)!;
  }

  /// Reads a reference to a kernel typedef node from this data source.
  ir.Typedef readTypedefNode() {
    _checkDataKind(DataKind.typedefNode);
    return _readTypedefNode();
  }

  ir.Typedef _readTypedefNode() {
    LibraryData library = _readLibraryData();
    String name = _readString();
    return library.lookupTypedef(name)!;
  }

  /// Reads a reference to a kernel member node from this data source.
  ir.Member readMemberNode() {
    _checkDataKind(DataKind.memberNode);
    return _readMemberData().node;
  }

  MemberData _readMemberData() {
    return _memberNodeIndex.read(this, _readMemberDataInternal)!;
  }

  MemberData _readMemberDataInternal() {
    MemberContextKind kind = _sourceReader.readEnum(MemberContextKind.values);
    switch (kind) {
      case MemberContextKind.cls:
        ClassData cls = _readClassData();
        String name = _readString();
        return cls.lookupMemberDataByName(name)!;
      case MemberContextKind.library:
        LibraryData library = _readLibraryData();
        String name = _readString();
        return library.lookupMemberDataByName(name)!;
    }
  }

  /// Reads a list of references to kernel member nodes from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodes].
  List<E> readMemberNodes<E extends ir.Member>() {
    return readMemberNodesOrNull<E>() ?? List.empty();
  }

  /// Reads a list of references to kernel member nodes from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodes].
  List<E>? readMemberNodesOrNull<E extends ir.Member>() {
    int count = readInt();
    if (count == 0) return null;
    return List<E>.generate(count, (_) => readMemberNode() as E,
        growable: false);
  }

  /// Reads a map from kernel member nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodeMap].
  Map<K, V> readMemberNodeMap<K extends ir.Member, V>(V f()) {
    return readMemberNodeMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from kernel member nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source.  `null` is returned
  /// instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberNodeMap].
  Map<K, V>? readMemberNodeMapOrNull<K extends ir.Member, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final node = readMemberNode() as K;
      V value = f();
      map[node] = value;
    }
    return map;
  }

  /// Reads a kernel name node from this data source.
  ir.Name readName() {
    String text = readString();
    ir.Library? library = readValueOrNull(readLibraryNode);
    return ir.Name(text, library);
  }

  /// Reads a [Name] from this data source.
  Name readMemberName() {
    String text = readString();
    Uri? uri = readValueOrNull(readUri);
    bool setter = readBool();
    return Name(text, uri, isSetter: setter);
  }

  /// Reads a kernel library dependency node from this data source.
  ir.LibraryDependency readLibraryDependencyNode() {
    ir.Library library = readLibraryNode();
    int index = readInt();
    return library.dependencies[index];
  }

  /// Reads a potentially `null` kernel library dependency node from this data
  /// source.
  ir.LibraryDependency? readLibraryDependencyNodeOrNull() {
    return readValueOrNull(readLibraryDependencyNode);
  }

  /// Reads a reference to a kernel tree node from this data source.
  ir.TreeNode readTreeNode() {
    _checkDataKind(DataKind.treeNode);
    return _readTreeNode(null);
  }

  ir.TreeNode _readTreeNode(MemberData? memberData) {
    _TreeNodeKind kind = _sourceReader.readEnum(_TreeNodeKind.values);
    switch (kind) {
      case _TreeNodeKind.cls:
        return _readClassData().node;
      case _TreeNodeKind.member:
        return _readMemberData().node;
      case _TreeNodeKind.functionDeclarationVariable:
        final functionDeclaration =
            _readTreeNode(memberData) as ir.FunctionDeclaration;
        return functionDeclaration.variable;
      case _TreeNodeKind.functionNode:
        return _readFunctionNode(memberData);
      case _TreeNodeKind.typeParameter:
        return _readTypeParameter(memberData);
      case _TreeNodeKind.constant:
        memberData ??= _readMemberData();
        final expression = _readTreeNode(memberData) as ir.ConstantExpression;
        ir.Constant constant =
            memberData.getConstantByIndex(expression, _sourceReader.readInt());
        return ConstantReference(expression, constant);
      case _TreeNodeKind.node:
        memberData ??= _readMemberData();
        int index = _sourceReader.readInt();
        ir.TreeNode treeNode = memberData.getTreeNodeByIndex(index);
        return treeNode;
    }
  }

  /// Reads a reference to a potentially `null` kernel tree node from this data
  /// source.
  ir.TreeNode? readTreeNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readTreeNode();
    }
    return null;
  }

  /// Reads a list of references to kernel tree nodes from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodes].
  List<E> readTreeNodes<E extends ir.TreeNode>() {
    return readTreeNodesOrNull<E>() ?? List.empty();
  }

  /// Reads a list of references to kernel tree nodes from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodes].
  List<E>? readTreeNodesOrNull<E extends ir.TreeNode>() {
    int count = readInt();
    if (count == 0) return null;
    return List<E>.generate(count, (i) => readTreeNode() as E, growable: false);
  }

  /// Reads a map from kernel tree nodes to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMap].
  Map<K, V> readTreeNodeMap<K extends ir.TreeNode, V>(V f()) {
    return readTreeNodeMapOrNull(f) ?? <K, V>{};
  }

  Map<K, V>? readTreeNodeMapOrNull<K extends ir.TreeNode, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final node = readTreeNode() as K;
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
  ir.TreeNode? readTreeNodeOrNullInContext() {
    bool hasValue = readBool();
    if (hasValue) {
      return readTreeNodeInContextInternal(currentMemberData);
    }
    return null;
  }

  /// Reads a map from kernel tree nodes to [V] values in the known [context]
  /// from this data source, calling [f] to read each value from the data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMapInContext].
  Map<K, V> readTreeNodeMapInContext<K extends ir.TreeNode, V>(V f()) {
    return readTreeNodeMapInContextOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from kernel tree nodes to [V] values in the known [context]
  /// from this data source, calling [f] to read each value from the data
  /// source. `null` is returned for an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTreeNodeMapInContext].
  Map<K, V>? readTreeNodeMapInContextOrNull<K extends ir.TreeNode, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final node = readTreeNodeInContextInternal(currentMemberData) as K;
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

  ir.TypeParameter _readTypeParameter(MemberData? memberData) {
    _TypeParameterKind kind = _sourceReader.readEnum(_TypeParameterKind.values);
    switch (kind) {
      case _TypeParameterKind.cls:
        ir.Class cls = _readClassData().node;
        return cls.typeParameters[_sourceReader.readInt()];
      case _TypeParameterKind.functionNode:
        ir.FunctionNode functionNode = _readFunctionNode(memberData);
        return functionNode.typeParameters[_sourceReader.readInt()];
    }
  }

  /// Reads a list of references to kernel type parameter nodes from this data
  /// source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTypeParameterNodes].
  List<ir.TypeParameter> readTypeParameterNodes() {
    int count = readInt();
    return List<ir.TypeParameter>.generate(
        count, (index) => readTypeParameterNode(),
        growable: false);
  }

  /// Reads a type from this data source.
  DartType readDartType() {
    _checkDataKind(DataKind.dartType);
    final type = DartType.readFromDataSource(this, []);
    return interner?.internDartType(type) ?? type;
  }

  /// Reads a nullable type from this data source.
  DartType? readDartTypeOrNull() {
    _checkDataKind(DataKind.dartType);
    return DartType.readFromDataSourceOrNull(this, []);
  }

  /// Reads a list of types from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypes].
  List<DartType> readDartTypes() {
    // Share the list when empty.
    return readDartTypesOrNull() ?? const [];
  }

  /// Reads a list of types from this data source. Returns `null` instead of an
  /// empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypes].
  List<DartType>? readDartTypesOrNull() {
    int count = readInt();
    if (count == 0) return null;
    return List.generate(count, (_) => readDartType(), growable: false);
  }

  /// Reads a kernel type node from this data source. If [allowNull], the
  /// returned type is allowed to be `null`.
  ir.DartType readDartTypeNode() {
    _checkDataKind(DataKind.dartTypeNode);
    ir.DartType? type = _readDartTypeNodeOrNull();
    if (type == null) throw UnsupportedError('Unexpected `null` DartTypeNode');
    return type;
  }

  /// Reads a kernel type node from this data source. The returned type is
  /// allowed to be `null`.
  ir.DartType? readDartTypeNodeOrNull() {
    _checkDataKind(DataKind.dartTypeNode);
    return _readDartTypeNodeOrNull();
  }

  ir.DartType? _readDartTypeNodeOrNull() {
    final type = _readDartTypeNode([]);
    return interner?.internDartTypeNode(type) ?? type;
  }

  ir.DartType? _readDartTypeNode(
      List<ir.StructuralParameter> functionTypeVariables) {
    DartTypeNodeKind kind = readEnum(DartTypeNodeKind.values);
    switch (kind) {
      case DartTypeNodeKind.none:
        return null;
      case DartTypeNodeKind.voidType:
        return const ir.VoidType();
      case DartTypeNodeKind.invalidType:
        return const ir.InvalidType();
      case DartTypeNodeKind.neverType:
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        return ir.NeverType.fromNullability(nullability);
      case DartTypeNodeKind.typeParameterType:
        ir.TypeParameter typeParameter = readTypeParameterNode();
        ir.Nullability typeParameterTypeNullability =
            readEnum(ir.Nullability.values);
        ir.DartType? promotedBound = _readDartTypeNode(functionTypeVariables);
        ir.TypeParameterType typeParameterType =
            ir.TypeParameterType(typeParameter, typeParameterTypeNullability);
        if (promotedBound == null) {
          return typeParameterType;
        } else {
          return ir.IntersectionType(typeParameterType, promotedBound);
        }
      case DartTypeNodeKind.functionTypeVariable:
        int index = readInt();
        assert(0 <= index && index < functionTypeVariables.length);
        ir.Nullability typeParameterTypeNullability =
            readEnum(ir.Nullability.values);
        ir.StructuralParameterType typeParameterType =
            ir.StructuralParameterType(
                functionTypeVariables[index], typeParameterTypeNullability);
        return typeParameterType;
      case DartTypeNodeKind.functionType:
        begin(functionTypeNodeTag);
        int typeParameterCount = readInt();
        List<ir.StructuralParameter> typeParameters =
            List<ir.StructuralParameter>.generate(
                typeParameterCount, (int index) => ir.StructuralParameter(),
                growable: false);
        functionTypeVariables =
            List<ir.StructuralParameter>.from(functionTypeVariables)
              ..addAll(typeParameters);
        for (int index = 0; index < typeParameterCount; index++) {
          typeParameters[index].name = readString();
          typeParameters[index].bound =
              _readDartTypeNode(functionTypeVariables)!;
          typeParameters[index].defaultType =
              _readDartTypeNode(functionTypeVariables)!;
        }
        ir.DartType returnType = _readDartTypeNode(functionTypeVariables)!;
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        int requiredParameterCount = readInt();
        List<ir.DartType> positionalParameters =
            _readDartTypeNodes(functionTypeVariables);
        final namedParameters = _readNamedTypeNodes(functionTypeVariables);
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
      case DartTypeNodeKind.recordType:
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> positional =
            _readDartTypeNodes(functionTypeVariables);
        List<ir.NamedType> named = _readNamedTypeNodes(functionTypeVariables);
        return ir.RecordType(positional, named, nullability);
      case DartTypeNodeKind.extensionType:
        ir.ExtensionTypeDeclaration extensionTypeDeclaration =
            readExtensionTypeDeclarationNode();
        ir.Nullability nullability = readEnum(ir.Nullability.values);
        List<ir.DartType> typeArguments =
            _readDartTypeNodes(functionTypeVariables);
        return ir.ExtensionType(
            extensionTypeDeclaration, nullability, typeArguments);
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
        ir.DartType typeArgument = _readDartTypeNode(functionTypeVariables)!;
        return ir.FutureOrType(typeArgument, nullability);
      case DartTypeNodeKind.nullType:
        return const ir.NullType();
    }
  }

  List<ir.NamedType> _readNamedTypeNodes(
      List<ir.StructuralParameter> functionTypeVariables) {
    int count = readInt();
    if (count == 0) return const [];
    return List<ir.NamedType>.generate(count, (index) {
      String name = readString();
      bool isRequired = readBool();
      ir.DartType type = _readDartTypeNode(functionTypeVariables)!;
      return ir.NamedType(name, type, isRequired: isRequired);
    }, growable: false);
  }

  /// Reads a list of kernel type nodes from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypeNodes].
  List<ir.DartType> readDartTypeNodes() {
    return readDartTypeNodesOrNull() ?? const [];
  }

  /// Reads a list of kernel type nodes from this data source. `null` is
  /// returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeDartTypeNodes].
  List<ir.DartType>? readDartTypeNodesOrNull() {
    int count = readInt();
    if (count == 0) return null;
    return List<ir.DartType>.generate(count, (index) => readDartTypeNode(),
        growable: false);
  }

  List<ir.DartType> _readDartTypeNodes(
      List<ir.StructuralParameter> functionTypeVariables) {
    int count = readInt();
    if (count == 0) return emptyListOfDartTypes;
    return List<ir.DartType>.generate(
        count, (index) => _readDartTypeNode(functionTypeVariables)!,
        growable: false);
  }

  /// Reads a source span from this data source.
  SourceSpan readSourceSpan() {
    _checkDataKind(DataKind.sourceSpan);
    Uri uri = _readUri();
    int begin = _sourceReader.readInt();
    int end = _sourceReader.readInt();
    return SourceSpan(uri, begin, end);
  }

  /// Reads a reference to a library entity from this data source.
  LibraryEntity readLibrary() {
    return readIndexed<LibraryEntity>(() => JLibrary.readFromDataSource(this));
  }

  /// Reads a reference to a potentially `null` library entity from this data
  /// source.
  LibraryEntity? readLibraryOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLibrary();
    }
    return null;
  }

  /// Reads a library from library entities to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLibraryMap].
  Map<K, V> readLibraryMap<K extends LibraryEntity, V>(V f()) {
    return readLibraryMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a library from library entities to [V] values from this data source,
  /// calling [f] to read each value from the data source. `null` is returned
  /// instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLibraryMap].
  Map<K, V>? readLibraryMapOrNull<K extends LibraryEntity, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final library = readLibrary() as K;
      V value = f();
      map[library] = value;
    }
    return map;
  }

  /// Reads a reference to an class entity from this data source.
  ClassEntity readClass() {
    return readIndexed<ClassEntity>(() => JClass.readFromDataSource(this));
  }

  /// Reads a reference to a potentially `null` class entity from this data
  /// source.
  ClassEntity? readClassOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readClass();
    }
    return null;
  }

  /// Reads a list of references to class entities from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClasses].
  List<E> readClasses<E extends ClassEntity>() {
    return readClassesOrNull<E>() ?? List.empty();
  }

  /// Reads a list of references to class entities from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClasses].
  List<E>? readClassesOrNull<E extends ClassEntity>() {
    int count = readInt();
    if (count == 0) return null;
    return List<E>.generate(count, (index) => readClass() as E,
        growable: false);
  }

  /// Reads a map from class entities to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClassMap].
  Map<K, V> readClassMap<K extends ClassEntity, V>(V f()) {
    return readClassMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from class entities to [V] values from this data source,
  /// calling [f] to read each value from the data source. `null` is returned if
  /// the map is empty.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeClassMap].
  Map<K, V>? readClassMapOrNull<K extends ClassEntity, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final cls = readClass() as K;
      V value = f();
      map[cls] = value;
    }
    return map;
  }

  /// Reads a reference to an member entity from this data source.
  MemberEntity readMember() {
    return readIndexed<MemberEntity>(() => JMember.readFromDataSource(this));
  }

  /// Reads a reference to a potentially `null` member entity from this data
  /// source.
  MemberEntity? readMemberOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readMember();
    }
    return null;
  }

  /// Reads a list of references to member entities from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMembers].
  List<E> readMembers<E extends MemberEntity>() {
    return readMembersOrNull() ?? List.empty();
  }

  /// Reads a list of references to member entities from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMembers].
  List<E>? readMembersOrNull<E extends MemberEntity>() {
    int count = readInt();
    if (count == 0) return null;
    return List<E>.generate(count, (index) => readMember() as E,
        growable: false);
  }

  /// Reads a map from member entities to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberMap].
  Map<K, V> readMemberMap<K extends MemberEntity, V>(V f(MemberEntity member)) {
    return readMemberMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from member entities to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  /// `null` is returned instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeMemberMap].
  Map<K, V>? readMemberMapOrNull<K extends MemberEntity, V>(
      V f(MemberEntity member)) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final member = readMember() as K;
      V value = f(member);
      map[member] = value;
    }
    return map;
  }

  /// Reads a reference to an type variable entity from this data source.
  TypeVariableEntity readTypeVariable() {
    return readIndexed<TypeVariableEntity>(
        () => JTypeVariable.readFromDataSource(this));
  }

  /// Reads a map from type variable entities to [V] values from this data
  /// source, calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeTypeVariableMap].
  Map<K, V> readTypeVariableMap<K extends TypeVariableEntity, V>(V f()) {
    int count = readInt();
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final node = readTypeVariable() as K;
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
        return readIndexed<Local>(() => JLocal.readFromDataSource(this));
      case LocalKind.thisLocal:
        ClassEntity cls = readClass();
        return ThisLocal(cls);
      case LocalKind.boxLocal:
        ClassEntity cls = readClass();
        return BoxLocal(cls);
      case LocalKind.anonymousClosureLocal:
        final cls = readClass() as JClosureClass;
        return AnonymousClosureLocal(cls);
      case LocalKind.typeVariableLocal:
        TypeVariableEntity typeVariable = readTypeVariable();
        return TypeVariableLocal(typeVariable);
    }
  }

  /// Reads a reference to a potentially `null` local from this data source.
  Local? readLocalOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readLocal();
    }
    return null;
  }

  /// Reads a map from locals to [V] values from this data source, calling [f]
  /// to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeLocalMap].
  Map<K, V> readLocalMap<K extends Local, V>(V f()) {
    int count = readInt();
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final local = readLocal() as K;
      V value = f();
      map[local] = value;
    }
    return map;
  }

  /// Reads a constant value from this data source.
  ConstantValue readConstant() {
    _checkDataKind(DataKind.constant);
    return _readConstant();
  }

  ConstantValue _readConstant() {
    return _constantIndex.read(this, _readConstantInternal)!;
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
        final function = readMember() as FunctionEntity;
        final type = readDartType() as FunctionType;
        return FunctionConstantValue(function, type);
      case ConstantValueKind.LIST:
        final type = readDartType() as InterfaceType;
        final entries = readConstants();
        return ListConstantValue(type, entries);
      case ConstantValueKind.SET:
        final type = readDartType() as InterfaceType;
        final values = readConstants();
        final indexObject =
            readConstantOrNull() as JavaScriptObjectConstantValue?;
        return constant_system.JavaScriptSetConstant(type, values, indexObject);
      case ConstantValueKind.MAP:
        final type = readDartType() as InterfaceType;
        final keyList = readConstant() as ListConstantValue;
        final valueList = readConstant() as ListConstantValue;
        bool onlyStringKeys = readBool();
        final indexObject = onlyStringKeys
            ? readConstant() as JavaScriptObjectConstantValue
            : null;
        return constant_system.JavaScriptMapConstant(
            type, keyList, valueList, onlyStringKeys, indexObject);
      case ConstantValueKind.CONSTRUCTED:
        final type = readDartType() as InterfaceType;
        Map<FieldEntity, ConstantValue> fields =
            readMemberMap<FieldEntity, ConstantValue>(
                (MemberEntity member) => readConstant());
        return ConstructedConstantValue(type, fields);
      case ConstantValueKind.RECORD:
        final shape = RecordShape.readFromDataSource(this);
        final values = readConstants();
        return RecordConstantValue(shape, values);
      case ConstantValueKind.TYPE:
        final representedType = readDartType();
        final type = readDartType() as InterfaceType;
        return TypeConstantValue(representedType, type);
      case ConstantValueKind.INSTANTIATION:
        List<DartType> typeArguments = readDartTypes();
        final function = readConstant() as FunctionConstantValue;
        return InstantiationConstantValue(typeArguments, function);
      case ConstantValueKind.INTERCEPTOR:
        ClassEntity cls = readClass();
        return InterceptorConstantValue(cls);
      case ConstantValueKind.JAVASCRIPT_OBJECT:
        final keys = readConstants();
        final values = readConstants();
        return JavaScriptObjectConstantValue(keys, values);
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
        final name = readJsNode() as js.LiteralString;
        return JsNameConstantValue(name);
    }
  }

  /// Reads a potentially `null` constant value from this data source.
  ConstantValue? readConstantOrNull() {
    bool hasClass = readBool();
    if (hasClass) {
      return readConstant();
    }
    return null;
  }

  /// Reads a list of constant values from this data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstants].
  List<E> readConstants<E extends ConstantValue>() {
    int count = readInt();
    return List<E>.generate(count, (index) => readConstant() as E,
        growable: false);
  }

  /// Reads a map from constant values to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstantMap].
  Map<K, V> readConstantMap<K extends ConstantValue, V>(V f()) {
    return readConstantMapOrNull<K, V>(f) ?? {};
  }

  /// Reads a map from constant values to [V] values from this data source,
  /// calling [f] to read each value from the data source. `null` is returned
  /// instead of an empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeConstantMap].
  Map<K, V>? readConstantMapOrNull<K extends ConstantValue, V>(V f()) {
    int count = readInt();
    if (count == 0) return null;
    Map<K, V> map = {};
    for (int i = 0; i < count; i++) {
      final key = readConstant() as K;
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

  ImportEntity readImport() {
    _checkDataKind(DataKind.import);
    return _readImport();
  }

  /// Reads a import from this data source.
  ImportEntity _readImport() {
    return _importIndex.read(this, _readImportInternal)!;
  }

  ImportEntity _readImportInternal() {
    String? name = readStringOrNull();
    Uri uri = _readUri();
    Uri enclosingLibraryUri = _readUri();
    bool isDeferred = _readBool();
    return ImportEntity(isDeferred, name, uri, enclosingLibraryUri);
  }

  /// Reads a potentially `null` import from this data source.
  ImportEntity? readImportOrNull() {
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
  List<ImportEntity> readImports() {
    return readImportsOrNull() ?? const [];
  }

  /// Reads a list of imports from this data source.
  /// `null` is returned instead of an empty list.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImports].
  List<ImportEntity>? readImportsOrNull() {
    int count = readInt();
    if (count == 0) return null;
    return List<ImportEntity>.generate(count, (index) => readImport(),
        growable: false);
  }

  /// Reads a map from imports to [V] values from this data source,
  /// calling [f] to read each value from the data source.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImportMap].
  Map<ImportEntity, V> readImportMap<V>(V f()) {
    return readImportMapOrNull<V>(f) ?? {};
  }

  /// Reads a map from imports to [V] values from this data source, calling [f]
  /// to read each value from the data source. `null` is returned if the map is
  /// empty map.
  ///
  /// This is a convenience method to be used together with
  /// [DataSinkWriter.writeImportMap].
  Map<ImportEntity, V>? readImportMapOrNull<V>(V f()) {
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
  AbstractValue readAbstractValue() {
    assert(
        _abstractValueDomain != null,
        "Can not deserialize an AbstractValue "
        "without a registered AbstractValueDomain.");
    return _abstractValueDomain!.readAbstractValueFromDataSource(this);
  }

  /// Reads a reference to an [OutputUnit] from this data source.
  OutputUnit readOutputUnitReference() {
    return readIndexed<OutputUnit>(() => OutputUnit.readFromDataSource(this));
  }

  /// Reads a [js.Node] value from this data source.
  js.Node readJsNode() {
    return JsNodeDeserializer.readFromDataSource(this);
  }

  /// Reads a potentially `null` [js.Node] value from this data source.
  js.Node? readJsNodeOrNull() {
    bool hasValue = readBool();
    if (hasValue) {
      return readJsNode();
    }
    return null;
  }

  /// Reads a [TypeRecipe] value from this data source.
  TypeRecipe readTypeRecipe() {
    return TypeRecipe.readFromDataSource(this);
  }

  MemberData _getMemberData(ir.Member node) {
    LibraryData libraryData =
        componentLookup.getLibraryDataByUri(node.enclosingLibrary.importUri);
    if (node.enclosingClass != null) {
      final classData = libraryData.lookupClassByNode(node.enclosingClass!)!;
      return classData.lookupMemberDataByNode(node)!;
    } else {
      return libraryData.lookupMemberDataByNode(node)!;
    }
  }

  ir.FunctionNode _readFunctionNode(MemberData? memberData) {
    _FunctionNodeKind kind = _sourceReader.readEnum(_FunctionNodeKind.values);
    switch (kind) {
      case _FunctionNodeKind.procedure:
        final procedure = _readMemberData().node as ir.Procedure;
        return procedure.function;
      case _FunctionNodeKind.constructor:
        final constructor = _readMemberData().node as ir.Constructor;
        return constructor.function;
      case _FunctionNodeKind.functionExpression:
        final functionExpression =
            _readTreeNode(memberData) as ir.FunctionExpression;
        return functionExpression.function;
      case _FunctionNodeKind.functionDeclaration:
        final functionDeclaration =
            _readTreeNode(memberData) as ir.FunctionDeclaration;
        return functionDeclaration.function;
    }
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
