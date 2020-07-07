// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_from_binary;

import 'dart:core' hide MapEntry;
import 'dart:developer';
import 'dart:convert';
import 'dart:typed_data';

import '../ast.dart';
import '../transformations/flags.dart';
import 'tag.dart';

class ParseError {
  String filename;
  int byteIndex;
  String message;
  String path;

  ParseError(this.message, {this.filename, this.byteIndex, this.path});

  String toString() => '$filename:$byteIndex: $message at $path';
}

class InvalidKernelVersionError {
  final int version;

  InvalidKernelVersionError(this.version);

  String toString() {
    return 'Unexpected Kernel Format Version ${version} '
        '(expected ${Tag.BinaryFormatVersion}).';
  }
}

class InvalidKernelSdkVersionError {
  final String version;

  InvalidKernelSdkVersionError(this.version);

  String toString() {
    return 'Unexpected Kernel SDK Version ${version} '
        '(expected ${expectedSdkHash}).';
  }
}

class CompilationModeError {
  final String message;

  CompilationModeError(this.message);

  String toString() => "CompilationModeError[$message]";
}

class CanonicalNameError {
  final String message;

  CanonicalNameError(this.message);
}

class CanonicalNameSdkError extends CanonicalNameError {
  CanonicalNameSdkError(String message) : super(message);
}

class _ComponentIndex {
  static const numberOfFixedFields = 10;

  int binaryOffsetForSourceTable;
  int binaryOffsetForCanonicalNames;
  int binaryOffsetForMetadataPayloads;
  int binaryOffsetForMetadataMappings;
  int binaryOffsetForStringTable;
  int binaryOffsetForConstantTable;
  int mainMethodReference;
  NonNullableByDefaultCompiledMode compiledMode;
  List<int> libraryOffsets;
  int libraryCount;
  int componentFileSizeInBytes;
}

class SubComponentView {
  final List<Library> libraries;
  final int componentStartOffset;
  final int componentFileSize;

  SubComponentView(
      this.libraries, this.componentStartOffset, this.componentFileSize);
}

class BinaryBuilder {
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final List<LabeledStatement> labelStack = <LabeledStatement>[];
  int labelStackBase = 0;
  int switchCaseStackBase = 0;
  final List<SwitchCase> switchCaseStack = <SwitchCase>[];
  final List<TypeParameter> typeParameterStack = <TypeParameter>[];
  final String filename;
  final List<int> _bytes;
  int _byteOffset = 0;
  final List<String> _stringTable = <String>[];
  final List<Uri> _sourceUriTable = <Uri>[];
  Map<int, Constant> _constantTable = <int, Constant>{};
  List<CanonicalName> _linkTable;
  int _transformerFlags = 0;
  Library _currentLibrary;
  int _componentStartOffset = 0;
  NonNullableByDefaultCompiledMode compilationMode;

  // If something goes wrong, this list should indicate what library,
  // class, and member was being built.
  List<String> debugPath = <String>[];

  final bool alwaysCreateNewNamedNodes;

  /// If binary contains metadata section with payloads referencing other nodes
  /// such Kernel binary can't be read lazily because metadata cross references
  /// will not be resolved correctly.
  bool _disableLazyReading = false;

  /// If binary contains metadata section with payloads referencing other nodes
  /// such Kernel binary can't be read lazily because metadata cross references
  /// will not be resolved correctly.
  bool _disableLazyClassReading = false;

  /// Note that [disableLazyClassReading] is incompatible
  /// with checkCanonicalNames on readComponent.
  BinaryBuilder(this._bytes,
      {this.filename,
      bool disableLazyReading = false,
      bool disableLazyClassReading = false,
      bool alwaysCreateNewNamedNodes})
      : _disableLazyReading = disableLazyReading,
        _disableLazyClassReading =
            disableLazyReading || disableLazyClassReading,
        this.alwaysCreateNewNamedNodes = alwaysCreateNewNamedNodes ?? false;

  fail(String message) {
    throw ParseError(message,
        byteIndex: _byteOffset, filename: filename, path: debugPath.join('::'));
  }

  int get byteOffset => _byteOffset;

  int readByte() => _bytes[_byteOffset++];

  int readUInt() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  int readUint32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  final Float64List _doubleBuffer = new Float64List(1);
  Uint8List _doubleBufferUint8;

  double readDouble() {
    _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    _doubleBufferUint8[0] = readByte();
    _doubleBufferUint8[1] = readByte();
    _doubleBufferUint8[2] = readByte();
    _doubleBufferUint8[3] = readByte();
    _doubleBufferUint8[4] = readByte();
    _doubleBufferUint8[5] = readByte();
    _doubleBufferUint8[6] = readByte();
    _doubleBufferUint8[7] = readByte();
    return _doubleBuffer[0];
  }

  Uint8List readBytes(int length) {
    Uint8List bytes = new Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return bytes;
  }

  Uint8List readByteList() {
    return readBytes(readUInt());
  }

  String readString() {
    return readStringEntry(readUInt());
  }

  String readStringEntry(int numBytes) {
    int start = _byteOffset;
    int end = start + numBytes;
    _byteOffset = end;
    for (int i = start; i < end; i++) {
      if (_bytes[i] > 127) {
        return _decodeWtf8(start, end);
      }
    }
    return new String.fromCharCodes(_bytes, start, end);
  }

  String _decodeWtf8(int start, int end) {
    // WTF-8 decoder that trusts its input, meaning that the correctness of
    // the code depends on the bytes from start to end being valid and
    // complete WTF-8. Instead of masking off the control bits from every
    // byte, it simply xor's the byte values together at their appropriate
    // bit shifts, and then xor's out all of the control bits at once.
    Uint16List charCodes = new Uint16List(end - start);
    int i = start;
    int j = 0;
    while (i < end) {
      int byte = _bytes[i++];
      if (byte < 0x80) {
        // ASCII.
        charCodes[j++] = byte;
      } else if (byte < 0xE0) {
        // Two-byte sequence (11-bit unicode value).
        int byte2 = _bytes[i++];
        int value = (byte << 6) ^ byte2 ^ 0x3080;
        assert(value >= 0x80 && value < 0x800);
        charCodes[j++] = value;
      } else if (byte < 0xF0) {
        // Three-byte sequence (16-bit unicode value).
        int byte2 = _bytes[i++];
        int byte3 = _bytes[i++];
        int value = (byte << 12) ^ (byte2 << 6) ^ byte3 ^ 0xE2080;
        assert(value >= 0x800 && value < 0x10000);
        charCodes[j++] = value;
      } else {
        // Four-byte sequence (non-BMP unicode value).
        int byte2 = _bytes[i++];
        int byte3 = _bytes[i++];
        int byte4 = _bytes[i++];
        int value =
            (byte << 18) ^ (byte2 << 12) ^ (byte3 << 6) ^ byte4 ^ 0x3C82080;
        assert(value >= 0x10000 && value < 0x110000);
        charCodes[j++] = 0xD7C0 + (value >> 10);
        charCodes[j++] = 0xDC00 + (value & 0x3FF);
      }
    }
    assert(i == end);
    return new String.fromCharCodes(charCodes, 0, j);
  }

  /// Read metadataMappings section from the binary.
  void _readMetadataMappings(
      Component component, int binaryOffsetForMetadataPayloads) {
    // Default reader ignores metadata section entirely.
  }

  /// Reads metadata for the given [node].
  Node _associateMetadata(Node node, int nodeOffset) {
    // Default reader ignores metadata section entirely.
    return node;
  }

  void readStringTable(List<String> table) {
    // Read the table of end offsets.
    int length = readUInt();
    List<int> endOffsets = new List<int>(length);
    for (int i = 0; i < length; ++i) {
      endOffsets[i] = readUInt();
    }
    // Read the WTF-8 encoded strings.
    table.length = length;
    int startOffset = 0;
    for (int i = 0; i < length; ++i) {
      table[i] = readStringEntry(endOffsets[i] - startOffset);
      startOffset = endOffsets[i];
    }
  }

  void readConstantTable() {
    final int length = readUInt();
    final int startOffset = byteOffset;
    for (int i = 0; i < length; i++) {
      _constantTable[byteOffset - startOffset] = readConstantTableEntry();
    }
  }

  Constant readConstantTableEntry() {
    final int constantTag = readByte();
    switch (constantTag) {
      case ConstantTag.NullConstant:
        return new NullConstant();
      case ConstantTag.BoolConstant:
        return new BoolConstant(readByte() == 1);
      case ConstantTag.IntConstant:
        return new IntConstant((readExpression() as IntLiteral).value);
      case ConstantTag.DoubleConstant:
        return new DoubleConstant(readDouble());
      case ConstantTag.StringConstant:
        return new StringConstant(readStringReference());
      case ConstantTag.SymbolConstant:
        Reference libraryReference = readLibraryReference(allowNull: true);
        return new SymbolConstant(readStringReference(), libraryReference);
      case ConstantTag.MapConstant:
        final DartType keyType = readDartType();
        final DartType valueType = readDartType();
        final int length = readUInt();
        final List<ConstantMapEntry> entries =
            new List<ConstantMapEntry>.filled(length, null, growable: true);
        for (int i = 0; i < length; i++) {
          final Constant key = readConstantReference();
          final Constant value = readConstantReference();
          entries[i] = new ConstantMapEntry(key, value);
        }
        return new MapConstant(keyType, valueType, entries);
      case ConstantTag.ListConstant:
        final DartType typeArgument = readDartType();
        final int length = readUInt();
        final List<Constant> entries =
            new List<Constant>.filled(length, null, growable: true);
        for (int i = 0; i < length; i++) {
          entries[i] = readConstantReference();
        }
        return new ListConstant(typeArgument, entries);
      case ConstantTag.SetConstant:
        final DartType typeArgument = readDartType();
        final int length = readUInt();
        final List<Constant> entries =
            new List<Constant>.filled(length, null, growable: true);
        for (int i = 0; i < length; i++) {
          entries[i] = readConstantReference();
        }
        return new SetConstant(typeArgument, entries);
      case ConstantTag.InstanceConstant:
        final Reference classReference = readClassReference();
        final int typeArgumentCount = readUInt();
        final List<DartType> typeArguments =
            new List<DartType>.filled(typeArgumentCount, null, growable: true);
        for (int i = 0; i < typeArgumentCount; i++) {
          typeArguments[i] = readDartType();
        }
        final int fieldValueCount = readUInt();
        final Map<Reference, Constant> fieldValues = <Reference, Constant>{};
        for (int i = 0; i < fieldValueCount; i++) {
          final Reference fieldRef =
              readCanonicalNameReference().getReference();
          final Constant constant = readConstantReference();
          fieldValues[fieldRef] = constant;
        }
        return new InstanceConstant(classReference, typeArguments, fieldValues);
      case ConstantTag.PartialInstantiationConstant:
        final tearOffConstant = readConstantReference() as TearOffConstant;
        final int length = readUInt();
        final List<DartType> types = new List<DartType>(length);
        for (int i = 0; i < length; i++) {
          types[i] = readDartType();
        }
        return new PartialInstantiationConstant(tearOffConstant, types);
      case ConstantTag.TearOffConstant:
        final Reference reference = readCanonicalNameReference().getReference();
        return new TearOffConstant.byReference(reference);
      case ConstantTag.TypeLiteralConstant:
        final DartType type = readDartType();
        return new TypeLiteralConstant(type);
      case ConstantTag.UnevaluatedConstant:
        final Expression expression = readExpression();
        return new UnevaluatedConstant(expression);
    }

    throw fail('unexpected constant tag: $constantTag');
  }

