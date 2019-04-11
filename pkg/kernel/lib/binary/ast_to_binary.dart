// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_to_binary;

import 'dart:core' hide MapEntry;
import 'dart:convert' show utf8;

import '../ast.dart';
import 'tag.dart';
import 'dart:io' show BytesBuilder;
import 'dart:typed_data';

/// Writes to a binary file.
///
/// A [BinaryPrinter] can be used to write one file and must then be
/// discarded.
class BinaryPrinter implements Visitor<void>, BinarySink {
  VariableIndexer _variableIndexer;
  LabelIndexer _labelIndexer;
  SwitchCaseIndexer _switchCaseIndexer;
  final TypeParameterIndexer _typeParameterIndexer = new TypeParameterIndexer();
  final StringIndexer stringIndexer;
  ConstantIndexer _constantIndexer;
  final UriIndexer _sourceUriIndexer = new UriIndexer();
  bool _currentlyInNonimplementation = false;
  final List<bool> _sourcesFromRealImplementation = new List<bool>();
  final List<bool> _sourcesFromRealImplementationInLibrary = new List<bool>();
  Map<LibraryDependency, int> _libraryDependencyIndex =
      <LibraryDependency, int>{};

  List<_MetadataSubsection> _metadataSubsections;

  final BufferedSink _mainSink;
  final BufferedSink _metadataSink;
  final BytesSink _constantsBytesSink;
  BufferedSink _constantsSink;
  BufferedSink _sink;
  bool includeSources;

  List<int> libraryOffsets;
  List<int> classOffsets;
  List<int> procedureOffsets;
  int _binaryOffsetForSourceTable = -1;
  int _binaryOffsetForLinkTable = -1;
  int _binaryOffsetForMetadataPayloads = -1;
  int _binaryOffsetForMetadataMappings = -1;
  int _binaryOffsetForStringTable = -1;
  int _binaryOffsetForConstantTable = -1;

  List<CanonicalName> _canonicalNameList;
  Set<CanonicalName> _knownCanonicalNameNonRootTops = new Set<CanonicalName>();
  Set<CanonicalName> _reindexedCanonicalNames = new Set<CanonicalName>();

  /// Create a printer that writes to the given [sink].
  ///
  /// The BinaryPrinter will use its own buffer, so the [sink] does not need
  /// one.
  BinaryPrinter(Sink<List<int>> sink,
      {StringIndexer stringIndexer, this.includeSources = true})
      : _mainSink = new BufferedSink(sink),
        _metadataSink = new BufferedSink(new BytesSink()),
        _constantsBytesSink = new BytesSink(),
        stringIndexer = stringIndexer ?? new StringIndexer() {
    _constantsSink = new BufferedSink(_constantsBytesSink);
    _constantIndexer = new ConstantIndexer(this.stringIndexer, this);
    _sink = _mainSink;
  }

  void _flush() {
    _sink.flushAndDestroy();
  }

  void writeByte(int byte) {
    _sink.addByte(byte);
  }

  void writeBytes(List<int> bytes) {
    _sink.addBytes(bytes);
  }

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

  void writeUInt32(int value) {
    _sink.addByte4((value >> 24) & 0xFF, (value >> 16) & 0xFF,
        (value >> 8) & 0xFF, value & 0xFF);
  }

  void writeByteList(List<int> utf8Bytes) {
    writeUInt30(utf8Bytes.length);
    writeBytes(utf8Bytes);
  }

  int getBufferOffset() {
    return _sink.offset;
  }

