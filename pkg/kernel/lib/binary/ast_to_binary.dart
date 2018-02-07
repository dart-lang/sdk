// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_to_binary;

// ignore: UNDEFINED_HIDDEN_NAME
import 'dart:core' hide MapEntry;

import '../ast.dart';
import 'tag.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';

/// Writes to a binary file.
///
/// A [BinaryPrinter] can be used to write one file and must then be
/// discarded.
class BinaryPrinter extends Visitor implements BinarySink {
  VariableIndexer _variableIndexer;
  LabelIndexer _labelIndexer;
  SwitchCaseIndexer _switchCaseIndexer;
  final TypeParameterIndexer _typeParameterIndexer = new TypeParameterIndexer();
  final StringIndexer stringIndexer;
  ConstantIndexer _constantIndexer;
  final StringIndexer _sourceUriIndexer = new StringIndexer();
  final Set<Uri> _knownSourceUri = new Set<Uri>();
  Map<LibraryDependency, int> _libraryDependencyIndex =
      <LibraryDependency, int>{};

  List<_MetadataSubsection> _metadataSubsections;

  /// Map used to assign reference ids to nodes contained within metadata
  /// payloads.
  Map<Node, int> _nodeReferences;

  final BufferedSink _sink;

  List<int> libraryOffsets;
  List<int> classOffsets;
  List<int> procedureOffsets;
  int _binaryOffsetForSourceTable = -1;
  int _binaryOffsetForStringTable = -1;
  int _binaryOffsetForLinkTable = -1;
  int _binaryOffsetForConstantTable = -1;

  List<CanonicalName> _canonicalNameList;
  Set<CanonicalName> _knownCanonicalNameNonRootTops = new Set<CanonicalName>();
  Set<CanonicalName> _reindexedCanonicalNames = new Set<CanonicalName>();

  /// Create a printer that writes to the given [sink].
  ///
  /// The BinaryPrinter will use its own buffer, so the [sink] does not need
  /// one.
  ///
  /// If multiple binaries are to be written based on the same IR, a shared
  /// [globalIndexer] may be passed in to avoid rebuilding the same indices
  /// in every printer.
  BinaryPrinter(Sink<List<int>> sink, {StringIndexer stringIndexer})
      : _sink = new BufferedSink(sink),
        stringIndexer = stringIndexer ?? new StringIndexer() {
    _constantIndexer = new ConstantIndexer(this.stringIndexer);
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
    return _sink.flushedLength + _sink.length;
  }

  void writeStringTable(StringIndexer indexer) {
    _binaryOffsetForStringTable = getBufferOffset();

    // Write the end offsets.
    writeUInt30(indexer.numberOfStrings);
    int endOffset = 0;
    for (var entry in indexer.entries) {
      endOffset += entry.utf8Bytes.length;
      writeUInt30(endOffset);
    }
    // Write the UTF-8 encoded strings.
    for (var entry in indexer.entries) {
      writeBytes(entry.utf8Bytes);
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
    for (final entry in indexer.entries) {
      writeConstantTableEntry(entry);
    }
  }

  void writeConstantTableEntry(Constant constant) {
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
      writeStringReference('${constant.value}');
    } else if (constant is StringConstant) {
      writeByte(ConstantTag.StringConstant);
      writeStringReference(constant.value);
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
    } else if (constant is InstanceConstant) {
      writeByte(ConstantTag.InstanceConstant);
      writeClassReference(constant.klass);
      writeUInt30(constant.typeArguments.length);
      constant.typeArguments.forEach(writeDartType);
      writeUInt30(constant.fieldValues.length);
      constant.fieldValues.forEach((Reference fieldRef, Constant value) {
        writeCanonicalNameReference(fieldRef.canonicalName);
        writeConstantReference(value);
      });
    } else if (constant is TearOffConstant) {
      writeByte(ConstantTag.TearOffConstant);
      writeCanonicalNameReference(constant.procedure.canonicalName);
    } else if (constant is TypeLiteralConstant) {
      writeByte(ConstantTag.TypeLiteralConstant);
      writeDartType(constant.type);
    } else {
      throw 'Unsupported constant $constant';
    }
  }

  void writeDartType(DartType type) {
    type.accept(this);
  }

  void writeUriReference(Uri uri) {
    int index = 0; // equivalent to index = _sourceUriIndexer[""];
    if (_knownSourceUri.contains(uri)) {
      index = _sourceUriIndexer.put(uri == null ? "" : "$uri");
    }
    writeUInt30(index);
  }

  void writeList<T>(List<T> items, void writeItem(T x)) {
    writeUInt30(items.length);
    items.forEach(writeItem);
  }

  void writeNodeList(List<Node> nodes) {
    final len = nodes.length;
    writeUInt30(len);
    for (var i = 0; i < len; i++) {
      final node = nodes[i];
      writeNode(node);
    }
  }

