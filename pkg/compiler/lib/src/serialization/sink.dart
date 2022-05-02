// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

part of 'serialization.dart';

/// Interface handling [DataSinkWriter] low-level data serialization.
///
/// Each implementation of [DataSink] should have a corresponding
/// [DataSource] that deserializes data serialized by that implementation.
abstract class DataSink {
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
/// To be used with [DataSourceReader] to read and write serialized data.
/// Serialization format is deferred to provided [DataSink].
class DataSinkWriter implements migrated.DataSinkWriter {
  final DataSink _sinkWriter;

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

  /// Map of [MemberData] object for serialized kernel member nodes.
  final Map<ir.Member, MemberData> _memberData = {};

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
  MemberData _currentMemberData;

  IndexedSink<T> _createSink<T>() {
    if (importedIndices == null || !importedIndices.caches.containsKey(T)) {
      return IndexedSink<T>(this._sinkWriter);
    } else {
      Map<T, int> cacheCopy = Map.from(importedIndices.caches[T].cache);
      return IndexedSink<T>(this._sinkWriter, cache: cacheCopy);
    }
  }

  DataSinkWriter(this._sinkWriter,
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

  /// Registers that the section [tag] starts.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  @override
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

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  @override
  void end(Object tag) {
    if (useDataKinds) {
      _sinkWriter.endTag(tag);

      String existingTag = _tags.removeLast();
      assert(existingTag == tag,
          "Unexpected tag end. Expected $existingTag, found $tag.");
    }
  }

  /// Writes a reference to [value] to this data sink. If [value] has not yet
  /// been serialized, [f] is called to serialize the value itself.
  @override
  void writeCached<E>(E value, void f(E value)) {
    IndexedSink sink = _generalCaches[E] ??= _createSink<E>();
    sink.write(value, (v) => f(v));
  }

  /// Writes the potentially `null` [value] to this data sink. If [value] is
  /// non-null [f] is called to write the non-null value to the data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readValueOrNull].
  void writeValueOrNull<E>(E value, void f(E value)) {
    writeBool(value != null);
    if (value != null) {
      f(value);
    }
  }

  /// Writes the [values] to this data sink calling [f] to write each value to
  /// the data sink. If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readList].
  @override
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

  /// Writes the boolean [value] to this data sink.
  @override
  void writeBool(bool value) {
    assert(value != null);
    _writeDataKind(DataKind.bool);
    _writeBool(value);
  }

  void _writeBool(bool value) {
    _sinkWriter.writeInt(value ? 1 : 0);
  }

  /// Writes the non-negative 30 bit integer [value] to this data sink.
  @override
  void writeInt(int value) {
    assert(value != null);
    assert(value >= 0 && value >> 30 == 0);
    _writeDataKind(DataKind.uint30);
    _sinkWriter.writeInt(value);
  }

  /// Writes the potentially `null` non-negative [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readIntOrNull].
  @override
  void writeIntOrNull(int value) {
    writeBool(value != null);
    if (value != null) {
      writeInt(value);
    }
  }

  /// Writes the string [value] to this data sink.
  @override
  void writeString(String value) {
    assert(value != null);
    _writeDataKind(DataKind.string);
    _writeString(value);
  }

  void _writeString(String value) {
    _stringIndex.write(value, _sinkWriter.writeString);
  }

  /// Writes the potentially `null` string [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readStringOrNull].
  @override
  void writeStringOrNull(String value) {
    writeBool(value != null);
    if (value != null) {
      writeString(value);
    }
  }

  /// Writes the [map] from string to [V] values to this data sink, calling [f]
  /// to write each value to the data sink. If [allowNull] is `true`, [map] is
  /// allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readStringMap].
  @override
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

  /// Writes the string [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readStrings].
  @override
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

  /// Writes the enum value [value] to this data sink.
  // TODO(johnniwinther): Change the signature to
  // `void writeEnum<E extends Enum<E>>(E value);` when an interface for enums
  // is added to the language.
  @override
  void writeEnum(dynamic value) {
    _writeDataKind(DataKind.enumValue);
    _sinkWriter.writeEnum(value);
  }

  /// Writes the URI [value] to this data sink.
  @override
  void writeUri(Uri value) {
    assert(value != null);
    _writeDataKind(DataKind.uri);
    _writeUri(value);
  }

  void _writeUri(Uri value) {
    _uriIndex.write(value, _doWriteUri);
  }

  void _doWriteUri(Uri value) {
    _writeString(value.toString());
  }

  /// Writes a reference to the kernel library node [value] to this data sink.
  void writeLibraryNode(ir.Library value) {
    _writeDataKind(DataKind.libraryNode);
    _writeLibraryNode(value);
  }

  void _writeLibraryNode(ir.Library value) {
    _writeUri(value.importUri);
  }

  /// Writes a reference to the kernel class node [value] to this data sink.
  void writeClassNode(ir.Class value) {
    _writeDataKind(DataKind.classNode);
    _writeClassNode(value);
  }

  void _writeClassNode(ir.Class value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  /// Writes a reference to the kernel typedef node [value] to this data sink.
  void writeTypedefNode(ir.Typedef value) {
    _writeDataKind(DataKind.typedefNode);
    _writeTypedefNode(value);
  }

  void _writeTypedefNode(ir.Typedef value) {
    _writeLibraryNode(value.enclosingLibrary);
    _writeString(value.name);
  }

  /// Writes a reference to the kernel member node [value] to this data sink.
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
      _writeString(computeMemberName(value));
    } else {
      _sinkWriter.writeEnum(MemberContextKind.library);
      _writeLibraryNode(value.enclosingLibrary);
      _writeString(computeMemberName(value));
    }
  }

