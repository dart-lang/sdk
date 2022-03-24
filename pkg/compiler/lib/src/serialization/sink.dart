// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'serialization.dart';

/// Interface handling [DataSink] low-level data serialization.
///
/// Each implementation of [SinkWriter] should have a corresponding
/// [SourceReader] that deserializes data serialized by that implementation.
abstract class SinkWriter {
  int get length;

  /// Serialization of a non-negative integer value.
  void writeInt(int value);

  /// Serialization of an enum value.
  void writeEnum(dynamic value);

  /// Serialization of a String value.
  void writeString(String value);

  /// Serialization of a section begin tag. May be omitted by some writers.
  void beginTag(String tag);

  /// Serialization of a section end tag. May be omitted by some writers.
  void endTag(String tag);

  /// Closes any underlying data sinks.
  void close();
}

/// Serialization writer
///
/// To be used with [DataSource] to read and write serialized data.
/// Serialization format is deferred to provided [SinkWriter].
class DataSink {
  final SinkWriter _sinkWriter;

  /// If `true`, serialization of every data kind is preceded by a [DataKind]
  /// value.
  ///
  /// This is used for debugging data inconsistencies between serialization
  /// and deserialization.
  final bool useDataKinds;
  DataSourceIndices importedIndices;

  /// Visitor used for serializing [ir.DartType]s.
  DartTypeNodeWriter _dartTypeNodeWriter;

  /// Stack of tags used when [useDataKinds] is `true` to help debugging section
  /// inconsistencies between serialization and deserialization.
  List<String> _tags;

  /// Map of [_MemberData] object for serialized kernel member nodes.
  final Map<ir.Member, _MemberData> _memberData = {};

  IndexedSink<String> _stringIndex;
  IndexedSink<Uri> _uriIndex;
  IndexedSink<ir.Member> _memberNodeIndex;
  IndexedSink<ImportEntity> _importIndex;
  IndexedSink<ConstantValue> _constantIndex;

  final Map<Type, IndexedSink> _generalCaches = {};

  EntityWriter _entityWriter = const EntityWriter();
  CodegenWriter _codegenWriter;

  final Map<String, int> tagFrequencyMap;

  ir.Member _currentMemberContext;
  _MemberData _currentMemberData;

  IndexedSink<T> _createSink<T>() {
    if (importedIndices == null || !importedIndices.caches.containsKey(T)) {
      return IndexedSink<T>(this._sinkWriter);
    } else {
      Map<T, int> cacheCopy = Map.from(importedIndices.caches[T].cache);
      return IndexedSink<T>(this._sinkWriter, cache: cacheCopy);
    }
  }

  DataSink(this._sinkWriter,
      {this.useDataKinds = false, this.tagFrequencyMap, this.importedIndices}) {
    _dartTypeNodeWriter = DartTypeNodeWriter(this);
    _stringIndex = _createSink<String>();
    _uriIndex = _createSink<Uri>();
    _memberNodeIndex = _createSink<ir.Member>();
    _importIndex = _createSink<ImportEntity>();
    _constantIndex = _createSink<ConstantValue>();
  }

  /// The amount of data written to this data sink.
  ///
  /// The units is based on the underlying data structure for this data sink.
  int get length => _sinkWriter.length;

  /// Flushes any pending data and closes this data sink.
  ///
  /// The data sink can no longer be written to after closing.
  void close() {
    _sinkWriter.close();
  }

  void begin(String tag) {
    if (tagFrequencyMap != null) {
      tagFrequencyMap[tag] ??= 0;
      tagFrequencyMap[tag]++;
    }
    if (useDataKinds) {
      _tags ??= <String>[];
      _tags.add(tag);
      _sinkWriter.beginTag(tag);
    }
  }

  void end(Object tag) {
    if (useDataKinds) {
      _sinkWriter.endTag(tag);

      String existingTag = _tags.removeLast();
      assert(existingTag == tag,
          "Unexpected tag end. Expected $existingTag, found $tag.");
    }
  }

  void inMemberContext(ir.Member context, void f()) {
    ir.Member oldMemberContext = _currentMemberContext;
    _MemberData oldMemberData = _currentMemberData;
    _currentMemberContext = context;
    _currentMemberData = null;
    f();
    _currentMemberData = oldMemberData;
    _currentMemberContext = oldMemberContext;
  }

