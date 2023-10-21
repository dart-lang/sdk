// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  /// Writes a deferred entity which can be skipped when reading and read later
  /// via an offset read.
  void writeDeferred(void writer());

  /// Closes any underlying data sinks.
  void close();
}

/// Serialization writer
///
/// To be used with [DataSourceReader] to read and write serialized data.
/// Serialization format is deferred to provided [DataSink].
class DataSinkWriter {
  final DataSink _sinkWriter;

  /// If `true`, serialization of every data kind is preceded by a [DataKind]
  /// value.
  ///
  /// This is used for debugging data inconsistencies between serialization
  /// and deserialization.
  final bool useDataKinds;

  final SerializationIndices importedIndices;

  /// Visitor used for serializing [ir.DartType]s.
  late final DartTypeNodeWriter _dartTypeNodeWriter;

  /// Stack of tags used when [useDataKinds] is `true` to help debugging section
  /// inconsistencies between serialization and deserialization.
  List<String>? _tags;

  /// Map of [MemberData] object for serialized kernel member nodes.
  final Map<ir.Member, MemberData> _memberData = {};

  late final IndexedSink<String> _stringIndex;
  late final IndexedSink<Uri> _uriIndex;
  late final IndexedSink<ir.Member> _memberNodeIndex;
  late final IndexedSink<ImportEntity> _importIndex;
  late final IndexedSink<ConstantValue> _constantIndex;

  final Map<Type, IndexedSink> _generalCaches = {};

  late AbstractValueDomain _abstractValueDomain;
  js.DeferredExpressionRegistry? _deferredExpressionRegistry;

  final Map<String, int>? tagFrequencyMap;

  ir.Member? _currentMemberContext;
  MemberData? _currentMemberData;

