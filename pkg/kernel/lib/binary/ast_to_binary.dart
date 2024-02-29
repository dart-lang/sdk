// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.ast_to_binary;

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import '../ast.dart';
import 'ast_from_binary.dart' show mergeCompilationModeOrThrow;
import 'tag.dart';

/// Writes to a binary file.
///
/// A [BinaryPrinter] can be used to write one file and must then be
/// discarded.
class BinaryPrinter implements Visitor<void>, BinarySink {
  final VariableIndexer Function() _newVariableIndexer;
  VariableIndexer? _variableIndexer;
  LabelIndexer? _labelIndexer;
  SwitchCaseIndexer? _switchCaseIndexer;
  TypeParameterIndexer _typeParameterIndexer = new TypeParameterIndexer();
  final StringIndexer stringIndexer;
  final ConstantIndexer _constantIndexer;
  final UriIndexer _sourceUriIndexer = new UriIndexer();
  bool _currentlyInNonimplementation = false;
  final List<bool?> _sourcesFromRealImplementation = <bool?>[];
  final List<bool?> _sourcesUsedInLibrary = <bool?>[];
  Map<LibraryDependency, int> _libraryDependencyIndex =
      <LibraryDependency, int>{};
  NonNullableByDefaultCompiledMode? compilationMode;

  List<_MetadataSubsection>? _metadataSubsections;

  final BufferedSink _mainSink;
  final BufferedSink _metadataSink;
  late BufferedSink _sink;
  final bool includeSources;
  final bool includeSourceBytes;
  final bool includeOffsets;
  final LibraryFilter? libraryFilter;

  late List<int> libraryOffsets;
  late List<int> classOffsets;
  late List<int> procedureOffsets;
  int _binaryOffsetForSourceTable = -1;
  int _binaryOffsetForLinkTable = -1;
  int _binaryOffsetForMetadataPayloads = -1;
  int _binaryOffsetForMetadataMappings = -1;
  int _binaryOffsetForStringTable = -1;
  int _binaryOffsetForConstantTableIndex = -1;
  int _binaryOffsetForConstantTable = -1;

  late List<CanonicalName> _canonicalNameList;
  bool _canonicalNameListDone = false;
  Set<CanonicalName> _knownCanonicalNameNonRootTops = new Set<CanonicalName>();

  Library? _currentLibrary;

  /// Create a printer that writes to the given [sink].
  ///
  /// The BinaryPrinter will use its own buffer, so the [sink] does not need
  /// one.
  BinaryPrinter(Sink<List<int>> sink,
      {this.libraryFilter,
      StringIndexer? stringIndexer,
      this.includeSources = true,
      this.includeSourceBytes = true,
      this.includeOffsets = true,
      VariableIndexer Function()? newVariableIndexerForTesting})
      : _mainSink = new BufferedSink(sink),
        _metadataSink = new BufferedSink(new BytesSink()),
        stringIndexer = stringIndexer ?? new StringIndexer(),
        _constantIndexer = new ConstantIndexer(),
        _newVariableIndexer =
            newVariableIndexerForTesting ?? VariableIndexer.new {
    _sink = _mainSink;
  }

  void _flush() {
    _sink.flushAndDestroy();
  }

  int _getVariableIndex(VariableDeclaration variable) {
    int? index = (_variableIndexer ??= _newVariableIndexer())[variable];
    assert(index != null, "No index found for ${variable}");
    return index!;
  }

  @override
  void writeByte(int byte) {
    assert((byte & 0xFF) == byte);
    _sink.addByte(byte);
  }

  void writeBytes(List<int> bytes) {
    _sink.addBytes(bytes);
  }

  @override
  @pragma("vm:prefer-inline")
  void writeUInt30(int value) {
    assert(value >= 0 && value >> 30 == 0);
    if (value < 0x80) {
      _sink.addByte(value);
    } else if (value < 0x4000) {
      _sink.addByte2((value >> 8) | 0x80, value & 0xFF);
    } else {
      _sink.addByte4((value >> 24) | 0xC0, (value >> 16) & 0xFF,
          (value >> 8) & 0xFF, value & 0xFF);
    }
  }

  @override
  void writeUInt32(int value) {
    _sink.addByte4((value >> 24) & 0xFF, (value >> 16) & 0xFF,
        (value >> 8) & 0xFF, value & 0xFF);
  }

  @override
  void writeByteList(List<int> bytes) {
    writeUInt30(bytes.length);
    writeBytes(bytes);
  }

  int getBufferOffset() {
    return _sink.offset;
  }

  void writeStringTable(StringIndexer indexer) {
    _binaryOffsetForStringTable = getBufferOffset();

    // Containers for the WTF-8 encoded strings.
    final List<Uint8List> data = <Uint8List>[];
    int totalLength = 0;
    const int minLength = 1 << 16;
    Uint8List? buffer;
    int index = 0;

    // Write the end offsets.
    writeUInt30(indexer.index.length);
    for (String key in indexer.index.keys) {
      if (key.isNotEmpty) {
        int requiredMinLength = key.length;
        int allocateMinLength = requiredMinLength * 3;
        int newIndex;
        while (true) {
          if (buffer == null || index + requiredMinLength >= buffer.length) {
            int newLength = minLength;
            if (allocateMinLength > newLength) newLength = allocateMinLength;
            if (buffer != null && index > 0) {
              data.add(new Uint8List.view(buffer.buffer, 0, index));
            }
            index = 0;
            buffer = new Uint8List(newLength);
          }
          newIndex = _writeWtf8(buffer, index, key);
          if (newIndex != -1) break;
          requiredMinLength = allocateMinLength;
        }
        assert(newIndex >= 0);
        totalLength += newIndex - index;
        index = newIndex;
      }
      writeUInt30(totalLength);
    }
    if (buffer != null && index > 0) {
      data.add(Uint8List.view(buffer.buffer, 0, index));
    }

    // Write the WTF-8 encoded strings.
    for (int i = 0; i < data.length; ++i) {
      writeBytes(data[i]);
    }
  }

  @override
  void writeStringReference(String string) {
    writeUInt30(stringIndexer.put(string));
  }

  void writeStringReferenceList(List<String> strings) {
    writeList(strings, writeStringReference);
  }

  @override
  void writeConstantReference(Constant constant) {
    writeUInt30(_constantIndexer.put(constant));
  }

  void writeConstantTable() {
    _binaryOffsetForConstantTable = getBufferOffset();

    writeUInt30(_constantIndexer.entries.length);
    assert(_constantIndexer.entries.length == _constantIndexer.offsets.length);
    for (int i = 0; i < _constantIndexer.entries.length; i++) {
      final Constant entry = _constantIndexer.entries[i];
      _constantIndexer.offsets[i] =
          getBufferOffset() - _binaryOffsetForConstantTable;
      writeConstantTableEntry(entry);
    }
  }

  void writeConstantTableIndex() {
    _binaryOffsetForConstantTableIndex = getBufferOffset();
    assert(identical(_sink, _mainSink));
    assert(_constantIndexer.entries.length == _constantIndexer.offsets.length);
    for (int i = 0; i < _constantIndexer.offsets.length; i++) {
      final int relativeOffset = _constantIndexer.offsets[i];
      assert(relativeOffset >= 0);
      writeUInt32(relativeOffset);
    }
    writeUInt32(_constantIndexer.entries.length);
  }

  void writeConstantTableEntry(Constant constant) {
    TypeParameterIndexer oldTypeParameterIndexer = _typeParameterIndexer;
    _typeParameterIndexer = new TypeParameterIndexer();
    if (constant is NullConstant) {
      writeByte(ConstantTag.NullConstant);
    } else if (constant is BoolConstant) {
      writeByte(ConstantTag.BoolConstant);
      writeByte(constant.value ? 1 : 0);
    } else if (constant is IntConstant) {
      writeByte(ConstantTag.IntConstant);
      writeInteger(constant.value, TreeNode.noOffset);
    } else if (constant is DoubleConstant) {
      writeByte(ConstantTag.DoubleConstant);
      writeDouble(constant.value);
    } else if (constant is StringConstant) {
      writeByte(ConstantTag.StringConstant);
      writeStringReference(constant.value);
    } else if (constant is SymbolConstant) {
      writeByte(ConstantTag.SymbolConstant);
      writeNullAllowedReference(constant.libraryReference);
      writeStringReference(constant.name);
    } else if (constant is MapConstant) {
      writeByte(ConstantTag.MapConstant);
      writeDartType(constant.keyType);
      writeDartType(constant.valueType);
      writeUInt30(constant.entries.length);
      for (final ConstantMapEntry entry in constant.entries) {
        writeConstantReference(entry.key);
        writeConstantReference(entry.value);
      }
    } else if (constant is ListConstant) {
      writeByte(ConstantTag.ListConstant);
      writeDartType(constant.typeArgument);
      writeUInt30(constant.entries.length);
      constant.entries.forEach(writeConstantReference);
    } else if (constant is SetConstant) {
      writeByte(ConstantTag.SetConstant);
      writeDartType(constant.typeArgument);
      writeUInt30(constant.entries.length);
      constant.entries.forEach(writeConstantReference);
    } else if (constant is InstanceConstant) {
      writeByte(ConstantTag.InstanceConstant);
      writeClassReference(constant.classNode);
      writeUInt30(constant.typeArguments.length);
      constant.typeArguments.forEach(writeDartType);
      writeUInt30(constant.fieldValues.length);
      constant.fieldValues.forEach((Reference fieldRef, Constant value) {
        writeNonNullCanonicalNameReference(fieldRef);
        writeConstantReference(value);
      });
    } else if (constant is InstantiationConstant) {
      writeByte(ConstantTag.InstantiationConstant);
      writeConstantReference(constant.tearOffConstant);
      final int length = constant.types.length;
      writeUInt30(length);
      for (int i = 0; i < length; ++i) {
        writeDartType(constant.types[i]);
      }
    } else if (constant is StaticTearOffConstant) {
      writeByte(ConstantTag.StaticTearOffConstant);
      writeNonNullCanonicalNameReference(constant.targetReference);
    } else if (constant is ConstructorTearOffConstant) {
      writeByte(ConstantTag.ConstructorTearOffConstant);
      writeNonNullCanonicalNameReference(constant.targetReference);
    } else if (constant is RedirectingFactoryTearOffConstant) {
      writeByte(ConstantTag.RedirectingFactoryTearOffConstant);
      writeNonNullCanonicalNameReference(constant.targetReference);
    } else if (constant is TypeLiteralConstant) {
      writeByte(ConstantTag.TypeLiteralConstant);
      writeDartType(constant.type);
    } else if (constant is UnevaluatedConstant) {
      writeByte(ConstantTag.UnevaluatedConstant);
      writeNode(constant.expression);
    } else if (constant is TypedefTearOffConstant) {
      writeByte(ConstantTag.TypedefTearOffConstant);
      enterScope(typeParameters: constant.parameters);
      writeNodeList(constant.parameters);
      writeConstantReference(constant.tearOffConstant);
      final int length = constant.types.length;
      writeUInt30(length);
      for (int i = 0; i < length; ++i) {
        writeDartType(constant.types[i]);
      }
      leaveScope(typeParameters: constant.parameters);
    } else if (constant is RecordConstant) {
      writeByte(ConstantTag.RecordConstant);
      writeUInt30(constant.positional.length);
      constant.positional.forEach(writeConstantReference);
      writeUInt30(constant.named.length);
      for (final MapEntry<String, Constant> entry in constant.named.entries) {
        writeStringReference(entry.key);
        writeConstantReference(entry.value);
      }
      writeDartType(constant.recordType);
    } else {
      throw new ArgumentError('Unsupported constant $constant');
    }
    _typeParameterIndexer = oldTypeParameterIndexer;
  }

  @override
  void writeDartType(DartType type) {
    type.accept(this);
  }