  void writeNode(Node node) {
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMapping(node);
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

  void writeOptionalReference(Reference ref) {
    if (ref == null) {
      writeByte(Tag.Nothing);
    } else {
      writeByte(Tag.Something);
      writeReference(ref);
    }
  }

  void writeLinkTable(Program program) {
    _binaryOffsetForLinkTable = getBufferOffset();
    writeList(_canonicalNameList, writeCanonicalNameEntry);
  }

  void indexLinkTable(Program program) {
    _canonicalNameList = <CanonicalName>[];
    void visitCanonicalName(CanonicalName node) {
      node.index = _canonicalNameList.length;
      _canonicalNameList.add(node);
      node.children.forEach(visitCanonicalName);
    }

    for (var library in program.libraries) {
      if (!shouldWriteLibraryCanonicalNames(library)) continue;
      visitCanonicalName(library.canonicalName);
      _knownCanonicalNameNonRootTops.add(library.canonicalName);
    }
  }

  /// Compute canonical names for the whole program or parts of it.
  void computeCanonicalNames(Program program) {
    program.computeCanonicalNames();
  }

  /// Return `true` if all canonical names of the [library] should be written
  /// into the link table.  If some libraries of the program are skipped,
  /// then all the additional names referenced by the libraries that are written
  /// by [writeLibraries] are automatically added.
  bool shouldWriteLibraryCanonicalNames(Library library) => true;

  void writeCanonicalNameEntry(CanonicalName node) {
    var parent = node.parent;
    if (parent.isRoot) {
      writeUInt30(0);
    } else {
      writeUInt30(parent.index + 1);
    }
    writeStringReference(node.name);
  }

  void writeProgramFile(Program program) {
    computeCanonicalNames(program);
    final programOffset = getBufferOffset();
    writeUInt32(Tag.ProgramFile);
    writeUInt32(Tag.BinaryFormatVersion);
    indexLinkTable(program);
    indexUris(program);
    // Note: must write metadata payloads before any other node in the program
    // to collect references to nodes contained within metadata payloads.
    _writeMetadataPayloads(program);
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMappingImpl(program, programOffset);
    }
    libraryOffsets = <int>[];
    CanonicalName main = getCanonicalNameOfMember(program.mainMethod);
    if (main != null) {
      checkCanonicalName(main);
    }
    writeLibraries(program);
    writeUriToSource(program.uriToSource);
    writeLinkTable(program);
    _writeMetadataMappingSection(program);
    writeStringTable(stringIndexer);
    writeConstantTable(_constantIndexer);
    writeProgramIndex(program, program.libraries);

    _flush();
  }

  @override
  void writeNodeReference(Node node) {
    if (!MetadataRepository.isSupported(node)) {
      throw "Can't reference nodes of type ${node.runtimeType} from metadata.";
    }

    if (node == null) {
      writeUInt30(0);
    } else {
      final id =
          _nodeReferences.putIfAbsent(node, () => _nodeReferences.length);
      writeUInt30(id + 1);
    }
  }

  /// Collect and write out all metadata contained in metadata repositories
  /// associated with the program.
  ///
  /// Non-empty metadata subsections will be collected in [_metadataSubsections]
  /// and used to generate metadata mappings after all nodes in the program
  /// are written and all node offsets are known.
  ///
  /// Note: must write metadata payloads before any other node in the program
  /// to collect references to nodes contained within metadata payloads.
  void _writeMetadataPayloads(Program program) {
    program.metadata.forEach((tag, repository) {
      if (repository.mapping.isEmpty) {
        return;
      }

      // Write all payloads collecting outgoing node references and remembering
      // metadata offset for each node that had associated metadata.
      _nodeReferences = <Node, int>{};
      final metadataOffsets = <Node, int>{};
      repository.mapping.forEach((node, value) {
        if (!MetadataRepository.isSupported(node)) {
          throw "Nodes of type ${node.runtimeType} can't have metadata.";
        }

        metadataOffsets[node] = getBufferOffset();
        repository.writeToBinary(value, this);
      });

      _metadataSubsections ??= <_MetadataSubsection>[];
      _metadataSubsections.add(new _MetadataSubsection(
          repository, metadataOffsets, _nodeReferences));

      _nodeReferences = null;
    });
  }

  /// If the given [Node] has any metadata associated with it or is referenced
  /// from some metadata payload then we need to record its offset.
  void _recordNodeOffsetForMetadataMapping(Node node) {
    _recordNodeOffsetForMetadataMappingImpl(node, getBufferOffset());
  }

  void _recordNodeOffsetForMetadataMappingImpl(Node node, int nodeOffset) {
    for (var subsection in _metadataSubsections) {
      final metadataOffset = subsection.metadataOffsets[node];
      if (metadataOffset != null) {
        subsection.metadataMapping..add(nodeOffset)..add(metadataOffset);
      }
      if (subsection.nodeToReferenceId != null) {
        final id = subsection.nodeToReferenceId[node];
        if (id != null) {
          subsection.offsetsOfReferencedNodes[id] = nodeOffset;
        }
      }
    }
  }

  void _writeMetadataMappingSection(Program program) {
    if (_metadataSubsections == null) {
      writeUInt32(0); // Empty section.
      return;
    }

    _recordNodeOffsetForMetadataMappingImpl(program, 0);

    // RList<MetadataMapping> metadataMappings
    for (var subsection in _metadataSubsections) {
      // UInt32 tag
      writeUInt32(stringIndexer.put(subsection.repository.tag));

      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      final mappingLength = subsection.metadataMapping.length;
      for (var i = 0; i < mappingLength; i += 2) {
        writeUInt32(subsection.metadataMapping[i]); // node offset
        writeUInt32(subsection.metadataMapping[i + 1]); // metadata offset
      }
      writeUInt32(mappingLength ~/ 2);

      // RList<UInt32> nodeReferences
      if (subsection.nodeToReferenceId != null) {
        for (var nodeOffset in subsection.offsetsOfReferencedNodes) {
          writeUInt32(nodeOffset);
        }
        writeUInt32(subsection.offsetsOfReferencedNodes.length);
      } else {
        writeUInt32(0);
      }
    }
    writeUInt32(_metadataSubsections.length);
  }

  /// Write all of some of the libraries of the [program].
  void writeLibraries(Program program) {
    program.libraries.forEach(writeNode);
  }