  DataSinkWriter(
      this._sinkWriter, CompilerOptions options, this.importedIndices,
      {this.useDataKinds = false, this.tagFrequencyMap}) {
    _dartTypeNodeWriter = DartTypeNodeWriter(this);
    _stringIndex = importedIndices.getIndexedSink<String>();
    _uriIndex = importedIndices.getIndexedSink<Uri>();
    _memberNodeIndex = importedIndices
        .getMappedIndexedSink<MemberData, ir.Member>((data) => data.node);
    _importIndex = importedIndices.getIndexedSink<ImportEntity>();
    _constantIndex = importedIndices.getIndexedSink<ConstantValue>();
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
  void begin(String tag) {
    tagFrequencyMap?.update(tag, (count) => count + 1, ifAbsent: () => 1);
    if (useDataKinds) {
      (_tags ??= <String>[]).add(tag);
      _sinkWriter.beginTag(tag);
    }
  }

  /// Registers that the section [tag] ends.
  ///
  /// This is used for debugging to verify that sections are correctly aligned
  /// between serialization and deserialization.
  void end(String tag) {
    if (useDataKinds) {
      _sinkWriter.endTag(tag);

      String existingTag = _tags!.removeLast();
      assert(existingTag == tag,
          "Unexpected tag end. Expected $existingTag, found $tag.");
    }
  }

  void writeDeferrable(void f()) {
    _sinkWriter.writeDeferred(f);
  }

  /// Writes a reference to [value] to this data sink. If [value] has not yet
  /// been serialized, [f] is called to serialize the value itself. If
  /// [identity] is true then the cache is backed by a [Map] created using
  /// [Map.identity]. (i.e. comparisons are done using [identical] rather than
  /// `==`)
  void writeCached<E extends Object>(E? value, void f(E value),
      {bool identity = false}) {
    IndexedSink<E> sink = (_generalCaches[E] ??=
            importedIndices.getIndexedSink<E>(identity: identity))
        as IndexedSink<E>;
    sink.write(this, value, f);
  }

  /// Writes the potentially `null` [value] to this data sink. If [value] is
  /// non-null [f] is called to write the non-null value to the data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readValueOrNull].
  void writeValueOrNull<E>(E? value, void f(E value)) {
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
  void writeList<E>(Iterable<E>? values, void f(E value),
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
  void writeBool(bool value) {
    _writeDataKind(DataKind.bool);
    _writeBool(value);
  }

  void _writeBool(bool value) {
    _sinkWriter.writeInt(value ? 1 : 0);
  }

  /// Writes the non-negative 30 bit integer [value] to this data sink.
  void writeInt(int value) {
    assert(value >= 0 && value >> 30 == 0);
    _writeDataKind(DataKind.uint30);
    _sinkWriter.writeInt(value);
  }

  /// Writes the potentially `null` non-negative [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readIntOrNull].
  void writeIntOrNull(int? value) {
    writeBool(value != null);
    if (value != null) {
      writeInt(value);
    }
  }

  /// Writes the string [value] to this data sink.
  void writeString(String value) {
    _writeDataKind(DataKind.string);
    _writeString(value);
  }

  void _writeString(String value) {
    _stringIndex.write(this, value, _sinkWriter.writeString);
  }

  /// Writes the potentially `null` string [value] to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readStringOrNull].
  void writeStringOrNull(String? value) {
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
  void writeStringMap<V>(Map<String, V>? map, void f(V value),
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

  /// Writes the [map] from [Name] to [V] values to this data sink, calling [f]
  /// to write each value to the data sink. If [allowNull] is `true`, [map] is
  /// allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readNameMap].
  void writeNameMap<V>(Map<Name, V>? map, void f(V value),
      {bool allowNull = false}) {
    if (map == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(map.length);
      map.forEach((Name key, V value) {
        writeMemberName(key);
        f(value);
      });
    }
  }

  /// Writes the string [values] to this data sink. If [allowNull] is `true`,
  /// [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readStrings].
  void writeStrings(Iterable<String>? values, {bool allowNull = false}) {
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

  void writeEnum(dynamic value) {
    _writeDataKind(DataKind.enumValue);
    _sinkWriter.writeEnum(value);
  }

  /// Writes the URI [value] to this data sink.
  void writeUri(Uri value) {
    _writeDataKind(DataKind.uri);
    _writeUri(value);
  }

  void _writeUri(Uri value) {
    _uriIndex.write(this, value, _doWriteUri);
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

  /// Writes a reference to the kernel extension type declaration node [value]
  /// to this data sink.
  void writeExtensionTypeDeclarationNode(ir.ExtensionTypeDeclaration value) {
    _writeDataKind(DataKind.extensionTypeDeclarationNode);
    _writeExtensionTypeDeclarationNode(value);
  }

  void _writeExtensionTypeDeclarationNode(ir.ExtensionTypeDeclaration value) {
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
    _memberNodeIndex.write(this, value, _writeMemberNodeInternal);
  }

  void _writeMemberNodeInternal(ir.Member value) {
    ir.Class? cls = value.enclosingClass;
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
  void writeMemberNodes(Iterable<ir.Member>? values, {bool allowNull = false}) {
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
  void writeMemberNodeMap<V>(Map<ir.Member, V>? map, void f(V value),
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

  /// Writes a [Name] to this data sink.
  void writeMemberName(Name value) {
    writeString(value.text);
    writeValueOrNull(value.uri, writeUri);
    writeBool(value.isSetter);
  }

  /// Writes a kernel library dependency node [value] to this data sink.
  void writeLibraryDependencyNode(ir.LibraryDependency value) {
    final library = value.parent as ir.Library;
    writeLibraryNode(library);
    writeInt(library.dependencies.indexOf(value));
  }

  /// Writes a potentially `null` kernel library dependency node [value] to
  /// this data sink.
  void writeLibraryDependencyNodeOrNull(ir.LibraryDependency? value) {
    writeValueOrNull(value, writeLibraryDependencyNode);
  }

  /// Writes a reference to the kernel tree node [value] to this data sink.
  void writeTreeNode(ir.TreeNode value) {
    _writeDataKind(DataKind.treeNode);
    _writeTreeNode(value, null);
  }

  void _writeTreeNode(ir.TreeNode value, MemberData? memberData) {
    if (value is ir.Class) {
      _sinkWriter.writeEnum(_TreeNodeKind.cls);
      _writeClassNode(value);
    } else if (value is ir.Member) {
      _sinkWriter.writeEnum(_TreeNodeKind.member);
      _writeMemberNode(value);
    } else if (value is ir.VariableDeclaration &&
        value.parent is ir.FunctionDeclaration) {
      _sinkWriter.writeEnum(_TreeNodeKind.functionDeclarationVariable);
      _writeTreeNode(value.parent!, memberData);
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
      _sinkWriter.writeInt(index);
    }
  }

  /// Writes a reference to the potentially `null` kernel tree node [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTreeNodeOrNull].
  void writeTreeNodeOrNull(ir.TreeNode? value) {
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
  void writeTreeNodes(Iterable<ir.TreeNode>? values, {bool allowNull = false}) {
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
  void writeTreeNodeMap<V>(Map<ir.TreeNode, V> map, void f(V value)) {
    writeInt(map.length);
    map.forEach((ir.TreeNode key, V value) {
      writeTreeNode(key);
      f(value);
    });
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
  void writeTreeNodeOrNullInContext(ir.TreeNode? value) {
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
  void writeTreeNodesInContext(Iterable<ir.TreeNode>? values,
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
  void writeTreeNodeMapInContext<V>(Map<ir.TreeNode, V>? map, void f(V value),
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

  void _writeTypeParameter(ir.TypeParameter value, MemberData? memberData) {
    ir.GenericDeclaration declaration = value.declaration!;
    // TODO(fishythefish): Use exhaustive pattern switch.
    if (declaration is ir.Class) {
      _sinkWriter.writeEnum(_TypeParameterKind.cls);
      _writeClassNode(declaration);
      _sinkWriter.writeInt(declaration.typeParameters.indexOf(value));
    } else if (declaration is ir.Procedure) {
      _sinkWriter.writeEnum(_TypeParameterKind.functionNode);
      _writeFunctionNode(declaration.function, memberData);
      _sinkWriter.writeInt(declaration.typeParameters.indexOf(value));
    } else if (declaration is ir.LocalFunction) {
      _sinkWriter.writeEnum(_TypeParameterKind.functionNode);
      _writeFunctionNode(declaration.function, memberData);
      _sinkWriter.writeInt(declaration.typeParameters.indexOf(value));
    } else {
      throw UnsupportedError(
          "Unsupported TypeParameter declaration ${declaration.runtimeType}");
    }
  }

  /// Writes references to the kernel type parameter node [values] to this data
  /// sink.
  /// If [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTypeParameterNodes].
  void writeTypeParameterNodes(Iterable<ir.TypeParameter> values) {
    writeInt(values.length);
    for (ir.TypeParameter value in values) {
      writeTypeParameterNode(value);
    }
  }

  /// Writes the type [value] to this data sink.
  void writeDartType(DartType value) {
    _writeDataKind(DataKind.dartType);
    value.writeToDataSink(this, []);
  }

  /// Writes the optional type [value] to this data sink.
  void writeDartTypeOrNull(DartType? value) {
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
  void writeDartTypesOrNull(Iterable<DartType>? values) {
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
  void writeDartTypes(Iterable<DartType> values) {
    writeInt(values.length);
    for (DartType value in values) {
      writeDartType(value);
    }
  }

  /// Writes the kernel type node [value] to this data sink.
  void writeDartTypeNode(ir.DartType value) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: false);
  }

  /// Writes the kernel type node [value] to this data sink, `null` permitted.
  void writeDartTypeNodeOrNull(ir.DartType? value) {
    _writeDataKind(DataKind.dartTypeNode);
    _writeDartTypeNode(value, [], allowNull: true);
  }

  void _writeDartTypeNode(
      ir.DartType? value, List<ir.StructuralParameter> functionTypeVariables,
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
  void writeDartTypeNodes(Iterable<ir.DartType>? values,
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

  /// Writes a reference to the library entity [value] to this data sink.
  void writeLibrary(LibraryEntity value) {
    if (value is JLibrary) {
      writeCached<LibraryEntity>(value, (_) => value.writeToDataSink(this));
    } else {
      failedAt(value, 'Unexpected library entity type ${value.runtimeType}');
    }
  }

  /// Writes a reference to the potentially `null` library entities [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLibraryOrNull].
  void writeLibraryOrNull(LibraryEntity? value) {
    writeBool(value != null);
    if (value != null) {
      writeLibrary(value);
    }
  }

  /// Writes the [map] from references to library entities to [V] values to
  /// this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLibraryMap].
  void writeLibraryMap<V>(Map<LibraryEntity, V>? map, void f(V value),
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

  /// Writes a reference to the class entity [value] to this data sink.
  void writeClass(ClassEntity value) {
    if (value is JClass) {
      writeCached<ClassEntity>(value, (_) => value.writeToDataSink(this));
    } else {
      failedAt(value, 'Unexpected class entity type ${value.runtimeType}');
    }
  }

  /// Writes a reference to the potentially `null` class entity [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClassOrNull].
  void writeClassOrNull(ClassEntity? value) {
    writeBool(value != null);
    if (value != null) {
      writeClass(value);
    }
  }

  /// Writes references to the class entity [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClasses].
  void writeClasses(Iterable<ClassEntity>? values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (ClassEntity value in values) {
        writeClass(value);
      }
    }
  }

  /// Writes the [map] from references to class entities to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readClassMap].
  void writeClassMap<V>(Map<ClassEntity, V>? map, void f(V value),
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

  /// Writes a reference to the member entity [value] to this data sink.
  void writeMember(MemberEntity value) {
    if (value is JMember) {
      writeCached<MemberEntity>(value, (_) => value.writeToDataSink(this));
    } else {
      failedAt(value, 'Unexpected member entity type ${value.runtimeType}');
    }
  }

  /// Writes a reference to the potentially `null` member entities [value]
  /// to this data sink.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberOrNull].
  void writeMemberOrNull(MemberEntity? value) {
    writeBool(value != null);
    if (value != null) {
      writeMember(value);
    }
  }

  /// Writes references to the member entities [values] to this data sink. If
  /// [allowNull] is `true`, [values] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMembers].
  void writeMembers(Iterable<MemberEntity>? values, {bool allowNull = false}) {
    if (values == null) {
      assert(allowNull);
      writeInt(0);
    } else {
      writeInt(values.length);
      for (MemberEntity value in values) {
        writeMember(value);
      }
    }
  }

  /// Writes the [map] from references to member entities to [V] values to this
  /// data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readMemberMap].
  void writeMemberMap<V>(
      Map<MemberEntity, V>? map, void f(MemberEntity member, V value),
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

  /// Writes a reference to the type variable entity [value] to this data sink.
  void writeTypeVariable(TypeVariableEntity value) {
    if (value is JTypeVariable) {
      writeCached<TypeVariableEntity>(
          value, (_) => value.writeToDataSink(this));
    } else {
      failedAt(
          value, 'Unexpected type variable entity type ${value.runtimeType}');
    }
  }

  /// Writes the [map] from references to type variable entities to [V] values
  /// to this data sink, calling [f] to write each value to the data sink. If
  /// [allowNull] is `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readTypeVariableMap].
  void writeTypeVariableMap<V>(
      Map<TypeVariableEntity, V> map, void f(V value)) {
    writeInt(map.length);
    map.forEach((TypeVariableEntity key, V value) {
      writeTypeVariable(key);
      f(value);
    });
  }

  /// Writes a reference to the local [local] to this data sink.
  void writeLocal(Local local) {
    if (local is JLocal) {
      writeEnum(LocalKind.jLocal);
      writeCached<Local>(local, (_) => local.writeToDataSink(this));
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
  void writeLocalOrNull(Local? value) {
    writeBool(value != null);
    if (value != null) {
      writeLocal(value);
    }
  }

  /// Writes the [map] from references to locals to [V] values to this data
  /// sink, calling [f] to write each value to the data sink. If [allowNull] is
  /// `true`, [map] is allowed to be `null`.
  ///
  /// This is a convenience method to be used together with
  /// [DataSourceReader.readLocalMap].
  void writeLocalMap<V>(Map<Local, V> map, void f(V value)) {
    writeInt(map.length);
    map.forEach((Local key, V value) {
      writeLocal(key);
      f(value);
    });
  }

  /// Writes the constant [value] to this data sink.
  void writeConstant(ConstantValue value) {
    _writeDataKind(DataKind.constant);
    _writeConstant(value);
  }

  void _writeConstant(ConstantValue value) {
    _constantIndex.write(this, value, _writeConstantInternal);
  }

  void _writeConstantInternal(ConstantValue value) {
    _sinkWriter.writeEnum(value.kind);
    switch (value.kind) {
      case ConstantValueKind.BOOL:
        final constant = value as BoolConstantValue;
        writeBool(constant.boolValue);
        break;
      case ConstantValueKind.INT:
        final constant = value as IntConstantValue;
        _writeBigInt(constant.intValue);
        break;
      case ConstantValueKind.DOUBLE:
        final constant = value as DoubleConstantValue;
        _writeDoubleValue(constant.doubleValue);
        break;
      case ConstantValueKind.STRING:
        final constant = value as StringConstantValue;
        writeString(constant.stringValue);
        break;
      case ConstantValueKind.NULL:
        break;
      case ConstantValueKind.FUNCTION:
        final constant = value as FunctionConstantValue;
        writeMember(constant.element);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.LIST:
        final constant = value as ListConstantValue;
        writeDartType(constant.type);
        writeConstants(constant.entries);
        break;
      case ConstantValueKind.SET:
        final constant = value as constant_system.JavaScriptSetConstant;
        writeDartType(constant.type);
        writeConstants(constant.values);
        writeConstantOrNull(constant.indexObject);
        break;
      case ConstantValueKind.MAP:
        final constant = value as constant_system.JavaScriptMapConstant;
        writeDartType(constant.type);
        writeConstant(constant.keyList);
        writeConstant(constant.valueList);
        writeBool(constant.onlyStringKeys);
        if (constant.onlyStringKeys) writeConstant(constant.indexObject!);
        break;
      case ConstantValueKind.CONSTRUCTED:
        final constant = value as ConstructedConstantValue;
        writeDartType(constant.type);
        writeMemberMap(constant.fields,
            (MemberEntity member, ConstantValue value) => writeConstant(value));
        break;
      case ConstantValueKind.RECORD:
        final constant = value as RecordConstantValue;
        constant.shape.writeToDataSink(this);
        writeConstants(constant.values);
        break;
      case ConstantValueKind.TYPE:
        final constant = value as TypeConstantValue;
        writeDartType(constant.representedType);
        writeDartType(constant.type);
        break;
      case ConstantValueKind.INSTANTIATION:
        final constant = value as InstantiationConstantValue;
        writeDartTypes(constant.typeArguments);
        writeConstant(constant.function);
        break;
      case ConstantValueKind.NON_CONSTANT:
        break;
      case ConstantValueKind.INTERCEPTOR:
        final constant = value as InterceptorConstantValue;
        writeClass(constant.cls);
        break;
      case ConstantValueKind.JAVASCRIPT_OBJECT:
        final constant = value as JavaScriptObjectConstantValue;
        writeConstants(constant.keys);
        writeConstants(constant.values);
        break;
      case ConstantValueKind.DEFERRED_GLOBAL:
        final constant = value as DeferredGlobalConstantValue;
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
        final constant = value as JsNameConstantValue;
        writeJsNode(constant.name);
        break;
    }
  }

  /// Writes the potentially `null` constant [value] to this data sink.
  void writeConstantOrNull(ConstantValue? value) {
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
  void writeConstants(Iterable<ConstantValue>? values,
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
  void writeConstantMap<V>(Map<ConstantValue, V>? map, void f(V value),
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
    _importIndex.write(this, value, _writeImportInternal);
  }

  void _writeImportInternal(ImportEntity value) {
    // TODO(johnniwinther): Do we need to serialize non-deferred imports?
    writeStringOrNull(value.name);
    _writeUri(value.uri);
    _writeUri(value.enclosingLibraryUri);
    _writeBool(value.isDeferred);
  }

  /// Writes the potentially `null` import [value] to this data sink.
  void writeImportOrNull(ImportEntity? value) {
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
  void writeImports(Iterable<ImportEntity>? values, {bool allowNull = false}) {
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
  void writeImportMap<V>(Map<ImportEntity, V>? map, void f(V value),
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
  /// This feature is only available a [AbstractValueDomain] has been
  /// registered.
  void writeAbstractValue(AbstractValue value) {
    _abstractValueDomain.writeAbstractValueToDataSink(this, value);
  }

  /// Writes a reference to the output unit [value] to this data sink.
  void writeOutputUnitReference(OutputUnit value) {
    writeCached<OutputUnit>(value, (v) => v.writeToDataSink(this));
  }

  void withDeferredExpressionRegistry(
      js.DeferredExpressionRegistry registry, void Function() f) {
    _deferredExpressionRegistry = registry;
    f();
    _deferredExpressionRegistry = null;
  }

  /// Writes a js node [value] to this data sink.
  void writeJsNode(js.Node value) {
    JsNodeSerializer.writeToDataSink(this, value, _deferredExpressionRegistry);
  }

  /// Writes a potentially `null` js node [value] to this data sink.
  void writeJsNodeOrNull(js.Node? value) {
    writeBool(value != null);
    if (value != null) {
      writeJsNode(value);
    }
  }

  /// Writes TypeRecipe [value] to this data sink.
  void writeTypeRecipe(TypeRecipe value) {
    value.writeToDataSink(this);
  }

  /// Register a [AbstractValueDomain] with this data sink to support
  /// serialization of abstract values.
  void registerAbstractValueDomain(AbstractValueDomain domain) {
    _abstractValueDomain = domain;
  }

  /// Invoke [f] in the context of [member]. This sets up support for
  /// serialization of `ir.TreeNode`s using the `writeTreeNode*InContext`
  /// methods.
  void inMemberContext(ir.Member? context, void f()) {
    ir.Member? oldMemberContext = _currentMemberContext;
    MemberData? oldMemberData = _currentMemberData;
    _currentMemberContext = context;
    _currentMemberData = null;
    f();
    _currentMemberData = oldMemberData;
    _currentMemberContext = oldMemberContext;
  }

  MemberData get currentMemberData {
    final currentMemberContext = _currentMemberContext!;
    return _currentMemberData ??=
        _memberData[currentMemberContext] ??= MemberData(currentMemberContext);
  }

  MemberData _getMemberData(ir.TreeNode node) {
    ir.TreeNode? member = node;
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

  void _writeFunctionNode(ir.FunctionNode value, MemberData? memberData) {
    ir.TreeNode parent = value.parent!;
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