  // Returns the new active file uri.
  void writeUriReference(Uri uri) {
    final int index = _sourceUriIndexer.put(uri);
    writeUInt30(index);
    if (!_currentlyInNonimplementation) {
      if (_sourcesFromRealImplementation.length <= index) {
        _sourcesFromRealImplementation.length = index + 1;
      }
      _sourcesFromRealImplementation[index] = true;
    }
    if (_sourcesUsedInLibrary.length <= index) {
      _sourcesUsedInLibrary.length = index + 1;
    }
    _sourcesUsedInLibrary[index] = true;
  }

  void writeList<T>(List<T> items, void writeItem(T x)) {
    writeUInt30(items.length);
    for (int i = 0; i < items.length; ++i) {
      writeItem(items[i]);
    }
  }

  void writeNodeList(List<Node> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Node node = nodes[i];
      writeNode(node);
    }
  }

  void writeProcedureNodeList(List<Procedure> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Procedure node = nodes[i];
      writeProcedureNode(node);
    }
  }

  void writeFieldNodeList(List<Field> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Field node = nodes[i];
      writeFieldNode(node);
    }
  }

  void writeClassNodeList(List<Class> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Class node = nodes[i];
      writeClassNode(node);
    }
  }

  void writeExtensionNodeList(List<Extension> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Extension node = nodes[i];
      writeExtensionNode(node);
    }
  }

  void writeExtensionTypeDeclarationNodeList(
      List<ExtensionTypeDeclaration> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final ExtensionTypeDeclaration node = nodes[i];
      writeExtensionTypeDeclarationNode(node);
    }
  }

  void writeConstructorNodeList(List<Constructor> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Constructor node = nodes[i];
      writeConstructorNode(node);
    }
  }

  void writeSwitchCaseNodeList(List<SwitchCase> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final SwitchCase node = nodes[i];
      writeSwitchCaseNode(node);
    }
  }

  void writeCatchNodeList(List<Catch> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Catch node = nodes[i];
      writeCatchNode(node);
    }
  }

  void writeTypedefNodeList(List<Typedef> nodes) {
    final int len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Typedef node = nodes[i];
      writeTypedefNode(node);
    }
  }

  void writeNode(Node node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeFunctionNode(FunctionNode node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeArgumentsNode(Arguments node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeLibraryNode(Library node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeProcedureNode(Procedure node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeFieldNode(Field node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeClassNode(Class node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeExtensionNode(Extension node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeExtensionTypeDeclarationNode(ExtensionTypeDeclaration node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeConstructorNode(Constructor node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeSwitchCaseNode(SwitchCase node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeCatchNode(Catch node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeTypedefNode(Typedef node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeOptionalNode(Node? node) {
    if (node == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeNode(node);
    }
  }

  void writeLinkTable(Component component) {
    _binaryOffsetForLinkTable = getBufferOffset();
    writeList(_canonicalNameList, writeCanonicalNameEntry);
    _canonicalNameListDone = true;
  }

  void indexLinkTable(Component component) {
    _canonicalNameList = <CanonicalName>[];
    for (int i = 0; i < component.libraries.length; ++i) {
      Library library = component.libraries[i];
      if (libraryFilter == null || libraryFilter!(library)) {
        _indexLinkTableInternal(library.reference.canonicalName!);
        _knownCanonicalNameNonRootTops.add(library.reference.canonicalName!);
      }
    }
  }

  void _indexLinkTableInternal(CanonicalName node) {
    node.index = _canonicalNameList.length;
    assert(!_canonicalNameListDone);
    _canonicalNameList.add(node);
    Iterable<CanonicalName>? children = node.childrenOrNull;
    if (children != null) {
      for (CanonicalName child in children) {
        _indexLinkTableInternal(child);
      }
    }
  }

  /// Compute canonical names for the whole component or parts of it.
  void _computeCanonicalNames(Component component) {
    for (int i = 0; i < component.libraries.length; ++i) {
      Library library = component.libraries[i];
      if (libraryFilter == null || libraryFilter!(library)) {
        component.computeCanonicalNamesForLibrary(library);
      }
    }
  }

  void writeCanonicalNameEntry(CanonicalName node) {
    assert(node.isConsistent, node.getInconsistency());
    CanonicalName parent = node.parent!;
    if (parent.isRoot) {
      writeUInt30(0);
    } else {
      writeUInt30(parent.index + 1);
    }
    writeStringReference(node.name);
  }

  void writeComponentFile(Component component) {
    Timeline.timeSync("BinaryPrinter.writeComponentFile", () {
      compilationMode = component.mode;
      _computeCanonicalNames(component);
      final int componentOffset = getBufferOffset();
      writeUInt32(Tag.ComponentFile);
      writeUInt32(Tag.BinaryFormatVersion);
      writeBytes(ascii.encode(expectedSdkHash));
      writeListOfStrings(component.problemsAsJson);
      indexLinkTable(component);
      _collectMetadata(component);
      if (_metadataSubsections != null) {
        _writeNodeMetadataImpl(component, componentOffset);
      }
      libraryOffsets = <int>[];
      Procedure? mainMethod = component.mainMethod;
      if (mainMethod != null) {
        checkCanonicalName(_ensureCanonicalName(
            getNonNullableMemberReferenceGetter(mainMethod)));
      }
      writeLibraries(component);
      writeUriToSource(component.uriToSource);
      // Writing constants can add both strings and canonical names.
      writeConstantTable();
      writeConstantTableIndex();
      // Writing canonical names can add strings.
      writeLinkTable(component);
      // Writing metadata sections can add strings.
      _writeMetadataSection(component);
      writeStringTable(stringIndexer);
      List<Library> libraries = component.libraries;
      if (libraryFilter != null) {
        List<Library> librariesNew = <Library>[];
        for (int i = 0; i < libraries.length; i++) {
          Library library = libraries[i];
          if (libraryFilter!(library)) librariesNew.add(library);
        }
        libraries = librariesNew;
      }
      writeComponentIndex(component, libraries);

      _flush();
    });
  }

  void writeListOfStrings(List<String>? strings) {
    writeUInt30(strings?.length ?? 0);
    if (strings != null) {
      for (int i = 0; i < strings.length; i++) {
        String s = strings[i];
        outputStringViaBuffer(s, new Uint8List(s.length * 3));
      }
    }
  }

  /// Collect metadata repositories associated with the component.
  void _collectMetadata(Component component) {
    if (component.metadata.isNotEmpty) {
      // Component might be loaded lazily - meaning that we can't
      // just skip empty repositories here, they might be populated by
      // the serialization process. Instead we will filter empty repositories
      // later before writing the section out.
      _metadataSubsections = component.metadata.values
          .map((MetadataRepository repository) =>
              new _MetadataSubsection(repository))
          .toList();
    }
  }

  /// Writes metadata associated with the given [Node].
  void _writeNodeMetadata(Node node) {
    _writeNodeMetadataImpl(node, getBufferOffset());
  }

  void _writeNodeMetadataImpl(Node node, int nodeOffset) {
    for (_MetadataSubsection subsection in _metadataSubsections!) {
      final MetadataRepository<Object?> repository = subsection.repository;
      final Object? value = repository.mapping[node];
      if (value == null) {
        continue;
      }

      if (!MetadataRepository.isSupported(node)) {
        throw new ArgumentError(
            "Nodes of type ${node.runtimeType} can't have metadata.");
      }

      if (!identical(_sink, _mainSink)) {
        throw new ArgumentError(
            "Node written into metadata can't have metadata "
            "(metadata: ${repository.tag}, node: ${node.runtimeType} $node)");
      }

      _sink = _metadataSink;
      subsection.metadataMapping.add(nodeOffset);
      subsection.metadataMapping.add(getBufferOffset());
      repository.writeToBinary(value, node, this);
      _sink = _mainSink;
    }
  }

  void enterScope(
      {List<TypeParameter>? typeParameters,
      bool memberScope = false,
      bool variableScope = false}) {
    if (typeParameters != null) {
      _typeParameterIndexer.enter(typeParameters);
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (variableScope) {
      _variableIndexer ??= _newVariableIndexer();
      _variableIndexer!.pushScope();
    }
  }

  void leaveScope(
      {List<TypeParameter>? typeParameters,
      bool memberScope = false,
      bool variableScope = false}) {
    if (variableScope) {
      _variableIndexer!.popScope();
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (typeParameters != null) {
      _typeParameterIndexer.exit(typeParameters);
    }
  }

  void enterFunctionTypeScope(
      {List<StructuralParameter>? typeParameters,
      bool memberScope = false,
      bool variableScope = false}) {
    if (typeParameters != null) {
      _typeParameterIndexer.enterFunctionType(typeParameters);
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (variableScope) {
      _variableIndexer ??= _newVariableIndexer();
      _variableIndexer!.pushScope();
    }
  }

  void leaveFunctionTypeScope(
      {List<StructuralParameter>? typeParameters,
      bool memberScope = false,
      bool variableScope = false}) {
    if (variableScope) {
      _variableIndexer!.popScope();
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (typeParameters != null) {
      _typeParameterIndexer.exitFunctionType(typeParameters);
    }
  }

  void _writeMetadataSection(Component component) {
    // Make sure metadata payloads section is 8-byte aligned,
    // so certain kinds of metadata can contain aligned data.
    const int metadataPayloadsAlignment = 8;
    int padding = ((getBufferOffset() + metadataPayloadsAlignment - 1) &
            -metadataPayloadsAlignment) -
        getBufferOffset();
    for (int i = 0; i < padding; ++i) {
      writeByte(0);
    }

    _binaryOffsetForMetadataPayloads = getBufferOffset();
    _metadataSubsections
        ?.removeWhere((_MetadataSubsection s) => s.metadataMapping.isEmpty);

    if (_metadataSubsections == null || _metadataSubsections!.isEmpty) {
      _binaryOffsetForMetadataMappings = getBufferOffset();
      writeUInt32(0); // Empty section.
      return;
    }

    assert(identical(_sink, _mainSink));
    _metadataSink.flushAndDestroy();
    writeBytes((_metadataSink._sink as BytesSink).builder.takeBytes());

    // RList<MetadataMapping> metadataMappings
    _binaryOffsetForMetadataMappings = getBufferOffset();
    for (_MetadataSubsection subsection in _metadataSubsections!) {
      // UInt32 tag
      writeUInt32(stringIndexer.put(subsection.repository.tag));

      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      final int mappingLength = subsection.metadataMapping.length;
      for (int i = 0; i < mappingLength; i += 2) {
        writeUInt32(subsection.metadataMapping[i]); // node offset
        writeUInt32(subsection.metadataMapping[i + 1]); // metadata offset
      }
      writeUInt32(mappingLength ~/ 2);
    }
    writeUInt32(_metadataSubsections!.length);
  }

  /// Write all of some of the libraries of the [component].
  void writeLibraries(Component component) {
    for (int i = 0; i < component.libraries.length; ++i) {
      Library library = component.libraries[i];
      if (libraryFilter == null || libraryFilter!(library)) {
        writeLibraryNode(library);
      }
    }
  }

  void writeComponentIndex(Component component, List<Library> libraries) {
    // It is allowed to concatenate several kernel binaries to create a
    // multi-component kernel file. In order to maintain alignment of
    // metadata sections within kernel binaries after concatenation,
    // size of each kernel binary should be aligned.
    // Component index is located at the end of a kernel binary, so padding
    // is added before component index.
    const int kernelFileAlignment = 8;

    // Keep this in sync with number of writeUInt32 below.
    int numComponentIndexEntries = 10 + libraryOffsets.length + 3;
    int componentIndexOffset = getBufferOffset();

    int unalignedSize = componentIndexOffset + numComponentIndexEntries * 4;
    int padding =
        ((unalignedSize + kernelFileAlignment - 1) & -kernelFileAlignment) -
            unalignedSize;
    for (int i = 0; i < padding; ++i) {
      writeByte(0);
    }

    // Fixed-size ints at the end used as an index.
    assert(_binaryOffsetForSourceTable >= 0);
    writeUInt32(_binaryOffsetForSourceTable);
    assert(_binaryOffsetForConstantTable >= 0);
    writeUInt32(_binaryOffsetForConstantTable);
    assert(_binaryOffsetForConstantTableIndex >= 0);
    writeUInt32(_binaryOffsetForConstantTableIndex);
    assert(_binaryOffsetForLinkTable >= 0);
    writeUInt32(_binaryOffsetForLinkTable);
    assert(_binaryOffsetForMetadataPayloads >= 0);
    writeUInt32(_binaryOffsetForMetadataPayloads);
    assert(_binaryOffsetForMetadataMappings >= 0);
    writeUInt32(_binaryOffsetForMetadataMappings);
    assert(_binaryOffsetForStringTable >= 0);
    writeUInt32(_binaryOffsetForStringTable);
    assert(componentIndexOffset >= 0);
    writeUInt32(componentIndexOffset);

    Procedure? mainMethod = component.mainMethod;
    if (mainMethod == null) {
      writeUInt32(0);
    } else {
      CanonicalName main =
          _ensureCanonicalName(getNonNullableMemberReferenceGetter(mainMethod));
      writeUInt32(main.index + 1);
    }
    assert(component.modeRaw != null, "Component mode not set.");
    writeUInt32(component.mode.index);

    assert(libraryOffsets.length == libraries.length);
    for (int offset in libraryOffsets) {
      writeUInt32(offset);
    }
    writeUInt32(_binaryOffsetForSourceTable); // end of last library.
    writeUInt32(libraries.length);

    writeUInt32(getBufferOffset() + 4); // total size.
  }

  void writeUriToSource(Map<Uri, Source> uriToSource) {
    _binaryOffsetForSourceTable = getBufferOffset();

    int length = _sourceUriIndexer.index.length;
    writeUInt32(length);
    List<int> index = new List<int>.filled(
        length,
        // Dummy element value.
        -1);

    // Write data.
    int i = 0;
    Uint8List buffer = new Uint8List(1 << 16);
    for (Uri uri in _sourceUriIndexer.index.keys) {
      index[i] = getBufferOffset();
      Source? source = uriToSource[uri];
      if (source == null ||
          !(includeSources &&
              _sourcesFromRealImplementation.length > i &&
              _sourcesFromRealImplementation[i] == true)) {
        source = new Source(
            <int>[], const <int>[], source?.importUri, source?.fileUri);
      }

      String uriAsString = "$uri";
      outputStringViaBuffer(uriAsString, buffer);

      writeByteList(includeSourceBytes ? source.source : const []);

      {
        List<int> lineStarts = source.lineStarts!;
        writeUInt30(lineStarts.length);
        int previousLineStart = 0;
        for (int j = 0; j < lineStarts.length; ++j) {
          int lineStart = lineStarts[j];
          writeUInt30(lineStart - previousLineStart);
          previousLineStart = lineStart;
        }
      }

      String importUriAsString =
          source.importUri == null ? "" : "${source.importUri}";
      outputStringViaBuffer(importUriAsString, buffer);

      {
        Set<Reference>? coverage = source.constantCoverageConstructors;
        if (coverage == null || coverage.isEmpty) {
          writeUInt30(0);
        } else {
          writeUInt30(coverage.length);
          for (Reference reference in coverage) {
            writeNonNullReference(reference);
          }
        }
      }

      i++;
    }

    // Write index for random access.
    for (int i = 0; i < index.length; ++i) {
      writeUInt32(index[i]);
    }
  }

  void outputStringViaBuffer(String s, Uint8List buffer) {
    int length = _writeWtf8(buffer, 0, s);
    if (length >= 0) {
      writeUInt30(length);
      for (int j = 0; j < length; j++) {
        writeByte(buffer[j]);
      }
    } else {
      // Uncommon case with very long url.
      outputStringViaBuffer(s, new Uint8List(s.length * 3));
    }
  }

  void writeLibraryDependencyReference(LibraryDependency node) {
    int? index = _libraryDependencyIndex[node];
    if (index == null) {
      throw new ArgumentError(
          'Reference to library dependency $node out of scope');
    }
    writeUInt30(index);
  }

  void writeNullAllowedReference(Reference? reference) {
    if (reference == null) {
      writeUInt30(0);
    } else {
      assert(reference.isConsistent, reference.getInconsistency());
      CanonicalName name = _ensureCanonicalName(reference);
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void writeNonNullInstanceMemberReference(Reference reference) {
    writeNonNullReference(reference);
    writeNullAllowedReference(
        getMemberReferenceGetter(reference.asMember.memberSignatureOrigin));
  }

  void writeNonNullReference(Reference reference) {
    assert(reference.isConsistent, reference.getInconsistency());
    CanonicalName name = _ensureCanonicalName(reference);
    checkCanonicalName(name);
    writeUInt30(name.index + 1);
  }

  /// Returns the canonical name for [reference].
  ///
  /// If the canonical name has already been computed it is returned. Otherwise
  /// canonical names for the reference node and all of its parent nodes are
  /// created. If the reference doesn't have a node or the node is not part of
  /// a component, an error is thrown.
  ///
  /// This should not be used for reference of the member of the serialized
  /// libraries, for instance for `Library.reference` in [visitLibrary], since
  /// the canonical names of these references should already have been computed
  /// through [_computeCanonicalNames].
  CanonicalName _ensureCanonicalName(Reference reference) {
    CanonicalName? canonicalName = reference.canonicalName;
    if (canonicalName != null) {
      return canonicalName;
    }

    CanonicalName ensureCanonicalNameForNode(TreeNode? parentNode) {
      if (parentNode is Component) {
        return parentNode.root;
      }
      if (parentNode is NamedNode) {
        CanonicalName? canonicalName = parentNode.reference.canonicalName;
        if (canonicalName != null) {
          return canonicalName;
        }
        CanonicalName parentCanonicalName =
            ensureCanonicalNameForNode(parentNode.parent);
        parentNode.bindCanonicalNames(parentCanonicalName);
        return parentNode.reference.canonicalName!;
      } else {
        throw new ArgumentError('Missing canonical name for $reference');
      }
    }

    ensureCanonicalNameForNode(reference.node);
    return reference.canonicalName!;
  }

  void checkCanonicalName(CanonicalName node) {
    if (_knownCanonicalNameNonRootTops.contains(node.nonRootTop)) return;
    if (node.isRoot) return;
    if (node.index >= 0 && node.index < _canonicalNameList.length) {
      CanonicalName claim = _canonicalNameList[node.index];
      if (node == claim) {
        // Already has the claimed index.
        return;
      }
    }
    checkCanonicalName(node.parent!);
    node.index = _canonicalNameList.length;
    assert(!_canonicalNameListDone);
    _canonicalNameList.add(node);
  }

  void _writeNullAllowedCanonicalName(CanonicalName? canonicalName) {
    if (canonicalName == null) {
      writeUInt30(0);
    } else {
      _writeNonNullCanonicalName(canonicalName);
    }
  }

  @override
  void writeNullAllowedCanonicalNameReference(Reference? reference) {
    if (reference == null) {
      writeUInt30(0);
    } else {
      CanonicalName name = _ensureCanonicalName(reference);
      _writeNonNullCanonicalName(name);
    }
  }

  void _writeNonNullCanonicalName(CanonicalName canonicalName) {
    checkCanonicalName(canonicalName);
    writeUInt30(canonicalName.index + 1);
  }

  void writeNonNullCanonicalNameReference(Reference reference) {
    CanonicalName name = _ensureCanonicalName(reference);
    checkCanonicalName(name);
    writeUInt30(name.index + 1);
  }

  void writeOffset(int offset) {
    // TODO(jensj): Delta-encoding.
    // File offset ranges from -1 and up,
    // but is here saved as unsigned (thus the +1)
    if (!includeOffsets) {
      writeUInt30(0);
    } else {
      writeUInt30(offset + 1);
    }
  }

  void writeClassReference(Class class_) {
    writeNonNullCanonicalNameReference(class_.reference);
  }

  void writeName(Name node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    writeStringReference(node.text);
    // TODO: Consider a more compressed format for private names within the
    // enclosing library.
    if (node.isPrivate) {
      writeNonNullCanonicalNameReference(node.library!.reference);
    }
  }

  @override
  void visitLibrary(Library node) {
    _currentLibrary = node;

    libraryOffsets.add(getBufferOffset());
    writeByte(node.flags);

    assert(
        mergeCompilationModeOrThrow(
                compilationMode, node.nonNullableByDefaultCompiledMode) ==
            compilationMode,
        "Cannot have ${node.nonNullableByDefaultCompiledMode} "
        "in component with mode $compilationMode");

    writeUInt30(node.languageVersion.major);
    writeUInt30(node.languageVersion.minor);

    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    _writeNonNullCanonicalName(canonicalName);
    writeStringReference(node.name ?? '');
    writeUriReference(node.fileUri);
    writeListOfStrings(node.problemsAsJson);
    enterScope(memberScope: true);
    writeAnnotationList(node.annotations);
    writeLibraryDependencies(node);
    writeAdditionalExports(node.additionalExports);
    writeLibraryParts(node);
    leaveScope(memberScope: true);

    writeTypedefNodeList(node.typedefs);
    classOffsets = <int>[];
    writeClassNodeList(node.classes);
    classOffsets.add(getBufferOffset());
    writeExtensionNodeList(node.extensions);
    writeExtensionTypeDeclarationNodeList(node.extensionTypeDeclarations);
    writeFieldNodeList(node.fields);
    procedureOffsets = <int>[];
    writeProcedureNodeList(node.procedures);
    procedureOffsets.add(getBufferOffset());

    // Dump all source-references used in this library; used by the VM.
    int sourceReferencesOffset = getBufferOffset();
    int sourceReferencesCount = 0;
    // Note: We start at 1 because 0 is the null-entry and we don't want to
    // include that.
    for (int i = 1; i < _sourcesUsedInLibrary.length; i++) {
      if (_sourcesUsedInLibrary[i] == true) {
        sourceReferencesCount++;
      }
    }
    writeUInt30(sourceReferencesCount);
    for (int i = 1; i < _sourcesUsedInLibrary.length; i++) {
      if (_sourcesUsedInLibrary[i] == true) {
        writeUInt30(i);
        _sourcesUsedInLibrary[i] = false;
      }
    }

    // Fixed-size ints at the end used as an index.
    writeUInt32(sourceReferencesOffset);
    assert(classOffsets.length > 0);
    for (int i = 0; i < classOffsets.length; ++i) {
      int offset = classOffsets[i];
      writeUInt32(offset);
    }
    writeUInt32(classOffsets.length - 1);

    assert(procedureOffsets.length > 0);
    for (int i = 0; i < procedureOffsets.length; ++i) {
      int offset = procedureOffsets[i];
      writeUInt32(offset);
    }
    writeUInt32(procedureOffsets.length - 1);

    _currentLibrary = null;
  }

  void writeLibraryDependencies(Library library) {
    _libraryDependencyIndex = library.dependencies.isEmpty
        ? const <LibraryDependency, int>{}
        : <LibraryDependency, int>{};
    writeUInt30(library.dependencies.length);
    for (int i = 0; i < library.dependencies.length; ++i) {
      LibraryDependency importNode = library.dependencies[i];
      _libraryDependencyIndex[importNode] = i;
      writeLibraryDependency(importNode);
    }
  }

  void writeAdditionalExports(List<Reference> additionalExports) {
    writeUInt30(additionalExports.length);
    for (Reference ref in additionalExports) {
      writeNonNullReference(ref);
    }
  }

  void writeLibraryDependency(LibraryDependency node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeAnnotationList(node.annotations);
    writeNonNullCanonicalNameReference(node.targetLibrary.reference);
    writeStringReference(node.name ?? '');
    writeNodeList(node.combinators);
  }

  @override
  void visitCombinator(Combinator node) {
    writeByte(node.isShow ? 1 : 0);
    writeStringReferenceList(node.names);
  }

  void writeLibraryParts(Library library) {
    writeUInt30(library.parts.length);
    for (int i = 0; i < library.parts.length; ++i) {
      LibraryPart partNode = library.parts[i];
      writeLibraryPart(partNode);
    }
  }

  void writeLibraryPart(LibraryPart node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    writeAnnotationList(node.annotations);
    writeStringReference(node.partUri);
  }

  @override
  void visitTypedef(Typedef node) {
    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    enterScope(memberScope: true);
    _writeNonNullCanonicalName(canonicalName);
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeStringReference(node.name);
    writeAnnotationList(node.annotations);

    enterScope(typeParameters: node.typeParameters, variableScope: true);
    writeNodeList(node.typeParameters);
    writeNode(node.type!);

    leaveScope(typeParameters: node.typeParameters, variableScope: true);
    leaveScope(memberScope: true);
  }

  void writeAnnotation(Expression annotation) {
    writeNode(annotation);
  }

  void writeAnnotationList(List<Expression> annotations) {
    final int len = annotations.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final Expression annotation = annotations[i];
      writeAnnotation(annotation);
    }
  }

  @override
  void visitClass(Class node) {
    classOffsets.add(getBufferOffset());

    if (node.isAnonymousMixin) _currentlyInNonimplementation = true;

    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    writeByte(Tag.Class);
    _writeNonNullCanonicalName(canonicalName);
    writeUriReference(node.fileUri);
    writeOffset(node.startFileOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);

    writeUInt30(node.flags);
    writeStringReference(node.name);

    enterScope(memberScope: true);
    writeAnnotationList(node.annotations);
    leaveScope(memberScope: true);
    enterScope(typeParameters: node.typeParameters);
    writeNodeList(node.typeParameters);
    writeOptionalNode(node.supertype);
    writeOptionalNode(node.mixedInType);
    writeNodeList(node.implementedTypes);
    writeFieldNodeList(node.fields);
    writeConstructorNodeList(node.constructors);
    procedureOffsets = <int>[];
    writeProcedureNodeList(node.procedures);
    procedureOffsets.add(getBufferOffset());
    leaveScope(typeParameters: node.typeParameters);

    assert(procedureOffsets.length > 0);
    for (int i = 0; i < procedureOffsets.length; ++i) {
      int offset = procedureOffsets[i];
      writeUInt32(offset);
    }
    writeUInt32(procedureOffsets.length - 1);
    _currentlyInNonimplementation = false;
  }

  @override
  void visitConstructor(Constructor node) {
    CanonicalName? canonicalName =
        getNonNullableMemberReferenceGetter(node).canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    enterScope(memberScope: true);
    writeByte(Tag.Constructor);
    _writeNonNullCanonicalName(canonicalName);
    writeUriReference(node.fileUri);
    writeOffset(node.startFileOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);

    writeByte(node.flags);
    writeName(node.name);

    writeAnnotationList(node.annotations);
    assert(node.function.typeParameters.isEmpty);
    writeFunctionNode(node.function);
    // Parameters are in scope in the initializers.
    _variableIndexer ??= _newVariableIndexer();
    _variableIndexer!.restoreScope(node.function.positionalParameters.length +
        node.function.namedParameters.length);
    writeNodeList(node.initializers);

    leaveScope(memberScope: true);
  }

  @override
  void visitProcedure(Procedure node) {
    assert(!(node.isMemberSignature && node.stubTargetReference == null),
        "No member signature origin for member signature $node.");
    assert(
        !(node.abstractForwardingStubTarget is Procedure &&
            (node.abstractForwardingStubTarget as Procedure).isMemberSignature),
        "Forwarding stub interface target is member signature: $node.");
    assert(
        !(node.concreteForwardingStubTarget is Procedure &&
            (node.concreteForwardingStubTarget as Procedure).isMemberSignature),
        "Forwarding stub super target is member signature: $node.");

    procedureOffsets.add(getBufferOffset());

    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    String? orphancy = node.reference.getOrphancyDescription(node);
    if (orphancy != null) {
      throw new ArgumentError(
          'Trying to serialize orphaned procedure reference.\n'
          'Orphaned procedure ${node} (${node.runtimeType}:${node.hashCode})\n'
          '${orphancy}');
    }
    orphancy = canonicalName.getOrphancyDescription(node, node.reference);
    if (orphancy != null) {
      throw new ArgumentError(
          'Trying to serialize orphaned procedure canonical name.\n'
          'Orphaned procedure ${node} (${node.runtimeType}:${node.hashCode})\n'
          '${orphancy}');
    }

    final bool currentlyInNonimplementationSaved =
        _currentlyInNonimplementation;
    if (node.isNoSuchMethodForwarder || node.isSyntheticForwarder) {
      _currentlyInNonimplementation = true;
    }

    enterScope(memberScope: true);
    writeByte(Tag.Procedure);
    _writeNonNullCanonicalName(canonicalName);
    writeUriReference(node.fileUri);
    writeOffset(node.fileStartOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.kind.index);
    writeByte(node.stubKind.index);
    writeUInt30(node.flags);
    writeName(node.name);
    writeAnnotationList(node.annotations);
    writeNullAllowedReference(node.stubTargetReference);
    writeOptionalNode(node.signatureType);
    writeFunctionNode(node.function);
    leaveScope(memberScope: true);
    _currentlyInNonimplementation = currentlyInNonimplementationSaved;
    assert(
        (node.concreteForwardingStubTarget != null) ||
            !(node.isForwardingStub && node.function.body != null),
        "Invalid forwarding stub $node.");
  }

  @override
  void visitField(Field node) {
    CanonicalName? fieldCanonicalName = node.fieldReference.canonicalName;
    if (fieldCanonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    String? fieldOrphancy = node.fieldReference.getOrphancyDescription(node);
    if (fieldOrphancy != null) {
      throw new ArgumentError('Trying to serialize orphaned field reference.\n'
          '${fieldOrphancy}');
    }
    fieldOrphancy =
        fieldCanonicalName.getOrphancyDescription(node, node.fieldReference);
    if (fieldOrphancy != null) {
      throw new ArgumentError(
          'Trying to serialize orphaned field canonical name.\n'
          '(${node.runtimeType}:${node.hashCode})\n'
          '${fieldOrphancy}');
    }

    CanonicalName? getterCanonicalName = node.getterReference.canonicalName;
    if (getterCanonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    String? getterOrphancy = node.getterReference.getOrphancyDescription(node);
    if (getterOrphancy != null) {
      throw new ArgumentError('Trying to serialize orphaned getter reference.\n'
          '${getterOrphancy}');
    }
    getterOrphancy =
        getterCanonicalName.getOrphancyDescription(node, node.getterReference);
    if (getterOrphancy != null) {
      throw new ArgumentError(
          'Trying to serialize orphaned getter canonical name.\n'
          '(${node.runtimeType}:${node.hashCode})\n'
          '${getterOrphancy}');
    }

    CanonicalName? setterCanonicalName;
    if (node.hasSetter) {
      Reference setterReference = node.setterReference!;
      setterCanonicalName = setterReference.canonicalName;
      if (setterCanonicalName == null) {
        throw new ArgumentError('Missing canonical name for $node');
      }
      String? setterOrphancy = setterReference.getOrphancyDescription(node);
      if (setterOrphancy != null) {
        throw new ArgumentError(
            'Trying to serialize orphaned setter reference.\n'
            '${setterOrphancy}');
      }
      setterOrphancy =
          setterCanonicalName.getOrphancyDescription(node, setterReference);
      if (setterOrphancy != null) {
        throw new ArgumentError(
            'Trying to serialize orphaned setter canonical name.\n'
            '${setterOrphancy}');
      }
    }
    enterScope(memberScope: true);
    writeByte(Tag.Field);
    _writeNonNullCanonicalName(fieldCanonicalName);
    _writeNonNullCanonicalName(getterCanonicalName);
    _writeNullAllowedCanonicalName(setterCanonicalName);
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeUInt30(node.flags);
    writeName(node.name);
    writeAnnotationList(node.annotations);
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    leaveScope(memberScope: true);
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    writeByte(Tag.InvalidInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    writeByte(Tag.FieldInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.fieldReference);
    writeNode(node.value);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    writeByte(Tag.SuperInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
    writeArgumentsNode(node.arguments);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    writeByte(Tag.RedirectingInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
    writeArgumentsNode(node.arguments);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    writeByte(Tag.LocalInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeVariableDeclaration(node.variable);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    writeByte(Tag.AssertInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeNode(node.statement);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    writeByte(Tag.FunctionNode);
    enterScope(typeParameters: node.typeParameters, variableScope: true);
    LabelIndexer? oldLabels = _labelIndexer;
    _labelIndexer = null;
    SwitchCaseIndexer? oldCases = _switchCaseIndexer;
    _switchCaseIndexer = null;
    // Note: FunctionNode has no tag.
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.asyncMarker.index);
    writeByte(node.dartAsyncMarker.index);
    writeNodeList(node.typeParameters);
    writeUInt30(node.positionalParameters.length + node.namedParameters.length);
    writeUInt30(node.requiredParameterCount);
    writeVariableDeclarationList(node.positionalParameters);
    writeVariableDeclarationList(node.namedParameters);
    writeNode(node.returnType);
    writeOptionalNode(node.emittedValueType);
    RedirectingFactoryTarget? redirectingFactoryTarget =
        node.redirectingFactoryTarget;
    if (redirectingFactoryTarget == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeNullAllowedReference(redirectingFactoryTarget.targetReference);
      List<DartType>? typeArguments = redirectingFactoryTarget.typeArguments;
      if (typeArguments == null) {
        writeByte(Tag.Nothing);
      } else {
        writeByte(Tag.Something);
        writeNodeList(typeArguments);
      }
      String? errorMessage = redirectingFactoryTarget.errorMessage;
      if (errorMessage == null) {
        writeByte(Tag.Nothing);
      } else {
        writeByte(Tag.Something);
        writeStringReference(errorMessage);
      }
    }
    writeOptionalNode(node.body);
    _labelIndexer = oldLabels;
    _switchCaseIndexer = oldCases;
    leaveScope(typeParameters: node.typeParameters, variableScope: true);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    writeByte(Tag.InvalidExpression);
    writeOffset(node.fileOffset);
    writeStringReference(node.message ?? '');
    writeOptionalNode(node.expression);
  }

  @override
  void visitVariableGet(VariableGet node) {
    int index = _getVariableIndex(node.variable);
    if (index & Tag.SpecializedPayloadMask == index &&
        node.promotedType == null) {
      writeByte(Tag.SpecializedVariableGet + index);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
    } else {
      writeByte(Tag.VariableGet);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
      writeUInt30(index);
      writeOptionalNode(node.promotedType);
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
    int index = _getVariableIndex(node.variable);
    if (index & Tag.SpecializedPayloadMask == index) {
      writeByte(Tag.SpecializedVariableSet + index);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
      writeNode(node.value);
    } else {
      writeByte(Tag.VariableSet);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
      writeUInt30(index);
      writeNode(node.value);
    }
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    writeByte(Tag.DynamicGet);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    writeByte(Tag.InstanceGet);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeDartType(node.resultType);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitRecordIndexGet(RecordIndexGet node) {
    writeByte(Tag.RecordIndexGet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeDartType(node.receiverType);
    writeUInt30(node.index);
  }

  @override
  void visitRecordNameGet(RecordNameGet node) {
    writeByte(Tag.RecordNameGet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeDartType(node.receiverType);
    writeStringReference(node.name);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    writeByte(Tag.InstanceTearOff);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeDartType(node.resultType);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    writeByte(Tag.DynamicSet);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.value);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    writeByte(Tag.InstanceSet);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.value);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) {
    writeByte(Tag.AbstractSuperPropertyGet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitAbstractSuperPropertySet(AbstractSuperPropertySet node) {
    writeByte(Tag.AbstractSuperPropertySet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNode(node.value);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    writeByte(Tag.SuperPropertyGet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    writeByte(Tag.SuperPropertySet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNode(node.value);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitStaticGet(StaticGet node) {
    writeByte(Tag.StaticGet);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    writeByte(Tag.ConstructorTearOff);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
  }

  @override
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    writeByte(Tag.RedirectingFactoryTearOff);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    writeByte(Tag.TypedefTearOff);
    writeOffset(node.fileOffset);
    enterScope(typeParameters: node.typeParameters);
    writeNodeList(node.typeParameters);
    writeNode(node.expression);
    writeNodeList(node.typeArguments);
    leaveScope(typeParameters: node.typeParameters);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    writeByte(Tag.StaticTearOff);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
  }

  @override
  void visitStaticSet(StaticSet node) {
    writeByte(Tag.StaticSet);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
    writeNode(node.value);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    writeByte(Tag.DynamicInvocation);
    writeByte(node.kind.index);
    writeByte(node.flags);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    writeByte(Tag.EqualsCall);
    writeOffset(node.fileOffset);
    writeNode(node.left);
    writeNode(node.right);
    writeDartType(node.functionType);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitEqualsNull(EqualsNull node) {
    writeByte(Tag.EqualsNull);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    writeByte(Tag.FunctionInvocation);
    writeByte(node.kind.index);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeArgumentsNode(node.arguments);
    // `const DynamicType()` is used to encode a missing function type.
    writeDartType(node.functionType ?? const DynamicType());
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    writeByte(Tag.InstanceInvocation);
    writeByte(node.kind.index);
    writeByte(node.flags);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    writeDartType(node.functionType);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    writeByte(Tag.InstanceGetterInvocation);
    writeByte(node.kind.index);
    writeByte(node.flags);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    // `const DynamicType()` is used to encode a missing function type.
    writeDartType(node.functionType ?? const DynamicType());
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    writeByte(Tag.LocalFunctionInvocation);
    writeOffset(node.fileOffset);
    _writeVariableReference(node.variable);
    writeArgumentsNode(node.arguments);
    writeDartType(node.functionType);
  }

  @override
  void visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node) {
    writeByte(Tag.AbstractSuperMethodInvocation);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    writeByte(Tag.SuperMethodInvocation);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    writeNonNullInstanceMemberReference(node.interfaceTargetReference);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    writeByte(node.isConst ? Tag.ConstStaticInvocation : Tag.StaticInvocation);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
    writeArgumentsNode(node.arguments);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    writeByte(node.isConst
        ? Tag.ConstConstructorInvocation
        : Tag.ConstructorInvocation);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.targetReference);
    writeArgumentsNode(node.arguments);
  }

  @override
  void visitArguments(Arguments node) {
    writeUInt30(node.positional.length + node.named.length);
    writeNodeList(node.types);
    writeNodeList(node.positional);
    writeNodeList(node.named);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    writeStringReference(node.name);
    writeNode(node.value);
  }

  @override
  void visitNot(Not node) {
    writeByte(Tag.Not);
    writeOffset(node.fileOffset);
    writeNode(node.operand);
  }

  @override
  void visitNullCheck(NullCheck node) {
    writeByte(Tag.NullCheck);
    writeOffset(node.fileOffset);
    writeNode(node.operand);
  }

  int logicalOperatorIndex(LogicalExpressionOperator operator) {
    switch (operator) {
      case LogicalExpressionOperator.AND:
        return 0;
      case LogicalExpressionOperator.OR:
        return 1;
    }
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    writeByte(Tag.LogicalExpression);
    writeOffset(node.fileOffset);
    writeNode(node.left);
    writeByte(logicalOperatorIndex(node.operatorEnum));
    writeNode(node.right);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    writeByte(Tag.ConditionalExpression);
    writeOffset(node.fileOffset);
    writeNode(node.condition);
    writeNode(node.then);
    writeNode(node.otherwise);
    writeOptionalNode(node.staticType);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    writeByte(Tag.StringConcatenation);
    writeOffset(node.fileOffset);
    writeNodeList(node.expressions);
  }

  @override
  void visitListConcatenation(ListConcatenation node) {
    writeByte(Tag.ListConcatenation);
    writeOffset(node.fileOffset);
    writeNode(node.typeArgument);
    writeNodeList(node.lists);
  }

  @override
  void visitSetConcatenation(SetConcatenation node) {
    writeByte(Tag.SetConcatenation);
    writeOffset(node.fileOffset);
    writeNode(node.typeArgument);
    writeNodeList(node.sets);
  }

  @override
  void visitMapConcatenation(MapConcatenation node) {
    writeByte(Tag.MapConcatenation);
    writeOffset(node.fileOffset);
    writeNode(node.keyType);
    writeNode(node.valueType);
    writeNodeList(node.maps);
  }

  @override
  void visitInstanceCreation(InstanceCreation node) {
    writeByte(Tag.InstanceCreation);
    writeOffset(node.fileOffset);
    writeNonNullReference(node.classReference);
    writeNodeList(node.typeArguments);
    writeUInt30(node.fieldValues.length);
    node.fieldValues.forEach((Reference fieldRef, Expression value) {
      writeNonNullReference(fieldRef);
      writeNode(value);
    });
    writeNodeList(node.asserts);
    writeNodeList(node.unusedArguments);
  }

  @override
  void visitFileUriExpression(FileUriExpression node) {
    writeByte(Tag.FileUriExpression);
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
  }

  @override
  void visitIsExpression(IsExpression node) {
    writeByte(Tag.IsExpression);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.operand);
    writeNode(node.type);
  }

  @override
  void visitAsExpression(AsExpression node) {
    writeByte(Tag.AsExpression);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.operand);
    writeNode(node.type);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    writeByte(Tag.StringLiteral);
    writeOffset(node.fileOffset);
    writeStringReference(node.value);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    writeInteger(node.value, node.fileOffset);
  }

  void writeInteger(int value, int fileOffset) {
    int biasedValue = value + Tag.SpecializedIntLiteralBias;
    if (biasedValue >= 0 &&
        biasedValue & Tag.SpecializedPayloadMask == biasedValue) {
      writeByte(Tag.SpecializedIntLiteral + biasedValue);
      writeOffset(fileOffset);
    } else if (value.abs() >> 30 == 0) {
      if (value < 0) {
        writeByte(Tag.NegativeIntLiteral);
        writeOffset(fileOffset);
        writeUInt30(-value);
      } else {
        writeByte(Tag.PositiveIntLiteral);
        writeOffset(fileOffset);
        writeUInt30(value);
      }
    } else {
      // TODO: Pick a better format for big int literals.
      writeByte(Tag.BigIntLiteral);
      writeOffset(fileOffset);
      writeStringReference('$value');
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    writeByte(Tag.DoubleLiteral);
    writeOffset(node.fileOffset);
    writeDouble(node.value);
  }

  void writeDouble(double value) {
    _sink.addDouble(value);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    writeByte(node.value ? Tag.TrueLiteral : Tag.FalseLiteral);
    writeOffset(node.fileOffset);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    writeByte(Tag.NullLiteral);
    writeOffset(node.fileOffset);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    writeByte(Tag.SymbolLiteral);
    writeOffset(node.fileOffset);
    writeStringReference(node.value);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    writeByte(Tag.TypeLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.type);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    writeByte(Tag.ThisExpression);
    writeOffset(node.fileOffset);
  }

  @override
  void visitRethrow(Rethrow node) {
    writeByte(Tag.Rethrow);
    writeOffset(node.fileOffset);
  }

  @override
  void visitThrow(Throw node) {
    writeByte(Tag.Throw);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.expression);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    writeByte(node.isConst ? Tag.ConstListLiteral : Tag.ListLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.typeArgument);
    writeNodeList(node.expressions);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    writeByte(node.isConst ? Tag.ConstSetLiteral : Tag.SetLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.typeArgument);
    writeNodeList(node.expressions);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    writeByte(node.isConst ? Tag.ConstMapLiteral : Tag.MapLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.keyType);
    writeNode(node.valueType);
    writeNodeList(node.entries);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    // Note: there is no tag on MapEntry
    writeNode(node.key);
    writeNode(node.value);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    writeByte(node.isConst ? Tag.ConstRecordLiteral : Tag.RecordLiteral);
    writeOffset(node.fileOffset);
    writeNodeList(node.positional);
    writeNodeList(node.named);
    writeNode(node.recordType);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    writeByte(Tag.AwaitExpression);
    writeOffset(node.fileOffset);
    writeNode(node.operand);
    writeOptionalNode(node.runtimeCheckType);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    writeByte(Tag.FunctionExpression);
    writeOffset(node.fileOffset);
    writeFunctionNode(node.function);
  }

  @override
  void visitLet(Let node) {
    writeByte(Tag.Let);
    writeOffset(node.fileOffset);
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeVariableDeclaration(node.variable);
    writeNode(node.body);
    variableIndexer.popScope();
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    writeByte(Tag.BlockExpression);
    writeOffset(node.fileOffset);
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeNodeList(node.body.statements);
    writeNode(node.value);
    variableIndexer.popScope();
  }

  @override
  void visitInstantiation(Instantiation node) {
    writeByte(Tag.Instantiation);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeNodeList(node.typeArguments);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    writeByte(Tag.LoadLibrary);
    writeOffset(node.fileOffset);
    writeLibraryDependencyReference(node.import);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeByte(Tag.CheckLibraryIsLoaded);
    writeOffset(node.fileOffset);
    writeLibraryDependencyReference(node.import);
  }

  void writeStatementOrEmpty(Statement? node) {
    if (node == null) {
      writeByte(Tag.EmptyStatement);
    } else {
      writeNode(node);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    writeByte(Tag.ExpressionStatement);
    writeNode(node.expression);
  }

  @override
  void visitBlock(Block node) {
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeByte(Tag.Block);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeNodeList(node.statements);
    variableIndexer.popScope();
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeByte(Tag.AssertBlock);
    writeNodeList(node.statements);
    variableIndexer.popScope();
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    writeByte(Tag.EmptyStatement);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    writeByte(Tag.AssertStatement);
    writeNode(node.condition);
    writeOffset(node.conditionStartOffset);
    writeOffset(node.conditionEndOffset);
    writeOptionalNode(node.message);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    LabelIndexer labelIndexer = _labelIndexer ??= new LabelIndexer();
    labelIndexer.enter(node);
    writeByte(Tag.LabeledStatement);
    writeOffset(node.fileOffset);
    writeNode(node.body);
    labelIndexer.exit();
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    if (node is FileUriConstantExpression) {
      writeByte(Tag.FileUriConstantExpression);
      writeOffset(node.fileOffset);
      writeUriReference(node.fileUri);
      writeDartType(node.type);
      writeConstantReference(node.constant);
    } else {
      writeByte(Tag.ConstantExpression);
      writeOffset(node.fileOffset);
      writeDartType(node.type);
      writeConstantReference(node.constant);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    writeByte(Tag.BreakStatement);
    writeOffset(node.fileOffset);
    writeUInt30(_labelIndexer![node.target]!);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    writeByte(Tag.WhileStatement);
    writeOffset(node.fileOffset);
    writeNode(node.condition);
    writeNode(node.body);
  }

  @override
  void visitDoStatement(DoStatement node) {
    writeByte(Tag.DoStatement);
    writeOffset(node.fileOffset);
    writeNode(node.body);
    writeNode(node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeByte(Tag.ForStatement);
    writeOffset(node.fileOffset);
    writeVariableDeclarationList(node.variables);
    writeOptionalNode(node.condition);
    writeNodeList(node.updates);
    writeNode(node.body);
    variableIndexer.popScope();
  }

  @override
  void visitForInStatement(ForInStatement node) {
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeByte(node.isAsync ? Tag.AsyncForInStatement : Tag.ForInStatement);
    writeOffset(node.fileOffset);
    writeOffset(node.bodyOffset);
    writeVariableDeclaration(node.variable);
    writeNode(node.iterable);
    writeNode(node.body);
    variableIndexer.popScope();
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    SwitchCaseIndexer switchCaseIndexer =
        _switchCaseIndexer ??= new SwitchCaseIndexer();
    switchCaseIndexer.enter(node);
    writeByte(Tag.SwitchStatement);
    writeOffset(node.fileOffset);
    writeByte(node.isExplicitlyExhaustive ? 1 : 0);
    writeNode(node.expression);
    writeOptionalNode(node.expressionTypeInternal);
    writeSwitchCaseNodeList(node.cases);
    switchCaseIndexer.exit(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // Note: there is no tag on SwitchCase.
    writeOffset(node.fileOffset);
    int length = node.expressions.length;
    writeUInt30(length);
    for (int i = 0; i < length; ++i) {
      writeOffset(node.expressionOffsets[i]);
      writeNode(node.expressions[i]);
    }
    writeByte(node.isDefault ? 1 : 0);
    writeNode(node.body);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    writeByte(Tag.ContinueSwitchStatement);
    writeOffset(node.fileOffset);
    writeUInt30(_switchCaseIndexer![node.target]!);
  }

  @override
  void visitIfStatement(IfStatement node) {
    writeByte(Tag.IfStatement);
    writeOffset(node.fileOffset);
    writeNode(node.condition);
    writeNode(node.then);
    writeStatementOrEmpty(node.otherwise);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    writeByte(Tag.ReturnStatement);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.expression);
  }

  int _encodeTryCatchFlags(bool needsStackTrace, bool isSynthetic) {
    return (needsStackTrace ? 1 : 0) | (isSynthetic ? 2 : 0);
  }

  @override
  void visitTryCatch(TryCatch node) {
    writeByte(Tag.TryCatch);
    writeOffset(node.fileOffset);
    writeNode(node.body);
    bool needsStackTrace = node.catches.any((Catch c) => c.stackTrace != null);
    writeByte(_encodeTryCatchFlags(needsStackTrace, node.isSynthetic));
    writeCatchNodeList(node.catches);
  }

  @override
  void visitCatch(Catch node) {
    // Note: there is no tag on Catch.
    VariableIndexer variableIndexer =
        _variableIndexer ??= _newVariableIndexer();
    variableIndexer.pushScope();
    writeOffset(node.fileOffset);
    writeNode(node.guard);
    writeOptionalVariableDeclaration(node.exception);
    writeOptionalVariableDeclaration(node.stackTrace);
    writeNode(node.body);
    variableIndexer.popScope();
  }

  @override
  void visitTryFinally(TryFinally node) {
    writeByte(Tag.TryFinally);
    writeOffset(node.fileOffset);
    writeNode(node.body);
    writeNode(node.finalizer);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    writeByte(Tag.YieldStatement);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.expression);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    writeByte(Tag.VariableDeclaration);
    writeVariableDeclaration(node);
  }

  void writeVariableDeclaration(VariableDeclaration node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.binaryOffsetNoTag = getBufferOffset();
    writeOffset(node.fileOffset);
    writeOffset(node.fileEqualsOffset);
    writeAnnotationList(node.annotations);
    writeUInt30(node.flags);
    writeStringReference(node.name ?? '');
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    // Declare the variable after its initializer. It is not in scope in its
    // own initializer.
    (_variableIndexer ??= _newVariableIndexer()).declare(node);
  }

  void writeVariableDeclarationList(List<VariableDeclaration> nodes) {
    writeList(nodes, writeVariableDeclaration);
  }

  void writeOptionalVariableDeclaration(VariableDeclaration? node) {
    if (node == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeVariableDeclaration(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    writeByte(Tag.FunctionDeclaration);
    writeOffset(node.fileOffset);
    writeVariableDeclaration(node.variable);
    writeFunctionNode(node.function);
  }

  @override
  void visitNeverType(NeverType node) {
    writeByte(Tag.NeverType);
    writeByte(node.nullability.index);
  }

  @override
  void visitInvalidType(InvalidType node) {
    writeByte(Tag.InvalidType);
  }

  @override
  void visitDynamicType(DynamicType node) {
    writeByte(Tag.DynamicType);
  }

  @override
  void visitVoidType(VoidType node) {
    writeByte(Tag.VoidType);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    if (node.typeArguments.isEmpty) {
      writeByte(Tag.SimpleInterfaceType);
      writeByte(node.nullability.index);
      writeNonNullReference(node.classReference);
    } else {
      writeByte(Tag.InterfaceType);
      writeByte(node.nullability.index);
      writeNonNullReference(node.classReference);
      writeNodeList(node.typeArguments);
    }
  }

  @override
  void visitExtensionType(ExtensionType node) {
    writeByte(Tag.ExtensionType);
    writeByte(node.declaredNullability.index);
    writeNonNullReference(node.extensionTypeDeclarationReference);
    writeNodeList(node.typeArguments);
    writeNode(node.extensionTypeErasure);
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    writeByte(Tag.FutureOrType);
    writeByte(node.declaredNullability.index);
    writeNode(node.typeArgument);
  }

  @override
  void visitNullType(NullType node) {
    writeByte(Tag.NullType);
  }

  @override
  void visitSupertype(Supertype node) {
    // Writing nullability below is only necessary because
    // BinaryBuilder.readSupertype reads the supertype as an InterfaceType and
    // breaks it into components afterwards, and reading an InterfaceType
    // requires the nullability byte.
    if (node.typeArguments.isEmpty) {
      writeByte(Tag.SimpleInterfaceType);
      writeByte(_currentLibrary!.nonNullable.index);
      writeNonNullReference(node.className);
    } else {
      writeByte(Tag.InterfaceType);
      writeByte(_currentLibrary!.nonNullable.index);
      writeNonNullReference(node.className);
      writeNodeList(node.typeArguments);
    }
  }

  @override
  void visitFunctionType(FunctionType node) {
    if (node.requiredParameterCount == node.positionalParameters.length &&
        node.typeParameters.isEmpty &&
        node.namedParameters.isEmpty) {
      writeByte(Tag.SimpleFunctionType);
      writeByte(node.nullability.index);
      writeNodeList(node.positionalParameters);
      writeNode(node.returnType);
    } else {
      writeByte(Tag.FunctionType);
      writeByte(node.nullability.index);
      enterFunctionTypeScope(typeParameters: node.typeParameters);
      writeNodeList(node.typeParameters);
      writeUInt30(node.requiredParameterCount);
      writeUInt30(
          node.positionalParameters.length + node.namedParameters.length);
      writeNodeList(node.positionalParameters);
      writeNodeList(node.namedParameters);
      writeNode(node.returnType);
      leaveFunctionTypeScope(typeParameters: node.typeParameters);
    }
  }

  @override
  void visitRecordType(RecordType node) {
    writeByte(Tag.RecordType);
    writeByte(node.nullability.index);
    writeNodeList(node.positional);
    writeNodeList(node.named);
  }

  @override
  void visitNamedType(NamedType node) {
    writeStringReference(node.name);
    writeNode(node.type);
    int flags = (node.isRequired ? NamedType.FlagRequiredNamedType : 0);
    writeByte(flags);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    writeByte(Tag.TypeParameterType);
    writeByte(node.declaredNullability.index);
    writeUInt30(_typeParameterIndexer[node.parameter]);
  }

  @override
  void visitStructuralParameterType(StructuralParameterType node) {
    writeByte(Tag.TypeParameterType);
    writeByte(node.declaredNullability.index);
    writeUInt30(_typeParameterIndexer[node.parameter]);
  }

  @override
  void visitIntersectionType(IntersectionType node) {
    writeByte(Tag.IntersectionType);
    writeDartType(node.left);
    writeDartType(node.right);
  }

  @override
  void visitTypedefType(TypedefType node) {
    writeByte(Tag.TypedefType);
    writeByte(node.nullability.index);
    writeNullAllowedReference(node.typedefReference);
    writeNodeList(node.typeArguments);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    writeByte(node.flags);
    writeAnnotationList(node.annotations);
    if (node.isLegacyCovariant) {
      writeByte(TypeParameter.legacyCovariantSerializationMarker);
    } else {
      writeByte(node.variance);
    }
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
    writeNode(node.defaultType);
  }

  @override
  void visitStructuralParameter(StructuralParameter node) {
    writeByte(node.flags);
    // TODO(cstefantsova): Eventually remove the annotations from the binary
    // encoding of [StructuralParameter] objects.
    writeAnnotationList([]);
    if (node.isLegacyCovariant) {
      writeByte(StructuralParameter.legacyCovariantSerializationMarker);
    } else {
      writeByte(node.variance);
    }
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
    writeNode(node.defaultType);
  }

  @override
  void visitExtension(Extension node) {
    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    writeByte(Tag.Extension);
    _writeNonNullCanonicalName(canonicalName);
    writeStringReference(node.name);
    writeAnnotationList(node.annotations);
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeByte(node.flags);

    enterScope(typeParameters: node.typeParameters);
    writeNodeList(node.typeParameters);
    writeDartType(node.onType);

    leaveScope(typeParameters: node.typeParameters);

    final int len = node.memberDescriptors.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final ExtensionMemberDescriptor descriptor = node.memberDescriptors[i];
      writeName(descriptor.name);
      writeByte(descriptor.kind.index);
      writeByte(descriptor.flags);
      assert(descriptor.memberReference.canonicalName != null,
          "No canonical name for ${descriptor}.");
      writeNonNullCanonicalNameReference(descriptor.memberReference);
      writeNullAllowedCanonicalNameReference(descriptor.tearOffReference);
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    CanonicalName? canonicalName = node.reference.canonicalName;
    if (canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    writeByte(Tag.ExtensionTypeDeclaration);
    _writeNonNullCanonicalName(canonicalName);
    writeStringReference(node.name);
    writeAnnotationList(node.annotations);
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeByte(node.flags);

    enterScope(typeParameters: node.typeParameters);
    writeNodeList(node.typeParameters);
    writeDartType(node.declaredRepresentationType);
    writeStringReference(node.representationName);
    writeNodeList(node.implements);
    // Ensure that [procedureOffsets] is initialized before serializing the
    // procedures. These offsets are not used for the extension type declaration
    // encoding.
    procedureOffsets = <int>[];
    writeProcedureNodeList(node.procedures);
    leaveScope(typeParameters: node.typeParameters);

    final int len = node.memberDescriptors.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final ExtensionTypeMemberDescriptor descriptor =
          node.memberDescriptors[i];
      writeName(descriptor.name);
      writeByte(descriptor.kind.index);
      writeByte(descriptor.flags);
      assert(descriptor.memberReference.canonicalName != null,
          "No canonical name for ${descriptor}.");
      writeNonNullCanonicalNameReference(descriptor.memberReference);
      assert(
          descriptor.tearOffReference == null ||
              descriptor.tearOffReference?.canonicalName != null,
          "No canonical name for ${descriptor} tear-off.");
      writeNullAllowedCanonicalNameReference(descriptor.tearOffReference);
    }
  }

  @override
  void visitFunctionTearOff(FunctionTearOff node) {
    writeByte(Tag.FunctionTearOff);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
  }

  void _writeVariableReference(VariableDeclaration variable) {
    int index = _getVariableIndex(variable);
    writeUInt30(variable.binaryOffsetNoTag);
    writeUInt30(index);
  }

  @override
  void visitAndPattern(AndPattern node) {
    writeByte(Tag.AndPattern);
    writeOffset(node.fileOffset);
    writeNode(node.left);
    writeNode(node.right);
  }

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    writeByte(Tag.AssignedVariablePattern);
    writeOffset(node.fileOffset);
    _writeVariableReference(node.variable);
    writeOptionalNode(node.matchedValueType);
    writeByte(node.needsCast ? 1 : 0);
  }

  @override
  void visitCastPattern(CastPattern node) {
    writeByte(Tag.CastPattern);
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
    writeDartType(node.type);
  }

  @override
  void visitConstantPattern(ConstantPattern node) {
    writeByte(Tag.ConstantPattern);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeOptionalNode(node.expressionType);
    writeNullAllowedReference(node.equalsTargetReference);
    writeOptionalNode(node.equalsType);
  }

  @override
  void visitInvalidPattern(InvalidPattern node) {
    writeByte(Tag.InvalidPattern);
    writeOffset(node.fileOffset);
    writeNode(node.invalidExpression);
    writeVariableDeclarationList(node.declaredVariables);
  }

  @override
  void visitListPattern(ListPattern node) {
    writeByte(Tag.ListPattern);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.typeArgument);
    writeNodeList(node.patterns);
    writeOptionalNode(node.requiredType);
    writeOptionalNode(node.matchedValueType);
    writeByte((node.needsCheck ? 0x1 : 0) | (node.hasRestPattern ? 0x2 : 0));
    writeOptionalNode(node.lookupType);
    writeNullAllowedReference(node.lengthTargetReference);
    writeOptionalNode(node.lengthType);
    writeNullAllowedReference(node.lengthCheckTargetReference);
    writeOptionalNode(node.lengthCheckType);
    writeNullAllowedReference(node.sublistTargetReference);
    writeOptionalNode(node.sublistType);
    writeNullAllowedReference(node.minusTargetReference);
    writeOptionalNode(node.minusType);
    writeNullAllowedReference(node.indexGetTargetReference);
    writeOptionalNode(node.indexGetType);
  }

  @override
  void visitMapPattern(MapPattern node) {
    writeByte(Tag.MapPattern);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.keyType);
    writeOptionalNode(node.valueType);
    writeNodeList(node.entries);
    writeOptionalNode(node.requiredType);
    writeOptionalNode(node.matchedValueType);
    writeByte(node.needsCheck ? 0x1 : 0);
    writeOptionalNode(node.lookupType);
    writeNullAllowedReference(node.containsKeyTargetReference);
    writeOptionalNode(node.containsKeyType);
    writeNullAllowedReference(node.indexGetTargetReference);
    writeOptionalNode(node.indexGetType);
  }

  @override
  void visitMapPatternEntry(MapPatternEntry node) {
    writeByte(Tag.MapPatternEntry);
    writeOffset(node.fileOffset);
    writeNode(node.key);
    writeNode(node.value);
    writeOptionalNode(node.keyType);
  }

  @override
  void visitMapPatternRestEntry(MapPatternRestEntry node) {
    writeByte(Tag.MapPatternRestEntry);
    writeOffset(node.fileOffset);
  }

  @override
  void visitNamedPattern(NamedPattern node) {
    writeByte(Tag.NamedPattern);
    writeOffset(node.fileOffset);
    writeStringReference(node.name);
    writeNode(node.pattern);
    writeName(node.fieldName);
    writeByte(node.accessKind.index);
    writeNullAllowedReference(node.targetReference);
    writeOptionalNode(node.resultType);
    writeOptionalNode(node.recordType);
    writeUInt30(node.recordFieldIndex);
    writeOptionalNode(node.functionType);
    if (node.typeArguments == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeNodeList(node.typeArguments!);
    }
  }

  @override
  void visitNullAssertPattern(NullAssertPattern node) {
    writeByte(Tag.NullAssertPattern);
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
  }

  @override
  void visitNullCheckPattern(NullCheckPattern node) {
    writeByte(Tag.NullCheckPattern);
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    writeByte(Tag.ObjectPattern);
    writeOffset(node.fileOffset);
    writeDartType(node.requiredType);
    writeNodeList(node.fields);
    writeOptionalNode(node.matchedValueType);
    writeByte(node.needsCheck ? 1 : 0);
    writeOptionalNode(node.lookupType);
  }

  @override
  void visitOrPattern(OrPattern node) {
    writeByte(Tag.OrPattern);
    writeOffset(node.fileOffset);
    writeNode(node.left);
    writeNode(node.right);
    writeList(node.orPatternJointVariables, _writeVariableReference);
  }

  @override
  void visitPatternGuard(PatternGuard node) {
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
    writeOptionalNode(node.guard);
  }

  @override
  void visitPatternSwitchCase(PatternSwitchCase node) {
    writeVariableDeclarationList(node.jointVariables);
    int length = node.patternGuards.length;
    writeUInt30(length);
    for (int i = 0; i < length; ++i) {
      writeOffset(node.caseOffsets[i]);
      writeNode(node.patternGuards[i]);
    }
    writeByte((node.isDefault ? 0x1 : 0) | (node.hasLabel ? 0x2 : 0));
    writeNode(node.body);
  }

  @override
  void visitPatternSwitchStatement(PatternSwitchStatement node) {
    SwitchCaseIndexer switchCaseIndexer =
        _switchCaseIndexer ??= new SwitchCaseIndexer();
    switchCaseIndexer.enter(node);
    writeByte(Tag.PatternSwitchStatement);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeOptionalNode(node.expressionTypeInternal);
    writeSwitchCaseNodeList(node.cases);
    switchCaseIndexer.exit(node);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    writeByte(Tag.RecordPattern);
    writeOffset(node.fileOffset);
    writeNodeList(node.patterns);
    writeOptionalNode(node.requiredType);
    writeOptionalNode(node.matchedValueType);
    writeByte(node.needsCheck ? 1 : 0);
    writeOptionalNode(node.lookupType);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    writeByte(Tag.RelationalPattern);
    writeOffset(node.fileOffset);
    writeByte(node.kind.index);
    writeNode(node.expression);
    writeOptionalNode(node.expressionType);
    writeOptionalNode(node.matchedValueType);
    writeByte(node.accessKind.index);
    writeOptionalNode(node.name);
    writeNullAllowedReference(node.targetReference);
    if (node.typeArguments == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeNodeList(node.typeArguments!);
    }
    writeOptionalNode(node.functionType);
  }

  @override
  void visitRestPattern(RestPattern node) {
    writeByte(Tag.RestPattern);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.subPattern);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    writeByte(Tag.SwitchExpression);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeOptionalNode(node.expressionType);
    writeList(node.cases, visitSwitchExpressionCase);
    writeOptionalNode(node.staticType);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    writeOffset(node.fileOffset);
    writeNode(node.patternGuard);
    writeNode(node.expression);
  }

  @override
  void visitVariablePattern(VariablePattern node) {
    writeByte(Tag.VariablePattern);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.type);
    writeVariableDeclaration(node.variable);
    writeOptionalNode(node.matchedValueType);
  }

  @override
  void visitWildcardPattern(WildcardPattern node) {
    writeByte(Tag.WildcardPattern);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.type);
  }

  @override
  void visitIfCaseStatement(IfCaseStatement node) {
    writeByte(Tag.IfCaseStatement);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeNode(node.patternGuard);
    writeNode(node.then);
    writeOptionalNode(node.otherwise);
    writeOptionalNode(node.matchedValueType);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    writeByte(Tag.PatternAssignment);
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
    writeNode(node.expression);
    writeOptionalNode(node.matchedValueType);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    writeByte(Tag.PatternVariableDeclaration);
    writeOffset(node.fileOffset);
    writeNode(node.pattern);
    writeNode(node.initializer);
    writeByte(node.isFinal ? 1 : 0);
    writeOptionalNode(node.matchedValueType);
  }

  // ================================================================
  // These are nodes that are never serialized directly.  Reaching one
  // during serialization is an error.
  @override
  void visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        'serialization of auxiliary DartType: ${node} (${node.runtimeType})');
  }

  @override
  void visitAuxiliaryExpression(AuxiliaryExpression node) {
    throw new UnsupportedError(
        'serialization of auxiliary Expression: ${node} (${node.runtimeType})');
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    throw new UnsupportedError('serialization of auxiliary Initializer: '
        '${node} (${node.runtimeType})');
  }

  @override
  void visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw new UnsupportedError(
        'serialization of auxiliary Statement: ${node} (${node.runtimeType})');
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    throw new UnsupportedError('serialization of BoolConstants');
  }

  @override
  void visitBoolConstantReference(BoolConstant node) {
    throw new UnsupportedError('serialization of BoolConstant references');
  }

  @override
  void visitClassReference(Class node) {
    throw new UnsupportedError('serialization of Class references');
  }

  @override
  void visitExtensionReference(Extension node) {
    throw new UnsupportedError('serialization of Extension references');
  }

  @override
  void visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node) {
    throw new UnsupportedError(
        'serialization of ExtensionTypeDeclaration references');
  }

  @override
  void visitConstructorReference(Constructor node) {
    throw new UnsupportedError('serialization of Constructor references');
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    throw new UnsupportedError('serialization of DoubleConstants');
  }

  @override
  void visitDoubleConstantReference(DoubleConstant node) {
    throw new UnsupportedError('serialization of DoubleConstant references');
  }

  @override
  void visitFieldReference(Field node) {
    throw new UnsupportedError('serialization of Field references');
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    throw new UnsupportedError('serialization of InstanceConstants');
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    throw new UnsupportedError('serialization of InstanceConstant references');
  }

  @override
  void visitIntConstant(IntConstant node) {
    throw new UnsupportedError('serialization of IntConstants');
  }

  @override
  void visitIntConstantReference(IntConstant node) {
    throw new UnsupportedError('serialization of IntConstant references');
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    throw new UnsupportedError('serialization of LibraryDependencies');
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    throw new UnsupportedError('serialization of LibraryParts');
  }

  @override
  void visitListConstant(ListConstant node) {
    throw new UnsupportedError('serialization of ListConstants');
  }

  @override
  void visitListConstantReference(ListConstant node) {
    throw new UnsupportedError('serialization of ListConstant references');
  }

  @override
  void visitSetConstant(SetConstant node) {
    throw new UnsupportedError('serialization of SetConstants');
  }

  @override
  void visitSetConstantReference(SetConstant node) {
    throw new UnsupportedError('serialization of SetConstant references');
  }

  @override
  void visitMapConstant(MapConstant node) {
    throw new UnsupportedError('serialization of MapConstants');
  }

  @override
  void visitMapConstantReference(MapConstant node) {
    throw new UnsupportedError('serialization of MapConstant references');
  }

  @override
  void visitRecordConstant(RecordConstant node) {
    throw new UnsupportedError('serialization of RecordConstants');
  }

  @override
  void visitRecordConstantReference(RecordConstant node) {
    throw new UnsupportedError('serialization of RecordConstant references');
  }

  @override
  void visitName(Name node) {
    throw new UnsupportedError('serialization of Names');
  }

  @override
  void visitNullConstant(NullConstant node) {
    throw new UnsupportedError('serialization of NullConstants');
  }

  @override
  void visitNullConstantReference(NullConstant node) {
    throw new UnsupportedError('serialization of NullConstant references');
  }

  @override
  void visitProcedureReference(Procedure node) {
    throw new UnsupportedError('serialization of Procedure references');
  }

  @override
  void visitComponent(Component node) {
    throw new UnsupportedError('serialization of Components');
  }

  @override
  void visitStringConstant(StringConstant node) {
    throw new UnsupportedError('serialization of StringConstants');
  }

  @override
  void visitStringConstantReference(StringConstant node) {
    throw new UnsupportedError('serialization of StringConstant references');
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    throw new UnsupportedError('serialization of SymbolConstants');
  }

  @override
  void visitSymbolConstantReference(SymbolConstant node) {
    throw new UnsupportedError('serialization of SymbolConstant references');
  }

  @override
  void visitInstantiationConstant(InstantiationConstant node) {
    throw new UnsupportedError('serialization of InstantiationConstants ');
  }

  @override
  void visitInstantiationConstantReference(InstantiationConstant node) {
    throw new UnsupportedError(
        'serialization of InstantiationConstant references');
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    throw new UnsupportedError('serialization of TypedefTearOffConstants ');
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    throw new UnsupportedError('serialization of StaticTearOffConstants ');
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    throw new UnsupportedError('serialization of ConstructorTearOffConstants ');
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    throw new UnsupportedError(
        'serialization of RedirectingFactoryTearOffConstants ');
  }

  @override
  void visitStaticTearOffConstantReference(StaticTearOffConstant node) {
    throw new UnsupportedError(
        'serialization of StaticTearOffConstant references');
  }

  @override
  void visitConstructorTearOffConstantReference(
      ConstructorTearOffConstant node) {
    throw new UnsupportedError(
        'serialization of ConstructorTearOffConstant references');
  }

  @override
  void visitRedirectingFactoryTearOffConstantReference(
      RedirectingFactoryTearOffConstant node) {
    throw new UnsupportedError(
        'serialization of RedirectingFactoryTearOffConstant references');
  }

  @override
  void visitTypedefTearOffConstantReference(TypedefTearOffConstant node) {
    throw new UnsupportedError('serialization of TypedefTearOffConstants ');
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    throw new UnsupportedError('serialization of TypeLiteralConstants');
  }

  @override
  void visitTypeLiteralConstantReference(TypeLiteralConstant node) {
    throw new UnsupportedError(
        'serialization of TypeLiteralConstant references');
  }

  @override
  void visitTypedefReference(Typedef node) {
    throw new UnsupportedError('serialization of Typedef references');
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    throw new UnsupportedError('serialization of UnevaluatedConstants');
  }

  @override
  void visitUnevaluatedConstantReference(UnevaluatedConstant node) {
    throw new UnsupportedError(
        'serialization of UnevaluatedConstant references');
  }

  @override
  void visitAuxiliaryConstant(AuxiliaryConstant node) {
    throw new UnsupportedError(
        "serialization of auxiliary constant ${node} (${node.runtimeType}).");
  }

  @override
  void visitAuxiliaryConstantReference(AuxiliaryConstant node) {
    throw new UnsupportedError("serialization of auxiliary constant reference "
        "${node} (${node.runtimeType}).");
  }

  VariableIndexer? getVariableIndexerForTesting() {
    return _variableIndexer;
  }

  TypeParameterIndexer getTypeParameterIndexerForTesting() {
    return _typeParameterIndexer;
  }
}

typedef bool LibraryFilter(Library _);

class VariableIndexer {
  Map<VariableDeclaration, int>? index;
  List<int>? scopes;
  int stackHeight = 0;

  void declare(VariableDeclaration node) {
    (index ??= <VariableDeclaration, int>{})[node] = stackHeight++;
  }

  void pushScope() {
    (scopes ??= <int>[]).add(stackHeight);
  }

  void popScope() {
    stackHeight = scopes!.removeLast();
  }

  void restoreScope(int numberOfVariables) {
    stackHeight += numberOfVariables;
  }

  int? operator [](VariableDeclaration node) {
    return index == null ? null : index![node];
  }
}

class LabelIndexer {
  final Map<LabeledStatement, int> index = <LabeledStatement, int>{};
  int stackHeight = 0;

  void enter(LabeledStatement node) {
    index[node] = stackHeight++;
  }

  void exit() {
    --stackHeight;
  }

  int? operator [](LabeledStatement node) => index[node];
}

class SwitchCaseIndexer {
  final Map<SwitchCase, int> index = <SwitchCase, int>{};
  int stackHeight = 0;

  void enter(SwitchStatement node) {
    for (SwitchCase caseNode in node.cases) {
      index[caseNode] = stackHeight++;
    }
  }

  void exit(SwitchStatement node) {
    stackHeight -= node.cases.length;
  }

  int? operator [](SwitchCase node) => index[node];
}

class ConstantIndexer extends RecursiveResultVisitor {
  final List<Constant> entries = <Constant>[];
  final List<int> offsets = <int>[];
  final Map<Constant, int> index = <Constant, int>{};

  int put(Constant constant) {
    final int? oldIndex = index[constant];
    if (oldIndex != null) return oldIndex;

    // Traverse DAG in post-order to ensure children have their offsets assigned
    // before the parent.
    constant.visitChildren(this);

    final int newIndex = entries.length;
    entries.add(constant);
    offsets.add(-1); // placeholder.
    assert(entries.length == offsets.length);
    return index[constant] = newIndex;
  }

  @override
  void defaultConstantReference(Constant node) {
    put(node);
  }
}

class TypeParameterIndexer {
  final Map< /* TypeParameter | StructuralParameter */ Object, int> index =
      <Object, int>{};
  int stackHeight = 0;

  void enter(List<TypeParameter> typeParameters) {
    for (int i = 0; i < typeParameters.length; ++i) {
      TypeParameter parameter = typeParameters[i];
      index[parameter] = stackHeight;
      ++stackHeight;
    }
  }

  void enterFunctionType(List<StructuralParameter> structuralParameters) {
    for (int i = 0; i < structuralParameters.length; ++i) {
      StructuralParameter parameter = structuralParameters[i];
      index[parameter] = stackHeight;
      ++stackHeight;
    }
  }

  void exit(List<TypeParameter> typeParameters) {
    stackHeight -= typeParameters.length;
    for (int i = 0; i < typeParameters.length; ++i) {
      index.remove(typeParameters[i]);
    }
  }

  void exitFunctionType(List<StructuralParameter> structuralParameters) {
    stackHeight -= structuralParameters.length;
    for (int i = 0; i < structuralParameters.length; ++i) {
      index.remove(structuralParameters[i]);
    }
  }

  int operator [](Object parameter) {
    assert(parameter is TypeParameter || parameter is StructuralParameter);
    return index[parameter] ??
        (throw new ArgumentError('Type parameter $parameter is not indexed'));
  }
}

class StringIndexer {
  // Note that the iteration order is important.
  final Map<String, int> index = new Map<String, int>();

  StringIndexer() {
    put('');
  }

  int put(String string) {
    int? result = index[string];
    if (result == null) {
      result = index.length;
      index[string] = result;
    }
    return result;
  }
}

class UriIndexer {
  // Note that the iteration order is important.
  final Map<Uri, int> index = new Map<Uri, int>();

  UriIndexer();

  int put(Uri uri) {
    int? result = index[uri];
    if (result == null) {
      result = index.length;
      index[uri] = result;
    }
    return result;
  }
}

/// Puts a buffer in front of a [Sink<List<int>>].
class BufferedSink {
  static const int SIZE = 100000;
  static const int SAFE_SIZE = SIZE - 5;
  static const int SMALL = 10000;
  final Sink<List<int>> _sink;
  Uint8List _buffer = new Uint8List(SIZE);
  int length = 0;
  int flushedLength = 0;

  Float64List _doubleBuffer = new Float64List(1);
  Uint8List? _doubleBufferUint8;

  int get offset => length + flushedLength;

  BufferedSink(this._sink);

  void addDouble(double d) {
    Uint8List doubleBufferUint8 =
        _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    _doubleBuffer[0] = d;
    addByte4(doubleBufferUint8[0], doubleBufferUint8[1], doubleBufferUint8[2],
        doubleBufferUint8[3]);
    addByte4(doubleBufferUint8[4], doubleBufferUint8[5], doubleBufferUint8[6],
        doubleBufferUint8[7]);
  }

  @pragma("vm:prefer-inline")
  void addByte(int byte) {
    _buffer[length++] = byte;
    if (length == SIZE) {
      _sink.add(_buffer);
      _buffer = new Uint8List(SIZE);
      length = 0;
      flushedLength += SIZE;
    }
  }

  @pragma("vm:prefer-inline")
  void addByte2(int byte1, int byte2) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
    } else {
      addByte(byte1);
      addByte(byte2);
    }
  }

  @pragma("vm:prefer-inline")
  void addByte4(int byte1, int byte2, int byte3, int byte4) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
      _buffer[length++] = byte3;
      _buffer[length++] = byte4;
    } else {
      addByte(byte1);
      addByte(byte2);
      addByte(byte3);
      addByte(byte4);
    }
  }

  void addBytes(List<int> bytes) {
    // Avoid copying a large buffer into the another large buffer. Also, if
    // the bytes buffer is too large to fit in our own buffer, just emit both.
    if (length + bytes.length < SIZE &&
        (bytes.length < SMALL || length < SMALL)) {
      _buffer.setRange(length, length + bytes.length, bytes);
      length += bytes.length;
    } else if (bytes.length < SMALL) {
      // Flush as much as we can in the current buffer.
      _buffer.setRange(length, SIZE, bytes);
      _sink.add(_buffer);
      // Copy over the remainder into a new buffer. It is guaranteed to fit
      // because the input byte array is small.
      int alreadyEmitted = SIZE - length;
      int remainder = bytes.length - alreadyEmitted;
      _buffer = new Uint8List(SIZE);
      _buffer.setRange(0, remainder, bytes, alreadyEmitted);
      length = remainder;
      flushedLength += SIZE;
    } else {
      flush();
      _sink.add(bytes);
      flushedLength += bytes.length;
    }
  }

  void flush() {
    _sink.add(_buffer.sublist(0, length));
    _buffer = new Uint8List(SIZE);
    flushedLength += length;
    length = 0;
  }

  void flushAndDestroy() {
    _sink.add(_buffer.sublist(0, length));
  }
}

/// Non-empty metadata subsection.
class _MetadataSubsection {
  final MetadataRepository<Object?> repository;

  /// List of (nodeOffset, metadataOffset) pairs.
  /// Gradually filled by the writer as writing progresses, which by
  /// construction guarantees that pairs are sorted by first component
  /// (nodeOffset) in ascending order.
  final List<int> metadataMapping = <int>[];

  _MetadataSubsection(this.repository);
}

/// A [Sink] that directly writes data into a byte builder.
// TODO(dartbug.com/28316): Remove this wrapper class.
class BytesSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {
    // Nothing to do.
  }
}

/**
 * Write [source] string into [target] starting at index [index].
 *
 * The output space needed is at most [source.length] * 3.
 *
 * Returns
 *  * Non-negative on success (the new index in [target]).
 *  * -1 when [target] doesn't have enough space. Note that [target] can be
 *    polluted starting at [index].
 */
int _writeWtf8(Uint8List target, int index, String source) {
  int end = source.length;
  if (end == 0) return index;
  int length = target.length;
  assert(index <= length);
  int i = 0;
  do {
    int codeUnit = source.codeUnitAt(i++);
    while (codeUnit < 128) {
      // ASCII.
      if (index >= length) return -1;
      target[index++] = codeUnit;
      if (i >= end) return index;
      codeUnit = source.codeUnitAt(i++);
    }
    if (codeUnit < 0x800) {
      // Two-byte sequence (11-bit unicode value).
      index += 2;
      if (index > length) return -1;
      target[index - 2] = 0xC0 | (codeUnit >> 6);
      target[index - 1] = 0x80 | (codeUnit & 0x3f);
    } else if ((codeUnit & 0xFC00) == 0xD800 &&
        i < end &&
        (source.codeUnitAt(i) & 0xFC00) == 0xDC00) {
      // Surrogate pair -> four-byte sequence (non-BMP unicode value).
      index += 4;
      if (index > length) return -1;
      int codeUnit2 = source.codeUnitAt(i++);
      int unicode = 0x10000 + ((codeUnit & 0x3FF) << 10) + (codeUnit2 & 0x3FF);
      target[index - 4] = 0xF0 | (unicode >> 18);
      target[index - 3] = 0x80 | ((unicode >> 12) & 0x3F);
      target[index - 2] = 0x80 | ((unicode >> 6) & 0x3F);
      target[index - 1] = 0x80 | (unicode & 0x3F);
    } else {
      // Three-byte sequence (16-bit unicode value), including lone
      // surrogates.
      index += 3;
      if (index > length) return -1;
      target[index - 3] = 0xE0 | (codeUnit >> 12);
      target[index - 2] = 0x80 | ((codeUnit >> 6) & 0x3f);
      target[index - 1] = 0x80 | (codeUnit & 0x3f);
    }
  } while (i < end);
  return index;
}