  void writeProgramIndex(Program program, List<Library> libraries) {
    // Fixed-size ints at the end used as an index.
    assert(_binaryOffsetForSourceTable >= 0);
    writeUInt32(_binaryOffsetForSourceTable);
    assert(_binaryOffsetForLinkTable >= 0);
    writeUInt32(_binaryOffsetForLinkTable);
    assert(_binaryOffsetForStringTable >= 0);
    writeUInt32(_binaryOffsetForStringTable);
    assert(_binaryOffsetForConstantTable >= 0);
    writeUInt32(_binaryOffsetForConstantTable);

    CanonicalName main = getCanonicalNameOfMember(program.mainMethod);
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

  void indexUris(Program program) {
    _knownSourceUri.addAll(program.uriToSource.keys);
  }

  void writeUriToSource(Map<Uri, Source> uriToSource) {
    _binaryOffsetForSourceTable = getBufferOffset();

    int length = _sourceUriIndexer.numberOfStrings;
    writeUInt32(length);
    List<int> index = new List<int>(_sourceUriIndexer.entries.length);

    // Write data.
    for (int i = 0; i < length; ++i) {
      index[i] = getBufferOffset();

      StringTableEntry uri = _sourceUriIndexer.entries[i];
      Source source = uriToSource[Uri.parse(uri.value)] ??
          new Source(<int>[], const <int>[]);

      writeByteList(uri.utf8Bytes);
      writeByteList(source.source);
      List<int> lineStarts = source.lineStarts;
      writeUInt30(lineStarts.length);
      int previousLineStart = 0;
      lineStarts.forEach((lineStart) {
        writeUInt30(lineStart - previousLineStart);
        previousLineStart = lineStart;
      });
    }

    // Write index for random access.
    for (int i = 0; i < index.length; ++i) {
      writeUInt32(index[i]);
    }
  }

  void writeLibraryDependencyReference(LibraryDependency node) {
    int index = _libraryDependencyIndex[node];
    if (index == null) {
      throw 'Reference to library dependency $node out of scope';
    }
    writeUInt30(index);
  }

  void writeReference(Reference reference) {
    if (reference == null) {
      writeUInt30(0);
    } else {
      CanonicalName name = reference.canonicalName;
      if (name == null) {
        throw 'Missing canonical name for $reference';
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

  void writeCanonicalNameReference(CanonicalName name) {
    if (name == null) {
      writeUInt30(0);
    } else {
      checkCanonicalName(name);
      writeUInt30(name.index + 1);
    }
  }

  void writeLibraryReference(Library node) {
    writeCanonicalNameReference(node.canonicalName);
  }

  writeOffset(int offset) {
    // TODO(jensj): Delta-encoding.
    // File offset ranges from -1 and up,
    // but is here saved as unsigned (thus the +1)
    writeUInt30(offset + 1);
  }

  void writeClassReference(Class class_, {bool allowNull: false}) {
    if (class_ == null && !allowNull) {
      throw 'Expected a class reference to be valid but was `null`.';
    }
    writeCanonicalNameReference(getCanonicalNameOfClass(class_));
  }

  void writeMemberReference(Member member, {bool allowNull: false}) {
    if (member == null && !allowNull) {
      throw 'Expected a member reference to be valid but was `null`.';
    }
    writeCanonicalNameReference(getCanonicalNameOfMember(member));
  }

  void writeName(Name node) {
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMapping(node);
    }
    writeStringReference(node.name);
    // TODO: Consider a more compressed format for private names within the
    // enclosing library.
    if (node.isPrivate) {
      writeLibraryReference(node.library);
    }
  }

  bool insideExternalLibrary = false;

  visitLibrary(Library node) {
    insideExternalLibrary = node.isExternal;
    libraryOffsets.add(getBufferOffset());
    writeByte(insideExternalLibrary ? 1 : 0);
    writeCanonicalNameReference(getCanonicalNameOfLibrary(node));
    writeStringReference(node.name ?? '');
    // TODO(jensj): We save (almost) the same URI twice.
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    writeLibraryDependencies(node);
    writeAdditionalExports(node.additionalExports);
    writeLibraryParts(node);
    writeNodeList(node.typedefs);
    classOffsets = <int>[];
    writeNodeList(node.classes);
    classOffsets.add(getBufferOffset());
    writeNodeList(node.fields);
    procedureOffsets = <int>[];
    writeNodeList(node.procedures);
    procedureOffsets.add(getBufferOffset());

    // Fixed-size ints at the end used as an index.
    assert(classOffsets.length > 0);
    for (int offset in classOffsets) {
      writeUInt32(offset);
    }
    writeUInt32(classOffsets.length - 1);

    assert(procedureOffsets.length > 0);
    for (int offset in procedureOffsets) {
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
      var importNode = library.dependencies[i];
      _libraryDependencyIndex[importNode] = i;
      writeLibraryDependency(importNode);
    }
  }

  void writeAdditionalExports(List<Reference> additionalExports) {
    writeUInt30(additionalExports.length);
    for (Reference ref in additionalExports) {
      writeReference(ref);
    }
  }

  void writeLibraryDependency(LibraryDependency node) {
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMapping(node);
    }
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNodeList(node.annotations);
    writeLibraryReference(node.targetLibrary);
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
      var partNode = library.parts[i];
      writeLibraryPart(partNode);
    }
  }

  void writeLibraryPart(LibraryPart node) {
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMapping(node);
    }
    writeNodeList(node.annotations);
    writeUriReference(node.fileUri);
  }

  void visitTypedef(Typedef node) {
    writeCanonicalNameReference(getCanonicalNameOfTypedef(node));
    writeOffset(node.fileOffset);
    writeStringReference(node.name);
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    _typeParameterIndexer.enter(node.typeParameters);
    writeNodeList(node.typeParameters);
    writeNode(node.type);
    _typeParameterIndexer.exit(node.typeParameters);
  }