  /// Writes references to the kernel member node [values] to this data sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberNodes].
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

  /// Writes the [map] from references to kernel member nodes to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberNodeMap].
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

  /// Writes a kernel name node to this data sink.
  void writeName(ir.Name value) {
    writeString(value.text);
    writeValueOrNull(value.library, writeLibraryNode);
  }

  /// Writes a kernel library dependency node [value] to this data sink.
  void writeLibraryDependencyNode(ir.LibraryDependency value) {
    ir.Library library = value.parent;
    writeLibraryNode(library);
    writeInt(library.dependencies.indexOf(value));
  }

  /// Writes a potentially `null` kernel library dependency node [value] to
  /// this data sink.
  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency value) {
    writeValueOrNull(value, writeLibraryDependencyNode);
  }

  /// Writes a reference to the kernel tree node [value] to this data sink.
  void writeTreeNode(ir.TreeNode value) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, null);
  }

  void _writeTreeNode(ir.TreeNode value, MemberData memberData) {
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

  /// Writes a reference to the potentially `null` kernel tree node [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodeOrNull].
  void writeTreeNodeOrNull(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNode(value);
    }
  }

  /// Writes references to the kernel tree node [values] to this data sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodes].
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

  /// Writes the [map] from references to kernel tree nodes to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodeMap].
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

  /// Writes a reference to the kernel tree node [value] in the known [context]
  /// to this data sink.
  void writeTreeNodeInContext(ir.TreeNode value) {
    writeTreeNodeInContextInternal(value, currentMemberData);
  }

  void writeTreeNodeInContextInternal(
      ir.TreeNode value, MemberData memberData) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, memberData);
  }

  /// Writes a reference to the potentially `null` kernel tree node [value] in
  /// the known [context] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodeOrNullInContext].
  void writeTreeNodeOrNullInContext(ir.TreeNode value) {
    writeBool(value != null);
    if (value != null) {
      writeTreeNodeInContextInternal(value, currentMemberData);
    }
  }

  /// Writes references to the kernel tree node [values] in the known [context]
  /// to this data sink. If [allowNull] is `true`, [values] is allowed to be
  /// `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodesInContext].
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

  /// Writes the [map] from references to kernel tree nodes to [V] values in the
  /// known [context] to this data sink, calling [f] to write each value to the
  /// data sink. If [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodeMapInContext].
  @override
  void writeTreeNodeMapInContext<V>(
      Map<ir.TreeNode, V> /*?*/ map, void f(V value),
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

  /// Writes a reference to the kernel type parameter node [value] to this data
  /// sink.
  void writeTypeParameterNode(ir.TypeParameter value) {
    _writeDataKind(DataKind.typeParameterNode);
    _writeTypeParameter(value, null);
  }

  void _writeTypeParameter(ir.TypeParameter value, MemberData memberData) {
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

  /// Writes references to the kernel type parameter node [values] to this data
  /// sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTypeParameterNodes].
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

  /// Writes the type [value] to this data sink.
  @override
  void writeDartType(DartType value) {
    _writeDataKind(DataKind.dartType);
    value.writeToDataSink(this, []);
  }

  /// Writes the optional type [value] to this data sink.
  @override
  void writeDartTypeOrNull(DartType /*?*/ value) {
    _writeDataKind(DataKind.dartType);
    if (value == null) {
      writeEnum(DartTypeKind.none);
    } else {
      value.writeToDataSink(this, []);
    }
  }

  /// Writes the types [values] to this data sink. If [values] is null, write a
  /// zero-length iterable.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readDartTypesOrNull].
  @override
  void writeDartTypesOrNull(Iterable<DartType> /*?*/ values) {
    if (values == null) {
      writeInt(0);
    } else {
      writeDartTypes(values);
    }
  }

  /// Writes the types [values] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readDartTypes].
  @override
  void writeDartTypes(Iterable<DartType> values) {
    writeInt(values.length);
    for (DartType value in values) {
      writeDartType(value);
    }
  }

  /// Writes the kernel type node [value] to this data sink.
  @override
  void writeDartTypeNode(ir.DartType /*!*/ value) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: false);
  }

  /// Writes the kernel type node [value] to this data sink, `null` permitted.
  @override
  void writeDartTypeNodeOrNull(ir.DartType /*?*/ value) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: true);
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

  /// Writes the kernel type node [values] to this data sink. If [allowNull] is
  /// `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readDartTypeNodes].
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

  /// Writes the source span [value] to this data sink.
  void writeSourceSpan(SourceSpan value) {
    _writeDataKind(DataKind.sourceSpan);
    _writeUri(value.uri);
    _sinkWriter.writeInt(value.begin);
    _sinkWriter.writeInt(value.end);
  }

  /// Writes a reference to the indexed library [value] to this data sink.
  @override
  void writeLibrary(IndexedLibrary value) {
    _entityWriter.writeLibraryToDataSink(this, value);
  }

  /// Writes a reference to the potentially `null` indexed library [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLibraryOrNull].
  @override
  void writeLibraryOrNull(IndexedLibrary value) {
    writeBool(value != null);
    if (value != null) {
      writeLibrary(value);
    }
  }

  /// Writes the [map] from references to indexed libraries to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLibraryMap].
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

  /// Writes a reference to the indexed class [value] to this data sink.
  @override
  void writeClass(IndexedClass value) {
    _entityWriter.writeClassToDataSink(this, value);
  }

  /// Writes a reference to the potentially `null` indexed class [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClassOrNull].
  @override
  void writeClassOrNull(IndexedClass value) {
    writeBool(value != null);
    if (value != null) {
      writeClass(value);
    }
  }

  /// Writes references to the indexed class [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClasses].
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

  /// Writes the [map] from references to indexed classes to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClassMap].
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

  /// Writes a reference to the indexed member [value] to this data sink.
  void writeMember(IndexedMember value) {
    _entityWriter.writeMemberToDataSink(this, value);
  }

  /// Writes a reference to the potentially `null` indexed member [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberOrNull].
  void writeMemberOrNull(IndexedMember value) {
    writeBool(value != null);
    if (value != null) {
      writeMember(value);
    }
  }

  /// Writes references to the indexed member [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMembers].
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

  /// Writes the [map] from references to indexed members to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberMap].
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

  /// Writes a reference to the indexed type variable [value] to this data sink.
  @override
  void writeTypeVariable(IndexedTypeVariable value) {
    _entityWriter.writeTypeVariableToDataSink(this, value);
  }

  /// Writes the [map] from references to indexed type variables to [V] values
  /// to this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTypeVariableMap].
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

  /// Writes a reference to the local [value] to this data sink.
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

  /// Writes a reference to the potentially `null` local [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLocalOrNull].
  void writeLocalOrNull(Local value) {
    writeBool(value != null);
    if (value != null) {
      writeLocal(value);
    }
  }

  /// Writes references to the local [values] to this data sink. If [allowNull]
  /// is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLocals].
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

  /// Writes the [map] from references to locals to [V] values to this data
  /// sink, calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLocalMap].
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

  /// Writes the constant [value] to this data sink.
  void writeConstant(ConstantValue value) {
    _writeDataKind(DataKind.constant);
    _writeConstant(value);
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

  /// Writes the potentially `null` constant [value] to this data sink.
  void writeConstantOrNull(ConstantValue value) {
    writeBool(value != null);
    if (value != null) {
      writeConstant(value);
    }
  }

  /// Writes constant [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readConstants].
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

  /// Writes the [map] from constant values to [V] values to this data sink,
  /// calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readConstantMap].
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

  /// Writes a double value to this data sink.
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

  /// Writes an integer of arbitrary value to this data sink.
  ///
  /// This is should only when the value is not known to be a non-negative
  /// 30 bit integer. Otherwise [writeInt] should be used.
  void writeIntegerValue(int value) {
    _writeDataKind(DataKind.int);
    _writeBigInt(BigInt.from(value));
  }

  void _writeBigInt(BigInt value) {
    writeString(value.toString());
  }

  /// Writes the import [value] to this data sink.
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

  /// Writes the potentially `null` import [value] to this data sink.
  void writeImportOrNull(ImportEntity value) {
    writeBool(value != null);
    if (value != null) {
      writeImport(value);
    }
  }

  /// Writes import [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readImports].
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

  /// Writes the [map] from imports to [V] values to this data sink,
  /// calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readImportMap].
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

  /// Writes an abstract [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeAbstractValue(AbstractValue value) {
    assert(_codegenWriter != null,
        "Can not serialize an AbstractValue without a registered codegen writer.");
    _codegenWriter.writeAbstractValue(this, value);
  }

  /// Writes a reference to the output unit [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeOutputUnitReference(OutputUnit value) {
    assert(
        _codegenWriter != null,
        "Can not serialize an OutputUnit reference "
        "without a registered codegen writer.");
    _codegenWriter.writeOutputUnitReference(this, value);
  }

  /// Writes a js node [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeJsNode(js.Node value) {
    assert(_codegenWriter != null,
        "Can not serialize a JS node without a registered codegen writer.");
    _codegenWriter.writeJsNode(this, value);
  }

  /// Writes a potentially `null` js node [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeJsNodeOrNull(js.Node value) {
    writeBool(value != null);
    if (value != null) {
      writeJsNode(value);
    }
  }

  /// Writes TypeRecipe [value] to this data sink.
  ///
  /// This feature is only available a [CodegenWriter] has been registered.
  void writeTypeRecipe(TypeRecipe value) {
    assert(_codegenWriter != null,
        "Can not serialize a TypeRecipe without a registered codegen writer.");
    _codegenWriter.writeTypeRecipe(this, value);
  }

  /// Register an [EntityWriter] with this data sink for non-default encoding
  /// of entity references.
  void registerEntityWriter(EntityWriter writer) {
    assert(writer != null);
    _entityWriter = writer;
  }

  /// Register a [CodegenWriter] with this data sink to support serialization
  /// of codegen only data.
  void registerCodegenWriter(CodegenWriter writer) {
    assert(writer != null);
    assert(_codegenWriter == null);
    _codegenWriter = writer;
  }

  /// Invoke [f] in the context of [member]. This sets up support for
  /// serialization of `ir.TreeNode`s using the `writeTreeNode*InContext`
  /// methods.
  @override
  void inMemberContext(ir.Member context, void f()) {
    ir.Member oldMemberContext = _currentMemberContext;
    MemberData oldMemberData = _currentMemberData;
    _currentMemberContext = context;
    _currentMemberData = null;
    f();
    _currentMemberData = oldMemberData;
    _currentMemberContext = oldMemberContext;
  }

  MemberData get currentMemberData {
    assert(_currentMemberContext != null,
        "DataSink has no current member context.");
    return _currentMemberData ??= _memberData[_currentMemberContext] ??=
        MemberData(_currentMemberContext);
  }

  MemberData _getMemberData(ir.TreeNode node) {
    ir.TreeNode member = node;
    while (member is! ir.Member) {
      if (member == null) {
        throw UnsupportedError("No enclosing member of TreeNode "
            "$node (${node.runtimeType})");
      }
      member = member.parent;
    }
    _writeMemberNode(member);
    return _memberData[member] ??= MemberData(member);
  }

  void _writeFunctionNode(ir.FunctionNode value, MemberData memberData) {
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

  void _writeDataKind(DataKind kind) {
    if (useDataKinds) _sinkWriter.writeEnum(kind);
  }
}