  _MemberData get currentMemberData {
    assert(_currentMemberContext != null,
        "DataSink has no current member context.");
    return _currentMemberData ??= _memberData[_currentMemberContext] ??=
        _MemberData(_currentMemberContext);
  }

  void writeCached<E>(E value, void f(E value)) {
    IndexedSink sink = _generalCaches[E] ??= _createSink<E>();
    sink.write(value, (v) => f(v));
  }

  void writeSourceSpan(SourceSpan value) {
    _writeDataKind(DataKind.sourceSpan);
    _writeUri(value.uri);
    _sinkWriter.writeInt(value.begin);
    _sinkWriter.writeInt(value.end);
  }

  void writeDartType(DartType value, {bool allowNull = false}) {
    _writeDataKind(DataKind.dartType);
    _writeDartType(value, [], allowNull: allowNull);
  }

  void _writeDartType(
      DartType value, List<FunctionTypeVariable> functionTypeVariables,
      {bool allowNull = false}) {
    if (value == null) {
      if (!allowNull) {
        throw UnsupportedError("Missing DartType is not allowed.");
      }
      writeEnum(DartTypeKind.none);
    } else {
      value.writeToDataSink(this, functionTypeVariables);
    }
  }

  void writeDartTypeNode(ir.DartType value, {bool allowNull = false}) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: allowNull);
  }

  void _writeDartTypeNode(
      ir.DartType value, List<ir.TypeParameter> functionTypeVariables,
      {bool allowNull = false}) {
    if (value == null) {
      if (!allowNull) {
        throw UnsupportedError("Missing ir.DartType node is not allowed.");
      }
      writeEnum(DartTypeNodeKind.none);
    } else {
      value.accept1(_dartTypeNodeWriter, functionTypeVariables);
    }
  }

  void writeMemberNode(ir.Member value) {
    _writeDataKind(DataKind.memberNode);
    _writeMemberNode(value);
  }

  void _writeMemberNode(ir.Member value) {
    _memberNodeIndex.write(value, _writeMemberNodeInternal);
  }

  void _writeMemberNodeInternal(ir.Member value) {
    ir.Class cls = value.enclosingClass;
    if (cls != null) {
      _sinkWriter.writeEnum(MemberContextKind.cls);
      _writeClassNode(cls);
      _writeString(_computeMemberName(value));
    } else {
      _sinkWriter.writeEnum(MemberContextKind.library);
      _writeLibraryNode(value.enclosingLibrary);
      _writeString(_computeMemberName(value));
    }
  }

  void writeClassNode(ir.Class value) {
    _writeDataKind(DataKind.classNode);
    _writeClassNode(value);
  }

  void _writeClassNode(ir.Class value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  void writeTypedefNode(ir.Typedef value) {
    _writeDataKind(DataKind.typedefNode);
    _writeTypedefNode(value);
  }

  void _writeTypedefNode(ir.Typedef value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  void writeLibraryNode(ir.Library value) {
    _writeDataKind(DataKind.libraryNode);
    _writeLibraryNode(value);
  }

  void _writeLibraryNode(ir.Library value) {
    _writeUri(value.importUri);
  }

  void writeEnum(dynamic value) {
    _writeDataKind(DataKind.enumValue);
    _sinkWriter.writeEnum(value);
  }

  void writeBool(bool value) {
    assert(value != null);
    _writeDataKind(DataKind.bool);
    _writeBool(value);
  }

  void _writeBool(bool value) {
    _sinkWriter.writeInt(value ? 1 : 0);
  }

  void writeUri(Uri value) {
    assert(value != null);
    _writeDataKind(DataKind.uri);
    _writeUri(value);
  }

  void writeString(String value) {
    assert(value != null);
    _writeDataKind(DataKind.string);
    _writeString(value);
  }

  void writeInt(int value) {
    assert(value != null);
    assert(value >= 0 && value >> 30 == 0);
    _writeDataKind(DataKind.uint30);
    _sinkWriter.writeInt(value);
  }

  void writeTreeNode(ir.TreeNode value) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, null);
  }

  void writeTreeNodeInContext(ir.TreeNode value) {
    writeTreeNodeInContextInternal(value, currentMemberData);
  }

  void writeTreeNodeInContextInternal(
      ir.TreeNode value, _MemberData memberData) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, memberData);
  }

  void writeTreeNodeOrNullInContext(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNodeInContextInternal(value, currentMemberData);
    }
  }

  void writeTreeNodesInContext(Iterable<ir.TreeNode> values,
      {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TreeNode value in values) {
        writeTreeNodeInContextInternal(value, currentMemberData);
      }
    }
  }

  void writeTreeNodeMapInContext<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.TreeNode key, V value) {
        writeTreeNodeInContextInternal(key, currentMemberData);
        f(value);
      });
    }
  }

  _MemberData _getMemberData(ir.TreeNode node) {
    ir.TreeNode member = node;
    while (member is! ir.Member) {
      if (member == null) {
        throw UnsupportedError("No enclosing member of TreeNode "
            "$node (${node.runtimeType})");
      }
      member = member.parent;
    }
    _writeMemberNode(member);
    return _memberData[member] ??= _MemberData(member);
  }

  void _writeTreeNode(ir.TreeNode value, _MemberData memberData) {
    if (value is ir.Class) {
      _sinkWriter.writeEnum(_TreeNodeKind.cls);
      _writeClassNode(value);
    } else if (value is ir.Member) {
      _sinkWriter.writeEnum(_TreeNodeKind.member);
      _writeMemberNode(value);
    } else if (value is ir.VariableDeclaration &&
        value.parent is ir.FunctionDeclaration) {
      _sinkWriter.writeEnum(_TreeNodeKind.functionDeclarationVariable);
      _writeTreeNode(value.parent, memberData);
    } else if (value is ir.FunctionNode) {
      _sinkWriter.writeEnum(_TreeNodeKind.functionNode);
      _writeFunctionNode(value, memberData);
    } else if (value is ir.TypeParameter) {
      _sinkWriter.writeEnum(_TreeNodeKind.typeParameter);
      _writeTypeParameter(value, memberData);
    } else if (value is ConstantReference) {
      _sinkWriter.writeEnum(_TreeNodeKind.constant);
      memberData ??= _getMemberData(value.expression);
      _writeTreeNode(value.expression, memberData);
      int index =
          memberData.getIndexByConstant(value.expression, value.constant);
      _sinkWriter.writeInt(index);
    } else {
      _sinkWriter.writeEnum(_TreeNodeKind.node);
      memberData ??= _getMemberData(value);
      int index = memberData.getIndexByTreeNode(value);
      assert(
          index != null,
          "No TreeNode index found for ${value.runtimeType} "
          "found in ${memberData}.");
      _sinkWriter.writeInt(index);
    }
  }

  void _writeFunctionNode(ir.FunctionNode value, _MemberData memberData) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Procedure) {
      _sinkWriter.writeEnum(_FunctionNodeKind.procedure);
      _writeMemberNode(parent);
    } else if (parent is ir.Constructor) {
      _sinkWriter.writeEnum(_FunctionNodeKind.constructor);
      _writeMemberNode(parent);
    } else if (parent is ir.FunctionExpression) {
      _sinkWriter.writeEnum(_FunctionNodeKind.functionExpression);
      _writeTreeNode(parent, memberData);
    } else if (parent is ir.FunctionDeclaration) {
      _sinkWriter.writeEnum(_FunctionNodeKind.functionDeclaration);
      _writeTreeNode(parent, memberData);
    } else {
      throw UnsupportedError(
          "Unsupported FunctionNode parent ${parent.runtimeType}");
    }
  }

  void writeTypeParameterNode(ir.TypeParameter value) {
    _writeDataKind(DataKind.typeParameterNode);
    _writeTypeParameter(value, null);
  }

  void _writeTypeParameter(ir.TypeParameter value, _MemberData memberData) {
    ir.TreeNode parent = value.parent;
    if (parent is ir.Class) {
      _sinkWriter.writeEnum(_TypeParameterKind.cls);
      _writeClassNode(parent);
      _sinkWriter.writeInt(parent.typeParameters.indexOf(value));
    } else if (parent is ir.FunctionNode) {
      _sinkWriter.writeEnum(_TypeParameterKind.functionNode);
      _writeFunctionNode(parent, memberData);
      _sinkWriter.writeInt(parent.typeParameters.indexOf(value));
    } else {
      throw UnsupportedError(
          "Unsupported TypeParameter parent ${parent.runtimeType}");
    }
  }

  void _writeDataKind(DataKind kind) {
    if (useDataKinds) _sinkWriter.writeEnum(kind);
  }

  void writeLibrary(IndexedLibrary value) {
    _entityWriter.writeLibraryToDataSink(this, value);
  }

  void writeClass(IndexedClass value) {
    _entityWriter.writeClassToDataSink(this, value);
  }

  void writeMember(IndexedMember value) {
    _entityWriter.writeMemberToDataSink(this, value);
  }

  void writeTypeVariable(IndexedTypeVariable value) {
    _entityWriter.writeTypeVariableToDataSink(this, value);
  }

  void writeLocal(Local local) {
    if (local is JLocal) {
      writeEnum(LocalKind.jLocal);
      writeMember(local.memberContext);
      writeInt(local.localIndex);
    } else if (local is ThisLocal) {
      writeEnum(LocalKind.thisLocal);
      writeClass(local.enclosingClass);
    } else if (local is BoxLocal) {
      writeEnum(LocalKind.boxLocal);
      writeClass(local.container);
    } else if (local is AnonymousClosureLocal) {
      writeEnum(LocalKind.anonymousClosureLocal);
      writeClass(local.closureClass);
    } else if (local is TypeVariableLocal) {
      writeEnum(LocalKind.typeVariableLocal);
      writeTypeVariable(local.typeVariable);
    } else {
      throw UnsupportedError("Unsupported local ${local.runtimeType}");
    }
  }

  void writeConstant(ConstantValue value) {
    _writeDataKind(DataKind.constant);
    _writeConstant(value);
  }

  void writeDoubleValue(double value) {
    _writeDataKind(DataKind.double);
    _writeDoubleValue(value);
  }

  void _writeDoubleValue(double value) {
    ByteData data = ByteData(8);
    data.setFloat64(0, value);
    writeInt(data.getUint16(0));
    writeInt(data.getUint16(2));
    writeInt(data.getUint16(4));
    writeInt(data.getUint16(6));
  }

  void writeIntegerValue(int value) {
    _writeDataKind(DataKind.int);
    _writeBigInt(BigInt.from(value));
  }

  void _writeBigInt(BigInt value) {
    writeString(value.toString());
  }

  void _writeConstant(ConstantValue value) {
    _constantIndex.write(value, _writeConstantInternal);
  }

  void _writeConstantInternal(ConstantValue value) {
    _sinkWriter.writeEnum(value.kind);
    switch (value.kind) {
      case ConstantValueKind.BOOL:
        BoolConstantValue constant = value;
        writeBool(constant.boolValue);
        break;
      case ConstantValueKind.INT:
        IntConstantValue constant = value;
        _writeBigInt(constant.intValue);
        break;
      case ConstantValueKind.DOUBLE:
        DoubleConstantValue constant = value;
        _writeDoubleValue(constant.doubleValue);
        break;
      case ConstantValueKind.STRING:
        StringConstantValue constant = value;
        writeString(constant.stringValue);
        break;
      case ConstantValueKind.NULL:
        break;
      case ConstantValueKind.FUNCTION:
        FunctionConstantValue constant = value;
        IndexedFunction function = constant.element;
        writeMember(function);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.LIST:
        ListConstantValue constant = value;
        writeDartType(constant.type);
        writeConstants(constant.entries);
        break;
      case ConstantValueKind.SET:
        constant_system.JavaScriptSetConstant constant = value;
        writeDartType(constant.type);
        writeConstant(constant.entries);
        break;
      case ConstantValueKind.MAP:
        constant_system.JavaScriptMapConstant constant = value;
        writeDartType(constant.type);
        writeConstant(constant.keyList);
        writeConstants(constant.values);
        writeBool(constant.onlyStringKeys);
        break;
      case ConstantValueKind.CONSTRUCTED:
        ConstructedConstantValue constant = value;
        writeDartType(constant.type);
        writeMemberMap(constant.fields,
            (MemberEntity member, ConstantValue value) => writeConstant(value));
        break;
      case ConstantValueKind.TYPE:
        TypeConstantValue constant = value;
        writeDartType(constant.representedType);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.INSTANTIATION:
        InstantiationConstantValue constant = value;
        writeDartTypes(constant.typeArguments);
        writeConstant(constant.function);
        break;
      case ConstantValueKind.NON_CONSTANT:
        break;
      case ConstantValueKind.INTERCEPTOR:
        InterceptorConstantValue constant = value;
        writeClass(constant.cls);
        break;
      case ConstantValueKind.DEFERRED_GLOBAL:
        DeferredGlobalConstantValue constant = value;
        writeConstant(constant.referenced);
        writeOutputUnitReference(constant.unit);
        break;
      case ConstantValueKind.DUMMY_INTERCEPTOR:
        break;
      case ConstantValueKind.LATE_SENTINEL:
        break;
      case ConstantValueKind.UNREACHABLE:
        break;
      case ConstantValueKind.JS_NAME:
        JsNameConstantValue constant = value;
        writeJsNode(constant.name);
        break;
    }
  }

  void _writeString(String value) {
    _stringIndex.write(value, _sinkWriter.writeString);
  }

  void _writeUri(Uri value) {
    _uriIndex.write(value, _doWriteUri);
  }

  void _doWriteUri(Uri value) {
    _writeString(value.toString());
  }

  void writeImport(ImportEntity value) {
    _writeDataKind(DataKind.import);
    _writeImport(value);
  }

  void _writeImport(ImportEntity value) {
    _importIndex.write(value, _writeImportInternal);
  }

  void _writeImportInternal(ImportEntity value) {
    // TODO(johnniwinther): Do we need to serialize non-deferred imports?
    writeStringOrNull(value.name);
    _writeUri(value.uri);
    _writeUri(value.enclosingLibraryUri);
    _writeBool(value.isDeferred);
  }

  void registerEntityWriter(EntityWriter writer) {
    assert(writer != null);
    _entityWriter = writer;
  }

  void registerCodegenWriter(CodegenWriter writer) {
    assert(writer != null);
    assert(_codegenWriter == null);
    _codegenWriter = writer;
  }

  void writeOutputUnitReference(OutputUnit value) {
    assert(
        _codegenWriter != null,
        "Can not serialize an OutputUnit reference "
        "without a registered codegen writer.");
    _codegenWriter.writeOutputUnitReference(this, value);
  }

  void writeAbstractValue(AbstractValue value) {
    assert(_codegenWriter != null,
        "Can not serialize an AbstractValue without a registered codegen writer.");
    _codegenWriter.writeAbstractValue(this, value);
  }

  void writeJsNode(js.Node value) {
    assert(_codegenWriter != null,
        "Can not serialize a JS node without a registered codegen writer.");
    _codegenWriter.writeJsNode(this, value);
  }

  void writeTypeRecipe(TypeRecipe value) {
    assert(_codegenWriter != null,
        "Can not serialize a TypeRecipe without a registered codegen writer.");
    _codegenWriter.writeTypeRecipe(this, value);
  }

  void writeIntOrNull(int value) {
    writeBool(value != null);
    if (value != null) {
      writeInt(value);
    }
  }

  void writeStringOrNull(String value) {
    writeBool(value != null);
    if (value != null) {
      writeString(value);
    }
  }

  void writeClassOrNull(IndexedClass value) {
    writeBool(value != null);
    if (value != null) {
      writeClass(value);
    }
  }

  void writeLocalOrNull(Local value) {
    writeBool(value != null);
    if (value != null) {
      writeLocal(value);
    }
  }

  void writeClasses(Iterable<ClassEntity> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (IndexedClass value in values) {
        writeClass(value);
      }
    }
  }

  void writeTreeNodes(Iterable<ir.TreeNode> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TreeNode value in values) {
        writeTreeNode(value);
      }
    }
  }

  void writeStrings(Iterable<String> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (String value in values) {
        writeString(value);
      }
    }
  }

  void writeMemberNodes(Iterable<ir.Member> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.Member value in values) {
        writeMemberNode(value);
      }
    }
  }

  void writeDartTypes(Iterable<DartType> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (DartType value in values) {
        writeDartType(value);
      }
    }
  }

  void writeLibraryMap<V>(Map<LibraryEntity, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((LibraryEntity library, V value) {
        writeLibrary(library);
        f(value);
      });
    }
  }

  void writeClassMap<V>(Map<ClassEntity, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ClassEntity cls, V value) {
        writeClass(cls);
        f(value);
      });
    }
  }

  void writeMemberMap<V>(
      Map<MemberEntity, V> map, void f(MemberEntity member, V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((MemberEntity member, V value) {
        writeMember(member);
        f(member, value);
      });
    }
  }

  void writeStringMap<V>(Map<String, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((String key, V value) {
        writeString(key);
        f(value);
      });
    }
  }

  void writeLocals(Iterable<Local> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (Local value in values) {
        writeLocal(value);
      }
    }
  }

  void writeLocalMap<V>(Map<Local, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((Local key, V value) {
        writeLocal(key);
        f(value);
      });
    }
  }

  void writeMemberNodeMap<V>(Map<ir.Member, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.Member key, V value) {
        writeMemberNode(key);
        f(value);
      });
    }
  }

  void writeTreeNodeMap<V>(Map<ir.TreeNode, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ir.TreeNode key, V value) {
        writeTreeNode(key);
        f(value);
      });
    }
  }

  void writeTypeVariableMap<V>(Map<IndexedTypeVariable, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((IndexedTypeVariable key, V value) {
        writeTypeVariable(key);
        f(value);
      });
    }
  }

  void writeList<E>(Iterable<E> values, void f(E value),
      {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      values.forEach(f);
    }
  }

  void writeTreeNodeOrNull(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNode(value);
    }
  }

  void writeValueOrNull<E>(E value, void f(E value)) {
    writeBool(value != null);
    if (value != null) {
      f(value);
    }
  }

  void writeMemberOrNull(IndexedMember value) {
    writeBool(value != null);
    if (value != null) {
      writeMember(value);
    }
  }

  void writeMembers(Iterable<MemberEntity> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (IndexedMember value in values) {
        writeMember(value);
      }
    }
  }

  void writeTypeParameterNodes(Iterable<ir.TypeParameter> values,
      {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.TypeParameter value in values) {
        writeTypeParameterNode(value);
      }
    }
  }

  void writeConstantOrNull(ConstantValue value) {
    writeBool(value != null);
    if (value != null) {
      writeConstant(value);
    }
  }

  void writeConstants(Iterable<ConstantValue> values,
      {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ConstantValue value in values) {
        writeConstant(value);
      }
    }
  }

  void writeConstantMap<V>(Map<ConstantValue, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ConstantValue key, V value) {
        writeConstant(key);
        f(value);
      });
    }
  }

  void writeLibraryOrNull(IndexedLibrary value) {
    writeBool(value != null);
    if (value != null) {
      writeLibrary(value);
    }
  }

  void writeImportOrNull(ImportEntity value) {
    writeBool(value != null);
    if (value != null) {
      writeImport(value);
    }
  }

  void writeImports(Iterable<ImportEntity> values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ImportEntity value in values) {
        writeImport(value);
      }
    }
  }

  void writeImportMap<V>(Map<ImportEntity, V> map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((ImportEntity key, V value) {
        writeImport(key);
        f(value);
      });
    }
  }

  void writeDartTypeNodes(Iterable<ir.DartType> values,
      {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ir.DartType value in values) {
        writeDartTypeNode(value);
      }
    }
  }

  void writeName(ir.Name value) {
    writeString(value.text);
    writeValueOrNull(value.library, writeLibraryNode);
  }

  void writeLibraryDependencyNode(ir.LibraryDependency value) {
    ir.Library library = value.parent;
    writeLibraryNode(library);
    writeInt(library.dependencies.indexOf(value));
  }

  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency value) {
    writeValueOrNull(value, writeLibraryDependencyNode);
  }

  void writeJsNodeOrNull(js.Node value) {
    writeBool(value != null);
    if (value != null) {
      writeJsNode(value);
    }
  }
}