  void writeAnnotation(Expression annotation) {
    _variableIndexer ??= new VariableIndexer();
    writeNode(annotation);
  }

  void writeAnnotationList(List<Expression> annotations) {
    final len = annotations.length;
    writeUInt30(len);
    for (var i = 0; i < len; i++) {
      final annotation = annotations[i];
      writeAnnotation(annotation);
    }
  }

  int _encodeClassFlags(bool isAbstract, bool isEnum,
      bool isSyntheticMixinImplementation, ClassLevel level) {
    int abstractFlag = isAbstract ? 1 : 0;
    int isEnumFlag = isEnum ? 2 : 0;
    int isSyntheticMixinImplementationFlag =
        isSyntheticMixinImplementation ? 4 : 0;
    int levelFlags = (level.index - 1) << 3;
    return abstractFlag |
        isEnumFlag |
        isSyntheticMixinImplementationFlag |
        levelFlags;
  }

  visitClass(Class node) {
    classOffsets.add(getBufferOffset());

    int flags = _encodeClassFlags(node.isAbstract, node.isEnum,
        node.isSyntheticMixinImplementation, node.level);
    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    writeByte(Tag.Class);
    writeCanonicalNameReference(getCanonicalNameOfClass(node));
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(flags);
    writeStringReference(node.name ?? '');
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    _typeParameterIndexer.enter(node.typeParameters);
    writeNodeList(node.typeParameters);
    writeOptionalNode(node.supertype);
    writeOptionalNode(node.mixedInType);
    writeNodeList(node.implementedTypes);
    writeNodeList(node.fields);
    writeNodeList(node.constructors);
    procedureOffsets = <int>[];
    writeNodeList(node.procedures);
    procedureOffsets.add(getBufferOffset());
    writeNodeList(node.redirectingFactoryConstructors);
    _typeParameterIndexer.exit(node.typeParameters);

    assert(procedureOffsets.length > 0);
    for (int offset in procedureOffsets) {
      writeUInt32(offset);
    }
    writeUInt32(procedureOffsets.length - 1);
  }

  static final Name _emptyName = new Name('');