  Constant readConstantReference() {
    final int offset = readUInt();
    Constant constant = _constantTable[offset];
    assert(constant != null);
    return constant;
  }

  Uri readUriReference() {
    return _sourceUriTable[readUInt()];
  }

  String readStringReference() {
    return _stringTable[readUInt()];
  }

  List<String> readStringReferenceList() {
    int length = readUInt();
    List<String> result = new List<String>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readStringReference();
    }
    return result;
  }

  String readStringOrNullIfEmpty() {
    var string = readStringReference();
    return string.isEmpty ? null : string;
  }

  bool readAndCheckOptionTag() {
    int tag = readByte();
    if (tag == Tag.Nothing) {
      return false;
    } else if (tag == Tag.Something) {
      return true;
    } else {
      throw fail('unexpected option tag: $tag');
    }
  }

  List<Expression> readAnnotationList(TreeNode parent) {
    int length = readUInt();
    if (length == 0) return const <Expression>[];
    List<Expression> list =
        new List<Expression>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      list[i] = readExpression()..parent = parent;
    }
    return list;
  }

  void _fillTreeNodeList(
      List<TreeNode> list, TreeNode buildObject(int index), TreeNode parent) {
    var length = readUInt();
    list.length = length;
    for (int i = 0; i < length; ++i) {
      TreeNode object = buildObject(i);
      list[i] = object..parent = parent;
    }
  }

  void _fillNonTreeNodeList(List<Node> list, Node buildObject()) {
    var length = readUInt();
    list.length = length;
    for (int i = 0; i < length; ++i) {
      Node object = buildObject();
      list[i] = object;
    }
  }

  /// Reads a list of named nodes, reusing any existing objects already in the
  /// linking tree. The nodes are merged into [list], and if reading the library
  /// implementation, the order is corrected.
  ///
  /// [readObject] should read the object definition and its canonical name.
  /// If an existing object is bound to the canonical name, the existing object
  /// must be reused and returned.
  void _mergeNamedNodeList(
      List<NamedNode> list, NamedNode readObject(int index), TreeNode parent) {
    // When reading the library implementation, overwrite the whole list
    // with the new one.
    _fillTreeNodeList(list, readObject, parent);
  }

  void readLinkTable(CanonicalName linkRoot) {
    int length = readUInt();
    _linkTable = new List<CanonicalName>(length);
    for (int i = 0; i < length; ++i) {
      int biasedParentIndex = readUInt();
      String name = readStringReference();
      var parent =
          biasedParentIndex == 0 ? linkRoot : _linkTable[biasedParentIndex - 1];
      _linkTable[i] = parent.getChild(name);
    }
  }

  List<int> _indexComponents() {
    _checkEmptyInput();
    int savedByteOffset = _byteOffset;
    _byteOffset = _bytes.length - 4;
    List<int> index = <int>[];
    while (_byteOffset > 0) {
      int size = readUint32();
      if (size <= 0) {
        throw fail("invalid size '$size' reported at offset $byteOffset");
      }
      int start = _byteOffset - size;
      if (start < 0) {
        throw fail("indicated size does not match file size");
      }
      index.add(size);
      _byteOffset = start - 4;
    }
    _byteOffset = savedByteOffset;
    return new List.from(index.reversed);
  }

  void _checkEmptyInput() {
    if (_bytes.length == 0) throw new StateError("Empty input given.");
  }

  void _readAndVerifySdkHash() {
    final sdkHash = ascii.decode(readBytes(sdkHashLength));
    if (!isValidSdkHash(sdkHash)) {
      throw InvalidKernelSdkVersionError(sdkHash);
    }
  }

  /// Deserializes a kernel component and stores it in [component].
  ///
  /// When linking with a non-empty component, canonical names must have been
  /// computed ahead of time.
  ///
  /// The input bytes may contain multiple files concatenated.
  ///
  /// If [createView] is true, returns a list of [SubComponentView] - one for
  /// each concatenated dill - each of which knowing where in the combined dill
  /// it came from. If [createView] is false null will be returned.
  List<SubComponentView> readComponent(Component component,
      {bool checkCanonicalNames: false, bool createView: false}) {
    return Timeline.timeSync<List<SubComponentView>>(
        "BinaryBuilder.readComponent", () {
      _checkEmptyInput();

      // Check that we have a .dill file and it has the correct version before we
      // start decoding it.  Otherwise we will fail for cryptic reasons.
      int offset = _byteOffset;
      int magic = readUint32();
      if (magic != Tag.ComponentFile) {
        throw ArgumentError('Not a .dill file (wrong magic number).');
      }
      int version = readUint32();
      if (version != Tag.BinaryFormatVersion) {
        throw InvalidKernelVersionError(version);
      }

      _readAndVerifySdkHash();

      _byteOffset = offset;
      List<int> componentFileSizes = _indexComponents();
      if (componentFileSizes.length > 1) {
        _disableLazyReading = true;
        _disableLazyClassReading = true;
      }
      int componentFileIndex = 0;
      List<SubComponentView> views;
      if (createView) {
        views = new List<SubComponentView>();
      }
      while (_byteOffset < _bytes.length) {
        SubComponentView view = _readOneComponent(
            component, componentFileSizes[componentFileIndex],
            createView: createView);
        if (createView) {
          views.add(view);
        }
        ++componentFileIndex;
      }

      if (checkCanonicalNames) {
        _checkCanonicalNameChildren(component.root);
      }
      return views;
    });
  }

  /// Deserializes the source and stores it in [component].
  ///
  /// The input bytes may contain multiple files concatenated.
  void readComponentSource(Component component) {
    List<int> componentFileSizes = _indexComponents();
    if (componentFileSizes.length > 1) {
      _disableLazyReading = true;
      _disableLazyClassReading = true;
    }
    int componentFileIndex = 0;
    while (_byteOffset < _bytes.length) {
      _readOneComponentSource(
          component, componentFileSizes[componentFileIndex]);
      ++componentFileIndex;
    }
  }

  /// Reads a single component file from the input and loads it into [component],
  /// overwriting and reusing any existing data in the component.
  ///
  /// When linking with a non-empty component, canonical names must have been
  /// computed ahead of time.
  ///
  /// This should *only* be used when there is a reason to not allow
  /// concatenated files.
  void readSingleFileComponent(Component component,
      {bool checkCanonicalNames: false}) {
    List<int> componentFileSizes = _indexComponents();
    if (componentFileSizes.isEmpty) throw fail("invalid component data");
    _readOneComponent(component, componentFileSizes[0]);
    if (_byteOffset < _bytes.length) {
      if (_byteOffset + 3 < _bytes.length) {
        int magic = readUint32();
        if (magic == Tag.ComponentFile) {
          throw 'Concatenated component file given when a single component '
              'was expected.';
        }
      }
      throw 'Unrecognized bytes following component data';
    }

    if (checkCanonicalNames) {
      _checkCanonicalNameChildren(component.root);
    }
  }

  void _checkCanonicalNameChildren(CanonicalName parent) {
    Iterable<CanonicalName> parentChildren = parent.childrenOrNull;
    if (parentChildren != null) {
      for (CanonicalName child in parentChildren) {
        if (child.name != '@methods' &&
            child.name != '@typedefs' &&
            child.name != '@fields' &&
            child.name != '@getters' &&
            child.name != '@setters' &&
            child.name != '@factories' &&
            child.name != '@constructors') {
          bool checkReferenceNode = true;
          if (child.reference == null) {
            // OK for "if private: URI of library" part of "Qualified name"...
            Iterable<CanonicalName> children = child.childrenOrNull;
            if (parent.parent != null &&
                children != null &&
                children.isNotEmpty &&
                children.first.name.startsWith("_")) {
              // OK then.
              checkReferenceNode = false;
            } else {
              throw buildCanonicalNameError(
                  "Null reference (${child.name}) ($child).", child);
            }
          }
          if (checkReferenceNode) {
            if (child.reference.canonicalName != child) {
              throw new CanonicalNameError(
                  "Canonical name and reference doesn't agree.");
            }
            if (child.reference.node == null) {
              throw buildCanonicalNameError(
                  "Reference is null (${child.name}) ($child).", child);
            }
          }
        }
        _checkCanonicalNameChildren(child);
      }
    }
  }

  CanonicalNameError buildCanonicalNameError(
      String message, CanonicalName problemNode) {
    // Special-case missing sdk entries as that is probably a change to the
    // platform - that's something we might want to react differently to.
    String libraryUri = problemNode?.nonRootTop?.name ?? "";
    if (libraryUri.startsWith("dart:")) {
      return new CanonicalNameSdkError(message);
    }
    return new CanonicalNameError(message);
  }

  _ComponentIndex _readComponentIndex(int componentFileSize) {
    int savedByteIndex = _byteOffset;

    _ComponentIndex result = new _ComponentIndex();

    // There are two fields: file size and library count.
    _byteOffset = _componentStartOffset + componentFileSize - (2) * 4;
    result.libraryCount = readUint32();
    // Library offsets are used for start and end offsets, so there is one extra
    // element that this the end offset of the last library
    result.libraryOffsets = new List<int>(result.libraryCount + 1);
    result.componentFileSizeInBytes = readUint32();
    if (result.componentFileSizeInBytes != componentFileSize) {
      throw "Malformed binary: This component file's component index indicates that"
          " the file size should be $componentFileSize but other component indexes"
          " has indicated that the size should be "
          "${result.componentFileSizeInBytes}.";
    }

    // Skip to the start of the index.
    _byteOffset -=
        ((result.libraryCount + 1) + _ComponentIndex.numberOfFixedFields) * 4;

    // Now read the component index.
    result.binaryOffsetForSourceTable = _componentStartOffset + readUint32();
    result.binaryOffsetForCanonicalNames = _componentStartOffset + readUint32();
    result.binaryOffsetForMetadataPayloads =
        _componentStartOffset + readUint32();
    result.binaryOffsetForMetadataMappings =
        _componentStartOffset + readUint32();
    result.binaryOffsetForStringTable = _componentStartOffset + readUint32();
    result.binaryOffsetForConstantTable = _componentStartOffset + readUint32();
    result.mainMethodReference = readUint32();
    result.compiledMode = NonNullableByDefaultCompiledMode.values[readUint32()];
    for (int i = 0; i < result.libraryCount + 1; ++i) {
      result.libraryOffsets[i] = _componentStartOffset + readUint32();
    }

    _byteOffset = savedByteIndex;

    return result;
  }

  void _readOneComponentSource(Component component, int componentFileSize) {
    _componentStartOffset = _byteOffset;

    final int magic = readUint32();
    if (magic != Tag.ComponentFile) {
      throw ArgumentError('Not a .dill file (wrong magic number).');
    }

    final int formatVersion = readUint32();
    if (formatVersion != Tag.BinaryFormatVersion) {
      throw InvalidKernelVersionError(formatVersion);
    }

    _readAndVerifySdkHash();

    // Read component index from the end of this ComponentFiles serialized data.
    _ComponentIndex index = _readComponentIndex(componentFileSize);

    _byteOffset = index.binaryOffsetForSourceTable;
    Map<Uri, Source> uriToSource = readUriToSource();
    _mergeUriToSource(component.uriToSource, uriToSource);

    _byteOffset = _componentStartOffset + componentFileSize;
  }

  SubComponentView _readOneComponent(Component component, int componentFileSize,
      {bool createView: false}) {
    _componentStartOffset = _byteOffset;

    final int magic = readUint32();
    if (magic != Tag.ComponentFile) {
      throw ArgumentError('Not a .dill file (wrong magic number).');
    }

    final int formatVersion = readUint32();
    if (formatVersion != Tag.BinaryFormatVersion) {
      throw InvalidKernelVersionError(formatVersion);
    }

    _readAndVerifySdkHash();

    List<String> problemsAsJson = readListOfStrings();
    if (problemsAsJson != null) {
      component.problemsAsJson ??= <String>[];
      component.problemsAsJson.addAll(problemsAsJson);
    }

    // Read component index from the end of this ComponentFiles serialized data.
    _ComponentIndex index = _readComponentIndex(componentFileSize);
    if (compilationMode == null) {
      compilationMode = component.modeRaw;
    }
    if (compilationMode == null) {
      compilationMode = index.compiledMode;
    } else if (compilationMode != index.compiledMode) {
      if (compilationMode == NonNullableByDefaultCompiledMode.Agnostic) {
        compilationMode = index.compiledMode;
      } else if (index.compiledMode ==
          NonNullableByDefaultCompiledMode.Agnostic) {
        // Keep as-is.
      } else {
        if ((compilationMode == NonNullableByDefaultCompiledMode.Disabled ||
                index.compiledMode ==
                    NonNullableByDefaultCompiledMode.Disabled) &&
            (compilationMode == NonNullableByDefaultCompiledMode.Weak ||
                index.compiledMode == NonNullableByDefaultCompiledMode.Weak)) {
          // One is disabled and one is weak.
          // => We allow that and "merge" them as disabled.
          compilationMode = NonNullableByDefaultCompiledMode.Disabled;
        } else {
          // Mixed mode where agnostic isn't involved and it's not
          // disabled + weak.
          throw new CompilationModeError(
              "Mixed compilation mode found: $compilationMode "
              "and ${index.compiledMode}.");
        }
      }
    }

    _byteOffset = index.binaryOffsetForStringTable;
    readStringTable(_stringTable);

    _byteOffset = index.binaryOffsetForCanonicalNames;
    readLinkTable(component.root);

    // TODO(alexmarkov): reverse metadata mappings and read forwards
    _byteOffset = index.binaryOffsetForStringTable; // Read backwards.
    _readMetadataMappings(component, index.binaryOffsetForMetadataPayloads);

    _associateMetadata(component, _componentStartOffset);

    _byteOffset = index.binaryOffsetForSourceTable;
    Map<Uri, Source> uriToSource = readUriToSource();
    _mergeUriToSource(component.uriToSource, uriToSource);

    _byteOffset = index.binaryOffsetForConstantTable;
    readConstantTable();

    int numberOfLibraries = index.libraryCount;

    SubComponentView result;
    if (createView) {
      result = new SubComponentView(new List<Library>(numberOfLibraries),
          _componentStartOffset, componentFileSize);
    }

    for (int i = 0; i < numberOfLibraries; ++i) {
      _byteOffset = index.libraryOffsets[i];
      Library library = readLibrary(component, index.libraryOffsets[i + 1]);
      if (createView) {
        result.libraries[i] = library;
      }
    }

    Reference mainMethod =
        getMemberReferenceFromInt(index.mainMethodReference, allowNull: true);
    component.setMainMethodAndMode(mainMethod, false, compilationMode);

    _byteOffset = _componentStartOffset + componentFileSize;

    assert(typeParameterStack.isEmpty);

    return result;
  }

  /// Read a list of strings. If the list is empty, [null] is returned.
  List<String> readListOfStrings() {
    int length = readUInt();
    if (length == 0) return null;
    List<String> strings =
        new List<String>.filled(length, null, growable: true);
    for (int i = 0; i < length; i++) {
      String s = readString();
      strings[i] = s;
    }
    return strings;
  }

  Map<Uri, Source> readUriToSource() {
    int length = readUint32();

    // Read data.
    _sourceUriTable.length = length;
    Map<Uri, Source> uriToSource = <Uri, Source>{};
    for (int i = 0; i < length; ++i) {
      String uriString = readString();
      Uri uri = uriString.isEmpty ? null : Uri.parse(uriString);
      _sourceUriTable[i] = uri;
      Uint8List sourceCode = readByteList();
      int lineCount = readUInt();
      List<int> lineStarts = new List<int>(lineCount);
      int previousLineStart = 0;
      for (int j = 0; j < lineCount; ++j) {
        int lineStart = readUInt() + previousLineStart;
        lineStarts[j] = lineStart;
        previousLineStart = lineStart;
      }
      String importUriString = readString();
      Uri importUri =
          importUriString.isEmpty ? null : Uri.parse(importUriString);
      uriToSource[uri] = new Source(lineStarts, sourceCode, importUri, uri);
    }

    // Read index.
    for (int i = 0; i < length; ++i) {
      readUint32();
    }
    return uriToSource;
  }

  // Add everything from [src] into [dst], but don't overwrite a non-empty
  // source with an empty source. Empty sources may be introduced by
  // synthetic, copy-down implementations such as mixin applications or
  // noSuchMethod forwarders.
  void _mergeUriToSource(Map<Uri, Source> dst, Map<Uri, Source> src) {
    if (dst.isEmpty) {
      // Fast path for the common case of one component per binary.
      dst.addAll(src);
    } else {
      src.forEach((Uri key, Source value) {
        if (value.source.isNotEmpty || !dst.containsKey(key)) {
          dst[key] = value;
        }
      });
    }
  }

  CanonicalName readCanonicalNameReference() {
    var index = readUInt();
    if (index == 0) return null;
    return _linkTable[index - 1];
  }

  CanonicalName getCanonicalNameReferenceFromInt(int index) {
    if (index == 0) return null;
    return _linkTable[index - 1];
  }

  Reference readLibraryReference({bool allowNull: false}) {
    CanonicalName canonicalName = readCanonicalNameReference();
    if (canonicalName != null) return canonicalName.getReference();
    if (allowNull) return null;
    throw 'Expected a library reference to be valid but was `null`.';
  }

  LibraryDependency readLibraryDependencyReference() {
    int index = readUInt();
    return _currentLibrary.dependencies[index];
  }

  Reference readClassReference({bool allowNull: false}) {
    var name = readCanonicalNameReference();
    if (name == null && !allowNull) {
      throw 'Expected a class reference to be valid but was `null`.';
    }
    return name?.getReference();
  }

  Reference readMemberReference({bool allowNull: false}) {
    var name = readCanonicalNameReference();
    if (name == null && !allowNull) {
      throw 'Expected a member reference to be valid but was `null`.';
    }
    return name?.getReference();
  }

  Reference getMemberReferenceFromInt(int index, {bool allowNull: false}) {
    var name = getCanonicalNameReferenceFromInt(index);
    if (name == null && !allowNull) {
      throw 'Expected a member reference to be valid but was `null`.';
    }
    return name?.getReference();
  }

  Reference readTypedefReference() {
    return readCanonicalNameReference()?.getReference();
  }

  Name readName() {
    String text = readStringReference();
    if (text.isNotEmpty && text[0] == '_') {
      return new Name.byReference(text, readLibraryReference());
    } else {
      return new Name(text);
    }
  }

  Library readLibrary(Component component, int endOffset) {
    // Read index.
    int savedByteOffset = _byteOffset;

    // There is a field for the procedure count.
    _byteOffset = endOffset - (1) * 4;
    int procedureCount = readUint32();
    List<int> procedureOffsets = new List<int>(procedureCount + 1);

    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets, and then the class count (i.e. procedure count + 3 fields).
    _byteOffset = endOffset - (procedureCount + 3) * 4;
    int classCount = readUint32();
    for (int i = 0; i < procedureCount + 1; i++) {
      procedureOffsets[i] = _componentStartOffset + readUint32();
    }
    List<int> classOffsets = new List<int>(classCount + 1);

    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets, then the class count and that number + 1 (for the end) offsets.
    // (i.e. procedure count + class count + 4 fields).
    _byteOffset = endOffset - (procedureCount + classCount + 4) * 4;
    for (int i = 0; i < classCount + 1; i++) {
      classOffsets[i] = _componentStartOffset + readUint32();
    }
    _byteOffset = savedByteOffset;

    int flags = readByte();

    int languageVersionMajor = readUInt();
    int languageVersionMinor = readUInt();

    var canonicalName = readCanonicalNameReference();
    Reference reference = canonicalName.getReference();
    Library library = reference.node;
    if (alwaysCreateNewNamedNodes) {
      library = null;
    }
    if (library == null) {
      library =
          new Library(Uri.parse(canonicalName.name), reference: reference);
      component.libraries.add(library..parent = component);
    }
    _currentLibrary = library;
    String name = readStringOrNullIfEmpty();

    // TODO(jensj): We currently save (almost the same) uri twice.
    Uri fileUri = readUriReference();

    List<String> problemsAsJson = readListOfStrings();

    library.flags = flags;
    library.setLanguageVersion(
        new Version(languageVersionMajor, languageVersionMinor));
    library.name = name;
    library.fileUri = fileUri;
    library.problemsAsJson = problemsAsJson;

    assert(() {
      debugPath.add(library.name ?? library.importUri?.toString() ?? 'library');
      return true;
    }());

    _fillTreeNodeList(
        library.annotations, (index) => readExpression(), library);
    _readLibraryDependencies(library);
    _readAdditionalExports(library);
    _readLibraryParts(library);
    _mergeNamedNodeList(library.typedefs, (index) => readTypedef(), library);

    _mergeNamedNodeList(library.classes, (index) {
      _byteOffset = classOffsets[index];
      return readClass(classOffsets[index + 1]);
    }, library);
    _byteOffset = classOffsets.last;

    _mergeNamedNodeList(library.extensions, (index) {
      return readExtension();
    }, library);

    _mergeNamedNodeList(library.fields, (index) => readField(), library);
    _mergeNamedNodeList(library.procedures, (index) {
      _byteOffset = procedureOffsets[index];
      return readProcedure(procedureOffsets[index + 1]);
    }, library);
    _byteOffset = procedureOffsets.last;

    assert(((_) => true)(debugPath.removeLast()));
    _currentLibrary = null;
    return library;
  }

  void _readLibraryDependencies(Library library) {
    int length = readUInt();
    library.dependencies.length = length;
    for (int i = 0; i < length; ++i) {
      library.dependencies[i] = readLibraryDependency(library);
    }
  }

  LibraryDependency readLibraryDependency(Library library) {
    var fileOffset = readOffset();
    var flags = readByte();
    var annotations = readExpressionList();
    var targetLibrary = readLibraryReference(allowNull: true);
    var prefixName = readStringOrNullIfEmpty();
    var names = readCombinatorList();
    return new LibraryDependency.byReference(
        flags, annotations, targetLibrary, prefixName, names)
      ..fileOffset = fileOffset
      ..parent = library;
  }

  void _readAdditionalExports(Library library) {
    int numExportedReference = readUInt();
    if (numExportedReference != 0) {
      library.additionalExports.clear();
      for (int i = 0; i < numExportedReference; i++) {
        CanonicalName exportedName = readCanonicalNameReference();
        Reference reference = exportedName.getReference();
        library.additionalExports.add(reference);
      }
    }
  }

  Combinator readCombinator() {
    var isShow = readByte() == 1;
    var names = readStringReferenceList();
    return new Combinator(isShow, names);
  }

  List<Combinator> readCombinatorList() {
    int length = readUInt();
    List<Combinator> result =
        new List<Combinator>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readCombinator();
    }
    return result;
  }

  void _readLibraryParts(Library library) {
    int length = readUInt();
    library.parts.length = length;
    for (int i = 0; i < length; ++i) {
      library.parts[i] = readLibraryPart(library);
    }
  }

  LibraryPart readLibraryPart(Library library) {
    List<Expression> annotations = readExpressionList();
    String partUri = readStringReference();
    return new LibraryPart(annotations, partUri)..parent = library;
  }

  Typedef readTypedef() {
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Typedef node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Typedef(null, null, reference: reference);
    }
    Uri fileUri = readUriReference();
    int fileOffset = readOffset();
    String name = readStringReference();
    node.annotations = readAnnotationList(node);
    readAndPushTypeParameterList(node.typeParameters, node);
    var type = readDartType();
    readAndPushTypeParameterList(node.typeParametersOfFunctionType, node);
    node.positionalParameters.clear();
    node.positionalParameters.addAll(readAndPushVariableDeclarationList());
    node.namedParameters.clear();
    node.namedParameters.addAll(readAndPushVariableDeclarationList());
    typeParameterStack.length = 0;
    variableStack.length = 0;
    node.fileOffset = fileOffset;
    node.name = name;
    node.fileUri = fileUri;
    node.type = type;
    return node;
  }

  Class readClass(int endOffset) {
    int tag = readByte();
    assert(tag == Tag.Class);

    // Read index.
    int savedByteOffset = _byteOffset;
    // There is a field for the procedure count.
    _byteOffset = endOffset - (1) * 4;
    int procedureCount = readUint32();
    List<int> procedureOffsets = new List<int>(procedureCount + 1);
    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets (i.e. procedure count + 2 fields).
    _byteOffset = endOffset - (procedureCount + 2) * 4;
    for (int i = 0; i < procedureCount + 1; i++) {
      procedureOffsets[i] = _componentStartOffset + readUint32();
    }
    _byteOffset = savedByteOffset;

    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Class node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Class(reference: reference)
        ..level = ClassLevel.Temporary
        ..dirty = false;
    }

    var fileUri = readUriReference();
    node.startFileOffset = readOffset();
    node.fileOffset = readOffset();
    node.fileEndOffset = readOffset();
    int flags = readByte();
    node.flags = flags & ~Class.LevelMask;
    int levelIndex = flags & Class.LevelMask;
    var level = ClassLevel.values[levelIndex + 1];
    if (level.index >= node.level.index) {
      node.level = level;
    }
    var name = readStringOrNullIfEmpty();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name ?? 'normal-class');
      return true;
    }());

    assert(typeParameterStack.length == 0);

    readAndPushTypeParameterList(node.typeParameters, node);
    var supertype = readSupertypeOption();
    var mixedInType = readSupertypeOption();
    _fillNonTreeNodeList(node.implementedTypes, readSupertype);
    if (_disableLazyClassReading) {
      readClassPartialContent(node, procedureOffsets);
    } else {
      _setLazyLoadClass(node, procedureOffsets);
    }

    typeParameterStack.length = 0;
    assert(debugPath.removeLast() != null);
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    node.supertype = supertype;
    node.mixedInType = mixedInType;

    _byteOffset = endOffset;

    return node;
  }

  Extension readExtension() {
    int tag = readByte();
    assert(tag == Tag.Extension);

    CanonicalName canonicalName = readCanonicalNameReference();
    Reference reference = canonicalName.getReference();
    Extension node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Extension(reference: reference);
    }

    String name = readStringOrNullIfEmpty();
    assert(() {
      debugPath.add(node.name ?? 'extension');
      return true;
    }());

    Uri fileUri = readUriReference();
    node.fileOffset = readOffset();

    readAndPushTypeParameterList(node.typeParameters, node);
    DartType onType = readDartType();
    typeParameterStack.length = 0;

    node.name = name;
    node.fileUri = fileUri;
    node.onType = onType;

    int length = readUInt();
    node.members.length = length;
    for (int i = 0; i < length; i++) {
      Name name = readName();
      int kind = readByte();
      int flags = readByte();
      CanonicalName canonicalName = readCanonicalNameReference();
      node.members[i] = new ExtensionMemberDescriptor(
          name: name,
          kind: ExtensionMemberKind.values[kind],
          member: canonicalName.getReference())
        ..flags = flags;
    }
    return node;
  }

  /// Reads the partial content of a class, namely fields, procedures,
  /// constructors and redirecting factory constructors.
  void readClassPartialContent(Class node, List<int> procedureOffsets) {
    _mergeNamedNodeList(node.fieldsInternal, (index) => readField(), node);
    _mergeNamedNodeList(
        node.constructorsInternal, (index) => readConstructor(), node);

    _mergeNamedNodeList(node.proceduresInternal, (index) {
      _byteOffset = procedureOffsets[index];
      return readProcedure(procedureOffsets[index + 1]);
    }, node);
    _byteOffset = procedureOffsets.last;
    _mergeNamedNodeList(node.redirectingFactoryConstructorsInternal,
        (index) => readRedirectingFactoryConstructor(), node);
  }

  /// Set the lazyBuilder on the class so it can be lazy loaded in the future.
  void _setLazyLoadClass(Class node, List<int> procedureOffsets) {
    final int savedByteOffset = _byteOffset;
    final int componentStartOffset = _componentStartOffset;
    final Library currentLibrary = _currentLibrary;
    node.lazyBuilder = () {
      _byteOffset = savedByteOffset;
      _currentLibrary = currentLibrary;
      assert(typeParameterStack.isEmpty);
      _componentStartOffset = componentStartOffset;
      typeParameterStack.addAll(node.typeParameters);

      readClassPartialContent(node, procedureOffsets);
      typeParameterStack.length = 0;
    };
  }

  int getAndResetTransformerFlags() {
    int flags = _transformerFlags;
    _transformerFlags = 0;
    return flags;
  }

  /// Adds the given flag to the current [Member.transformerFlags].
  void addTransformerFlag(int flags) {
    _transformerFlags |= flags;
  }

  Field readField() {
    int tag = readByte();
    assert(tag == Tag.Field);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Field node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Field(null, reference: reference);
    }
    var fileUri = readUriReference();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readUInt();
    var name = readName();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name?.name ?? 'field');
      return true;
    }());
    var type = readDartType();
    var initializer = readExpressionOption();
    int transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    node.type = type;
    node.initializer = initializer;
    node.initializer?.parent = node;
    node.transformerFlags = transformerFlags;
    return node;
  }

  Constructor readConstructor() {
    int tag = readByte();
    assert(tag == Tag.Constructor);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Constructor node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Constructor(null, reference: reference);
    }
    var fileUri = readUriReference();
    var startFileOffset = readOffset();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    var flags = readByte();
    var name = readName();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name?.name ?? 'constructor');
      return true;
    }());
    var function = readFunctionNode();
    pushVariableDeclarations(function.positionalParameters);
    pushVariableDeclarations(function.namedParameters);
    _fillTreeNodeList(node.initializers, (index) => readInitializer(), node);
    variableStack.length = 0;
    var transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    node.startFileOffset = startFileOffset;
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    node.function = function..parent = node;
    node.transformerFlags = transformerFlags;
    return node;
  }

  Procedure readProcedure(int endOffset) {
    int tag = readByte();
    assert(tag == Tag.Procedure);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Procedure node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new Procedure(null, null, null, reference: reference);
    }
    var fileUri = readUriReference();
    var startFileOffset = readOffset();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    int kindIndex = readByte();
    var kind = ProcedureKind.values[kindIndex];
    var flags = readUInt();
    var name = readName();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name?.name ?? 'procedure');
      return true;
    }());
    int functionNodeSize = endOffset - _byteOffset;
    // Read small factories up front. Postpone everything else.
    bool readFunctionNodeNow =
        (kind == ProcedureKind.Factory && functionNodeSize <= 50) ||
            _disableLazyReading;
    var forwardingStubSuperTargetReference =
        readMemberReference(allowNull: true);
    var forwardingStubInterfaceTargetReference =
        readMemberReference(allowNull: true);
    var function = readFunctionNodeOption(!readFunctionNodeNow, endOffset);
    var transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    node.startFileOffset = startFileOffset;
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.kind = kind;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    node.function = function;
    function?.parent = node;
    node.setTransformerFlagsWithoutLazyLoading(transformerFlags);
    node.forwardingStubSuperTargetReference =
        forwardingStubSuperTargetReference;
    node.forwardingStubInterfaceTargetReference =
        forwardingStubInterfaceTargetReference;

    assert((node.forwardingStubSuperTargetReference != null) ||
        !(node.isForwardingStub && node.function.body != null));
    _byteOffset = endOffset;
    return node;
  }

  RedirectingFactoryConstructor readRedirectingFactoryConstructor() {
    int tag = readByte();
    assert(tag == Tag.RedirectingFactoryConstructor);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    RedirectingFactoryConstructor node = reference.node;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    if (node == null) {
      node = new RedirectingFactoryConstructor(null, reference: reference);
    }
    var fileUri = readUriReference();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    var flags = readByte();
    var name = readName();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name?.name ?? 'redirecting-factory-constructor');
      return true;
    }());
    var targetReference = readMemberReference();
    var typeArguments = readDartTypeList();
    int typeParameterStackHeight = typeParameterStack.length;
    var typeParameters = readAndPushTypeParameterList();
    readUInt(); // Total parameter count.
    var requiredParameterCount = readUInt();
    int variableStackHeight = variableStack.length;
    var positional = readAndPushVariableDeclarationList();
    var named = readAndPushVariableDeclarationList();
    variableStack.length = variableStackHeight;
    typeParameterStack.length = typeParameterStackHeight;
    debugPath.removeLast();
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    node.targetReference = targetReference;
    node.typeArguments.addAll(typeArguments);
    node.typeParameters = typeParameters;
    node.requiredParameterCount = requiredParameterCount;
    node.positionalParameters = positional;
    node.namedParameters = named;
    return node;
  }

  Initializer readInitializer() {
    int tag = readByte();
    bool isSynthetic = readByte() == 1;
    switch (tag) {
      case Tag.InvalidInitializer:
        return new InvalidInitializer();
      case Tag.FieldInitializer:
        var reference = readMemberReference();
        var value = readExpression();
        return new FieldInitializer.byReference(reference, value)
          ..isSynthetic = isSynthetic;
      case Tag.SuperInitializer:
        int offset = readOffset();
        var reference = readMemberReference();
        var arguments = readArguments();
        return new SuperInitializer.byReference(reference, arguments)
          ..isSynthetic = isSynthetic
          ..fileOffset = offset;
      case Tag.RedirectingInitializer:
        int offset = readOffset();
        return new RedirectingInitializer.byReference(
            readMemberReference(), readArguments())
          ..fileOffset = offset;
      case Tag.LocalInitializer:
        return new LocalInitializer(readAndPushVariableDeclaration());
      case Tag.AssertInitializer:
        return new AssertInitializer(readStatement());
      default:
        throw fail('unexpected initializer tag: $tag');
    }
  }

  FunctionNode readFunctionNodeOption(bool lazyLoadBody, int outerEndOffset) {
    return readAndCheckOptionTag()
        ? readFunctionNode(
            lazyLoadBody: lazyLoadBody, outerEndOffset: outerEndOffset)
        : null;
  }

  FunctionNode readFunctionNode(
      {bool lazyLoadBody: false, int outerEndOffset: -1}) {
    int tag = readByte();
    assert(tag == Tag.FunctionNode);
    int offset = readOffset();
    int endOffset = readOffset();
    AsyncMarker asyncMarker = AsyncMarker.values[readByte()];
    AsyncMarker dartAsyncMarker = AsyncMarker.values[readByte()];
    int typeParameterStackHeight = typeParameterStack.length;
    var typeParameters = readAndPushTypeParameterList();
    readUInt(); // total parameter count.
    var requiredParameterCount = readUInt();
    int variableStackHeight = variableStack.length;
    var positional = readAndPushVariableDeclarationList();
    var named = readAndPushVariableDeclarationList();
    var returnType = readDartType();
    int oldLabelStackBase = labelStackBase;
    int oldSwitchCaseStackBase = switchCaseStackBase;

    if (lazyLoadBody && outerEndOffset > 0) {
      lazyLoadBody = outerEndOffset - _byteOffset >
          2; // e.g. outline has Tag.Something and Tag.EmptyStatement
    }

    var body;
    if (!lazyLoadBody) {
      labelStackBase = labelStack.length;
      switchCaseStackBase = switchCaseStack.length;
      body = readStatementOption();
    }

    FunctionNode result = new FunctionNode(body,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount,
        positionalParameters: positional,
        namedParameters: named,
        returnType: returnType,
        asyncMarker: asyncMarker,
        dartAsyncMarker: dartAsyncMarker)
      ..fileOffset = offset
      ..fileEndOffset = endOffset;

    if (lazyLoadBody) {
      _setLazyLoadFunction(result, oldLabelStackBase, oldSwitchCaseStackBase,
          variableStackHeight);
    }

    labelStackBase = oldLabelStackBase;
    switchCaseStackBase = oldSwitchCaseStackBase;
    variableStack.length = variableStackHeight;
    typeParameterStack.length = typeParameterStackHeight;

    return result;
  }

  void _setLazyLoadFunction(FunctionNode result, int oldLabelStackBase,
      int oldSwitchCaseStackBase, int variableStackHeight) {
    final int savedByteOffset = _byteOffset;
    final int componentStartOffset = _componentStartOffset;
    final List<TypeParameter> typeParameters = typeParameterStack.toList();
    final List<VariableDeclaration> variables = variableStack.toList();
    final Library currentLibrary = _currentLibrary;
    result.lazyBuilder = () {
      _byteOffset = savedByteOffset;
      _currentLibrary = currentLibrary;
      typeParameterStack.clear();
      typeParameterStack.addAll(typeParameters);
      variableStack.clear();
      variableStack.addAll(variables);
      _componentStartOffset = componentStartOffset;

      result.body = readStatementOption();
      result.body?.parent = result;
      labelStackBase = oldLabelStackBase;
      switchCaseStackBase = oldSwitchCaseStackBase;
      variableStack.length = variableStackHeight;
      typeParameterStack.clear();
      if (result.parent is Procedure) {
        Procedure parent = result.parent;
        parent.transformerFlags |= getAndResetTransformerFlags();
      }
    };
  }

  void pushVariableDeclaration(VariableDeclaration variable) {
    variableStack.add(variable);
  }

  void pushVariableDeclarations(List<VariableDeclaration> variables) {
    variableStack.addAll(variables);
  }

  VariableDeclaration readVariableReference() {
    int index = readUInt();
    if (index >= variableStack.length) {
      throw fail('unexpected variable index: $index');
    }
    return variableStack[index];
  }

  String logicalOperatorToString(int index) {
    switch (index) {
      case 0:
        return '&&';
      case 1:
        return '||';
      default:
        throw fail('unexpected logical operator index: $index');
    }
  }

  List<Expression> readExpressionList() {
    int length = readUInt();
    List<Expression> result =
        new List<Expression>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readExpression();
    }
    return result;
  }

  Expression readExpressionOption() {
    return readAndCheckOptionTag() ? readExpression() : null;
  }

  Expression readExpression() {
    int tagByte = readByte();
    int tag = tagByte & Tag.SpecializedTagHighBit == 0
        ? tagByte
        : (tagByte & Tag.SpecializedTagMask);
    switch (tag) {
      case Tag.LoadLibrary:
        return new LoadLibrary(readLibraryDependencyReference());
      case Tag.CheckLibraryIsLoaded:
        return new CheckLibraryIsLoaded(readLibraryDependencyReference());
      case Tag.InvalidExpression:
        int offset = readOffset();
        return new InvalidExpression(readStringOrNullIfEmpty())
          ..fileOffset = offset;
      case Tag.VariableGet:
        int offset = readOffset();
        readUInt(); // offset of the variable declaration in the binary.
        return new VariableGet(readVariableReference(), readDartTypeOption())
          ..fileOffset = offset;
      case Tag.SpecializedVariableGet:
        int index = tagByte & Tag.SpecializedPayloadMask;
        int offset = readOffset();
        readUInt(); // offset of the variable declaration in the binary.
        return new VariableGet(variableStack[index])..fileOffset = offset;
      case Tag.VariableSet:
        int offset = readOffset();
        readUInt(); // offset of the variable declaration in the binary.
        return new VariableSet(readVariableReference(), readExpression())
          ..fileOffset = offset;
      case Tag.SpecializedVariableSet:
        int index = tagByte & Tag.SpecializedPayloadMask;
        int offset = readOffset();
        readUInt(); // offset of the variable declaration in the binary.
        return new VariableSet(variableStack[index], readExpression())
          ..fileOffset = offset;
      case Tag.PropertyGet:
        int offset = readOffset();
        return new PropertyGet.byReference(
            readExpression(), readName(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.PropertySet:
        int offset = readOffset();
        return new PropertySet.byReference(readExpression(), readName(),
            readExpression(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.SuperPropertyGet:
        int offset = readOffset();
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperPropertyGet.byReference(
            readName(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.SuperPropertySet:
        int offset = readOffset();
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperPropertySet.byReference(
            readName(), readExpression(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.DirectPropertyGet:
        int offset = readOffset();
        return new DirectPropertyGet.byReference(
            readExpression(), readMemberReference())
          ..fileOffset = offset;
      case Tag.DirectPropertySet:
        int offset = readOffset();
        return new DirectPropertySet.byReference(
            readExpression(), readMemberReference(), readExpression())
          ..fileOffset = offset;
      case Tag.StaticGet:
        int offset = readOffset();
        return new StaticGet.byReference(readMemberReference())
          ..fileOffset = offset;
      case Tag.StaticSet:
        int offset = readOffset();
        return new StaticSet.byReference(
            readMemberReference(), readExpression())
          ..fileOffset = offset;
      case Tag.MethodInvocation:
        int offset = readOffset();
        return new MethodInvocation.byReference(readExpression(), readName(),
            readArguments(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.SuperMethodInvocation:
        int offset = readOffset();
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperMethodInvocation.byReference(
            readName(), readArguments(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.DirectMethodInvocation:
        int offset = readOffset();
        return new DirectMethodInvocation.byReference(
            readExpression(), readMemberReference(), readArguments())
          ..fileOffset = offset;
      case Tag.StaticInvocation:
        int offset = readOffset();
        return new StaticInvocation.byReference(
            readMemberReference(), readArguments(),
            isConst: false)
          ..fileOffset = offset;
      case Tag.ConstStaticInvocation:
        int offset = readOffset();
        return new StaticInvocation.byReference(
            readMemberReference(), readArguments(),
            isConst: true)
          ..fileOffset = offset;
      case Tag.ConstructorInvocation:
        int offset = readOffset();
        return new ConstructorInvocation.byReference(
            readMemberReference(), readArguments(),
            isConst: false)
          ..fileOffset = offset;
      case Tag.ConstConstructorInvocation:
        int offset = readOffset();
        return new ConstructorInvocation.byReference(
            readMemberReference(), readArguments(),
            isConst: true)
          ..fileOffset = offset;
      case Tag.Not:
        return new Not(readExpression());
      case Tag.NullCheck:
        int offset = readOffset();
        return new NullCheck(readExpression())..fileOffset = offset;
      case Tag.LogicalExpression:
        return new LogicalExpression(readExpression(),
            logicalOperatorToString(readByte()), readExpression());
      case Tag.ConditionalExpression:
        return new ConditionalExpression(readExpression(), readExpression(),
            readExpression(), readDartTypeOption());
      case Tag.StringConcatenation:
        int offset = readOffset();
        return new StringConcatenation(readExpressionList())
          ..fileOffset = offset;
      case Tag.ListConcatenation:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new ListConcatenation(readExpressionList(),
            typeArgument: typeArgument)
          ..fileOffset = offset;
      case Tag.SetConcatenation:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new SetConcatenation(readExpressionList(),
            typeArgument: typeArgument)
          ..fileOffset = offset;
      case Tag.MapConcatenation:
        int offset = readOffset();
        var keyType = readDartType();
        var valueType = readDartType();
        return new MapConcatenation(readExpressionList(),
            keyType: keyType, valueType: valueType)
          ..fileOffset = offset;
      case Tag.InstanceCreation:
        int offset = readOffset();
        Reference classReference = readClassReference();
        List<DartType> typeArguments = readDartTypeList();
        int fieldValueCount = readUInt();
        Map<Reference, Expression> fieldValues = <Reference, Expression>{};
        for (int i = 0; i < fieldValueCount; i++) {
          final Reference fieldRef =
              readCanonicalNameReference().getReference();
          final Expression value = readExpression();
          fieldValues[fieldRef] = value;
        }
        int assertCount = readUInt();
        List<AssertStatement> asserts = new List<AssertStatement>(assertCount);
        for (int i = 0; i < assertCount; i++) {
          asserts[i] = readStatement();
        }
        List<Expression> unusedArguments = readExpressionList();
        return new InstanceCreation(classReference, typeArguments, fieldValues,
            asserts, unusedArguments)
          ..fileOffset = offset;
      case Tag.FileUriExpression:
        Uri fileUri = readUriReference();
        int offset = readOffset();
        return new FileUriExpression(readExpression(), fileUri)
          ..fileOffset = offset;
      case Tag.IsExpression:
        int offset = readOffset();
        int flags = readByte();
        return new IsExpression(readExpression(), readDartType())
          ..fileOffset = offset
          ..flags = flags;
      case Tag.AsExpression:
        int offset = readOffset();
        int flags = readByte();
        return new AsExpression(readExpression(), readDartType())
          ..fileOffset = offset
          ..flags = flags;
      case Tag.StringLiteral:
        return new StringLiteral(readStringReference());
      case Tag.SpecializedIntLiteral:
        int biasedValue = tagByte & Tag.SpecializedPayloadMask;
        return new IntLiteral(biasedValue - Tag.SpecializedIntLiteralBias);
      case Tag.PositiveIntLiteral:
        return new IntLiteral(readUInt());
      case Tag.NegativeIntLiteral:
        return new IntLiteral(-readUInt());
      case Tag.BigIntLiteral:
        return new IntLiteral(int.parse(readStringReference()));
      case Tag.DoubleLiteral:
        return new DoubleLiteral(readDouble());
      case Tag.TrueLiteral:
        return new BoolLiteral(true);
      case Tag.FalseLiteral:
        return new BoolLiteral(false);
      case Tag.NullLiteral:
        return new NullLiteral();
      case Tag.SymbolLiteral:
        return new SymbolLiteral(readStringReference());
      case Tag.TypeLiteral:
        return new TypeLiteral(readDartType());
      case Tag.ThisExpression:
        return new ThisExpression();
      case Tag.Rethrow:
        int offset = readOffset();
        return new Rethrow()..fileOffset = offset;
      case Tag.Throw:
        int offset = readOffset();
        return new Throw(readExpression())..fileOffset = offset;
      case Tag.ListLiteral:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new ListLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: false)
          ..fileOffset = offset;
      case Tag.ConstListLiteral:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new ListLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: true)
          ..fileOffset = offset;
      case Tag.SetLiteral:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new SetLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: false)
          ..fileOffset = offset;
      case Tag.ConstSetLiteral:
        int offset = readOffset();
        var typeArgument = readDartType();
        return new SetLiteral(readExpressionList(),
            typeArgument: typeArgument, isConst: true)
          ..fileOffset = offset;
      case Tag.MapLiteral:
        int offset = readOffset();
        var keyType = readDartType();
        var valueType = readDartType();
        return new MapLiteral(readMapEntryList(),
            keyType: keyType, valueType: valueType, isConst: false)
          ..fileOffset = offset;
      case Tag.ConstMapLiteral:
        int offset = readOffset();
        var keyType = readDartType();
        var valueType = readDartType();
        return new MapLiteral(readMapEntryList(),
            keyType: keyType, valueType: valueType, isConst: true)
          ..fileOffset = offset;
      case Tag.AwaitExpression:
        return new AwaitExpression(readExpression());
      case Tag.FunctionExpression:
        int offset = readOffset();
        return new FunctionExpression(readFunctionNode())..fileOffset = offset;
      case Tag.Let:
        var variable = readVariableDeclaration();
        int stackHeight = variableStack.length;
        pushVariableDeclaration(variable);
        var body = readExpression();
        variableStack.length = stackHeight;
        return new Let(variable, body);
      case Tag.BlockExpression:
        int stackHeight = variableStack.length;
        var statements = readStatementList();
        var value = readExpression();
        variableStack.length = stackHeight;
        return new BlockExpression(new Block(statements), value);
      case Tag.Instantiation:
        var expression = readExpression();
        var typeArguments = readDartTypeList();
        return new Instantiation(expression, typeArguments);
      case Tag.ConstantExpression:
        int offset = readOffset();
        DartType type = readDartType();
        Constant constant = readConstantReference();
        return new ConstantExpression(constant, type)..fileOffset = offset;
      default:
        throw fail('unexpected expression tag: $tag');
    }
  }

  List<MapEntry> readMapEntryList() {
    int length = readUInt();
    List<MapEntry> result =
        new List<MapEntry>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readMapEntry();
    }
    return result;
  }

  MapEntry readMapEntry() {
    return new MapEntry(readExpression(), readExpression());
  }

  List<Statement> readStatementList() {
    int length = readUInt();
    List<Statement> result =
        new List<Statement>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readStatement();
    }
    return result;
  }

  Statement readStatementOrNullIfEmpty() {
    var node = readStatement();
    if (node is EmptyStatement) {
      return null;
    } else {
      return node;
    }
  }

  Statement readStatementOption() {
    return readAndCheckOptionTag() ? readStatement() : null;
  }

  Statement readStatement() {
    int tag = readByte();
    switch (tag) {
      case Tag.ExpressionStatement:
        return new ExpressionStatement(readExpression());
      case Tag.Block:
        return readBlock();
      case Tag.AssertBlock:
        return readAssertBlock();
      case Tag.EmptyStatement:
        return new EmptyStatement();
      case Tag.AssertStatement:
        return new AssertStatement(readExpression(),
            conditionStartOffset: readOffset(),
            conditionEndOffset: readOffset(),
            message: readExpressionOption());
      case Tag.LabeledStatement:
        var label = new LabeledStatement(null);
        labelStack.add(label);
        label.body = readStatement()..parent = label;
        labelStack.removeLast();
        return label;
      case Tag.BreakStatement:
        int offset = readOffset();
        int index = readUInt();
        return new BreakStatement(labelStack[labelStackBase + index])
          ..fileOffset = offset;
      case Tag.WhileStatement:
        var offset = readOffset();
        return new WhileStatement(readExpression(), readStatement())
          ..fileOffset = offset;
      case Tag.DoStatement:
        var offset = readOffset();
        return new DoStatement(readStatement(), readExpression())
          ..fileOffset = offset;
      case Tag.ForStatement:
        int variableStackHeight = variableStack.length;
        var offset = readOffset();
        var variables = readAndPushVariableDeclarationList();
        var condition = readExpressionOption();
        var updates = readExpressionList();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForStatement(variables, condition, updates, body)
          ..fileOffset = offset;
      case Tag.ForInStatement:
      case Tag.AsyncForInStatement:
        bool isAsync = tag == Tag.AsyncForInStatement;
        int variableStackHeight = variableStack.length;
        var offset = readOffset();
        var bodyOffset = readOffset();
        var variable = readAndPushVariableDeclaration();
        var iterable = readExpression();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForInStatement(variable, iterable, body, isAsync: isAsync)
          ..fileOffset = offset
          ..bodyOffset = bodyOffset;
      case Tag.SwitchStatement:
        var offset = readOffset();
        var expression = readExpression();
        int count = readUInt();
        List<SwitchCase> cases =
            new List<SwitchCase>.filled(count, null, growable: true);
        for (int i = 0; i < count; ++i) {
          cases[i] = new SwitchCase.empty();
        }
        switchCaseStack.addAll(cases);
        for (int i = 0; i < cases.length; ++i) {
          readSwitchCaseInto(cases[i]);
        }
        switchCaseStack.length -= count;
        return new SwitchStatement(expression, cases)..fileOffset = offset;
      case Tag.ContinueSwitchStatement:
        int offset = readOffset();
        int index = readUInt();
        return new ContinueSwitchStatement(
            switchCaseStack[switchCaseStackBase + index])
          ..fileOffset = offset;
      case Tag.IfStatement:
        int offset = readOffset();
        return new IfStatement(
            readExpression(), readStatement(), readStatementOrNullIfEmpty())
          ..fileOffset = offset;
      case Tag.ReturnStatement:
        int offset = readOffset();
        return new ReturnStatement(readExpressionOption())..fileOffset = offset;
      case Tag.TryCatch:
        Statement body = readStatement();
        int flags = readByte();
        return new TryCatch(body, readCatchList(), isSynthetic: flags & 2 == 2);
      case Tag.TryFinally:
        return new TryFinally(readStatement(), readStatement());
      case Tag.YieldStatement:
        int offset = readOffset();
        int flags = readByte();
        return new YieldStatement(readExpression(),
            isYieldStar: flags & YieldStatement.FlagYieldStar != 0,
            isNative: flags & YieldStatement.FlagNative != 0)
          ..fileOffset = offset;
      case Tag.VariableDeclaration:
        var variable = readVariableDeclaration();
        variableStack.add(variable); // Will be popped by the enclosing scope.
        return variable;
      case Tag.FunctionDeclaration:
        int offset = readOffset();
        var variable = readVariableDeclaration();
        variableStack.add(variable); // Will be popped by the enclosing scope.
        var function = readFunctionNode();
        return new FunctionDeclaration(variable, function)..fileOffset = offset;
      default:
        throw fail('unexpected statement tag: $tag');
    }
  }

  void readSwitchCaseInto(SwitchCase caseNode) {
    int length = readUInt();
    caseNode.expressions.length = length;
    caseNode.expressionOffsets.length = length;
    for (int i = 0; i < length; ++i) {
      caseNode.expressionOffsets[i] = readOffset();
      caseNode.expressions[i] = readExpression()..parent = caseNode;
    }
    caseNode.isDefault = readByte() == 1;
    caseNode.body = readStatement()..parent = caseNode;
  }

  List<Catch> readCatchList() {
    int length = readUInt();
    List<Catch> result = new List<Catch>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readCatch();
    }
    return result;
  }

  Catch readCatch() {
    int variableStackHeight = variableStack.length;
    var offset = readOffset();
    var guard = readDartType();
    var exception = readAndPushVariableDeclarationOption();
    var stackTrace = readAndPushVariableDeclarationOption();
    var body = readStatement();
    variableStack.length = variableStackHeight;
    return new Catch(exception, body, guard: guard, stackTrace: stackTrace)
      ..fileOffset = offset;
  }

  Block readBlock() {
    int stackHeight = variableStack.length;
    var body = readStatementList();
    variableStack.length = stackHeight;
    return new Block(body);
  }

  AssertBlock readAssertBlock() {
    int stackHeight = variableStack.length;
    var body = readStatementList();
    variableStack.length = stackHeight;
    return new AssertBlock(body);
  }

  Supertype readSupertype() {
    InterfaceType type = readDartType();
    assert(
        type.nullability == _currentLibrary.nonNullable,
        "In serialized form supertypes should have Nullability.legacy if they "
        "are in a library that is opted out of the NNBD feature.  If they are "
        "in an opted-in library, they should have Nullability.nonNullable.");
    return new Supertype.byReference(type.className, type.typeArguments);
  }

  Supertype readSupertypeOption() {
    return readAndCheckOptionTag() ? readSupertype() : null;
  }

  List<Supertype> readSupertypeList() {
    int length = readUInt();
    List<Supertype> result =
        new List<Supertype>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readSupertype();
    }
    return result;
  }

  List<DartType> readDartTypeList() {
    int length = readUInt();
    List<DartType> result =
        new List<DartType>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readDartType();
    }
    return result;
  }

  List<NamedType> readNamedTypeList() {
    int length = readUInt();
    List<NamedType> result =
        new List<NamedType>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readNamedType();
    }
    return result;
  }

  NamedType readNamedType() {
    String name = readStringReference();
    DartType type = readDartType();
    int flags = readByte();
    return new NamedType(name, type,
        isRequired: (flags & NamedType.FlagRequiredNamedType) != 0);
  }

  DartType readDartTypeOption() {
    return readAndCheckOptionTag() ? readDartType() : null;
  }

  DartType readDartType() {
    int tag = readByte();
    switch (tag) {
      case Tag.TypedefType:
        int nullabilityIndex = readByte();
        return new TypedefType.byReference(readTypedefReference(),
            Nullability.values[nullabilityIndex], readDartTypeList());
      case Tag.BottomType:
        return const BottomType();
      case Tag.InvalidType:
        return const InvalidType();
      case Tag.DynamicType:
        return const DynamicType();
      case Tag.VoidType:
        return const VoidType();
      case Tag.NeverType:
        int nullabilityIndex = readByte();
        return new NeverType(Nullability.values[nullabilityIndex]);
      case Tag.InterfaceType:
        int nullabilityIndex = readByte();
        Reference reference = readClassReference();
        List<DartType> typeArguments = readDartTypeList();
        {
          CanonicalName canonicalName = reference.canonicalName;
          if (canonicalName.name == "FutureOr" &&
              canonicalName.parent != null &&
              canonicalName.parent.name == "dart:async" &&
              canonicalName.parent.parent != null &&
              canonicalName.parent.parent.isRoot) {
            return new FutureOrType(
                typeArguments.single, Nullability.values[nullabilityIndex]);
          }
        }
        return new InterfaceType.byReference(
            reference, Nullability.values[nullabilityIndex], typeArguments);
      case Tag.SimpleInterfaceType:
        int nullabilityIndex = readByte();
        return new InterfaceType.byReference(readClassReference(),
            Nullability.values[nullabilityIndex], const <DartType>[]);
      case Tag.FunctionType:
        int typeParameterStackHeight = typeParameterStack.length;
        int nullabilityIndex = readByte();
        var typeParameters = readAndPushTypeParameterList();
        var requiredParameterCount = readUInt();
        var totalParameterCount = readUInt();
        var positional = readDartTypeList();
        var named = readNamedTypeList();
        var typedefType = readDartTypeOption();
        assert(positional.length + named.length == totalParameterCount);
        var returnType = readDartType();
        typeParameterStack.length = typeParameterStackHeight;
        return new FunctionType(
            positional, returnType, Nullability.values[nullabilityIndex],
            typeParameters: typeParameters,
            requiredParameterCount: requiredParameterCount,
            namedParameters: named,
            typedefType: typedefType);
      case Tag.SimpleFunctionType:
        int nullabilityIndex = readByte();
        var positional = readDartTypeList();
        var returnType = readDartType();
        return new FunctionType(
            positional, returnType, Nullability.values[nullabilityIndex]);
      case Tag.TypeParameterType:
        int declaredNullabilityIndex = readByte();
        int index = readUInt();
        var bound = readDartTypeOption();
        return new TypeParameterType(typeParameterStack[index],
            Nullability.values[declaredNullabilityIndex], bound);
      default:
        throw fail('unexpected dart type tag: $tag');
    }
  }

  List<TypeParameter> readAndPushTypeParameterList(
      [List<TypeParameter> list, TreeNode parent]) {
    int length = readUInt();
    if (length == 0) return list ?? <TypeParameter>[];
    if (list == null) {
      list = new List<TypeParameter>.filled(length, null, growable: true);
      for (int i = 0; i < length; ++i) {
        list[i] = new TypeParameter(null, null)..parent = parent;
      }
    } else if (list.length != length) {
      list.length = length;
      for (int i = 0; i < length; ++i) {
        list[i] = new TypeParameter(null, null)..parent = parent;
      }
    }
    typeParameterStack.addAll(list);
    for (int i = 0; i < list.length; ++i) {
      readTypeParameter(list[i]);
    }
    return list;
  }

  void readTypeParameter(TypeParameter node) {
    node.flags = readByte();
    node.annotations = readAnnotationList(node);
    int variance = readByte();
    if (variance == TypeParameter.legacyCovariantSerializationMarker) {
      node.variance = null;
    } else {
      node.variance = variance;
    }
    node.name = readStringOrNullIfEmpty();
    node.bound = readDartType();
    node.defaultType = readDartTypeOption();
  }

  Arguments readArguments() {
    var numArguments = readUInt();
    var typeArguments = readDartTypeList();
    var positional = readExpressionList();
    var named = readNamedExpressionList();
    assert(numArguments == positional.length + named.length);
    return new Arguments(positional, types: typeArguments, named: named);
  }

  List<NamedExpression> readNamedExpressionList() {
    int length = readUInt();
    List<NamedExpression> result =
        new List<NamedExpression>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readNamedExpression();
    }
    return result;
  }

  NamedExpression readNamedExpression() {
    return new NamedExpression(readStringReference(), readExpression());
  }

  List<VariableDeclaration> readAndPushVariableDeclarationList() {
    int length = readUInt();
    List<VariableDeclaration> result =
        new List<VariableDeclaration>.filled(length, null, growable: true);
    for (int i = 0; i < length; ++i) {
      result[i] = readAndPushVariableDeclaration();
    }
    return result;
  }

  VariableDeclaration readAndPushVariableDeclarationOption() {
    return readAndCheckOptionTag() ? readAndPushVariableDeclaration() : null;
  }

  VariableDeclaration readAndPushVariableDeclaration() {
    var variable = readVariableDeclaration();
    variableStack.add(variable);
    return variable;
  }

  VariableDeclaration readVariableDeclaration() {
    int offset = readOffset();
    int fileEqualsOffset = readOffset();
    // The [VariableDeclaration] instance is not created at this point yet,
    // so `null` is temporarily set as the parent of the annotation nodes.
    var annotations = readAnnotationList(null);
    int flags = readByte();
    var node = new VariableDeclaration(readStringOrNullIfEmpty(),
        type: readDartType(), initializer: readExpressionOption(), flags: flags)
      ..fileOffset = offset
      ..fileEqualsOffset = fileEqualsOffset;
    if (annotations.isNotEmpty) {
      for (int i = 0; i < annotations.length; ++i) {
        var annotation = annotations[i];
        annotation.parent = node;
      }
      node.annotations = annotations;
    }
    return node;
  }

  int readOffset() {
    // Offset is saved as unsigned,
    // but actually ranges from -1 and up (thus the -1)
    return readUInt() - 1;
  }
}

class BinaryBuilderWithMetadata extends BinaryBuilder implements BinarySource {
  /// List of metadata subsections that have corresponding [MetadataRepository]
  /// and are awaiting to be parsed and attached to nodes.
  List<_MetadataSubsection> _subsections;

  BinaryBuilderWithMetadata(List<int> bytes,
      {String filename,
      bool disableLazyReading = false,
      bool disableLazyClassReading = false,
      bool alwaysCreateNewNamedNodes})
      : super(bytes,
            filename: filename,
            disableLazyReading: disableLazyReading,
            disableLazyClassReading: disableLazyClassReading,
            alwaysCreateNewNamedNodes: alwaysCreateNewNamedNodes);

  @override
  void _readMetadataMappings(
      Component component, int binaryOffsetForMetadataPayloads) {
    // At the beginning of this function _byteOffset points right past
    // metadataMappings to string table.

    // Read the length of metadataMappings.
    _byteOffset -= 4;
    final subSectionCount = readUint32();

    int endOffset = _byteOffset - 4; // End offset of the current subsection.
    for (var i = 0; i < subSectionCount; i++) {
      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      _byteOffset = endOffset - 4;
      final mappingLength = readUint32();
      final mappingStart = (endOffset - 4) - 4 * 2 * mappingLength;
      _byteOffset = mappingStart - 4;

      // UInt32 tag (fixed size StringReference)
      final tag = _stringTable[readUint32()];

      final repository = component.metadata[tag];
      if (repository != null) {
        // Read nodeOffsetToMetadataOffset mapping.
        final mapping = <int, int>{};
        _byteOffset = mappingStart;
        for (var j = 0; j < mappingLength; j++) {
          final nodeOffset = readUint32();
          final metadataOffset = binaryOffsetForMetadataPayloads + readUint32();
          mapping[nodeOffset] = metadataOffset;
        }

        _subsections ??= <_MetadataSubsection>[];
        _subsections.add(new _MetadataSubsection(repository, mapping));
      }

      // Start of the subsection and the end of the previous one.
      endOffset = mappingStart - 4;
    }
  }

  Object _readMetadata(Node node, MetadataRepository repository, int offset) {
    final int savedOffset = _byteOffset;
    _byteOffset = offset;

    final metadata = repository.readFromBinary(node, this);

    _byteOffset = savedOffset;
    return metadata;
  }

  @override
  void enterScope({List<TypeParameter> typeParameters}) {
    if (typeParameters != null) {
      typeParameterStack.addAll(typeParameters);
    }
  }

  @override
  void leaveScope({List<TypeParameter> typeParameters}) {
    if (typeParameters != null) {
      typeParameterStack.length -= typeParameters.length;
    }
  }

  @override
  Node _associateMetadata(Node node, int nodeOffset) {
    if (_subsections == null) {
      return node;
    }

    for (var subsection in _subsections) {
      // First check if there is any metadata associated with this node.
      final metadataOffset = subsection.mapping[nodeOffset];
      if (metadataOffset != null) {
        subsection.repository.mapping[node] =
            _readMetadata(node, subsection.repository, metadataOffset);
      }
    }

    return node;
  }

  @override
  DartType readDartType() {
    final nodeOffset = _byteOffset;
    final result = super.readDartType();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Library readLibrary(Component component, int endOffset) {
    final nodeOffset = _byteOffset;
    final result = super.readLibrary(component, endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Typedef readTypedef() {
    final nodeOffset = _byteOffset;
    final result = super.readTypedef();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Class readClass(int endOffset) {
    final nodeOffset = _byteOffset;
    final result = super.readClass(endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Extension readExtension() {
    final nodeOffset = _byteOffset;
    final result = super.readExtension();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Field readField() {
    final nodeOffset = _byteOffset;
    final result = super.readField();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Constructor readConstructor() {
    final nodeOffset = _byteOffset;
    final result = super.readConstructor();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Procedure readProcedure(int endOffset) {
    final nodeOffset = _byteOffset;
    final result = super.readProcedure(endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  RedirectingFactoryConstructor readRedirectingFactoryConstructor() {
    final nodeOffset = _byteOffset;
    final result = super.readRedirectingFactoryConstructor();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Initializer readInitializer() {
    final nodeOffset = _byteOffset;
    final result = super.readInitializer();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  FunctionNode readFunctionNode(
      {bool lazyLoadBody: false, int outerEndOffset: -1}) {
    final nodeOffset = _byteOffset;
    final result = super.readFunctionNode(
        lazyLoadBody: lazyLoadBody, outerEndOffset: outerEndOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Expression readExpression() {
    final nodeOffset = _byteOffset;
    final result = super.readExpression();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Arguments readArguments() {
    final nodeOffset = _byteOffset;
    final result = super.readArguments();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  NamedExpression readNamedExpression() {
    final nodeOffset = _byteOffset;
    final result = super.readNamedExpression();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  VariableDeclaration readVariableDeclaration() {
    final nodeOffset = _byteOffset;
    final result = super.readVariableDeclaration();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Statement readStatement() {
    final nodeOffset = _byteOffset;
    final result = super.readStatement();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Combinator readCombinator() {
    final nodeOffset = _byteOffset;
    final result = super.readCombinator();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  LibraryDependency readLibraryDependency(Library library) {
    final nodeOffset = _byteOffset;
    final result = super.readLibraryDependency(library);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  LibraryPart readLibraryPart(Library library) {
    final nodeOffset = _byteOffset;
    final result = super.readLibraryPart(library);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  void readSwitchCaseInto(SwitchCase caseNode) {
    _associateMetadata(caseNode, _byteOffset);
    super.readSwitchCaseInto(caseNode);
  }

  @override
  void readTypeParameter(TypeParameter param) {
    _associateMetadata(param, _byteOffset);
    super.readTypeParameter(param);
  }

  @override
  Supertype readSupertype() {
    final nodeOffset = _byteOffset;
    InterfaceType type = super.readDartType();
    return _associateMetadata(
        new Supertype.byReference(type.className, type.typeArguments),
        nodeOffset);
  }

  @override
  Name readName() {
    final nodeOffset = _byteOffset;
    final result = super.readName();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  int get currentOffset => _byteOffset;

  @override
  List<int> get bytes => _bytes;
}

/// Deserialized MetadataMapping corresponding to the given metadata repository.
class _MetadataSubsection {
  /// [MetadataRepository] that can read this subsection.
  final MetadataRepository repository;

  /// Deserialized mapping from node offsets to metadata offsets.
  final Map<int, int> mapping;

  _MetadataSubsection(this.repository, this.mapping);
}