  void writeStringTable(StringIndexer indexer) {
    _binaryOffsetForStringTable = getBufferOffset();

    // Containers for the utf8 encoded strings.
    final List<Uint8List> data = new List<Uint8List>();
    int totalLength = 0;
    const int minLength = 1 << 16;
    Uint8List buffer;
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
          newIndex = NotQuiteString.writeUtf8(buffer, index, key);
          if (newIndex != -1) break;
          requiredMinLength = allocateMinLength;
        }
        if (newIndex < 0) {
          // Utf8 encoding failed.
          if (buffer != null && index > 0) {
            data.add(new Uint8List.view(buffer.buffer, 0, index));
            buffer = null;
            index = 0;
          }
          List<int> converted = utf8.encoder.convert(key);
          data.add(converted);
          totalLength += converted.length;
        } else {
          totalLength += newIndex - index;
          index = newIndex;
        }
      }
      writeUInt30(totalLength);
    }
    if (buffer != null && index > 0) {
      data.add(Uint8List.view(buffer.buffer, 0, index));
    }

    // Write the UTF-8 encoded strings.
    for (int i = 0; i < data.length; ++i) {
      writeBytes(data[i]);
    }
  }

  void writeStringReference(String string) {
    writeUInt30(stringIndexer.put(string));
  }

  void writeStringReferenceList(List<String> strings) {
    writeList(strings, writeStringReference);
  }

  void writeConstantReference(Constant constant) {
    writeUInt30(_constantIndexer.put(constant));
  }

  void writeConstantTable(ConstantIndexer indexer) {
    _binaryOffsetForConstantTable = getBufferOffset();

    writeUInt30(indexer.entries.length);
    assert(identical(_sink, _mainSink));
    _constantsSink.flushAndDestroy();
    writeBytes(_constantsBytesSink.builder.takeBytes());
  }

  int writeConstantTableEntry(Constant constant) {
    BufferedSink oldSink = _sink;
    _sink = _constantsSink;
    int initialOffset = _sink.offset;
    if (constant is NullConstant) {
      writeByte(ConstantTag.NullConstant);
    } else if (constant is BoolConstant) {
      writeByte(ConstantTag.BoolConstant);
      writeByte(constant.value ? 1 : 0);
    } else if (constant is IntConstant) {
      writeByte(ConstantTag.IntConstant);
      writeInteger(constant.value);
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
        writeNonNullCanonicalNameReference(fieldRef.canonicalName);
        writeConstantReference(value);
      });
    } else if (constant is PartialInstantiationConstant) {
      writeByte(ConstantTag.PartialInstantiationConstant);
      writeConstantReference(constant.tearOffConstant);
      final int length = constant.types.length;
      writeUInt30(length);
      for (int i = 0; i < length; ++i) {
        writeDartType(constant.types[i]);
      }
    } else if (constant is TearOffConstant) {
      writeByte(ConstantTag.TearOffConstant);
      writeNonNullCanonicalNameReference(constant.procedure.canonicalName);
    } else if (constant is TypeLiteralConstant) {
      writeByte(ConstantTag.TypeLiteralConstant);
      writeDartType(constant.type);
    } else if (constant is UnevaluatedConstant) {
      writeByte(ConstantTag.UnevaluatedConstant);
      writeNode(constant.expression);
    } else {
      throw new ArgumentError('Unsupported constant $constant');
    }
    _sink = oldSink;
    return _constantsSink.offset - initialOffset;
  }

  void writeDartType(DartType type) {
    type.accept(this);
  }

  // Returns the new active file uri.
  void writeUriReference(Uri uri) {
    final int index = _sourceUriIndexer.put(uri);
    writeUInt30(index);
    if (!_currentlyInNonimplementation) {
      if (_sourcesFromRealImplementationInLibrary.length <= index) {
        _sourcesFromRealImplementationInLibrary.length = index + 1;
      }
      _sourcesFromRealImplementationInLibrary[index] = true;
      if (_sourcesFromRealImplementation.length <= index) {
        _sourcesFromRealImplementation.length = index + 1;
      }
      _sourcesFromRealImplementation[index] = true;
    }
  }

  void writeList<T>(List<T> items, void writeItem(T x)) {
    writeUInt30(items.length);
    for (int i = 0; i < items.length; ++i) {
      writeItem(items[i]);
    }
  }

  void writeNodeList(List<Node> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeNode(node);
    }
  }

  void writeProcedureNodeList(List<Procedure> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeProcedureNode(node);
    }
  }

  void writeFieldNodeList(List<Field> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeFieldNode(node);
    }
  }

  void writeClassNodeList(List<Class> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeClassNode(node);
    }
  }

  void writeConstructorNodeList(List<Constructor> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeConstructorNode(node);
    }
  }

  void writeRedirectingFactoryConstructorNodeList(
      List<RedirectingFactoryConstructor> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeRedirectingFactoryConstructorNode(node);
    }
  }

  void writeSwitchCaseNodeList(List<SwitchCase> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeSwitchCaseNode(node);
    }
  }

  void writeCatchNodeList(List<Catch> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
      writeCatchNode(node);
    }
  }

  void writeTypedefNodeList(List<Typedef> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final node = nodes[i];
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

  void writeConstructorNode(Constructor node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    node.accept(this);
  }

  void writeRedirectingFactoryConstructorNode(
      RedirectingFactoryConstructor node) {
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

  void writeOptionalNode(Node node) {
    if (node == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeNode(node);
    }
  }

  void writeOptionalFunctionNode(FunctionNode node) {
    if (node == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeFunctionNode(node);
    }
  }

  void writeLinkTable(Component component) {
    _binaryOffsetForLinkTable = getBufferOffset();
    writeList(_canonicalNameList, writeCanonicalNameEntry);
  }

  void indexLinkTable(Component component) {
    _canonicalNameList = <CanonicalName>[];
    for (int i = 0; i < component.libraries.length; ++i) {
      Library library = component.libraries[i];
      if (!shouldWriteLibraryCanonicalNames(library)) continue;
      _indexLinkTableInternal(library.canonicalName);
      _knownCanonicalNameNonRootTops.add(library.canonicalName);
    }
  }

  void _indexLinkTableInternal(CanonicalName node) {
    node.index = _canonicalNameList.length;
    _canonicalNameList.add(node);
    Iterable<CanonicalName> children = node.childrenOrNull;
    if (children != null) {
      for (CanonicalName child in children) {
        _indexLinkTableInternal(child);
      }
    }
  }

  /// Compute canonical names for the whole component or parts of it.
  void computeCanonicalNames(Component component) {
    component.computeCanonicalNames();
  }

  /// Return `true` if all canonical names of the [library] should be written
  /// into the link table.  If some libraries of the component are skipped,
  /// then all the additional names referenced by the libraries that are written
  /// by [writeLibraries] are automatically added.
  bool shouldWriteLibraryCanonicalNames(Library library) => true;

  void writeCanonicalNameEntry(CanonicalName node) {
    CanonicalName parent = node.parent;
    if (parent.isRoot) {
      writeUInt30(0);
    } else {
      writeUInt30(parent.index + 1);
    }
    writeStringReference(node.name);
  }

  void writeComponentFile(Component component) {
    computeCanonicalNames(component);
    final componentOffset = getBufferOffset();
    writeUInt32(Tag.ComponentFile);
    writeUInt32(Tag.BinaryFormatVersion);
    writeListOfStrings(component.problemsAsJson);
    indexLinkTable(component);
    _collectMetadata(component);
    if (_metadataSubsections != null) {
      _writeNodeMetadataImpl(component, componentOffset);
    }
    libraryOffsets = <int>[];
    CanonicalName main = getCanonicalNameOfMember(component.mainMethod);
    if (main != null) {
      checkCanonicalName(main);
    }
    writeLibraries(component);
    writeUriToSource(component.uriToSource);
    writeLinkTable(component);
    _writeMetadataSection(component);
    writeStringTable(stringIndexer);
    writeConstantTable(_constantIndexer);
    writeComponentIndex(component, component.libraries);

    _flush();
  }

  void writeListOfStrings(List<String> strings) {
    writeUInt30(strings?.length ?? 0);
    if (strings != null) {
      for (int i = 0; i < strings.length; i++) {
        String s = strings[i];
        // This is slow, but we expect there to in general be no problems. If this
        // turns out to be wrong we can optimize it as we do URLs for instance.
        writeByteList(utf8.encoder.convert(s));
      }
    }
  }

  /// Collect non-empty metadata repositories associated with the component.
  void _collectMetadata(Component component) {
    component.metadata.forEach((tag, repository) {
      if (repository.mapping.isEmpty) {
        return;
      }

      _metadataSubsections ??= <_MetadataSubsection>[];
      _metadataSubsections.add(new _MetadataSubsection(repository));
    });
  }

  /// Writes metadata associated with the given [Node].
  void _writeNodeMetadata(Node node) {
    _writeNodeMetadataImpl(node, getBufferOffset());
  }

  void _writeNodeMetadataImpl(Node node, int nodeOffset) {
    for (_MetadataSubsection subsection in _metadataSubsections) {
      final repository = subsection.repository;
      final value = repository.mapping[node];
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

  @override
  void enterScope(
      {List<TypeParameter> typeParameters,
      bool memberScope: false,
      bool variableScope: false}) {
    if (typeParameters != null) {
      _typeParameterIndexer.enter(typeParameters);
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (variableScope) {
      _variableIndexer ??= new VariableIndexer();
      _variableIndexer.pushScope();
    }
  }

  @override
  void leaveScope(
      {List<TypeParameter> typeParameters,
      bool memberScope: false,
      bool variableScope: false}) {
    if (variableScope) {
      _variableIndexer.popScope();
    }
    if (memberScope) {
      _variableIndexer = null;
    }
    if (typeParameters != null) {
      _typeParameterIndexer.exit(typeParameters);
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

    if (_metadataSubsections == null) {
      _binaryOffsetForMetadataMappings = getBufferOffset();
      writeUInt32(0); // Empty section.
      return;
    }

    assert(identical(_sink, _mainSink));
    _metadataSink.flushAndDestroy();
    writeBytes((_metadataSink._sink as BytesSink).builder.takeBytes());

    // RList<MetadataMapping> metadataMappings
    _binaryOffsetForMetadataMappings = getBufferOffset();
    for (_MetadataSubsection subsection in _metadataSubsections) {
      // UInt32 tag
      writeUInt32(stringIndexer.put(subsection.repository.tag));

      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      final mappingLength = subsection.metadataMapping.length;
      for (int i = 0; i < mappingLength; i += 2) {
        writeUInt32(subsection.metadataMapping[i]); // node offset
        writeUInt32(subsection.metadataMapping[i + 1]); // metadata offset
      }
      writeUInt32(mappingLength ~/ 2);
    }
    writeUInt32(_metadataSubsections.length);
  }

  /// Write all of some of the libraries of the [component].
  void writeLibraries(Component component) {
    for (int i = 0; i < component.libraries.length; ++i) {
      writeLibraryNode(component.libraries[i]);
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
    int numComponentIndexEntries = 7 + libraryOffsets.length + 3;

    int unalignedSize = getBufferOffset() + numComponentIndexEntries * 4;
    int padding =
        ((unalignedSize + kernelFileAlignment - 1) & -kernelFileAlignment) -
            unalignedSize;
    for (int i = 0; i < padding; ++i) {
      writeByte(0);
    }

    // Fixed-size ints at the end used as an index.
    assert(_binaryOffsetForSourceTable >= 0);
    writeUInt32(_binaryOffsetForSourceTable);
    assert(_binaryOffsetForLinkTable >= 0);
    writeUInt32(_binaryOffsetForLinkTable);
    assert(_binaryOffsetForMetadataPayloads >= 0);
    writeUInt32(_binaryOffsetForMetadataPayloads);
    assert(_binaryOffsetForMetadataMappings >= 0);
    writeUInt32(_binaryOffsetForMetadataMappings);
    assert(_binaryOffsetForStringTable >= 0);
    writeUInt32(_binaryOffsetForStringTable);
    assert(_binaryOffsetForConstantTable >= 0);
    writeUInt32(_binaryOffsetForConstantTable);

    CanonicalName main = getCanonicalNameOfMember(component.mainMethod);
    if (main == null) {
      writeUInt32(0);
    } else {
      writeUInt32(main.index + 1);
    }

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
    List<int> index = new List<int>(length);

    // Write data.
    int i = 0;
    Uint8List buffer = new Uint8List(1 << 16);
    for (Uri uri in _sourceUriIndexer.index.keys) {
      index[i] = getBufferOffset();
      Source source = uriToSource[uri];
      if (source == null ||
          !(includeSources &&
              _sourcesFromRealImplementation.length > i &&
              _sourcesFromRealImplementation[i] == true)) {
        source = new Source(
            <int>[], const <int>[], source?.importUri, source?.fileUri);
      }

      String uriAsString = uri == null ? "" : "$uri";
      outputStringViaBuffer(uriAsString, buffer);

      writeByteList(source.source);

      List<int> lineStarts = source.lineStarts;
      writeUInt30(lineStarts.length);
      int previousLineStart = 0;
      for (int j = 0; j < lineStarts.length; ++j) {
        int lineStart = lineStarts[j];
        writeUInt30(lineStart - previousLineStart);
        previousLineStart = lineStart;
      }

      String importUriAsString =
          source.importUri == null ? "" : "${source.importUri}";
      outputStringViaBuffer(importUriAsString, buffer);

      i++;
    }

    // Write index for random access.
    for (int i = 0; i < index.length; ++i) {
      writeUInt32(index[i]);
    }
  }

  void outputStringViaBuffer(String uriAsString, Uint8List buffer) {
    if (uriAsString.length * 3 < buffer.length) {
      int length = NotQuiteString.writeUtf8(buffer, 0, uriAsString);
      if (length < 0) {
        // Utf8 encoding failed.
        writeByteList(utf8.encoder.convert(uriAsString));
      } else {
        writeUInt30(length);
        for (int j = 0; j < length; j++) {
          writeByte(buffer[j]);
        }
      }
    } else {
      // Uncommon case with very long url.
      writeByteList(utf8.encoder.convert(uriAsString));
    }
  }

  void writeLibraryDependencyReference(LibraryDependency node) {
    int index = _libraryDependencyIndex[node];
    if (index == null) {
      throw new ArgumentError(
          'Reference to library dependency $node out of scope');
    }
    writeUInt30(index);
  }

  void writeNullAllowedReference(Reference reference) {
    if (reference == null) {
      writeUInt30(0);
    } else {
      CanonicalName name = reference.canonicalName;
      if (name == null) {
        throw new ArgumentError('Missing canonical name for $reference');
      }
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void writeNonNullReference(Reference reference) {
    if (reference == null) {
      throw new ArgumentError('Got null reference');
    } else {
      CanonicalName name = reference.canonicalName;
      if (name == null) {
        throw new ArgumentError('Missing canonical name for $reference');
      }
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void checkCanonicalName(CanonicalName node) {
    if (_knownCanonicalNameNonRootTops.contains(node.nonRootTop)) return;
    if (node == null || node.isRoot) return;
    if (_reindexedCanonicalNames.contains(node)) return;

    checkCanonicalName(node.parent);
    node.index = _canonicalNameList.length;
    _canonicalNameList.add(node);
    _reindexedCanonicalNames.add(node);
  }

  void writeNullAllowedCanonicalNameReference(CanonicalName name) {
    if (name == null) {
      writeUInt30(0);
    } else {
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void writeNonNullCanonicalNameReference(CanonicalName name) {
    if (name == null) {
      throw new ArgumentError(
          'Expected a canonical name to be valid but was `null`.');
    } else {
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void writeLibraryReference(Library node, {bool allowNull: false}) {
    if (node.canonicalName == null && !allowNull) {
      throw new ArgumentError(
          'Expected a library reference to be valid but was `null`.');
    }
    writeNullAllowedCanonicalNameReference(node.canonicalName);
  }

  writeOffset(int offset) {
    // TODO(jensj): Delta-encoding.
    // File offset ranges from -1 and up,
    // but is here saved as unsigned (thus the +1)
    writeUInt30(offset + 1);
  }

  void writeClassReference(Class class_) {
    if (class_ == null) {
      throw new ArgumentError(
          'Expected a class reference to be valid but was `null`.');
    }
    writeNonNullCanonicalNameReference(getCanonicalNameOfClass(class_));
  }

  void writeName(Name node) {
    if (_metadataSubsections != null) {
      _writeNodeMetadata(node);
    }
    writeStringReference(node.name);
    // TODO: Consider a more compressed format for private names within the
    // enclosing library.
    if (node.isPrivate) {
      writeLibraryReference(node.library);
    }
  }

  bool insideExternalLibrary = false;

  @override
  void visitLibrary(Library node) {
    insideExternalLibrary = node.isExternal;
    libraryOffsets.add(getBufferOffset());
    writeByte(node.flags);
    writeNonNullCanonicalNameReference(getCanonicalNameOfLibrary(node));
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
    classOffsets = new List<int>();
    writeClassNodeList(node.classes);
    classOffsets.add(getBufferOffset());
    writeFieldNodeList(node.fields);
    procedureOffsets = new List<int>();
    writeProcedureNodeList(node.procedures);
    procedureOffsets.add(getBufferOffset());

    // Dump all source-references used in this library; used by the VM.
    int sourceReferencesOffset = getBufferOffset();
    int sourceReferencesCount = 0;
    // Note: We start at 1 because 0 is the null-entry and we don't want to
    // include that.
    for (int i = 1; i < _sourcesFromRealImplementationInLibrary.length; i++) {
      if (_sourcesFromRealImplementationInLibrary[i] == true) {
        sourceReferencesCount++;
      }
    }
    writeUInt30(sourceReferencesCount);
    for (int i = 1; i < _sourcesFromRealImplementationInLibrary.length; i++) {
      if (_sourcesFromRealImplementationInLibrary[i] == true) {
        writeUInt30(i);
        _sourcesFromRealImplementationInLibrary[i] = false;
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
    writeLibraryReference(node.targetLibrary, allowNull: true);
    writeStringReference(node.name ?? '');
    writeNodeList(node.combinators);
  }

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

  void visitTypedef(Typedef node) {
    enterScope(memberScope: true);
    writeNonNullCanonicalNameReference(getCanonicalNameOfTypedef(node));
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeStringReference(node.name);
    writeAnnotationList(node.annotations);

    enterScope(typeParameters: node.typeParameters, variableScope: true);
    writeNodeList(node.typeParameters);
    writeNode(node.type);

    enterScope(typeParameters: node.typeParametersOfFunctionType);
    writeNodeList(node.typeParametersOfFunctionType);
    writeVariableDeclarationList(node.positionalParameters);
    writeVariableDeclarationList(node.namedParameters);

    leaveScope(typeParameters: node.typeParametersOfFunctionType);
    leaveScope(typeParameters: node.typeParameters, variableScope: true);
    leaveScope(memberScope: true);
  }

  void writeAnnotation(Expression annotation) {
    writeNode(annotation);
  }

  void writeAnnotationList(List<Expression> annotations) {
    final len = annotations.length;
    writeUInt30(len);
    for (int i = 0; i < len; i++) {
      final annotation = annotations[i];
      writeAnnotation(annotation);
    }
  }

  int _encodeClassFlags(int flags, ClassLevel level) {
    assert((flags & Class.LevelMask) == 0);
    final levelIndex = level.index - 1;
    assert((levelIndex & Class.LevelMask) == levelIndex);
    return flags | levelIndex;
  }

  @override
  void visitClass(Class node) {
    classOffsets.add(getBufferOffset());

    if (node.isAnonymousMixin) _currentlyInNonimplementation = true;

    int flags = _encodeClassFlags(node.flags, node.level);
    if (node.canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    writeByte(Tag.Class);
    writeNonNullCanonicalNameReference(getCanonicalNameOfClass(node));
    writeUriReference(node.fileUri);
    writeOffset(node.startFileOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);

    writeByte(flags);
    writeStringReference(node.name ?? '');

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
    writeRedirectingFactoryConstructorNodeList(
        node.redirectingFactoryConstructors);
    leaveScope(typeParameters: node.typeParameters);

    assert(procedureOffsets.length > 0);
    for (int i = 0; i < procedureOffsets.length; ++i) {
      int offset = procedureOffsets[i];
      writeUInt32(offset);
    }
    writeUInt32(procedureOffsets.length - 1);
    _currentlyInNonimplementation = false;
  }

  static final Name _emptyName = new Name('');

  @override
  void visitConstructor(Constructor node) {
    if (node.canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    enterScope(memberScope: true);
    writeByte(Tag.Constructor);
    writeNonNullCanonicalNameReference(getCanonicalNameOfMember(node));
    writeUriReference(node.fileUri);
    writeOffset(node.startFileOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);

    writeByte(node.flags);
    writeName(node.name ?? _emptyName);

    writeAnnotationList(node.annotations);
    assert(node.function.typeParameters.isEmpty);
    writeFunctionNode(node.function);
    // Parameters are in scope in the initializers.
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.restoreScope(node.function.positionalParameters.length +
        node.function.namedParameters.length);
    writeNodeList(node.initializers);

    leaveScope(memberScope: true);
  }

  @override
  void visitProcedure(Procedure node) {
    procedureOffsets.add(getBufferOffset());

    if (node.canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }

    final bool currentlyInNonimplementationSaved =
        _currentlyInNonimplementation;
    if (node.isNoSuchMethodForwarder || node.isSyntheticForwarder) {
      _currentlyInNonimplementation = true;
    }

    enterScope(memberScope: true);
    writeByte(Tag.Procedure);
    writeNonNullCanonicalNameReference(getCanonicalNameOfMember(node));
    writeUriReference(node.fileUri);
    writeOffset(node.startFileOffset);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.kind.index);
    writeByte(node.flags);
    writeName(node.name ?? _emptyName);
    writeAnnotationList(node.annotations);
    writeNullAllowedReference(node.forwardingStubSuperTargetReference);
    writeNullAllowedReference(node.forwardingStubInterfaceTargetReference);
    writeOptionalFunctionNode(node.function);
    leaveScope(memberScope: true);

    _currentlyInNonimplementation = currentlyInNonimplementationSaved;
    assert((node.forwardingStubSuperTarget != null) ||
        !(node.isForwardingStub && node.function.body != null));
  }

  @override
  void visitField(Field node) {
    if (node.canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    enterScope(memberScope: true);
    writeByte(Tag.Field);
    writeNonNullCanonicalNameReference(getCanonicalNameOfMember(node));
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.flags);
    writeName(node.name);
    writeAnnotationList(node.annotations);
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    leaveScope(memberScope: true);
  }

  @override
  void visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    if (node.canonicalName == null) {
      throw new ArgumentError('Missing canonical name for $node');
    }
    writeByte(Tag.RedirectingFactoryConstructor);
    enterScope(
        typeParameters: node.typeParameters,
        memberScope: true,
        variableScope: true);
    writeNonNullCanonicalNameReference(getCanonicalNameOfMember(node));
    writeUriReference(node.fileUri);
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.flags);
    writeName(node.name);

    writeAnnotationList(node.annotations);
    writeNonNullReference(node.targetReference);
    writeNodeList(node.typeArguments);
    writeNodeList(node.typeParameters);
    writeUInt30(node.positionalParameters.length + node.namedParameters.length);
    writeUInt30(node.requiredParameterCount);
    writeVariableDeclarationList(node.positionalParameters);
    writeVariableDeclarationList(node.namedParameters);

    leaveScope(
        typeParameters: node.typeParameters,
        memberScope: true,
        variableScope: true);
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
    LabelIndexer oldLabels = _labelIndexer;
    _labelIndexer = null;
    SwitchCaseIndexer oldCases = _switchCaseIndexer;
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
  }

  @override
  void visitVariableGet(VariableGet node) {
    _variableIndexer ??= new VariableIndexer();
    int index = _variableIndexer[node.variable];
    assert(index != null);
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
    _variableIndexer ??= new VariableIndexer();
    int index = _variableIndexer[node.variable];
    assert(index != null);
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
  void visitPropertyGet(PropertyGet node) {
    writeByte(Tag.PropertyGet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitPropertySet(PropertySet node) {
    writeByte(Tag.PropertySet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.value);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    writeByte(Tag.SuperPropertyGet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    writeByte(Tag.SuperPropertySet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNode(node.value);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    writeByte(Tag.DirectPropertyGet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeNonNullReference(node.targetReference);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    writeByte(Tag.DirectPropertySet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeNonNullReference(node.targetReference);
    writeNode(node.value);
  }

  @override
  void visitStaticGet(StaticGet node) {
    writeByte(Tag.StaticGet);
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
  void visitMethodInvocation(MethodInvocation node) {
    writeByte(Tag.MethodInvocation);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    writeByte(Tag.SuperMethodInvocation);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeArgumentsNode(node.arguments);
    writeNullAllowedReference(node.interfaceTargetReference);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    writeByte(Tag.DirectMethodInvocation);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeNonNullReference(node.targetReference);
    writeArgumentsNode(node.arguments);
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
    writeNode(node.operand);
  }

  int logicalOperatorIndex(String operator) {
    switch (operator) {
      case '&&':
        return 0;
      case '||':
        return 1;
    }
    throw new ArgumentError('Not a logical operator: $operator');
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    writeByte(Tag.LogicalExpression);
    writeNode(node.left);
    writeByte(logicalOperatorIndex(node.operator));
    writeNode(node.right);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    writeByte(Tag.ConditionalExpression);
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
  }

  @override
  void visitIsExpression(IsExpression node) {
    writeByte(Tag.IsExpression);
    writeOffset(node.fileOffset);
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
    writeStringReference(node.value);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    writeInteger(node.value);
  }

  writeInteger(int value) {
    int biasedValue = value + Tag.SpecializedIntLiteralBias;
    if (biasedValue >= 0 &&
        biasedValue & Tag.SpecializedPayloadMask == biasedValue) {
      writeByte(Tag.SpecializedIntLiteral + biasedValue);
    } else if (value.abs() >> 30 == 0) {
      if (value < 0) {
        writeByte(Tag.NegativeIntLiteral);
        writeUInt30(-value);
      } else {
        writeByte(Tag.PositiveIntLiteral);
        writeUInt30(value);
      }
    } else {
      // TODO: Pick a better format for big int literals.
      writeByte(Tag.BigIntLiteral);
      writeStringReference('$value');
    }
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    writeByte(Tag.DoubleLiteral);
    writeDouble(node.value);
  }

  writeDouble(double value) {
    _sink.addDouble(value);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    writeByte(node.value ? Tag.TrueLiteral : Tag.FalseLiteral);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    writeByte(Tag.NullLiteral);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    writeByte(Tag.SymbolLiteral);
    writeStringReference(node.value);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    writeByte(Tag.TypeLiteral);
    writeNode(node.type);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    writeByte(Tag.ThisExpression);
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
  void visitMapEntry(MapEntry node) {
    // Note: there is no tag on MapEntry
    writeNode(node.key);
    writeNode(node.value);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    writeByte(Tag.AwaitExpression);
    writeNode(node.operand);
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
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeVariableDeclaration(node.variable);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    writeByte(Tag.BlockExpression);
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeNodeList(node.body.statements);
    writeNode(node.value);
    _variableIndexer.popScope();
  }

  @override
  void visitInstantiation(Instantiation node) {
    writeByte(Tag.Instantiation);
    writeNode(node.expression);
    writeNodeList(node.typeArguments);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    writeByte(Tag.LoadLibrary);
    writeLibraryDependencyReference(node.import);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeByte(Tag.CheckLibraryIsLoaded);
    writeLibraryDependencyReference(node.import);
  }

  writeStatementOrEmpty(Statement node) {
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
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeByte(Tag.Block);
    writeNodeList(node.statements);
    _variableIndexer.popScope();
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeByte(Tag.AssertBlock);
    writeNodeList(node.statements);
    _variableIndexer.popScope();
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
    if (_labelIndexer == null) {
      _labelIndexer = new LabelIndexer();
    }
    _labelIndexer.enter(node);
    writeByte(Tag.LabeledStatement);
    writeNode(node.body);
    _labelIndexer.exit();
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    writeByte(Tag.ConstantExpression);
    writeOffset(node.fileOffset);
    writeDartType(node.type);
    writeConstantReference(node.constant);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    writeByte(Tag.BreakStatement);
    writeOffset(node.fileOffset);
    writeUInt30(_labelIndexer[node.target]);
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
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeByte(Tag.ForStatement);
    writeOffset(node.fileOffset);
    writeVariableDeclarationList(node.variables);
    writeOptionalNode(node.condition);
    writeNodeList(node.updates);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  @override
  void visitForInStatement(ForInStatement node) {
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeByte(node.isAsync ? Tag.AsyncForInStatement : Tag.ForInStatement);
    writeOffset(node.fileOffset);
    writeOffset(node.bodyOffset);
    writeVariableDeclaration(node.variable);
    writeNode(node.iterable);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (_switchCaseIndexer == null) {
      _switchCaseIndexer = new SwitchCaseIndexer();
    }
    _switchCaseIndexer.enter(node);
    writeByte(Tag.SwitchStatement);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeSwitchCaseNodeList(node.cases);
    _switchCaseIndexer.exit(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    // Note: there is no tag on SwitchCase.
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
    writeUInt30(_switchCaseIndexer[node.target]);
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
    writeNode(node.body);
    bool needsStackTrace = node.catches.any((Catch c) => c.stackTrace != null);
    writeByte(_encodeTryCatchFlags(needsStackTrace, node.isSynthetic));
    writeCatchNodeList(node.catches);
  }

  @override
  void visitCatch(Catch node) {
    // Note: there is no tag on Catch.
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.pushScope();
    writeOffset(node.fileOffset);
    writeNode(node.guard);
    writeOptionalVariableDeclaration(node.exception);
    writeOptionalVariableDeclaration(node.stackTrace);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  @override
  void visitTryFinally(TryFinally node) {
    writeByte(Tag.TryFinally);
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
    writeByte(node.flags);
    writeStringReference(node.name ?? '');
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    // Declare the variable after its initializer. It is not in scope in its
    // own initializer.
    _variableIndexer ??= new VariableIndexer();
    _variableIndexer.declare(node);
  }

  void writeVariableDeclarationList(List<VariableDeclaration> nodes) {
    writeList(nodes, writeVariableDeclaration);
  }

  void writeOptionalVariableDeclaration(VariableDeclaration node) {
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
  void visitBottomType(BottomType node) {
    writeByte(Tag.BottomType);
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
      writeNonNullReference(node.className);
    } else {
      writeByte(Tag.InterfaceType);
      writeNonNullReference(node.className);
      writeNodeList(node.typeArguments);
    }
  }

  @override
  void visitSupertype(Supertype node) {
    if (node.typeArguments.isEmpty) {
      writeByte(Tag.SimpleInterfaceType);
      writeNonNullReference(node.className);
    } else {
      writeByte(Tag.InterfaceType);
      writeNonNullReference(node.className);
      writeNodeList(node.typeArguments);
    }
  }

  @override
  void visitFunctionType(FunctionType node) {
    if (node.requiredParameterCount == node.positionalParameters.length &&
        node.typeParameters.isEmpty &&
        node.namedParameters.isEmpty &&
        node.typedefType == null) {
      writeByte(Tag.SimpleFunctionType);
      writeNodeList(node.positionalParameters);
      writeNode(node.returnType);
    } else {
      writeByte(Tag.FunctionType);
      enterScope(typeParameters: node.typeParameters);
      writeNodeList(node.typeParameters);
      writeUInt30(node.requiredParameterCount);
      writeUInt30(
          node.positionalParameters.length + node.namedParameters.length);
      writeNodeList(node.positionalParameters);
      writeNodeList(node.namedParameters);
      writeOptionalNode(node.typedefType);
      writeNode(node.returnType);
      leaveScope(typeParameters: node.typeParameters);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    writeStringReference(node.name);
    writeNode(node.type);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    writeByte(Tag.TypeParameterType);
    writeUInt30(_typeParameterIndexer[node.parameter]);
    writeOptionalNode(node.promotedBound);
  }

  @override
  void visitTypedefType(TypedefType node) {
    writeByte(Tag.TypedefType);
    writeNullAllowedReference(node.typedefReference);
    writeNodeList(node.typeArguments);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    writeByte(node.flags);
    writeAnnotationList(node.annotations);
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
    writeOptionalNode(node.defaultType);
  }

  // ================================================================
  // These are nodes that are never serialized directly.  Reaching one
  // during serialization is an error.
  @override
  void defaultNode(Node node) {
    throw new UnsupportedError('serialization of generic Nodes');
  }

  @override
  void defaultConstant(Constant node) {
    throw new UnsupportedError('serialization of generic Constants');
  }

  @override
  void defaultBasicLiteral(BasicLiteral node) {
    throw new UnsupportedError('serialization of generic BasicLiterals');
  }

  @override
  void defaultConstantReference(Constant node) {
    throw new UnsupportedError('serialization of generic Constant references');
  }

  @override
  void defaultDartType(DartType node) {
    throw new UnsupportedError('serialization of generic DartTypes');
  }

  @override
  void defaultExpression(Expression node) {
    throw new UnsupportedError('serialization of generic Expressions');
  }

  @override
  void defaultInitializer(Initializer node) {
    throw new UnsupportedError('serialization of generic Initializers');
  }

  @override
  void defaultMember(Member node) {
    throw new UnsupportedError('serialization of generic Members');
  }

  @override
  void defaultMemberReference(Member node) {
    throw new UnsupportedError('serialization of generic Member references');
  }

  @override
  void defaultStatement(Statement node) {
    throw new UnsupportedError('serialization of generic Statements');
  }

  @override
  void defaultTreeNode(TreeNode node) {
    throw new UnsupportedError('serialization of generic TreeNodes');
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
    throw new UnsupportedError('serialization of LibraryDependencys');
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
  void visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {
    throw new UnsupportedError(
        'serialization of RedirectingFactoryConstructor references');
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
  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    throw new UnsupportedError(
        'serialization of PartialInstantiationConstants ');
  }

  @override
  void visitPartialInstantiationConstantReference(
      PartialInstantiationConstant node) {
    throw new UnsupportedError(
        'serialization of PartialInstantiationConstant references');
  }

  @override
  void visitTearOffConstant(TearOffConstant node) {
    throw new UnsupportedError('serialization of TearOffConstants ');
  }

  @override
  void visitTearOffConstantReference(TearOffConstant node) {
    throw new UnsupportedError('serialization of TearOffConstant references');
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
}

typedef bool LibraryFilter(Library _);

class VariableIndexer {
  Map<VariableDeclaration, int> index;
  List<int> scopes;
  int stackHeight = 0;

  void declare(VariableDeclaration node) {
    index ??= <VariableDeclaration, int>{};
    index[node] = stackHeight++;
  }

  void pushScope() {
    scopes ??= new List<int>();
    scopes.add(stackHeight);
  }

  void popScope() {
    stackHeight = scopes.removeLast();
  }

  void restoreScope(int numberOfVariables) {
    stackHeight += numberOfVariables;
  }

  int operator [](VariableDeclaration node) {
    return index == null ? null : index[node];
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

  int operator [](LabeledStatement node) => index[node];
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

  int operator [](SwitchCase node) => index[node];
}

class ConstantIndexer extends RecursiveVisitor {
  final StringIndexer stringIndexer;

  final List<Constant> entries = <Constant>[];
  final Map<Constant, int> offsets = <Constant, int>{};
  int nextOffset = 0;

  final BinaryPrinter _printer;

  ConstantIndexer(this.stringIndexer, this._printer);

  int put(Constant constant) {
    final int oldOffset = offsets[constant];
    if (oldOffset != null) return oldOffset;

    // Traverse DAG in post-order to ensure children have their offsets assigned
    // before the parent.
    constant.visitChildren(this);

    if (constant is StringConstant) {
      stringIndexer.put(constant.value);
    } else if (constant is SymbolConstant) {
      stringIndexer.put(constant.name);
    } else if (constant is DoubleConstant) {
      stringIndexer.put('${constant.value}');
    } else if (constant is IntConstant) {
      final int value = constant.value;
      if ((value.abs() >> 30) != 0) {
        stringIndexer.put('$value');
      }
    }

    final int newOffset = nextOffset;
    entries.add(constant);
    nextOffset += _printer.writeConstantTableEntry(constant);
    return offsets[constant] = newOffset;
  }

  defaultConstantReference(Constant node) {
    put(node);
  }

  int operator [](Constant node) => offsets[node];
}

class TypeParameterIndexer {
  final Map<TypeParameter, int> index = <TypeParameter, int>{};
  int stackHeight = 0;

  void enter(List<TypeParameter> typeParameters) {
    for (int i = 0; i < typeParameters.length; ++i) {
      TypeParameter parameter = typeParameters[i];
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

  int operator [](TypeParameter parameter) =>
      index[parameter] ??
      (throw new ArgumentError('Type parameter $parameter is not indexed'));
}

class StringIndexer {
  // Note that the iteration order is important.
  final Map<String, int> index = new Map<String, int>();

  StringIndexer() {
    put('');
  }

  int put(String string) {
    int result = index[string];
    if (result == null) {
      result = index.length;
      index[string] = result;
    }
    return result;
  }

  int operator [](String string) => index[string];
}

class UriIndexer {
  // Note that the iteration order is important.
  final Map<Uri, int> index = new Map<Uri, int>();

  UriIndexer() {
    put(null);
  }

  int put(Uri uri) {
    int result = index[uri];
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
  Uint8List _doubleBufferUint8;

  int get offset => length + flushedLength;

  BufferedSink(this._sink);

  void addDouble(double d) {
    _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    _doubleBuffer[0] = d;
    addByte4(_doubleBufferUint8[0], _doubleBufferUint8[1],
        _doubleBufferUint8[2], _doubleBufferUint8[3]);
    addByte4(_doubleBufferUint8[4], _doubleBufferUint8[5],
        _doubleBufferUint8[6], _doubleBufferUint8[7]);
  }

  void addByte(int byte) {
    _buffer[length++] = byte;
    if (length == SIZE) {
      _sink.add(_buffer);
      _buffer = new Uint8List(SIZE);
      length = 0;
      flushedLength += SIZE;
    }
  }

  void addByte2(int byte1, int byte2) {
    if (length < SAFE_SIZE) {
      _buffer[length++] = byte1;
      _buffer[length++] = byte2;
    } else {
      addByte(byte1);
      addByte(byte2);
    }
  }

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
  final MetadataRepository<Object> repository;

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

class NotQuiteString {
  /**
   * Write [source] string into [target] starting at index [index].
   *
   * Optionally only write part of the input [source] starting at [start] and
   * ending at [end].
   *
   * The output space needed is at most [source.length] * 3.
   *
   * Returns
   *  * Non-negative on success (the new index in [target]).
   *  * -1 when [target] doesn't have enough space. Note that [target] can be
   *    poluted starting at [index].
   *  * -2 on input error, i.e. an unpaired lead or tail surrogate.
   */
  static int writeUtf8(List<int> target, int index, String source,
      [int start = 0, int end]) {
    RangeError.checkValidIndex(index, target, null, target.length);
    end = RangeError.checkValidRange(start, end, source.length);
    if (start == end) return index;
    int i = start;
    int length = target.length;
    do {
      int codeUnit = source.codeUnitAt(i++);
      while (codeUnit < 128) {
        if (index >= length) return -1;
        target[index++] = codeUnit;
        if (i >= end) return index;
        codeUnit = source.codeUnitAt(i++);
      }
      if (codeUnit < 0x800) {
        index += 2;
        if (index > length) return -1;
        target[index - 2] = 0xC0 | (codeUnit >> 6);
        target[index - 1] = 0x80 | (codeUnit & 0x3f);
      } else if (codeUnit & 0xF800 != 0xD800) {
        // Not a surrogate.
        index += 3;
        if (index > length) return -1;
        target[index - 3] = 0xE0 | (codeUnit >> 12);
        target[index - 2] = 0x80 | ((codeUnit >> 6) & 0x3f);
        target[index - 1] = 0x80 | (codeUnit & 0x3f);
      } else {
        if (codeUnit >= 0xDC00) return -2; // Unpaired tail surrogate.
        if (i >= end) return -2; // Unpaired lead surrogate.
        int nextChar = source.codeUnitAt(i++);
        if (nextChar & 0xFC00 != 0xDC00) return -2; // Unpaired lead surrogate.
        index += 4;
        if (index > length) return -1;
        codeUnit = (codeUnit & 0x3FF) + 0x40;
        target[index - 4] = 0xF0 | (codeUnit >> 8);
        target[index - 3] = 0x80 | ((codeUnit >> 2) & 0x3F);
        target[index - 2] =
            0x80 | (((codeUnit & 3) << 4) | ((nextChar & 0x3FF) >> 6));
        target[index - 1] = 0x80 | (nextChar & 0x3f);
      }
    } while (i < end);
    return index;
  }
}