  visitConstructor(Constructor node) {
    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    _variableIndexer = new VariableIndexer();
    writeByte(Tag.Constructor);
    writeCanonicalNameReference(getCanonicalNameOfMember(node));
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.flags);
    writeName(node.name ?? _emptyName);
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    assert(node.function.typeParameters.isEmpty);
    writeNode(node.function);
    // Parameters are in scope in the initializers.
    _variableIndexer.restoreScope(node.function.positionalParameters.length +
        node.function.namedParameters.length);
    writeNodeList(node.initializers);
    _variableIndexer = null;
  }

  visitProcedure(Procedure node) {
    procedureOffsets.add(getBufferOffset());

    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    _variableIndexer = new VariableIndexer();
    writeByte(Tag.Procedure);
    writeCanonicalNameReference(getCanonicalNameOfMember(node));
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.kind.index);
    writeByte(node.flags);
    writeName(node.name ?? '');
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    writeOptionalReference(node.forwardingStubSuperTargetReference);
    writeOptionalReference(node.forwardingStubInterfaceTargetReference);
    writeOptionalNode(node.function);
    _variableIndexer = null;

    assert((node.forwardingStubSuperTarget != null) ||
        !(node.isForwardingStub && node.function.body != null));
  }

  visitField(Field node) {
    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    _variableIndexer = new VariableIndexer();
    writeByte(Tag.Field);
    writeCanonicalNameReference(getCanonicalNameOfMember(node));
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.flags);
    writeByte(node.flags2);
    writeName(node.name);
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    _variableIndexer = null;
  }

  visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    writeByte(Tag.RedirectingFactoryConstructor);
    _variableIndexer = new VariableIndexer();
    _variableIndexer.pushScope();
    _typeParameterIndexer.enter(node.typeParameters);
    writeCanonicalNameReference(getCanonicalNameOfMember(node));
    writeOffset(node.fileOffset);
    writeOffset(node.fileEndOffset);
    writeByte(node.flags);
    writeName(node.name);
    writeUriReference(node.fileUri);
    writeAnnotationList(node.annotations);
    writeReference(node.targetReference);
    writeNodeList(node.typeArguments);
    writeNodeList(node.typeParameters);
    writeUInt30(node.positionalParameters.length + node.namedParameters.length);
    writeUInt30(node.requiredParameterCount);
    writeVariableDeclarationList(node.positionalParameters);
    writeVariableDeclarationList(node.namedParameters);
    _typeParameterIndexer.exit(node.typeParameters);
    _variableIndexer.popScope();
    _variableIndexer = null;
  }

  visitInvalidInitializer(InvalidInitializer node) {
    writeByte(Tag.InvalidInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
  }

  visitFieldInitializer(FieldInitializer node) {
    writeByte(Tag.FieldInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeReference(node.fieldReference);
    writeNode(node.value);
  }

  visitSuperInitializer(SuperInitializer node) {
    writeByte(Tag.SuperInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    writeByte(Tag.RedirectingInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitLocalInitializer(LocalInitializer node) {
    writeByte(Tag.LocalInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeVariableDeclaration(node.variable);
  }

  visitAssertInitializer(AssertInitializer node) {
    writeByte(Tag.AssertInitializer);
    writeByte(node.isSynthetic ? 1 : 0);
    writeNode(node.statement);
  }

  visitFunctionNode(FunctionNode node) {
    writeByte(Tag.FunctionNode);
    assert(_variableIndexer != null);
    _variableIndexer.pushScope();
    var oldLabels = _labelIndexer;
    _labelIndexer = null;
    var oldCases = _switchCaseIndexer;
    _switchCaseIndexer = null;
    // Note: FunctionNode has no tag.
    _typeParameterIndexer.enter(node.typeParameters);
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
    _typeParameterIndexer.exit(node.typeParameters);
    _variableIndexer.popScope();
  }

  visitInvalidExpression(InvalidExpression node) {
    writeByte(Tag.InvalidExpression);
    writeOffset(node.fileOffset);
    writeStringReference(node.message ?? '');
  }

  visitVariableGet(VariableGet node) {
    assert(_variableIndexer != null);
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
      writeUInt30(_variableIndexer[node.variable]);
      writeOptionalNode(node.promotedType);
    }
  }

  visitVariableSet(VariableSet node) {
    assert(_variableIndexer != null);
    int index = _variableIndexer[node.variable];
    if (index & Tag.SpecializedPayloadMask == index) {
      writeByte(Tag.SpecializedVariableSet + index);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
      writeNode(node.value);
    } else {
      writeByte(Tag.VariableSet);
      writeOffset(node.fileOffset);
      writeUInt30(node.variable.binaryOffsetNoTag);
      writeUInt30(_variableIndexer[node.variable]);
      writeNode(node.value);
    }
  }

  visitPropertyGet(PropertyGet node) {
    writeByte(Tag.PropertyGet);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeName(node.name);
    writeReference(node.interfaceTargetReference);
  }

  visitPropertySet(PropertySet node) {
    writeByte(Tag.PropertySet);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.value);
    writeReference(node.interfaceTargetReference);
  }

  visitSuperPropertyGet(SuperPropertyGet node) {
    writeByte(Tag.SuperPropertyGet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeReference(node.interfaceTargetReference);
  }

  visitSuperPropertySet(SuperPropertySet node) {
    writeByte(Tag.SuperPropertySet);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNode(node.value);
    writeReference(node.interfaceTargetReference);
  }

  visitDirectPropertyGet(DirectPropertyGet node) {
    writeByte(Tag.DirectPropertyGet);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeReference(node.targetReference);
  }

  visitDirectPropertySet(DirectPropertySet node) {
    writeByte(Tag.DirectPropertySet);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeReference(node.targetReference);
    writeNode(node.value);
  }

  visitStaticGet(StaticGet node) {
    writeByte(Tag.StaticGet);
    writeOffset(node.fileOffset);
    writeReference(node.targetReference);
  }

  visitStaticSet(StaticSet node) {
    writeByte(Tag.StaticSet);
    writeOffset(node.fileOffset);
    writeReference(node.targetReference);
    writeNode(node.value);
  }

  visitMethodInvocation(MethodInvocation node) {
    writeByte(Tag.MethodInvocation);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.arguments);
    writeReference(node.interfaceTargetReference);
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    writeByte(Tag.SuperMethodInvocation);
    writeOffset(node.fileOffset);
    writeName(node.name);
    writeNode(node.arguments);
    writeReference(node.interfaceTargetReference);
  }

  visitDirectMethodInvocation(DirectMethodInvocation node) {
    writeByte(Tag.DirectMethodInvocation);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.receiver);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitStaticInvocation(StaticInvocation node) {
    writeByte(node.isConst ? Tag.ConstStaticInvocation : Tag.StaticInvocation);
    writeOffset(node.fileOffset);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    writeByte(node.isConst
        ? Tag.ConstConstructorInvocation
        : Tag.ConstructorInvocation);
    writeOffset(node.fileOffset);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitArguments(Arguments node) {
    writeUInt30(node.positional.length + node.named.length);
    writeNodeList(node.types);
    writeNodeList(node.positional);
    writeNodeList(node.named);
  }

  visitNamedExpression(NamedExpression node) {
    writeStringReference(node.name);
    writeNode(node.value);
  }

  visitNot(Not node) {
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
    throw 'Not a logical operator: $operator';
  }

  visitLogicalExpression(LogicalExpression node) {
    writeByte(Tag.LogicalExpression);
    writeNode(node.left);
    writeByte(logicalOperatorIndex(node.operator));
    writeNode(node.right);
  }

  visitConditionalExpression(ConditionalExpression node) {
    writeByte(Tag.ConditionalExpression);
    writeNode(node.condition);
    writeNode(node.then);
    writeNode(node.otherwise);
    writeOptionalNode(node.staticType);
  }

  visitStringConcatenation(StringConcatenation node) {
    writeByte(Tag.StringConcatenation);
    writeOffset(node.fileOffset);
    writeNodeList(node.expressions);
  }

  visitIsExpression(IsExpression node) {
    writeByte(Tag.IsExpression);
    writeOffset(node.fileOffset);
    writeNode(node.operand);
    writeNode(node.type);
  }

  visitAsExpression(AsExpression node) {
    writeByte(Tag.AsExpression);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.operand);
    writeNode(node.type);
  }

  visitStringLiteral(StringLiteral node) {
    writeByte(Tag.StringLiteral);
    writeStringReference(node.value);
  }

  visitIntLiteral(IntLiteral node) {
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

  visitDoubleLiteral(DoubleLiteral node) {
    writeDouble(node.value);
  }

  writeDouble(double value) {
    // TODO: Pick a better format for double literals.
    writeByte(Tag.DoubleLiteral);
    writeStringReference('$value');
  }

  visitBoolLiteral(BoolLiteral node) {
    writeByte(node.value ? Tag.TrueLiteral : Tag.FalseLiteral);
  }

  visitNullLiteral(NullLiteral node) {
    writeByte(Tag.NullLiteral);
  }

  visitSymbolLiteral(SymbolLiteral node) {
    writeByte(Tag.SymbolLiteral);
    writeStringReference(node.value);
  }

  visitTypeLiteral(TypeLiteral node) {
    writeByte(Tag.TypeLiteral);
    writeNode(node.type);
  }

  visitThisExpression(ThisExpression node) {
    writeByte(Tag.ThisExpression);
  }

  visitRethrow(Rethrow node) {
    writeByte(Tag.Rethrow);
    writeOffset(node.fileOffset);
  }

  visitThrow(Throw node) {
    writeByte(Tag.Throw);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
  }

  visitListLiteral(ListLiteral node) {
    writeByte(node.isConst ? Tag.ConstListLiteral : Tag.ListLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.typeArgument);
    writeNodeList(node.expressions);
  }

  visitMapLiteral(MapLiteral node) {
    writeByte(node.isConst ? Tag.ConstMapLiteral : Tag.MapLiteral);
    writeOffset(node.fileOffset);
    writeNode(node.keyType);
    writeNode(node.valueType);
    writeNodeList(node.entries);
  }

  visitMapEntry(MapEntry node) {
    // Note: there is no tag on MapEntry
    writeNode(node.key);
    writeNode(node.value);
  }

  visitAwaitExpression(AwaitExpression node) {
    writeByte(Tag.AwaitExpression);
    writeNode(node.operand);
  }

  visitFunctionExpression(FunctionExpression node) {
    writeByte(Tag.FunctionExpression);
    writeOffset(node.fileOffset);
    writeNode(node.function);
  }

  visitLet(Let node) {
    writeByte(Tag.Let);
    writeVariableDeclaration(node.variable);
    writeNode(node.body);
    --_variableIndexer.stackHeight;
  }

  visitInstantiation(Instantiation node) {
    writeByte(Tag.Instantiation);
    writeNode(node.expression);
    writeNodeList(node.typeArguments);
  }

  visitLoadLibrary(LoadLibrary node) {
    writeByte(Tag.LoadLibrary);
    writeLibraryDependencyReference(node.import);
  }

  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeByte(Tag.CheckLibraryIsLoaded);
    writeLibraryDependencyReference(node.import);
  }

  visitVectorCreation(VectorCreation node) {
    writeByte(Tag.VectorCreation);
    writeUInt30(node.length);
  }

  visitVectorGet(VectorGet node) {
    writeByte(Tag.VectorGet);
    writeNode(node.vectorExpression);
    writeUInt30(node.index);
  }

  visitVectorSet(VectorSet node) {
    writeByte(Tag.VectorSet);
    writeNode(node.vectorExpression);
    writeUInt30(node.index);
    writeNode(node.value);
  }

  visitVectorCopy(VectorCopy node) {
    writeByte(Tag.VectorCopy);
    writeNode(node.vectorExpression);
  }

  visitClosureCreation(ClosureCreation node) {
    writeByte(Tag.ClosureCreation);
    writeReference(node.topLevelFunctionReference);
    writeNode(node.contextVector);
    writeNode(node.functionType);
    writeNodeList(node.typeArguments);
  }

  writeStatementOrEmpty(Statement node) {
    if (node == null) {
      writeByte(Tag.EmptyStatement);
    } else {
      writeNode(node);
    }
  }

  visitExpressionStatement(ExpressionStatement node) {
    writeByte(Tag.ExpressionStatement);
    writeNode(node.expression);
  }

  visitBlock(Block node) {
    _variableIndexer.pushScope();
    writeByte(Tag.Block);
    writeNodeList(node.statements);
    _variableIndexer.popScope();
  }

  visitEmptyStatement(EmptyStatement node) {
    writeByte(Tag.EmptyStatement);
  }

  visitAssertStatement(AssertStatement node) {
    writeByte(Tag.AssertStatement);
    writeNode(node.condition);
    writeOffset(node.conditionStartOffset);
    writeOffset(node.conditionEndOffset);
    writeOptionalNode(node.message);
  }

  visitLabeledStatement(LabeledStatement node) {
    if (_labelIndexer == null) {
      _labelIndexer = new LabelIndexer();
    }
    _labelIndexer.enter(node);
    writeByte(Tag.LabeledStatement);
    writeNode(node.body);
    _labelIndexer.exit();
  }

  visitConstantExpression(ConstantExpression node) {
    writeByte(Tag.ConstantExpression);
    writeConstantReference(node.constant);
  }

  visitBreakStatement(BreakStatement node) {
    writeByte(Tag.BreakStatement);
    writeOffset(node.fileOffset);
    writeUInt30(_labelIndexer[node.target]);
  }

  visitWhileStatement(WhileStatement node) {
    writeByte(Tag.WhileStatement);
    writeOffset(node.fileOffset);
    writeNode(node.condition);
    writeNode(node.body);
  }

  visitDoStatement(DoStatement node) {
    writeByte(Tag.DoStatement);
    writeOffset(node.fileOffset);
    writeNode(node.body);
    writeNode(node.condition);
  }

  visitForStatement(ForStatement node) {
    _variableIndexer.pushScope();
    writeByte(Tag.ForStatement);
    writeOffset(node.fileOffset);
    writeVariableDeclarationList(node.variables);
    writeOptionalNode(node.condition);
    writeNodeList(node.updates);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  visitForInStatement(ForInStatement node) {
    _variableIndexer.pushScope();
    writeByte(node.isAsync ? Tag.AsyncForInStatement : Tag.ForInStatement);
    writeOffset(node.fileOffset);
    writeOffset(node.bodyOffset);
    writeVariableDeclaration(node.variable);
    writeNode(node.iterable);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  visitSwitchStatement(SwitchStatement node) {
    if (_switchCaseIndexer == null) {
      _switchCaseIndexer = new SwitchCaseIndexer();
    }
    _switchCaseIndexer.enter(node);
    writeByte(Tag.SwitchStatement);
    writeOffset(node.fileOffset);
    writeNode(node.expression);
    writeNodeList(node.cases);
    _switchCaseIndexer.exit(node);
  }

  visitSwitchCase(SwitchCase node) {
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

  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    writeByte(Tag.ContinueSwitchStatement);
    writeOffset(node.fileOffset);
    writeUInt30(_switchCaseIndexer[node.target]);
  }

  visitIfStatement(IfStatement node) {
    writeByte(Tag.IfStatement);
    writeOffset(node.fileOffset);
    writeNode(node.condition);
    writeNode(node.then);
    writeStatementOrEmpty(node.otherwise);
  }

  visitReturnStatement(ReturnStatement node) {
    writeByte(Tag.ReturnStatement);
    writeOffset(node.fileOffset);
    writeOptionalNode(node.expression);
  }

  visitTryCatch(TryCatch node) {
    writeByte(Tag.TryCatch);
    writeNode(node.body);
    if (node.catches.any((Catch c) => c.stackTrace != null)) {
      // at least one catch needs the stack trace.
      writeByte(1);
    } else {
      // no catch needs the stack trace.
      writeByte(0);
    }
    writeNodeList(node.catches);
  }

  visitCatch(Catch node) {
    // Note: there is no tag on Catch.
    _variableIndexer.pushScope();
    writeOffset(node.fileOffset);
    writeNode(node.guard);
    writeOptionalVariableDeclaration(node.exception);
    writeOptionalVariableDeclaration(node.stackTrace);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  visitTryFinally(TryFinally node) {
    writeByte(Tag.TryFinally);
    writeNode(node.body);
    writeNode(node.finalizer);
  }

  visitYieldStatement(YieldStatement node) {
    writeByte(Tag.YieldStatement);
    writeOffset(node.fileOffset);
    writeByte(node.flags);
    writeNode(node.expression);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    writeByte(Tag.VariableDeclaration);
    writeVariableDeclaration(node);
  }

  void writeVariableDeclaration(VariableDeclaration node) {
    if (_metadataSubsections != null) {
      _recordNodeOffsetForMetadataMapping(node);
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

  visitFunctionDeclaration(FunctionDeclaration node) {
    writeByte(Tag.FunctionDeclaration);
    writeOffset(node.fileOffset);
    writeVariableDeclaration(node.variable);
    writeNode(node.function);
  }

  visitBottomType(BottomType node) {
    writeByte(Tag.BottomType);
  }

  visitInvalidType(InvalidType node) {
    writeByte(Tag.InvalidType);
  }

  visitDynamicType(DynamicType node) {
    writeByte(Tag.DynamicType);
  }

  visitVoidType(VoidType node) {
    writeByte(Tag.VoidType);
  }

  visitInterfaceType(InterfaceType node) {
    if (node.typeArguments.isEmpty) {
      writeByte(Tag.SimpleInterfaceType);
      writeReference(node.className);
    } else {
      writeByte(Tag.InterfaceType);
      writeReference(node.className);
      writeNodeList(node.typeArguments);
    }
  }

  visitSupertype(Supertype node) {
    if (node.typeArguments.isEmpty) {
      writeByte(Tag.SimpleInterfaceType);
      writeReference(node.className);
    } else {
      writeByte(Tag.InterfaceType);
      writeReference(node.className);
      writeNodeList(node.typeArguments);
    }
  }

  visitFunctionType(FunctionType node) {
    if (node.requiredParameterCount == node.positionalParameters.length &&
        node.typeParameters.isEmpty &&
        node.namedParameters.isEmpty &&
        node.typedefReference == null) {
      writeByte(Tag.SimpleFunctionType);
      writeNodeList(node.positionalParameters);
      writeStringReferenceList(node.positionalParameterNames);
      writeNode(node.returnType);
    } else {
      writeByte(Tag.FunctionType);
      _typeParameterIndexer.enter(node.typeParameters);
      writeNodeList(node.typeParameters);
      writeUInt30(node.requiredParameterCount);
      writeUInt30(
          node.positionalParameters.length + node.namedParameters.length);
      writeNodeList(node.positionalParameters);
      writeNodeList(node.namedParameters);
      writeStringReferenceList(node.positionalParameterNames);
      writeReference(node.typedefReference);
      writeNode(node.returnType);
      _typeParameterIndexer.exit(node.typeParameters);
    }
  }

  visitNamedType(NamedType node) {
    writeStringReference(node.name);
    writeNode(node.type);
  }

  visitTypeParameterType(TypeParameterType node) {
    writeByte(Tag.TypeParameterType);
    writeUInt30(_typeParameterIndexer[node.parameter]);
    writeOptionalNode(node.promotedBound);
  }

  visitVectorType(VectorType node) {
    writeByte(Tag.VectorType);
  }

  visitTypedefType(TypedefType node) {
    writeByte(Tag.TypedefType);
    writeReference(node.typedefReference);
    writeNodeList(node.typeArguments);
  }

  visitTypeParameter(TypeParameter node) {
    writeByte(node.flags);
    writeAnnotationList(node.annotations);
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
  }

  defaultConstant(Constant node) {
    throw 'Implement handling of ${node.runtimeType}';
  }

  defaultNode(Node node) {
    throw 'Unsupported node: $node';
  }
}

typedef bool LibraryFilter(Library _);

class VariableIndexer {
  final Map<VariableDeclaration, int> index = <VariableDeclaration, int>{};
  final List<int> scopes = <int>[];
  int stackHeight = 0;

  void declare(VariableDeclaration node) {
    index[node] = stackHeight++;
  }

  void pushScope() {
    scopes.add(stackHeight);
  }

  void popScope() {
    stackHeight = scopes.removeLast();
  }

  void restoreScope(int numberOfVariables) {
    stackHeight += numberOfVariables;
  }

  int operator [](VariableDeclaration node) {
    return index[node];
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
    for (var caseNode in node.cases) {
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
  final Map<Constant, int> index = <Constant, int>{};

  ConstantIndexer(this.stringIndexer);

  defaultConstantReference(Constant node) {
    put(node);
  }

  int put(Constant constant) {
    final int value = index[constant];
    if (value != null) return value;

    // Traverse DAG in post-order to ensure children have their id's assigned
    // before the parent.
    return constant.accept(this);
  }

  defaultConstant(Constant node) {
    final int oldIndex = index[node];
    if (oldIndex != null) return oldIndex;

    if (node is StringConstant) {
      stringIndexer.put(node.value);
    } else if (node is DoubleConstant) {
      stringIndexer.put('${node.value}');
    } else if (node is IntConstant) {
      final int value = node.value;
      if ((value.abs() >> 30) != 0) {
        stringIndexer.put('$value');
      }
    }

    final int newIndex = entries.length;
    entries.add(node);
    return index[node] = newIndex;
  }

  visitMapConstant(MapConstant node) {
    for (final ConstantMapEntry entry in node.entries) {
      put(entry.key);
      put(entry.value);
    }
    return defaultConstant(node);
  }

  visitListConstant(ListConstant node) {
    for (final Constant entry in node.entries) {
      put(entry);
    }
    return defaultConstant(node);
  }

  visitInstanceConstant(InstanceConstant node) {
    for (final Constant entry in node.fieldValues.values) {
      put(entry);
    }
    return defaultConstant(node);
  }

  int operator [](Constant node) => index[node];
}

class TypeParameterIndexer {
  final Map<TypeParameter, int> index = <TypeParameter, int>{};
  int stackHeight = 0;

  void enter(List<TypeParameter> typeParameters) {
    for (var parameter in typeParameters) {
      index[parameter] = stackHeight;
      ++stackHeight;
    }
  }

  void exit(List<TypeParameter> typeParameters) {
    stackHeight -= typeParameters.length;
  }

  int operator [](TypeParameter parameter) => index[parameter];
}

class StringTableEntry {
  final String value;
  final List<int> utf8Bytes;

  StringTableEntry(String value)
      : value = value,
        utf8Bytes = const Utf8Encoder().convert(value);
}

class StringIndexer {
  final List<StringTableEntry> entries = <StringTableEntry>[];
  final LinkedHashMap<String, int> index = new LinkedHashMap<String, int>();

  StringIndexer() {
    put('');
  }

  int get numberOfStrings => index.length;

  int put(String string) {
    var result = index[string];
    if (result == null) {
      entries.add(new StringTableEntry(string));
      result = index.length;
      index[string] = result;
    }
    return result;
  }

  int operator [](String string) => index[string];
}

/// Computes and stores the index of a library, class, or member within its
/// parent list.
class GlobalIndexer extends TreeVisitor {
  final Map<TreeNode, int> indices = <TreeNode, int>{};

  void buildIndexForContainer(TreeNode libraryOrClass) {
    libraryOrClass.accept(this);
  }

  void buildIndexForList(List<TreeNode> list) {
    for (int i = 0; i < list.length; ++i) {
      TreeNode child = list[i];
      if (child != null) {
        indices[child] = i;
      }
    }
  }

  visitProgram(Program node) {
    buildIndexForList(node.libraries);
  }

  visitLibrary(Library node) {
    buildIndexForList(node.classes);
    buildIndexForList(node.fields);
    buildIndexForList(node.procedures);
  }

  visitClass(Class node) {
    buildIndexForList(node.fields);
    buildIndexForList(node.constructors);
    buildIndexForList(node.procedures);
  }

  int operator [](TreeNode memberOrLibraryOrClass) {
    var node = memberOrLibraryOrClass;
    assert(node is Member || node is Library || node is Class);
    int index = indices[node];
    if (index == null) {
      buildIndexForContainer(node.parent);
      return indices[node];
    } else {
      return index;
    }
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

  BufferedSink(this._sink);

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
      if (length == 0) {
        _sink.add(bytes);
        flushedLength += bytes.length;
      } else {
        _buffer.setRange(length, length + bytes.length, bytes);
        length += bytes.length;
      }
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
      _sink.add(_buffer.sublist(0, length));
      _sink.add(bytes);
      _buffer = new Uint8List(SIZE);
      flushedLength += length;
      flushedLength += bytes.length;
      length = 0;
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

  /// Offsets of metadata payloads associated with the nodes.
  final Map<Node, int> metadataOffsets;

  /// List of (nodeOffset, metadataOffset) pairs.
  /// Gradually filled by the writer as writing progresses, which by
  /// construction guarantees that pairs are sorted by first component
  /// (nodeOffset) in ascending order.
  final List<int> metadataMapping = <int>[];

  /// Mapping between nodes that are referenced from inside metadata payloads
  /// and their ids.
  final Map<Node, int> nodeToReferenceId;

  /// Mapping between reference ids and offsets of referenced nodes.
  /// Gradually filled by the writer as writing progresses but is not
  /// guaranteed to be sorted.
  final List<int> offsetsOfReferencedNodes;

  _MetadataSubsection(
      this.repository, this.metadataOffsets, Map<Node, int> nodeToReferenceId)
      : nodeToReferenceId =
            nodeToReferenceId.isNotEmpty ? nodeToReferenceId : null,
        offsetsOfReferencedNodes = nodeToReferenceId.isNotEmpty
            ? new List<int>.filled(nodeToReferenceId.length, 0)
            : null;
}
