// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.ast_from_binary;

import 'dart:developer';
import 'dart:convert';
import 'dart:typed_data';

import '../ast.dart';
import '../transformations/flags.dart';
import 'tag.dart';

const int $_ = 95;

class ParseError {
  final String? filename;
  final int byteIndex;
  final String message;
  final String path;

  ParseError(this.message,
      {required this.filename, required this.byteIndex, required this.path});

  @override
  String toString() => '$filename:$byteIndex: $message at $path';
}

class InvalidKernelVersionError {
  final String? filename;
  final int version;

  InvalidKernelVersionError(this.filename, this.version);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Unexpected Kernel Format Version ${version} '
        '(expected ${Tag.BinaryFormatVersion})');
    if (filename != null) {
      sb.write(' when reading $filename.');
    }
    return '$sb';
  }
}

class InvalidKernelSdkVersionError {
  final String version;

  InvalidKernelSdkVersionError(this.version);

  @override
  String toString() {
    return 'Unexpected Kernel SDK Version ${version} '
        '(expected ${expectedSdkHash}).';
  }
}

class CompilationModeError {
  final String message;

  CompilationModeError(this.message);

  @override
  String toString() => "CompilationModeError[$message]";
}

class _ComponentIndex {
  static const int numberOfFixedFields = 12;

  final int binaryOffsetForSourceTable;
  final int binaryOffsetForCanonicalNames;
  final int binaryOffsetForMetadataPayloads;
  final int binaryOffsetForMetadataMappings;
  final int binaryOffsetForStringTable;
  final int binaryOffsetForConstantTable;
  final int binaryOffsetForConstantTableIndex;
  final int binaryOffsetForStartOfComponentIndex;
  final int mainMethodReference;
  final NonNullableByDefaultCompiledMode compiledMode;
  final List<int> libraryOffsets;
  final int libraryCount;
  final int componentFileSizeInBytes;

  _ComponentIndex(
      {required this.binaryOffsetForSourceTable,
      required this.binaryOffsetForCanonicalNames,
      required this.binaryOffsetForMetadataPayloads,
      required this.binaryOffsetForMetadataMappings,
      required this.binaryOffsetForStringTable,
      required this.binaryOffsetForConstantTable,
      required this.binaryOffsetForConstantTableIndex,
      required this.binaryOffsetForStartOfComponentIndex,
      required this.mainMethodReference,
      required this.compiledMode,
      required this.libraryOffsets,
      required this.libraryCount,
      required this.componentFileSizeInBytes});
}

class SubComponentView {
  final List<Library> libraries;
  final int componentStartOffset;
  final int componentFileSize;

  SubComponentView(
      this.libraries, this.componentStartOffset, this.componentFileSize);
}

/// [StringInterner] allows Strings created from the binary to be shared with
/// other components.
///
/// The [StringInterner] is an optional parameter to [BinaryBuilder], so sharing
/// should not be required for correctness, and an implementation of
/// [StringInterner] method may be partial (sometimes not finding an existing
/// object) or trivial (returning the argument).
abstract class StringInterner {
  /// Returns a string with the same contents as [string].
  String internString(String string);
}

/// Helper used to trigger the read of a late variable in asserts.
bool _lateIsInitialized(dynamic value) {
  return true;
}

class BinaryBuilder {
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final List<LabeledStatement> labelStack = <LabeledStatement>[];
  int labelStackBase = 0;
  int switchCaseStackBase = 0;
  final List<SwitchCase> switchCaseStack = <SwitchCase>[];
  final List< /* TypeParameter | StructuralParameter */ Object>
      typeParameterStack = <Object>[];
  final String? filename;
  final List<int> _bytes;
  int _byteOffset = 0;
  List<String> _stringTable = const [];
  late Map<int, Name?> _nameCache;
  List<Uri> _sourceUriTable = const [];
  List<Constant> _constantTable = const <Constant>[];
  late List<CanonicalName> _linkTable;

  /// Advanced use only. Coordinate with the kernel team.
  List<CanonicalName> get linkTable => _linkTable;

  late Map<int, DartType?> _cachedSimpleInterfaceTypes;
  List<FunctionType?> _voidFunctionFunctionTypesCache = [
    null,
    null,
    null,
    null
  ];
  int _transformerFlags = 0;
  Library? _currentLibrary;
  int _componentStartOffset = 0;
  NonNullableByDefaultCompiledMode? compilationMode;

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

  /// [stringInterner] (optional) may be used to allow components to share
  /// instances of [String] that have the same contents.
  final StringInterner? stringInterner;

  /// When creating lists that *might* be growable, use this boolean as the
  /// setting to pass to `growable` so the dill can be loaded in a more compact
  /// manner if the caller knows that the growability isn't needed.
  final bool useGrowableLists;

  /// Note that [disableLazyClassReading] is incompatible
  /// with checkCanonicalNames on readComponent.
  BinaryBuilder(this._bytes,
      {this.filename,
      bool disableLazyReading = false,
      bool disableLazyClassReading = false,
      bool? alwaysCreateNewNamedNodes,
      this.stringInterner,
      this.useGrowableLists = true})
      : _disableLazyReading = disableLazyReading,
        _disableLazyClassReading = disableLazyReading ||
            disableLazyClassReading ||
            // Disable lazy class reading when forcing the creation of new named
            // nodes as it is a logical "relink" to the new version (overwriting
            // the old one) - which doesn't play well with lazy loading class
            // content as old loaded references will then potentially still
            // point to the old content until the new class has been lazy
            // loaded.
            (alwaysCreateNewNamedNodes == true),
        this.alwaysCreateNewNamedNodes = alwaysCreateNewNamedNodes ?? false;

  Never fail(String message) {
    throw ParseError(message,
        byteIndex: _byteOffset, filename: filename, path: debugPath.join('::'));
  }

  int get byteOffset => _byteOffset;

  int readByte() => _bytes[_byteOffset++];
  int peekByte() => _bytes[_byteOffset];

  int readUInt30() {
    int byte = readByte();
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
  Uint8List? _doubleBufferUint8;

  double readDouble() {
    Uint8List doubleBufferUint8 =
        _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    doubleBufferUint8[0] = readByte();
    doubleBufferUint8[1] = readByte();
    doubleBufferUint8[2] = readByte();
    doubleBufferUint8[3] = readByte();
    doubleBufferUint8[4] = readByte();
    doubleBufferUint8[5] = readByte();
    doubleBufferUint8[6] = readByte();
    doubleBufferUint8[7] = readByte();
    return _doubleBuffer[0];
  }

  Uint8List readBytes(int length) {
    Uint8List bytes = new Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return bytes;
  }

  Uint8List readByteList() {
    return readBytes(readUInt30());
  }

  Uint8List readOrViewByteList() {
    int length = readUInt30();
    List<int> source = _bytes;
    if (source is Uint8List) {
      Uint8List view =
          source.buffer.asUint8List(source.offsetInBytes + _byteOffset, length);
      _byteOffset += length;
      return view;
    }
    return readBytes(length);
  }

  String readString() {
    return readStringEntry(readUInt30());
  }

  String readStringEntry(int numBytes) {
    String string = _readStringEntry(numBytes);
    if (stringInterner == null) return string;
    return stringInterner!.internString(string);
  }

  String _readStringEntry(int numBytes) {
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
  T _associateMetadata<T extends Node>(T node, int nodeOffset) {
    // Default reader ignores metadata section entirely.
    return node;
  }

  void readStringTable() {
    // Read the table of end offsets.
    int length = readUInt30();
    List<int> endOffsets =
        new List<int>.generate(length, (_) => readUInt30(), growable: false);
    // Read the WTF-8 encoded strings.
    int startOffset = 0;

    // Reset name cache here to make any index into it always
    // be about the corresponding string table entry.
    _nameCache = {};
    _stringTable = new List<String>.generate(length, (int index) {
      String result = readStringEntry(endOffsets[index] - startOffset);
      startOffset = endOffsets[index];
      return result;
    }, growable: false);
  }

  void readConstantTable() {
    final int length = readUInt30();
    // Because of "back-references" (e.g. the 10th constant referencing the 3rd
    // constant) we can't use List.generate.
    _constantTable =
        new List<Constant>.filled(length, dummyConstant, growable: false);
    for (int i = 0; i < length; i++) {
      _constantTable[i] = readConstantTableEntry();
    }
  }

  Constant readConstantTableEntry() {
    final int constantTag = readByte();
    switch (constantTag) {
      case ConstantTag.NullConstant:
        return _readNullConstant();
      case ConstantTag.BoolConstant:
        return _readBoolConstant();
      case ConstantTag.IntConstant:
        return _readIntConstant();
      case ConstantTag.DoubleConstant:
        return _readDoubleConstant();
      case ConstantTag.StringConstant:
        return _readStringConstant();
      case ConstantTag.SymbolConstant:
        return _readSymbolConstant();
      case ConstantTag.MapConstant:
        return _readMapConstant();
      case ConstantTag.ListConstant:
        return _readListConstant();
      case ConstantTag.SetConstant:
        return _readSetConstant();
      case ConstantTag.RecordConstant:
        return _readRecordConstant();
      case ConstantTag.InstanceConstant:
        return _readInstanceConstant();
      case ConstantTag.InstantiationConstant:
        return _readInstantiationConstant();
      case ConstantTag.TypedefTearOffConstant:
        return _readTypedefTearOffConstant();
      case ConstantTag.StaticTearOffConstant:
        return _readStaticTearOffConstant();
      case ConstantTag.ConstructorTearOffConstant:
        return _readConstructorTearOffConstant();
      case ConstantTag.RedirectingFactoryTearOffConstant:
        return _readRedirectingFactoryTearOffConstant();
      case ConstantTag.TypeLiteralConstant:
        return _readTypeLiteralConstant();
      case ConstantTag.UnevaluatedConstant:
        return _readUnevaluatedConstant();
    }

    throw fail('unexpected constant tag: $constantTag');
  }

  Constant _readNullConstant() {
    return new NullConstant();
  }

  Constant _readBoolConstant() {
    return new BoolConstant(readByte() == 1);
  }

  Constant _readIntConstant() {
    return new IntConstant((readExpression() as IntLiteral).value);
  }

  Constant _readDoubleConstant() {
    return new DoubleConstant(readDouble());
  }

  Constant _readStringConstant() {
    return new StringConstant(readStringReference());
  }

  Constant _readSymbolConstant() {
    Reference? libraryReference = readNullableLibraryReference();
    return new SymbolConstant(readStringReference(), libraryReference);
  }

  Constant _readMapConstant() {
    final DartType keyType = readDartType();
    final DartType valueType = readDartType();
    final int length = readUInt30();
    final List<ConstantMapEntry> entries =
        new List<ConstantMapEntry>.generate(length, (_) {
      final Constant key = readConstantReference();
      final Constant value = readConstantReference();
      return new ConstantMapEntry(key, value);
    }, growable: useGrowableLists);
    return new MapConstant(keyType, valueType, entries);
  }

  Constant _readListConstant() {
    final DartType typeArgument = readDartType();
    List<Constant> entries = _readConstantReferenceList();
    return new ListConstant(typeArgument, entries);
  }

  Constant _readSetConstant() {
    final DartType typeArgument = readDartType();
    List<Constant> entries = _readConstantReferenceList();
    return new SetConstant(typeArgument, entries);
  }

  Constant _readRecordConstant() {
    List<Constant> positional = _readConstantReferenceList();
    final int namedLength = readUInt30();
    final List<MapEntry<String, Constant>> named =
        new List<MapEntry<String, Constant>>.generate(namedLength, (_) {
      final String name = readStringReference();
      final Constant value = readConstantReference();
      return new MapEntry<String, Constant>(name, value);
    }, growable: useGrowableLists);
    final RecordType recordType = readDartType() as RecordType;
    return new RecordConstant(
        positional, new Map<String, Constant>.fromEntries(named), recordType);
  }

  Constant _readInstanceConstant() {
    final Reference classReference = readNonNullClassReference();
    final List<DartType> typeArguments = readDartTypeList();
    final int fieldValueCount = readUInt30();
    final Map<Reference, Constant> fieldValues = <Reference, Constant>{};
    for (int i = 0; i < fieldValueCount; i++) {
      final Reference fieldRef = readNonNullCanonicalNameReference().reference;
      final Constant constant = readConstantReference();
      fieldValues[fieldRef] = constant;
    }
    return new InstanceConstant(classReference, typeArguments, fieldValues);
  }

  Constant _readInstantiationConstant() {
    final Constant tearOffConstant = readConstantReference();
    final List<DartType> types = readDartTypeList();
    return new InstantiationConstant(tearOffConstant, types);
  }

  Constant _readTypedefTearOffConstant() {
    final List<TypeParameter> parameters = readAndPushTypeParameterList();
    final TearOffConstant tearOffConstant =
        readConstantReference() as TearOffConstant;
    final List<DartType> types = readDartTypeList();
    typeParameterStack.length -= parameters.length;
    return new TypedefTearOffConstant(parameters, tearOffConstant, types);
  }

  Constant _readStaticTearOffConstant() {
    final Reference reference = readNonNullCanonicalNameReference().reference;
    return new StaticTearOffConstant.byReference(reference);
  }

  Constant _readConstructorTearOffConstant() {
    final Reference reference = readNonNullCanonicalNameReference().reference;
    return new ConstructorTearOffConstant.byReference(reference);
  }

  Constant _readRedirectingFactoryTearOffConstant() {
    final Reference reference = readNonNullCanonicalNameReference().reference;
    return new RedirectingFactoryTearOffConstant.byReference(reference);
  }

  Constant _readTypeLiteralConstant() {
    final DartType type = readDartType();
    return new TypeLiteralConstant(type);
  }

  Constant _readUnevaluatedConstant() {
    final Expression expression = readExpression();
    return new UnevaluatedConstant(expression);
  }

  Constant readConstantReference() {
    final int index = readUInt30();
    Constant constant = _constantTable[index];
    assert(!identical(constant, dummyConstant),
        "No constant found at index $index.");
    return constant;
  }

  List<Constant> _readConstantReferenceList() {
    final int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfConstant;
    }
    return new List<Constant>.generate(length, (_) => readConstantReference(),
        growable: useGrowableLists);
  }

  Uri readUriReference() {
    return _sourceUriTable[readUInt30()];
  }

  String readStringReference() {
    return _stringTable[readUInt30()];
  }

  List<String> readStringReferenceList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfString;
    }
    return new List<String>.generate(length, (_) => readStringReference(),
        growable: useGrowableLists);
  }

  String? readStringOrNullIfEmpty() {
    String string = readStringReference();
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

  List<Expression> readAnnotationList([TreeNode? parent]) {
    int length = readUInt30();
    if (length == 0) return const <Expression>[];
    return new List<Expression>.generate(
        length, (_) => readExpression()..parent = parent,
        growable: useGrowableLists);
  }

  void readLinkTable(CanonicalName linkRoot) {
    int length = readUInt30();
    _linkTable = new List<CanonicalName>.filled(
        length,
        // Use [linkRoot] as a dummy default value.
        linkRoot,
        growable: false);
    // Reset simple interface type cache here to make any index into it always
    // be about the corresponding link table entry.
    _cachedSimpleInterfaceTypes = {};
    for (int i = 0; i < length; ++i) {
      int biasedParentIndex = readUInt30();
      String name = readStringReference();
      CanonicalName parent =
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
    return new List.of(index.reversed);
  }

  void _checkEmptyInput() {
    if (_bytes.length == 0) throw new StateError("Empty input given.");
  }

  void _readAndVerifySdkHash() {
    final String sdkHash = ascii.decode(readBytes(sdkHashLength));
    if (!isValidSdkHash(sdkHash)) {
      throw InvalidKernelSdkVersionError(sdkHash);
    }
  }

  /// Splits the input into views of the sub-components.
  ///
  /// Note that the result will not have the libraries filled out.
  static List<SubComponentView> index(Uint8List bytes) {
    BinaryBuilder bb = new BinaryBuilder(bytes);
    bb._verifyComponentInitialBytes(resetOffset: true);
    List<int> componentFileSizes = bb._indexComponents();
    int componentFileIndex = 0;
    List<SubComponentView> views = [];
    while (bb._byteOffset < bb._bytes.length) {
      int componentStartOffset = bb._byteOffset;
      int componentFileSize = componentFileSizes[componentFileIndex];
      bb._verifyComponentInitialBytes(resetOffset: true);
      views.add(new SubComponentView(
          const [], componentStartOffset, componentFileSize));

      bb._byteOffset = componentStartOffset + componentFileSize;
      ++componentFileIndex;
    }
    return views;
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
  List<SubComponentView>? readComponent(Component component,
      {bool checkCanonicalNames = false, bool createView = false}) {
    return Timeline.timeSync<List<SubComponentView>?>(
        "BinaryBuilder.readComponent", () {
      _verifyComponentInitialBytes(resetOffset: true);

      List<int> componentFileSizes = _indexComponents();
      if (componentFileSizes.length > 1) {
        _disableLazyReading = true;
        _disableLazyClassReading = true;
      }
      int componentFileIndex = 0;
      List<SubComponentView>? views;
      if (createView) {
        views = <SubComponentView>[];
      }
      while (_byteOffset < _bytes.length) {
        SubComponentView? view = _readOneComponent(
            component, componentFileSizes[componentFileIndex],
            createView: createView);
        if (createView) {
          views!.add(view!);
        }
        ++componentFileIndex;
      }

      if (checkCanonicalNames) {
        component.root.checkCanonicalNameChildren();
      }
      return views;
    });
  }

  /// Deserializes the source and stores it in [component].
  /// Note that the _coverage_ normally included in the source in the
  /// uri-to-source mapping is _not_ included.
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

  /// Reads a single component file from the input and loads it into
  /// [component], overwriting and reusing any existing data in the component.
  ///
  /// When linking with a non-empty component, canonical names must have been
  /// computed ahead of time.
  ///
  /// This should *only* be used when there is a reason to not allow
  /// concatenated files.
  void readSingleFileComponent(Component component,
      {bool checkCanonicalNames = false}) {
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
      component.root.checkCanonicalNameChildren();
    }
  }

  _ComponentIndex _readComponentIndex(int componentFileSize) {
    int savedByteIndex = _byteOffset;

    // There are two fields: file size and library count.
    _byteOffset = _componentStartOffset + componentFileSize - (2) * 4;
    int libraryCount = readUint32();
    // Library offsets are used for start and end offsets, so there is one extra
    // element that this the end offset of the last library
    List<int> libraryOffsets = new List<int>.filled(
        libraryCount + 1,
        // Use `-1` as a dummy default value.
        -1,
        growable: false);
    int componentFileSizeInBytes = readUint32();
    if (componentFileSizeInBytes != componentFileSize) {
      throw "Malformed binary: This component file's component index indicates "
          "that the file size should be $componentFileSize but other component "
          "indexes has indicated that the size should be "
          "${componentFileSizeInBytes}.";
    }

    // Skip to the start of the index.
    _byteOffset -=
        ((libraryCount + 1) + _ComponentIndex.numberOfFixedFields) * 4;

    // Now read the component index.
    int binaryOffsetForSourceTable = _componentStartOffset + readUint32();
    int binaryOffsetForConstantTable = _componentStartOffset + readUint32();
    int binaryOffsetForConstantTableIndex =
        _componentStartOffset + readUint32();
    int binaryOffsetForCanonicalNames = _componentStartOffset + readUint32();
    int binaryOffsetForMetadataPayloads = _componentStartOffset + readUint32();
    int binaryOffsetForMetadataMappings = _componentStartOffset + readUint32();
    int binaryOffsetForStringTable = _componentStartOffset + readUint32();
    int binaryOffsetForStartOfComponentIndex =
        _componentStartOffset + readUint32();
    int mainMethodReference = readUint32();
    NonNullableByDefaultCompiledMode compiledMode =
        NonNullableByDefaultCompiledMode.values[readUint32()];
    for (int i = 0; i < libraryCount + 1; ++i) {
      libraryOffsets[i] = _componentStartOffset + readUint32();
    }

    _byteOffset = savedByteIndex;

    return new _ComponentIndex(
        libraryCount: libraryCount,
        libraryOffsets: libraryOffsets,
        componentFileSizeInBytes: componentFileSizeInBytes,
        binaryOffsetForSourceTable: binaryOffsetForSourceTable,
        binaryOffsetForCanonicalNames: binaryOffsetForCanonicalNames,
        binaryOffsetForMetadataPayloads: binaryOffsetForMetadataPayloads,
        binaryOffsetForMetadataMappings: binaryOffsetForMetadataMappings,
        binaryOffsetForStringTable: binaryOffsetForStringTable,
        binaryOffsetForConstantTable: binaryOffsetForConstantTable,
        binaryOffsetForConstantTableIndex: binaryOffsetForConstantTableIndex,
        binaryOffsetForStartOfComponentIndex:
            binaryOffsetForStartOfComponentIndex,
        mainMethodReference: mainMethodReference,
        compiledMode: compiledMode);
  }

  void _readOneComponentSource(Component component, int componentFileSize) {
    _componentStartOffset = _byteOffset;
    _verifyComponentInitialBytes(resetOffset: false);

    // Read component index from the end of this ComponentFiles serialized data.
    _ComponentIndex index = _readComponentIndex(componentFileSize);

    _byteOffset = index.binaryOffsetForSourceTable;
    Map<Uri, Source> uriToSource = readUriToSource(readCoverage: false);
    _mergeUriToSource(component.uriToSource, uriToSource);

    _byteOffset = _componentStartOffset + componentFileSize;
  }

  /// Verify the initial bytes could correspond to a valid component.
  ///
  /// * Checks we have non-empty input.
  /// * Verifies that the magic number is correct.
  /// * Verifies the binary format version.
  /// * Verifies the sdk hash.
  ///
  /// If [resetOffset] is true the [_byteOffset] will be reset to match what it
  /// was before this method was called. If false it will be so we read passed
  /// the sdk hash.
  void _verifyComponentInitialBytes({required bool resetOffset}) {
    // Check that we have a .dill file and it has the correct version before
    // we start decoding it.  Otherwise we will fail for cryptic reasons.
    _checkEmptyInput();
    int offset = _byteOffset;
    int magic = readUint32();
    if (magic != Tag.ComponentFile) {
      throw ArgumentError('Not a .dill file (wrong magic number).');
    }
    int version = readUint32();
    if (version != Tag.BinaryFormatVersion) {
      throw InvalidKernelVersionError(filename, version);
    }

    _readAndVerifySdkHash();

    if (resetOffset) {
      _byteOffset = offset;
    }
  }

  SubComponentView? _readOneComponent(
      Component component, int componentFileSize,
      {bool createView = false}) {
    _componentStartOffset = _byteOffset;
    _verifyComponentInitialBytes(resetOffset: false);

    List<String>? problemsAsJson = readListOfStrings();
    if (problemsAsJson != null) {
      component.problemsAsJson ??= <String>[];
      component.problemsAsJson!.addAll(problemsAsJson);
    }

    // Read component index from the end of this ComponentFiles serialized data.
    _ComponentIndex index = _readComponentIndex(componentFileSize);
    if (compilationMode == null) {
      compilationMode = component.modeRaw;
    }
    compilationMode =
        mergeCompilationModeOrThrow(compilationMode, index.compiledMode);

    _byteOffset = index.binaryOffsetForStringTable;
    readStringTable();

    _byteOffset = index.binaryOffsetForCanonicalNames;
    readLinkTable(component.root);

    // TODO(alexmarkov): reverse metadata mappings and read forwards
    _byteOffset = index.binaryOffsetForStringTable; // Read backwards.
    _readMetadataMappings(component, index.binaryOffsetForMetadataPayloads);

    _associateMetadata(component, _componentStartOffset);

    _byteOffset = index.binaryOffsetForSourceTable;
    Map<Uri, Source> uriToSource = readUriToSource(readCoverage: true);
    _mergeUriToSource(component.uriToSource, uriToSource);

    _byteOffset = index.binaryOffsetForConstantTable;
    readConstantTable();
    // We don't need the constant table index on the dart side.

    int numberOfLibraries = index.libraryCount;

    SubComponentView? result;
    if (createView) {
      result = new SubComponentView(
          new List<Library>.generate(numberOfLibraries, (int i) {
            _byteOffset = index.libraryOffsets[i];
            return readLibrary(component, index.libraryOffsets[i + 1]);
          }, growable: false),
          _componentStartOffset,
          componentFileSize);
    } else {
      for (int i = 0; i < numberOfLibraries; ++i) {
        _byteOffset = index.libraryOffsets[i];
        readLibrary(component, index.libraryOffsets[i + 1]);
      }
    }

    Reference? mainMethod =
        getNullableMemberReferenceFromInt(index.mainMethodReference);
    component.setMainMethodAndMode(mainMethod, false, compilationMode!);

    _byteOffset = _componentStartOffset + componentFileSize;

    assert(typeParameterStack.isEmpty);

    return result;
  }

  /// Read a list of strings. If the list is empty, [null] is returned.
  List<String>? readListOfStrings() {
    int length = readUInt30();
    if (length == 0) return null;
    return new List<String>.generate(length, (_) => readString(),
        growable: useGrowableLists);
  }

  /// Read the uri-to-source part of the binary.
  /// Note that this can include coverage, but that it is only included if
  /// [readCoverage] is true, otherwise coverage will be skipped. Note also that
  /// if [readCoverage] is true, references are read and that the link table
  /// thus has to be read first.
  Map<Uri, Source> readUriToSource({required bool readCoverage}) {
    assert(!readCoverage || (readCoverage && _lateIsInitialized(_linkTable)));

    int length = readUint32();

    // Read data.
    _sourceUriTable = new List<Uri>.filled(length, dummyUri, growable: false);
    Map<Uri, Source> uriToSource = <Uri, Source>{};
    for (int i = 0; i < length; ++i) {
      String uriString = readString();
      Uri uri = Uri.parse(uriString);
      _sourceUriTable[i] = uri;
      Uint8List sourceCode = readOrViewByteList();
      int lineCount = readUInt30();
      List<int> lineStarts = new List<int>.filled(
          lineCount,
          // Use `-1` as a dummy default value.
          -1,
          growable: false);
      int previousLineStart = 0;
      for (int j = 0; j < lineCount; ++j) {
        int lineStart = readUInt30() + previousLineStart;
        lineStarts[j] = lineStart;
        previousLineStart = lineStart;
      }
      String importUriString = readString();
      Uri importUri = Uri.parse(importUriString);

      Set<Reference>? coverageConstructors;
      {
        int constructorCoverageCount = readUInt30();
        if (constructorCoverageCount > 0) {
          if (readCoverage) {
            coverageConstructors = new Set<Reference>();
            for (int j = 0; j < constructorCoverageCount; ++j) {
              coverageConstructors.add(readNonNullMemberReference());
            }
          } else {
            for (int j = 0; j < constructorCoverageCount; ++j) {
              skipMemberReference();
            }
          }
        }
      }

      uriToSource[uri] = new Source(lineStarts, sourceCode, importUri, uri)
        ..constantCoverageConstructors = coverageConstructors;
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
        Source? originalDestinationSource = dst[key];
        Source? mergeFrom;
        Source mergeTo;
        if (value.source.isNotEmpty || originalDestinationSource == null) {
          dst[key] = value;
          mergeFrom = originalDestinationSource;
          mergeTo = value;
        } else {
          mergeFrom = value;
          mergeTo = originalDestinationSource;
        }

        // TODO(jensj): Find out what the right thing to do is --- it probably
        // depends on what we do if read the same library twice - do we merge or
        // do we overwrite, and should we even support such a thing?

        // Merge coverage. Note that mergeFrom might be null.
        if (mergeTo.constantCoverageConstructors == null) {
          mergeTo.constantCoverageConstructors =
              mergeFrom?.constantCoverageConstructors;
        } else if (mergeFrom?.constantCoverageConstructors == null) {
          // Nothing to do.
        } else {
          // Both are non-null: Merge.
          mergeTo.constantCoverageConstructors!
              .addAll(mergeFrom!.constantCoverageConstructors!);
        }
      });
    }
  }

  void skipCanonicalNameReference() {
    readUInt30();
  }

  CanonicalName? readNullableCanonicalNameReference() {
    int index = readUInt30();
    if (index == 0) return null;
    return _linkTable[index - 1];
  }

  CanonicalName readNonNullCanonicalNameReference() {
    CanonicalName? canonicalName = readNullableCanonicalNameReference();
    if (canonicalName == null) {
      throw new StateError('No canonical name found.');
    }
    return canonicalName;
  }

  CanonicalName? getNullableCanonicalNameReferenceFromInt(int index) {
    if (index == 0) return null;
    return _linkTable[index - 1];
  }

  Reference? readNullableLibraryReference() {
    CanonicalName? canonicalName = readNullableCanonicalNameReference();
    return canonicalName?.reference;
  }

  Reference readNonNullLibraryReference() {
    CanonicalName? canonicalName = readNullableCanonicalNameReference();
    if (canonicalName != null) return canonicalName.reference;
    throw 'Expected a library reference to be valid but was `null`.';
  }

  LibraryDependency readLibraryDependencyReference() {
    int index = readUInt30();
    return _currentLibrary!.dependencies[index];
  }

  Reference readNonNullClassReference() {
    CanonicalName? name = readNullableCanonicalNameReference();
    if (name == null) {
      throw 'Expected a class reference to be valid but was `null`.';
    }
    return name.reference;
  }

  Reference readNonNullExtensionTypeDeclarationReference() {
    CanonicalName? name = readNullableCanonicalNameReference();
    if (name == null) {
      throw 'Expected an extension type declaration reference to be valid but '
          'was `null`.';
    }
    return name.reference;
  }

  void skipMemberReference() {
    skipCanonicalNameReference();
  }

  Reference? readNullableMemberReference() {
    CanonicalName? name = readNullableCanonicalNameReference();
    return name?.reference;
  }

  Reference readNonNullMemberReference() {
    CanonicalName? name = readNullableCanonicalNameReference();
    if (name == null) {
      throw 'Expected a member reference to be valid but was `null`.';
    }
    return name.reference;
  }

  Reference readNonNullInstanceMemberReference() {
    Reference reference = readNonNullMemberReference();
    readNullableMemberReference(); // Skip origin
    return reference;
  }

  Reference? getNullableMemberReferenceFromInt(int index) {
    return getNullableCanonicalNameReferenceFromInt(index)?.reference;
  }

  Reference readNonNullTypedefReference() {
    return readNonNullCanonicalNameReference().reference;
  }

  Name readName() {
    final int stringReference = readUInt30();
    assert(stringReference < (1 << 30));
    final String text = _stringTable[stringReference];
    final bool isPrivate = text.isNotEmpty && text.codeUnitAt(0) == $_;
    final int libraryReferenceIndex;
    final int nameCacheIndex;

    if (isPrivate) {
      // "Raw" reference index of 0 means null which we don't allow.
      libraryReferenceIndex = readUInt30();
      if (libraryReferenceIndex == 0) {
        throw 'Expected a library reference to be valid but was `null`.';
      }

      // Check cache using the upper bits for the library reference.
      nameCacheIndex = stringReference | ((libraryReferenceIndex) << 30);
    } else {
      // the 0 will be unused but we need to assign it.
      libraryReferenceIndex = 0;
      nameCacheIndex = stringReference;
    }

    final Name? cached = _nameCache[nameCacheIndex];
    if (cached != null) {
      return cached;
    }

    // Not in cache. Create it and cache it.
    final Name name;
    if (isPrivate) {
      // libraryReferenceIndex was checked to be > 0 so we get a canonical name.
      final CanonicalName canonicalName =
          getNullableCanonicalNameReferenceFromInt(libraryReferenceIndex)!;
      final Reference libraryReference = canonicalName.reference;
      name = new Name.byReference(text, libraryReference);
    } else {
      name = new Name(text);
    }
    _nameCache[nameCacheIndex] = name;
    return name;
  }

  Library readLibrary(Component component, int endOffset) {
    // Read index.
    int savedByteOffset = _byteOffset;

    // There is a field for the procedure count.
    _byteOffset = endOffset - (1) * 4;
    int procedureCount = readUint32();

    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets, and then the class count (i.e. procedure count + 3 fields).
    _byteOffset = endOffset - (procedureCount + 3) * 4;
    int classCount = readUint32();
    List<int> procedureOffsets = new List<int>.generate(
        procedureCount + 1, (int index) => _componentStartOffset + readUint32(),
        growable: false);

    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets, then the class count and that number + 1 (for the end) offsets.
    // (i.e. procedure count + class count + 4 fields).
    _byteOffset = endOffset - (procedureCount + classCount + 4) * 4;
    List<int> classOffsets = new List<int>.generate(
        classCount + 1, (int index) => _componentStartOffset + readUint32(),
        growable: false);
    _byteOffset = savedByteOffset;

    int flags = readByte();

    int languageVersionMajor = readUInt30();
    int languageVersionMinor = readUInt30();

    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Library? library = reference.node as Library?;
    String? name = readStringOrNullIfEmpty();

    // TODO(jensj): We currently save (almost the same) uri twice.
    Uri fileUri = readUriReference();

    if (alwaysCreateNewNamedNodes) {
      library = null;
    }
    if (library == null) {
      library = new Library(Uri.parse(canonicalName.name),
          reference: reference, fileUri: fileUri);
      component.libraries.add(library..parent = component);
    }
    _currentLibrary = library;

    List<String>? problemsAsJson = readListOfStrings();

    library.flags = flags;
    library.setLanguageVersion(
        new Version(languageVersionMajor, languageVersionMinor));
    library.name = name;
    library.fileUri = fileUri;
    library.problemsAsJson = problemsAsJson;

    assert(
        mergeCompilationModeOrThrow(
                compilationMode, library.nonNullableByDefaultCompiledMode) ==
            compilationMode,
        "Cannot load ${library.nonNullableByDefaultCompiledMode} "
        "into component with mode $compilationMode");

    assert(() {
      debugPath.add(library!.name ?? library.importUri.toString());
      return true;
    }());

    library.annotations = readAnnotationList(library);
    _readLibraryDependencies(library);
    _readAdditionalExports(library);
    _readLibraryParts(library);
    _readTypedefList(library);
    _readClassList(library, classOffsets);
    _readExtensionList(library);
    _readExtensionTypeDeclarationList(library);
    library.fieldsInternal = _readFieldList(library);
    library.proceduresInternal = _readProcedureList(library, procedureOffsets);

    assert(((_) => true)(debugPath.removeLast()));
    _currentLibrary = null;
    return library;
  }

  void _readTypedefList(Library library) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.typedefsInternal = emptyListOfTypedef;
    } else {
      library.typedefsInternal = new List<Typedef>.generate(
          length, (int index) => readTypedef()..parent = library,
          growable: useGrowableLists);
    }
  }

  void _readClassList(Library library, List<int> classOffsets) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.classesInternal = emptyListOfClass;
    } else {
      library.classesInternal = new List<Class>.generate(length, (int index) {
        _byteOffset = classOffsets[index];
        return readClass(classOffsets[index + 1])..parent = library;
      }, growable: useGrowableLists);
      _byteOffset = classOffsets.last;
    }
  }

  void _readExtensionList(Library library) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.extensionsInternal = emptyListOfExtension;
    } else {
      library.extensionsInternal = new List<Extension>.generate(
          length, (int index) => readExtension()..parent = library,
          growable: useGrowableLists);
    }
  }

  void _readExtensionTypeDeclarationList(Library library) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.extensionTypeDeclarationsInternal =
          emptyListOfExtensionTypeDeclaration;
    } else {
      library.extensionTypeDeclarationsInternal =
          new List<ExtensionTypeDeclaration>.generate(length,
              (int index) => readExtensionTypeDeclaration()..parent = library,
              growable: useGrowableLists);
    }
  }

  List<Field> _readFieldList(TreeNode parent) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfField;
    }
    return new List<Field>.generate(
        length, (int index) => readField()..parent = parent,
        growable: useGrowableLists);
  }

  List<Procedure> _readProcedureList(
      TreeNode parent, List<int> procedureOffsets) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfProcedure;
    }
    List<Procedure> list = new List<Procedure>.generate(length, (int index) {
      _byteOffset = procedureOffsets[index];
      return readProcedure(procedureOffsets[index + 1])..parent = parent;
    }, growable: useGrowableLists);
    _byteOffset = procedureOffsets.last;
    return list;
  }

  List<Procedure> _readProcedureListWithoutOffsets(TreeNode parent) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfProcedure;
    }
    List<Procedure> list = new List<Procedure>.generate(length, (int index) {
      return readProcedure(/* no end offset = */ -1)..parent = parent;
    }, growable: useGrowableLists);
    return list;
  }

  void _readLibraryDependencies(Library library) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.dependencies = emptyListOfLibraryDependency;
    } else {
      library.dependencies = new List<LibraryDependency>.generate(
          length, (int index) => readLibraryDependency()..parent = library,
          growable: useGrowableLists);
    }
  }

  LibraryDependency readLibraryDependency() {
    int fileOffset = readOffset();
    int flags = readByte();
    List<Expression> annotations = readExpressionList();
    Reference targetLibrary = readNonNullLibraryReference();
    String? prefixName = readStringOrNullIfEmpty();
    List<Combinator> names = readCombinatorList();
    return new LibraryDependency.byReference(
        flags, annotations, targetLibrary, prefixName, names)
      ..fileOffset = fileOffset;
  }

  void _readAdditionalExports(Library library) {
    int numExportedReference = readUInt30();
    if (numExportedReference != 0) {
      library.additionalExports.clear();
      for (int i = 0; i < numExportedReference; i++) {
        CanonicalName exportedName = readNonNullCanonicalNameReference();
        Reference reference = exportedName.reference;
        library.additionalExports.add(reference);
      }
    }
  }

  Combinator readCombinator() {
    bool isShow = readByte() == 1;
    List<String> names = readStringReferenceList();
    return new Combinator(isShow, names);
  }

  List<Combinator> readCombinatorList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfCombinator;
    }
    return new List<Combinator>.generate(length, (_) => readCombinator(),
        growable: useGrowableLists);
  }

  void _readLibraryParts(Library library) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      library.parts = emptyListOfLibraryPart;
    } else {
      library.parts = new List<LibraryPart>.generate(
          length, (int index) => readLibraryPart()..parent = library,
          growable: useGrowableLists);
    }
  }

  LibraryPart readLibraryPart() {
    List<Expression> annotations = readExpressionList();
    String partUri = readStringReference();
    return new LibraryPart(annotations, partUri);
  }

  Typedef readTypedef() {
    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Typedef? node = reference.node as Typedef?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    Uri fileUri = readUriReference();
    int fileOffset = readOffset();
    String name = readStringReference();
    if (node == null) {
      node = new Typedef(name, null, reference: reference, fileUri: fileUri);
    }
    node.annotations = readAnnotationList(node);
    readAndPushTypeParameterList(node.typeParameters, node);
    DartType type = readDartType();
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
    // There is a field for the procedure count, that number + 1 (for the end)
    // offsets (i.e. procedure count + 2 fields).
    _byteOffset = endOffset - (procedureCount + 2) * 4;
    List<int> procedureOffsets = new List<int>.generate(
        procedureCount + 1, (_) => _componentStartOffset + readUint32(),
        growable: false);
    _byteOffset = savedByteOffset;

    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Class? node = reference.node as Class?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    Uri fileUri = readUriReference();
    int startFileOffset = readOffset();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readUInt30();
    String name = readStringReference();
    if (node == null) {
      node = new Class(name: name, reference: reference, fileUri: fileUri)
        ..dirty = false;
    }

    node.startFileOffset = startFileOffset;
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    List<Expression> annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(name);
      return true;
    }());

    assert(typeParameterStack.length == 0);

    readAndPushTypeParameterList(node.typeParameters, node);
    Supertype? supertype = readSupertypeOption();
    Supertype? mixedInType = readSupertypeOption();
    node.implementedTypes = readSupertypeList();
    if (_disableLazyClassReading) {
      readClassPartialContent(node, procedureOffsets);
    } else {
      _setLazyLoadClass(node, procedureOffsets);
    }

    typeParameterStack.length = 0;
    assert(() {
      debugPath.removeLast();
      return true;
    }());
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

    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Extension? node = reference.node as Extension?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }

    String name = readStringReference();
    assert(() {
      debugPath.add(name);
      return true;
    }());

    List<Expression> annotations = readAnnotationList();

    Uri fileUri = readUriReference();

    if (node == null) {
      node = new Extension(name: name, reference: reference, fileUri: fileUri);
    }
    node.annotations = annotations;
    setParents(annotations, node);

    node.fileOffset = readOffset();

    node.flags = readByte();

    readAndPushTypeParameterList(node.typeParameters, node);
    DartType onType = readDartType();

    typeParameterStack.length = 0;

    node.name = name;
    node.fileUri = fileUri;
    node.onType = onType;

    node.memberDescriptors = _readExtensionMemberDescriptorList();

    return node;
  }

  List<ExtensionMemberDescriptor> _readExtensionMemberDescriptorList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      return emptyListOfExtensionMemberDescriptor;
    }
    return new List<ExtensionMemberDescriptor>.generate(
        length, (_) => _readExtensionMemberDescriptor(),
        growable: useGrowableLists);
  }

  ExtensionMemberDescriptor _readExtensionMemberDescriptor() {
    Name name = readName();
    int kind = readByte();
    int flags = readByte();
    CanonicalName memberName = readNonNullCanonicalNameReference();
    CanonicalName? tearOffName = readNullableCanonicalNameReference();
    return new ExtensionMemberDescriptor(
        name: name,
        kind: ExtensionMemberKind.values[kind],
        memberReference: memberName.reference,
        tearOffReference: tearOffName?.reference)
      ..flags = flags;
  }

  ExtensionTypeDeclaration readExtensionTypeDeclaration() {
    int tag = readByte();
    assert(tag == Tag.ExtensionTypeDeclaration, "Unexpected tag $tag");

    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    ExtensionTypeDeclaration? node =
        reference.node as ExtensionTypeDeclaration?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }

    String name = readStringReference();
    assert(() {
      debugPath.add(name);
      return true;
    }());

    List<Expression> annotations = readAnnotationList();

    Uri fileUri = readUriReference();

    if (node == null) {
      node = new ExtensionTypeDeclaration(
          name: name, reference: reference, fileUri: fileUri);
    }
    node.annotations = annotations;
    setParents(annotations, node);

    node.fileOffset = readOffset();

    node.flags = readByte();

    readAndPushTypeParameterList(node.typeParameters, node);
    DartType representationType = readDartType();
    String representationName = readStringReference();
    List<TypeDeclarationType> implements =
        _readExtensionTypeDeclarationImplementsList();

    node.proceduresInternal = _readProcedureListWithoutOffsets(node);
    typeParameterStack.length = 0;

    node.name = name;
    node.fileUri = fileUri;
    node.declaredRepresentationType = representationType;
    node.representationName = representationName;

    node.implements = implements;

    node.memberDescriptors = _readExtensionTypeMemberDescriptorList();

    return node;
  }

  List<TypeDeclarationType> _readExtensionTypeDeclarationImplementsList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      return emptyListOfTypeDeclarationType;
    }
    return new List<TypeDeclarationType>.generate(
        length, (_) => readDartType() as TypeDeclarationType,
        growable: useGrowableLists);
  }

  List<ExtensionTypeMemberDescriptor> _readExtensionTypeMemberDescriptorList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      return emptyListOfExtensionTypeMemberDescriptor;
    }
    return new List<ExtensionTypeMemberDescriptor>.generate(
        length, (_) => _readExtensionTypeMemberDescriptor(),
        growable: useGrowableLists);
  }

  ExtensionTypeMemberDescriptor _readExtensionTypeMemberDescriptor() {
    Name name = readName();
    int kind = readByte();
    int flags = readByte();
    CanonicalName memberName = readNonNullCanonicalNameReference();
    CanonicalName? tearOffName = readNullableCanonicalNameReference();
    return new ExtensionTypeMemberDescriptor(
        name: name,
        kind: ExtensionTypeMemberKind.values[kind],
        memberReference: memberName.reference,
        tearOffReference: tearOffName?.reference)
      ..flags = flags;
  }

  /// Reads the partial content of a class, namely fields, procedures,
  /// constructors and redirecting factory constructors.
  void readClassPartialContent(Class node, List<int> procedureOffsets) {
    node.fieldsInternal = _readFieldList(node);
    _readConstructorList(node);
    node.proceduresInternal = _readProcedureList(node, procedureOffsets);
  }

  void _readConstructorList(Class node) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      node.constructorsInternal = emptyListOfConstructor;
    } else {
      node.constructorsInternal = new List<Constructor>.generate(
          length, (int index) => readConstructor()..parent = node,
          growable: useGrowableLists);
    }
  }

  /// Set the lazyBuilder on the class so it can be lazy loaded in the future.
  void _setLazyLoadClass(Class node, List<int> procedureOffsets) {
    final int savedByteOffset = _byteOffset;
    final int componentStartOffset = _componentStartOffset;
    final Library? currentLibrary = _currentLibrary;
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
    CanonicalName fieldCanonicalName = readNonNullCanonicalNameReference();
    Reference fieldReference = fieldCanonicalName.reference;
    CanonicalName getterCanonicalName = readNonNullCanonicalNameReference();
    Reference getterReference = getterCanonicalName.reference;
    CanonicalName? setterCanonicalName = readNullableCanonicalNameReference();
    Reference? setterReference = setterCanonicalName?.reference;
    Field? node = fieldReference.node as Field?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    Uri fileUri = readUriReference();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readUInt30();
    Name name = readName();
    if (node == null) {
      if (setterReference != null) {
        node = new Field.mutable(name,
            fieldReference: fieldReference,
            getterReference: getterReference,
            setterReference: setterReference,
            fileUri: fileUri);
      } else {
        node = new Field.immutable(name,
            fieldReference: fieldReference,
            getterReference: getterReference,
            fileUri: fileUri);
      }
    }
    List<Expression> annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(name.text);
      return true;
    }());
    DartType type = readDartType();
    Expression? initializer = readExpressionOption();
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
    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Constructor? node = reference.node as Constructor?;
    if (alwaysCreateNewNamedNodes) {
      node = null;
    }
    Uri fileUri = readUriReference();
    int startFileOffset = readOffset();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readByte();
    Name name = readName();
    List<Expression> annotations = readAnnotationList();
    assert(() {
      debugPath.add(name.text);
      return true;
    }());
    FunctionNode function = readFunctionNode();
    if (node == null) {
      node = new Constructor(function,
          reference: reference, name: name, fileUri: fileUri);
    }
    pushVariableDeclarations(function.positionalParameters);
    pushVariableDeclarations(function.namedParameters);
    _readInitializers(node);
    variableStack.length = 0;
    int transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    node.startFileOffset = startFileOffset;
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    setParents(annotations, node);
    node.function = function..parent = node;
    node.transformerFlags = transformerFlags;
    return node;
  }

  Procedure readProcedure(int endOffset) {
    int tag = readByte();
    assert(tag == Tag.Procedure);
    CanonicalName canonicalName = readNonNullCanonicalNameReference();
    Reference reference = canonicalName.reference;
    Procedure? node;
    if (!alwaysCreateNewNamedNodes) {
      node = reference.node as Procedure?;
    }
    Uri fileUri = readUriReference();
    int startFileOffset = readOffset();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int kindIndex = readByte();
    ProcedureKind kind = ProcedureKind.values[kindIndex];
    ProcedureStubKind stubKind = ProcedureStubKind.values[readByte()];
    int flags = readUInt30();
    Name name = readName();
    List<Expression> annotations = readAnnotationList();
    assert(() {
      debugPath.add(name.text);
      return true;
    }());

    int functionNodeSize = endOffset - _byteOffset;
    // Read small factories and extension type declaration procedures
    // (where `endOffset == -1`) up front. Postpone everything else.
    bool readFunctionNodeNow = endOffset == -1 ||
        (kind == ProcedureKind.Factory && functionNodeSize <= 50) ||
        _disableLazyReading;
    Reference? stubTargetReference = readNullableMemberReference();
    FunctionType? signatureType = readDartTypeOption() as FunctionType?;
    FunctionNode function = readFunctionNode(
        lazyLoadBody: !readFunctionNodeNow, outerEndOffset: endOffset);
    if (node == null) {
      node = new Procedure(name, kind, function,
          reference: reference, fileUri: fileUri);
    } else {
      assert(node.kind == kind);
    }
    int transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    node.fileStartOffset = startFileOffset;
    node.fileOffset = fileOffset;
    node.fileEndOffset = fileEndOffset;
    node.flags = flags;
    node.name = name;
    node.fileUri = fileUri;
    node.annotations = annotations;
    setParents(annotations, node);
    node.function = function..parent = node;
    node.setTransformerFlagsWithoutLazyLoading(transformerFlags);
    node.stubKind = stubKind;
    node.stubTargetReference = stubTargetReference;
    node.signatureType = signatureType;

    assert((node.stubKind == ProcedureStubKind.ConcreteForwardingStub &&
            node.stubTargetReference != null) ||
        !(node.isForwardingStub && node.function.body != null));
    assert(!(node.isMemberSignature && node.stubTargetReference == null),
        "No member signature origin for member signature $node.");
    return node;
  }

  void _readInitializers(Constructor constructor) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      constructor.initializers = emptyListOfInitializer;
    } else {
      constructor.initializers = new List<Initializer>.generate(
          length, (int index) => readInitializer()..parent = constructor,
          growable: useGrowableLists);
    }
  }

  Initializer readInitializer() {
    int tag = readByte();
    bool isSynthetic = readByte() == 1;
    switch (tag) {
      // 52.71% (43.80% - 59.02%).
      case Tag.FieldInitializer:
        return _readFieldInitializer(isSynthetic);

      // 42.01% (28.38% - 55.93%)
      case Tag.SuperInitializer:
        return _readSuperInitializer(isSynthetic);

      // 4.69% (0.00% - 16.00%).
      case Tag.AssertInitializer:
        return _readAssertInitializer();

      // The rest is < 2% on average in sampled dills.
      case Tag.InvalidInitializer:
        return _readInvalidInitializer();
      case Tag.RedirectingInitializer:
        return _readRedirectingInitializer();
      case Tag.LocalInitializer:
        return _readLocalInitializer();
      default:
        throw fail('unexpected initializer tag: $tag');
    }
  }

  Initializer _readInvalidInitializer() {
    return new InvalidInitializer();
  }

  Initializer _readFieldInitializer(bool isSynthetic) {
    int offset = readOffset();
    Reference reference = readNonNullMemberReference();
    Expression value = readExpression();
    return new FieldInitializer.byReference(reference, value)
      ..isSynthetic = isSynthetic
      ..fileOffset = offset;
  }

  Initializer _readSuperInitializer(bool isSynthetic) {
    int offset = readOffset();
    Reference reference = readNonNullMemberReference();
    Arguments arguments = readArguments();
    return new SuperInitializer.byReference(reference, arguments)
      ..isSynthetic = isSynthetic
      ..fileOffset = offset;
  }

  Initializer _readRedirectingInitializer() {
    int offset = readOffset();
    return new RedirectingInitializer.byReference(
        readNonNullMemberReference(), readArguments())
      ..fileOffset = offset;
  }

  Initializer _readLocalInitializer() {
    return new LocalInitializer(readAndPushVariableDeclaration());
  }

  Initializer _readAssertInitializer() {
    return new AssertInitializer(readStatement() as AssertStatement);
  }

  FunctionNode readFunctionNode(
      {bool lazyLoadBody = false, int outerEndOffset = -1}) {
    int tag = readByte();
    assert(tag == Tag.FunctionNode);
    int offset = readOffset();
    int endOffset = readOffset();
    AsyncMarker asyncMarker = AsyncMarker.values[readByte()];
    AsyncMarker dartAsyncMarker = AsyncMarker.values[readByte()];
    int typeParameterStackHeight = typeParameterStack.length;
    List<TypeParameter> typeParameters = readAndPushTypeParameterList();
    readUInt30(); // total parameter count.
    int requiredParameterCount = readUInt30();
    int variableStackHeight = variableStack.length;
    List<VariableDeclaration> positional = readAndPushVariableDeclarationList();
    List<VariableDeclaration> named = readAndPushVariableDeclarationList();
    DartType returnType = readDartType();
    DartType? futureValueType = readDartTypeOption();
    RedirectingFactoryTarget? redirectingFactoryTarget;
    if (readAndCheckOptionTag()) {
      Reference? targetReference = readNullableMemberReference();
      List<DartType>? typeArguments;
      if (readAndCheckOptionTag()) {
        typeArguments = readDartTypeList();
      }
      if (readAndCheckOptionTag()) {
        assert(targetReference == null && typeArguments == null);
        String errorMessage = readStringReference();
        redirectingFactoryTarget =
            new RedirectingFactoryTarget.error(errorMessage);
      } else {
        assert(targetReference != null && typeArguments != null);
        redirectingFactoryTarget = new RedirectingFactoryTarget.byReference(
            targetReference!, typeArguments!);
      }
    }

    int oldLabelStackBase = labelStackBase;
    int oldSwitchCaseStackBase = switchCaseStackBase;

    if (lazyLoadBody && outerEndOffset > 0) {
      lazyLoadBody = outerEndOffset - _byteOffset >
          2; // e.g. outline has Tag.Something and Tag.EmptyStatement
    }

    Statement? body;
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
        dartAsyncMarker: dartAsyncMarker,
        emittedValueType: futureValueType)
      ..fileOffset = offset
      ..fileEndOffset = endOffset
      ..redirectingFactoryTarget = redirectingFactoryTarget;

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
    final List<TypeParameter> typeParameters =
        typeParameterStack.cast<TypeParameter>().toList();
    final List<VariableDeclaration> variables = variableStack.toList();
    final Library currentLibrary = _currentLibrary!;
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
      TreeNode? parent = result.parent;
      if (parent is Procedure) {
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
    readUInt30(); // offset of the variable declaration in the binary.
    return _readVariableReferenceInternal();
  }

  VariableDeclaration _readVariableReferenceInternal() {
    int index = readUInt30();
    if (index >= variableStack.length) {
      throw fail('Unexpected variable index: $index. '
          'Current variable count: ${variableStack.length}.');
    }
    return variableStack[index];
  }

  LogicalExpressionOperator logicalOperatorToEnum(int index) {
    switch (index) {
      case 0:
        return LogicalExpressionOperator.AND;
      case 1:
        return LogicalExpressionOperator.OR;
      default:
        throw fail('unexpected logical operator index: $index');
    }
  }

  List<Expression> readExpressionList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      return emptyListOfExpression;
    }
    return new List<Expression>.generate(length, (_) => readExpression(),
        growable: useGrowableLists);
  }

  Expression? readExpressionOption() {
    return readAndCheckOptionTag() ? readExpression() : null;
  }

  Expression readExpression() {
    int tagByte = readByte();
    int tag = tagByte & Tag.SpecializedTagHighBits == Tag.SpecializedTagHighBits
        ? (tagByte & Tag.SpecializedTagMask)
        : tagByte;
    switch (tag) {
      // 18.57% (13.56% - 23.28%).
      case Tag.SpecializedVariableGet:
        return _readSpecializedVariableGet(tagByte);

      // 12.02% (9.14% - 14.14%).
      case Tag.InstanceGet:
        return _readInstanceGet();

      // 10.61% (6.82% - 14.13%).
      case Tag.ThisExpression:
        return _readThisLiteral();

      // 10.19% (6.51% - 15.46%).
      case Tag.ConstantExpression:
        return _readConstantExpression();

      // 9.95% (5.96% - 13.10%).
      case Tag.InstanceInvocation:
        return _readInstanceInvocation();

      // 6.20% (2.67% - 12.88%)
      case Tag.StringLiteral:
        return _readStringLiteral();

      // 4.30% (1.89% - 5.58%).
      case Tag.VariableGet:
        return _readVariableGet();

      // 3.94% (2.48% - 6.29%).
      case Tag.StaticInvocation:
        return _readStaticInvocation();

      // 2.95% (1.58% - 5.31%).
      case Tag.SpecializedIntLiteral:
        return _readSpecializedIntLiteral(tagByte);

      // 2.92% (1.76% - 5.21%).
      case Tag.ConstructorInvocation:
        return _readConstructorInvocation();

      // The rest is < 2% on average in sampled dills.
      case Tag.LoadLibrary:
        return _readLoadLibrary();
      case Tag.CheckLibraryIsLoaded:
        return _readCheckLibraryIsLoaded();
      case Tag.InvalidExpression:
        return _readInvalidExpression();
      case Tag.VariableSet:
        return _readVariableSet();
      case Tag.SpecializedVariableSet:
        return _readSpecializedVariableSet(tagByte);
      case Tag.InstanceTearOff:
        return _readInstanceTearOff();
      case Tag.DynamicGet:
        return _readDynamicGet();
      case Tag.RecordIndexGet:
        return _readRecordIndexGet();
      case Tag.RecordNameGet:
        return _readRecordNameGet();
      case Tag.InstanceSet:
        return _readInstanceSet();
      case Tag.DynamicSet:
        return _readDynamicSet();
      case Tag.AbstractSuperPropertyGet:
        return _readAbstractSuperPropertyGet();
      case Tag.AbstractSuperPropertySet:
        return _readAbstractSuperPropertySet();
      case Tag.SuperPropertyGet:
        return _readSuperPropertyGet();
      case Tag.SuperPropertySet:
        return _readSuperPropertySet();
      case Tag.StaticGet:
        return _readStaticGet();
      case Tag.StaticTearOff:
        return _readStaticTearOff();
      case Tag.StaticSet:
        return _readStaticSet();
      case Tag.ConstructorTearOff:
        return _readConstructorTearOff();
      case Tag.TypedefTearOff:
        return _readTypedefTearOff();
      case Tag.RedirectingFactoryTearOff:
        return _readRedirectingFactoryTearOff();
      case Tag.InstanceGetterInvocation:
        return _readInstanceGetterInvocation();
      case Tag.DynamicInvocation:
        return _readDynamicInvocation();
      case Tag.FunctionInvocation:
        return _readFunctionInvocation();
      case Tag.FunctionTearOff:
        return _readFunctionTearOff();
      case Tag.LocalFunctionInvocation:
        return _readLocalFunctionInvocation();
      case Tag.EqualsNull:
        return _readEqualsNull();
      case Tag.EqualsCall:
        return _readEqualsCall();
      case Tag.AbstractSuperMethodInvocation:
        return _readAbstractSuperMethodInvocation();
      case Tag.SuperMethodInvocation:
        return _readSuperMethodInvocation();
      case Tag.ConstStaticInvocation:
        return _readConstStaticInvocation();
      case Tag.ConstConstructorInvocation:
        return _readConstConstructorInvocation();
      case Tag.Not:
        return _readNot();
      case Tag.NullCheck:
        return _readNullCheck();
      case Tag.LogicalExpression:
        return _readLogicalExpression();
      case Tag.ConditionalExpression:
        return _readConditionalExpression();
      case Tag.StringConcatenation:
        return _readStringConcatenation();
      case Tag.ListConcatenation:
        return _readListConcatenation();
      case Tag.SetConcatenation:
        return _readSetConcatenation();
      case Tag.MapConcatenation:
        return _readMapConcatenation();
      case Tag.InstanceCreation:
        return _readInstanceCreation();
      case Tag.FileUriExpression:
        return _readFileUriExpression();
      case Tag.IsExpression:
        return _readIsExpression();
      case Tag.AsExpression:
        return _readAsExpression();
      case Tag.PositiveIntLiteral:
        return _readPositiveIntLiteral();
      case Tag.NegativeIntLiteral:
        return _readNegativeIntLiteral();
      case Tag.BigIntLiteral:
        return _readBigIntLiteral();
      case Tag.DoubleLiteral:
        return _readDoubleLiteral();
      case Tag.TrueLiteral:
        return _readTrueLiteral();
      case Tag.FalseLiteral:
        return _readFalseLiteral();
      case Tag.NullLiteral:
        return _readNullLiteral();
      case Tag.SymbolLiteral:
        return _readSymbolLiteral();
      case Tag.TypeLiteral:
        return _readTypeLiteral();
      case Tag.Rethrow:
        return _readRethrow();
      case Tag.Throw:
        return _readThrow();
      case Tag.ListLiteral:
        return _readListLiteral();
      case Tag.ConstListLiteral:
        return _readConstListLiteral();
      case Tag.SetLiteral:
        return _readSetLiteral();
      case Tag.ConstSetLiteral:
        return _readConstSetLiteral();
      case Tag.MapLiteral:
        return _readMapLiteral();
      case Tag.ConstMapLiteral:
        return _readConstMapLiteral();
      case Tag.RecordLiteral:
        return _readRecordLiteral();
      case Tag.ConstRecordLiteral:
        return _readConstRecordLiteral();
      case Tag.AwaitExpression:
        return _readAwaitExpression();
      case Tag.FunctionExpression:
        return _readFunctionExpression();
      case Tag.Let:
        return _readLet();
      case Tag.BlockExpression:
        return _readBlockExpression();
      case Tag.Instantiation:
        return _readInstantiation();
      case Tag.SwitchExpression:
        return _readSwitchExpression();
      case Tag.PatternAssignment:
        return _readPatternAssignment();
      case Tag.FileUriConstantExpression:
        return _readFileUriConstantExpression();
      default:
        throw fail('unexpected expression tag: $tag');
    }
  }

  Expression _readLoadLibrary() {
    int offset = readOffset();
    return new LoadLibrary(readLibraryDependencyReference())
      ..fileOffset = offset;
  }

  Expression _readCheckLibraryIsLoaded() {
    int offset = readOffset();
    return new CheckLibraryIsLoaded(readLibraryDependencyReference())
      ..fileOffset = offset;
  }

  Expression _readInvalidExpression() {
    int offset = readOffset();
    return new InvalidExpression(
        readStringOrNullIfEmpty(), readExpressionOption())
      ..fileOffset = offset;
  }

  Expression _readVariableGet() {
    int offset = readOffset();
    return new VariableGet(readVariableReference(), readDartTypeOption())
      ..fileOffset = offset;
  }

  Expression _readSpecializedVariableGet(int tagByte) {
    int index = tagByte & Tag.SpecializedPayloadMask;
    int offset = readOffset();
    readUInt30(); // offset of the variable declaration in the binary.
    return new VariableGet(variableStack[index])..fileOffset = offset;
  }

  Expression _readVariableSet() {
    int offset = readOffset();
    return new VariableSet(readVariableReference(), readExpression())
      ..fileOffset = offset;
  }

  Expression _readSpecializedVariableSet(int tagByte) {
    int index = tagByte & Tag.SpecializedPayloadMask;
    int offset = readOffset();
    readUInt30(); // offset of the variable declaration in the binary.
    return new VariableSet(variableStack[index], readExpression())
      ..fileOffset = offset;
  }

  Expression _readInstanceGet() {
    InstanceAccessKind kind = InstanceAccessKind.values[readByte()];
    int offset = readOffset();
    return new InstanceGet.byReference(kind, readExpression(), readName(),
        resultType: readDartType(),
        interfaceTargetReference: readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readInstanceTearOff() {
    InstanceAccessKind kind = InstanceAccessKind.values[readByte()];
    int offset = readOffset();
    return new InstanceTearOff.byReference(kind, readExpression(), readName(),
        resultType: readDartType(),
        interfaceTargetReference: readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readDynamicGet() {
    DynamicAccessKind kind = DynamicAccessKind.values[readByte()];
    int offset = readOffset();
    return new DynamicGet(kind, readExpression(), readName())
      ..fileOffset = offset;
  }

  Expression _readRecordIndexGet() {
    int offset = readOffset();
    Expression receiver = readExpression();
    RecordType receiverType = readDartType() as RecordType;
    int index = readUInt30();
    return RecordIndexGet(receiver, receiverType, index)..fileOffset = offset;
  }

  Expression _readRecordNameGet() {
    int offset = readOffset();
    Expression receiver = readExpression();
    RecordType receiverType = readDartType() as RecordType;
    String name = readStringReference();
    return RecordNameGet(receiver, receiverType, name)..fileOffset = offset;
  }

  Expression _readInstanceSet() {
    InstanceAccessKind kind = InstanceAccessKind.values[readByte()];
    int offset = readOffset();
    return new InstanceSet.byReference(
        kind, readExpression(), readName(), readExpression(),
        interfaceTargetReference: readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readDynamicSet() {
    DynamicAccessKind kind = DynamicAccessKind.values[readByte()];
    int offset = readOffset();
    return new DynamicSet(kind, readExpression(), readName(), readExpression())
      ..fileOffset = offset;
  }

  Expression _readAbstractSuperPropertyGet() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new AbstractSuperPropertyGet.byReference(
        readName(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readAbstractSuperPropertySet() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new AbstractSuperPropertySet.byReference(
        readName(), readExpression(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readSuperPropertyGet() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new SuperPropertyGet.byReference(
        readName(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readSuperPropertySet() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new SuperPropertySet.byReference(
        readName(), readExpression(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readStaticGet() {
    int offset = readOffset();
    return new StaticGet.byReference(readNonNullMemberReference())
      ..fileOffset = offset;
  }

  Expression _readConstructorTearOff() {
    int offset = readOffset();
    Reference constructorReference = readNonNullMemberReference();
    return new ConstructorTearOff.byReference(constructorReference)
      ..fileOffset = offset;
  }

  Expression _readTypedefTearOff() {
    int offset = readOffset();
    List<TypeParameter> typeParameters = readAndPushTypeParameterList();
    Expression expression = readExpression();
    List<DartType> typeArguments = readDartTypeList();
    typeParameterStack.length -= typeParameters.length;
    return new TypedefTearOff(typeParameters, expression, typeArguments)
      ..fileOffset = offset;
  }

  Expression _readRedirectingFactoryTearOff() {
    int offset = readOffset();
    Reference constructorReference = readNonNullMemberReference();
    return new RedirectingFactoryTearOff.byReference(constructorReference)
      ..fileOffset = offset;
  }

  Expression _readStaticTearOff() {
    int offset = readOffset();
    return new StaticTearOff.byReference(readNonNullMemberReference())
      ..fileOffset = offset;
  }

  Expression _readStaticSet() {
    int offset = readOffset();
    return new StaticSet.byReference(
        readNonNullMemberReference(), readExpression())
      ..fileOffset = offset;
  }

  Expression _readInstanceInvocation() {
    InstanceAccessKind kind = InstanceAccessKind.values[readByte()];
    int flags = readByte();
    int offset = readOffset();
    return new InstanceInvocation.byReference(
        kind, readExpression(), readName(), readArguments(),
        functionType: readDartType() as FunctionType,
        interfaceTargetReference: readNonNullInstanceMemberReference())
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readInstanceGetterInvocation() {
    InstanceAccessKind kind = InstanceAccessKind.values[readByte()];
    int flags = readByte();
    int offset = readOffset();
    Expression receiver = readExpression();
    Name name = readName();
    Arguments arguments = readArguments();
    DartType functionType = readDartType();
    // `const DynamicType()` is used to encode a missing function type.
    assert(functionType is FunctionType || functionType is DynamicType,
        "Unexpected function type $functionType for InstanceGetterInvocation");
    Reference interfaceTargetReference = readNonNullInstanceMemberReference();
    return new InstanceGetterInvocation.byReference(
        kind, receiver, name, arguments,
        functionType: functionType is FunctionType ? functionType : null,
        interfaceTargetReference: interfaceTargetReference)
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readDynamicInvocation() {
    DynamicAccessKind kind = DynamicAccessKind.values[readByte()];
    int flags = readByte();
    int offset = readOffset();
    return new DynamicInvocation(
        kind, readExpression(), readName(), readArguments())
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readFunctionInvocation() {
    FunctionAccessKind kind = FunctionAccessKind.values[readByte()];
    int offset = readOffset();
    Expression receiver = readExpression();
    Arguments arguments = readArguments();
    DartType functionType = readDartType();
    // `const DynamicType()` is used to encode a missing function type.
    assert(functionType is FunctionType || functionType is DynamicType,
        "Unexpected function type $functionType for FunctionInvocation");
    return new FunctionInvocation(kind, receiver, arguments,
        functionType: functionType is FunctionType ? functionType : null)
      ..fileOffset = offset;
  }

  Expression _readFunctionTearOff() {
    int offset = readOffset();
    return new FunctionTearOff(readExpression())..fileOffset = offset;
  }

  Expression _readLocalFunctionInvocation() {
    int offset = readOffset();
    VariableDeclaration variable = readVariableReference();
    return new LocalFunctionInvocation(variable, readArguments(),
        functionType: readDartType() as FunctionType)
      ..fileOffset = offset;
  }

  Expression _readEqualsNull() {
    int offset = readOffset();
    return new EqualsNull(readExpression())..fileOffset = offset;
  }

  Expression _readEqualsCall() {
    int offset = readOffset();
    return new EqualsCall.byReference(readExpression(), readExpression(),
        functionType: readDartType() as FunctionType,
        interfaceTargetReference: readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readAbstractSuperMethodInvocation() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new AbstractSuperMethodInvocation.byReference(
        readName(), readArguments(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readSuperMethodInvocation() {
    int offset = readOffset();
    addTransformerFlag(TransformerFlag.superCalls);
    return new SuperMethodInvocation.byReference(
        readName(), readArguments(), readNonNullInstanceMemberReference())
      ..fileOffset = offset;
  }

  Expression _readStaticInvocation() {
    int offset = readOffset();
    return new StaticInvocation.byReference(
        readNonNullMemberReference(), readArguments(),
        isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstStaticInvocation() {
    int offset = readOffset();
    return new StaticInvocation.byReference(
        readNonNullMemberReference(), readArguments(),
        isConst: true)
      ..fileOffset = offset;
  }

  Expression _readConstructorInvocation() {
    int offset = readOffset();
    return new ConstructorInvocation.byReference(
        readNonNullMemberReference(), readArguments(),
        isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstConstructorInvocation() {
    int offset = readOffset();
    return new ConstructorInvocation.byReference(
        readNonNullMemberReference(), readArguments(),
        isConst: true)
      ..fileOffset = offset;
  }

  Expression _readNot() {
    int offset = readOffset();
    return new Not(readExpression())..fileOffset = offset;
  }

  Expression _readNullCheck() {
    int offset = readOffset();
    return new NullCheck(readExpression())..fileOffset = offset;
  }

  Expression _readLogicalExpression() {
    int offset = readOffset();
    return new LogicalExpression(
        readExpression(), logicalOperatorToEnum(readByte()), readExpression())
      ..fileOffset = offset;
  }

  Expression _readConditionalExpression() {
    int offset = readOffset();
    return new ConditionalExpression(
        readExpression(),
        readExpression(),
        readExpression(),
        // TODO(johnniwinther): Change this to use `readDartType`.
        readDartTypeOption()!)
      ..fileOffset = offset;
  }

  Expression _readStringConcatenation() {
    int offset = readOffset();
    return new StringConcatenation(readExpressionList())..fileOffset = offset;
  }

  Expression _readListConcatenation() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new ListConcatenation(readExpressionList(),
        typeArgument: typeArgument)
      ..fileOffset = offset;
  }

  Expression _readSetConcatenation() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new SetConcatenation(readExpressionList(),
        typeArgument: typeArgument)
      ..fileOffset = offset;
  }

  Expression _readMapConcatenation() {
    int offset = readOffset();
    DartType keyType = readDartType();
    DartType valueType = readDartType();
    return new MapConcatenation(readExpressionList(),
        keyType: keyType, valueType: valueType)
      ..fileOffset = offset;
  }

  Expression _readInstanceCreation() {
    int offset = readOffset();
    Reference classReference = readNonNullClassReference();
    List<DartType> typeArguments = readDartTypeList();
    int fieldValueCount = readUInt30();
    Map<Reference, Expression> fieldValues = <Reference, Expression>{};
    for (int i = 0; i < fieldValueCount; i++) {
      final Reference fieldRef = readNonNullCanonicalNameReference().reference;
      final Expression value = readExpression();
      fieldValues[fieldRef] = value;
    }
    int assertCount = readUInt30();
    List<AssertStatement> asserts;

    if (!useGrowableLists && assertCount == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      asserts = emptyListOfAssertStatement;
    } else {
      asserts = new List<AssertStatement>.generate(
          assertCount, (_) => readStatement() as AssertStatement,
          growable: false);
    }
    List<Expression> unusedArguments = readExpressionList();
    return new InstanceCreation(
        classReference, typeArguments, fieldValues, asserts, unusedArguments)
      ..fileOffset = offset;
  }

  Expression _readFileUriExpression() {
    Uri fileUri = readUriReference();
    int offset = readOffset();
    return new FileUriExpression(readExpression(), fileUri)
      ..fileOffset = offset;
  }

  Expression _readIsExpression() {
    int offset = readOffset();
    int flags = readByte();
    return new IsExpression(readExpression(), readDartType())
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readAsExpression() {
    int offset = readOffset();
    int flags = readByte();
    return new AsExpression(readExpression(), readDartType())
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readStringLiteral() {
    int offset = readOffset();
    return new StringLiteral(readStringReference())..fileOffset = offset;
  }

  Expression _readSpecializedIntLiteral(int tagByte) {
    int biasedValue = tagByte & Tag.SpecializedPayloadMask;
    return new IntLiteral(biasedValue - Tag.SpecializedIntLiteralBias)
      ..fileOffset = readOffset();
  }

  Expression _readPositiveIntLiteral() {
    int offset = readOffset();
    int value = readUInt30();
    return new IntLiteral(value)..fileOffset = offset;
  }

  Expression _readNegativeIntLiteral() {
    int offset = readOffset();
    int value = -readUInt30();
    return new IntLiteral(value)..fileOffset = offset;
  }

  Expression _readBigIntLiteral() {
    int offset = readOffset();
    int value = int.parse(readStringReference());
    return new IntLiteral(value)..fileOffset = offset;
  }

  Expression _readDoubleLiteral() {
    int offset = readOffset();
    double value = readDouble();
    return new DoubleLiteral(value)..fileOffset = offset;
  }

  Expression _readTrueLiteral() {
    return new BoolLiteral(true)..fileOffset = readOffset();
  }

  Expression _readFalseLiteral() {
    return new BoolLiteral(false)..fileOffset = readOffset();
  }

  Expression _readNullLiteral() {
    return new NullLiteral()..fileOffset = readOffset();
  }

  Expression _readSymbolLiteral() {
    int offset = readOffset();
    String value = readStringReference();
    return new SymbolLiteral(value)..fileOffset = offset;
  }

  Expression _readTypeLiteral() {
    int offset = readOffset();
    return new TypeLiteral(readDartType())..fileOffset = offset;
  }

  Expression _readThisLiteral() {
    return new ThisExpression()..fileOffset = readOffset();
  }

  Expression _readRethrow() {
    int offset = readOffset();
    return new Rethrow()..fileOffset = offset;
  }

  Expression _readThrow() {
    int offset = readOffset();
    int flags = readByte();
    return new Throw(readExpression())
      ..fileOffset = offset
      ..flags = flags;
  }

  Expression _readListLiteral() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new ListLiteral(readExpressionList(),
        typeArgument: typeArgument, isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstListLiteral() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new ListLiteral(readExpressionList(),
        typeArgument: typeArgument, isConst: true)
      ..fileOffset = offset;
  }

  Expression _readSetLiteral() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new SetLiteral(readExpressionList(),
        typeArgument: typeArgument, isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstSetLiteral() {
    int offset = readOffset();
    DartType typeArgument = readDartType();
    return new SetLiteral(readExpressionList(),
        typeArgument: typeArgument, isConst: true)
      ..fileOffset = offset;
  }

  Expression _readMapLiteral() {
    int offset = readOffset();
    DartType keyType = readDartType();
    DartType valueType = readDartType();
    return new MapLiteral(readMapLiteralEntryList(),
        keyType: keyType, valueType: valueType, isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstMapLiteral() {
    int offset = readOffset();
    DartType keyType = readDartType();
    DartType valueType = readDartType();
    return new MapLiteral(readMapLiteralEntryList(),
        keyType: keyType, valueType: valueType, isConst: true)
      ..fileOffset = offset;
  }

  Expression _readRecordLiteral() {
    int offset = readOffset();
    List<Expression> positional = readExpressionList();
    List<NamedExpression> named = readNamedExpressionList();
    RecordType recordType = readDartType() as RecordType;
    return new RecordLiteral(positional, named, recordType, isConst: false)
      ..fileOffset = offset;
  }

  Expression _readConstRecordLiteral() {
    int offset = readOffset();
    List<Expression> positional = readExpressionList();
    List<NamedExpression> named = readNamedExpressionList();
    RecordType recordType = readDartType() as RecordType;
    return new RecordLiteral(positional, named, recordType, isConst: true)
      ..fileOffset = offset;
  }

  Expression _readAwaitExpression() {
    int offset = readOffset();
    return new AwaitExpression(readExpression())
      ..fileOffset = offset
      ..runtimeCheckType = readDartTypeOption();
  }

  Expression _readFunctionExpression() {
    int offset = readOffset();
    return new FunctionExpression(readFunctionNode())..fileOffset = offset;
  }

  Expression _readLet() {
    int offset = readOffset();
    VariableDeclaration variable = readVariableDeclaration();
    int stackHeight = variableStack.length;
    pushVariableDeclaration(variable);
    Expression body = readExpression();
    variableStack.length = stackHeight;
    return new Let(variable, body)..fileOffset = offset;
  }

  Expression _readBlockExpression() {
    int offset = readOffset();
    int stackHeight = variableStack.length;
    List<Statement> statements = readStatementListAlwaysGrowable();
    Expression value = readExpression();
    variableStack.length = stackHeight;
    return new BlockExpression(new Block(statements), value)
      ..fileOffset = offset;
  }

  Expression _readInstantiation() {
    int offset = readOffset();
    Expression expression = readExpression();
    List<DartType> typeArguments = readDartTypeList();
    return new Instantiation(expression, typeArguments)..fileOffset = offset;
  }

  Expression _readConstantExpression() {
    int offset = readOffset();
    DartType type = readDartType();
    Constant constant = readConstantReference();
    return new ConstantExpression(constant, type)..fileOffset = offset;
  }

  Expression _readFileUriConstantExpression() {
    int offset = readOffset();
    Uri fileUri = readUriReference();
    DartType type = readDartType();
    Constant constant = readConstantReference();
    return new FileUriConstantExpression(constant, type: type, fileUri: fileUri)
      ..fileOffset = offset;
  }

  List<MapLiteralEntry> readMapLiteralEntryList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfMapLiteralEntry;
    }
    return new List<MapLiteralEntry>.generate(length, (_) => readMapEntry(),
        growable: useGrowableLists);
  }

  MapLiteralEntry readMapEntry() {
    return new MapLiteralEntry(readExpression(), readExpression());
  }

  Pattern _readPattern() {
    int tag = readByte();
    switch (tag) {
      case Tag.AndPattern:
        return _readAndPattern();
      case Tag.AssignedVariablePattern:
        return _readAssignedVariablePattern();
      case Tag.CastPattern:
        return _readCastPattern();
      case Tag.ConstantPattern:
        return _readConstantPattern();
      case Tag.InvalidPattern:
        return _readInvalidPattern();
      case Tag.ListPattern:
        return _readListPattern();
      case Tag.MapPattern:
        return _readMapPattern();
      case Tag.NamedPattern:
        return _readNamedPattern();
      case Tag.NullAssertPattern:
        return _readNullAssertPattern();
      case Tag.NullCheckPattern:
        return _readNullCheckPattern();
      case Tag.ObjectPattern:
        return _readObjectPattern();
      case Tag.OrPattern:
        return _readOrPattern();
      case Tag.RecordPattern:
        return _readRecordPattern();
      case Tag.RelationalPattern:
        return _readRelationalPattern();
      case Tag.RestPattern:
        return _readRestPattern();
      case Tag.VariablePattern:
        return _readVariablePattern();
      case Tag.WildcardPattern:
        return _readWildcardPattern();
      default:
        throw fail('unexpected pattern tag: $tag');
    }
  }

  Pattern? _readOptionalPattern() {
    return readAndCheckOptionTag() ? _readPattern() : null;
  }

  List<Pattern> _readPatternList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfPattern;
    }
    return new List<Pattern>.generate(length, (_) => _readPattern(),
        growable: useGrowableLists);
  }

  List<NamedPattern> _readNamedPatternList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfNamedPattern;
    }
    return new List<NamedPattern>.generate(
        length, (_) => _readPattern() as NamedPattern,
        growable: useGrowableLists);
  }

  List<VariableDeclaration> _readVariableReferenceList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfVariableDeclaration;
    }
    return new List<VariableDeclaration>.generate(
        length, (_) => readVariableReference(),
        growable: useGrowableLists);
  }

  List<MapPatternEntry> _readMapPatternEntryList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfMapPatternEntry;
    }
    return new List<MapPatternEntry>.generate(
        length, (_) => _readMapPatternEntry(),
        growable: useGrowableLists);
  }

  AndPattern _readAndPattern() {
    int fileOffset = readOffset();
    return new AndPattern(_readPattern(), _readPattern())
      ..fileOffset = fileOffset;
  }

  AssignedVariablePattern _readAssignedVariablePattern() {
    int fileOffset = readOffset();
    VariableDeclaration variable = readVariableReference();
    DartType? matchedType = readDartTypeOption();
    bool needsCheck = readByte() == 1;
    return AssignedVariablePattern(variable)
      ..fileOffset = fileOffset
      ..matchedValueType = matchedType
      ..needsCast = needsCheck;
  }

  CastPattern _readCastPattern() {
    int fileOffset = readOffset();
    return new CastPattern(_readPattern(), readDartType())
      ..fileOffset = fileOffset;
  }

  ConstantPattern _readConstantPattern() {
    int fileOffset = readOffset();
    Expression expression = readExpression();
    DartType? expressionType = readDartTypeOption();
    Reference? equalsTargetReference = readNullableMemberReference();
    FunctionType? equalsType = readDartTypeOption() as FunctionType?;
    return new ConstantPattern(expression)
      ..expressionType = expressionType
      ..equalsTargetReference = equalsTargetReference
      ..equalsType = equalsType
      ..fileOffset = fileOffset;
  }

  InvalidPattern _readInvalidPattern() {
    int fileOffset = readOffset();
    Expression invalidExpression = readExpression();
    List<VariableDeclaration> declaredVariables =
        readAndPushVariableDeclarationList();
    return InvalidPattern(invalidExpression,
        declaredVariables: declaredVariables)
      ..fileOffset = fileOffset;
  }

  ListPattern _readListPattern() {
    int fileOffset = readOffset();
    DartType? typeArgument = readDartTypeOption();
    List<Pattern> patterns = _readPatternList();
    DartType? requiredType = readDartTypeOption();
    DartType? matchedValueType = readDartTypeOption();
    int flags = readByte();
    bool needsCheck = flags & 0x1 != 0;
    bool hasRestPattern = flags & 0x2 != 0;
    DartType? lookupType = readDartTypeOption();
    Reference? lengthTargetReference = readNullableMemberReference();
    DartType? lengthType = readDartTypeOption();
    Reference? lengthCheckTargetReference = readNullableMemberReference();
    FunctionType? lengthCheckType = readDartTypeOption() as FunctionType?;
    Reference? sublistTargetReference = readNullableMemberReference();
    FunctionType? sublistType = readDartTypeOption() as FunctionType?;
    Reference? minusTargetReference = readNullableMemberReference();
    FunctionType? minusType = readDartTypeOption() as FunctionType?;
    Reference? indexGetTargetReference = readNullableMemberReference();
    FunctionType? indexGetType = readDartTypeOption() as FunctionType?;
    return new ListPattern(typeArgument, patterns)
      ..requiredType = requiredType
      ..matchedValueType = matchedValueType
      ..needsCheck = needsCheck
      ..lookupType = lookupType
      ..hasRestPattern = hasRestPattern
      ..lengthTargetReference = lengthTargetReference
      ..lengthType = lengthType
      ..lengthCheckTargetReference = lengthCheckTargetReference
      ..lengthCheckType = lengthCheckType
      ..sublistTargetReference = sublistTargetReference
      ..sublistType = sublistType
      ..minusTargetReference = minusTargetReference
      ..minusType = minusType
      ..indexGetTargetReference = indexGetTargetReference
      ..indexGetType = indexGetType
      ..fileOffset = fileOffset;
  }

  MapPattern _readMapPattern() {
    int fileOffset = readOffset();
    DartType? keyType = readDartTypeOption();
    DartType? valueType = readDartTypeOption();
    List<MapPatternEntry> entries = _readMapPatternEntryList();
    DartType? requiredType = readDartTypeOption();
    DartType? matchedValueType = readDartTypeOption();
    int flags = readByte();
    bool needsCheck = flags & 0x1 != 0;
    DartType? lookupType = readDartTypeOption();
    Reference? containsKeyTargetReference = readNullableMemberReference();
    FunctionType? containsKeyType = readDartTypeOption() as FunctionType?;
    Reference? indexGetTargetReference = readNullableMemberReference();
    FunctionType? indexGetType = readDartTypeOption() as FunctionType?;
    return new MapPattern(keyType, valueType, entries)
      ..requiredType = requiredType
      ..matchedValueType = matchedValueType
      ..needsCheck = needsCheck
      ..lookupType = lookupType
      ..containsKeyTargetReference = containsKeyTargetReference
      ..containsKeyType = containsKeyType
      ..indexGetTargetReference = indexGetTargetReference
      ..indexGetType = indexGetType
      ..fileOffset = fileOffset;
  }

  NamedPattern _readNamedPattern() {
    int fileOffset = readOffset();
    String name = readStringReference();
    Pattern pattern = _readPattern();
    Name fieldName = readName();
    ObjectAccessKind accessKind = ObjectAccessKind.values[readByte()];
    Reference? targetReference = readNullableMemberReference();
    DartType? resultType = readDartTypeOption();
    RecordType? recordType = readDartTypeOption() as RecordType?;
    int recordFieldIndex = readUInt30();
    FunctionType? functionType = readDartTypeOption() as FunctionType?;
    List<DartType>? typeArguments;
    if (readAndCheckOptionTag()) {
      typeArguments = readDartTypeList();
    }
    return new NamedPattern(name, pattern)
      ..fieldName = fieldName
      ..accessKind = accessKind
      ..targetReference = targetReference
      ..resultType = resultType
      ..recordType = recordType
      ..recordFieldIndex = recordFieldIndex
      ..functionType = functionType
      ..typeArguments = typeArguments
      ..fileOffset = fileOffset;
  }

  NullAssertPattern _readNullAssertPattern() {
    int fileOffset = readOffset();
    Pattern pattern = _readPattern();
    return new NullAssertPattern(pattern)..fileOffset = fileOffset;
  }

  NullCheckPattern _readNullCheckPattern() {
    int fileOffset = readOffset();
    Pattern pattern = _readPattern();
    return new NullCheckPattern(pattern)..fileOffset = fileOffset;
  }

  ObjectPattern _readObjectPattern() {
    int fileOffset = readOffset();
    DartType type = readDartType();
    List<NamedPattern> fields = _readNamedPatternList();
    DartType? matchedType = readDartTypeOption();
    bool needsCheck = readByte() == 1;
    DartType? objectType = readDartTypeOption();
    return new ObjectPattern(type, fields)
      ..matchedValueType = matchedType
      ..needsCheck = needsCheck
      ..lookupType = objectType
      ..fileOffset = fileOffset;
  }

  OrPattern _readOrPattern() {
    int fileOffset = readOffset();
    Pattern left = _readPattern();
    Pattern right = _readPattern();
    List<VariableDeclaration> orPatternJointVariables =
        _readVariableReferenceList();
    return new OrPattern(left, right,
        orPatternJointVariables: orPatternJointVariables)
      ..fileOffset = fileOffset;
  }

  RecordPattern _readRecordPattern() {
    int fileOffset = readOffset();
    List<Pattern> patterns = _readPatternList();
    RecordType? type = readDartTypeOption() as RecordType?;
    DartType? matchedType = readDartTypeOption();
    bool needsCheck = readByte() == 1;
    RecordType? recordType = readDartTypeOption() as RecordType?;
    return new RecordPattern(patterns)
      ..requiredType = type
      ..matchedValueType = matchedType
      ..needsCheck = needsCheck
      ..lookupType = recordType
      ..fileOffset = fileOffset;
  }

  RelationalPattern _readRelationalPattern() {
    int fileOffset = readOffset();
    RelationalPatternKind kind = RelationalPatternKind.values[readByte()];
    Expression expression = readExpression();
    DartType? expressionType = readDartTypeOption();
    DartType? matchedType = readDartTypeOption();
    RelationalAccessKind accessKind = RelationalAccessKind.values[readByte()];
    Name name = readName();
    Reference? targetReference = readNullableMemberReference();
    List<DartType>? typeArguments;
    if (readAndCheckOptionTag()) {
      typeArguments = readDartTypeList();
    }
    FunctionType? functionType = readDartTypeOption() as FunctionType?;
    return new RelationalPattern(kind, expression)
      ..expressionType = expressionType
      ..matchedValueType = matchedType
      ..accessKind = accessKind
      ..name = name
      ..targetReference = targetReference
      ..typeArguments = typeArguments
      ..functionType = functionType
      ..fileOffset = fileOffset;
  }

  RestPattern _readRestPattern() {
    int fileOffset = readOffset();
    Pattern? subPattern = _readOptionalPattern();
    return new RestPattern(subPattern)..fileOffset = fileOffset;
  }

  VariablePattern _readVariablePattern() {
    int fileOffset = readOffset();
    DartType? type = readDartTypeOption();
    VariableDeclaration variable = readVariableDeclaration();
    DartType? matchedType = readDartTypeOption();
    return new VariablePattern(type, variable)
      ..matchedValueType = matchedType
      ..fileOffset = fileOffset;
  }

  WildcardPattern _readWildcardPattern() {
    int fileOffset = readOffset();
    DartType? type = readDartTypeOption();
    return new WildcardPattern(type)..fileOffset = fileOffset;
  }

  MapPatternEntry _readMapPatternEntry() {
    int tag = readByte();
    switch (tag) {
      case Tag.MapPatternEntry:
        int fileOffset = readOffset();
        Expression key = readExpression();
        Pattern value = _readPattern();
        DartType? keyType = readDartTypeOption();
        return new MapPatternEntry(key, value)
          ..keyType = keyType
          ..fileOffset = fileOffset;
      case Tag.MapPatternRestEntry:
        int fileOffset = readOffset();
        return new MapPatternRestEntry()..fileOffset = fileOffset;
      default:
        throw fail('unexpected pattern tag: $tag');
    }
  }

  SwitchExpression _readSwitchExpression() {
    int fileOffset = readOffset();
    Expression expression = readExpression();
    DartType? expressionType = readDartTypeOption();
    List<SwitchExpressionCase> cases = _readSwitchExpressionCaseList();
    DartType? staticType = readDartTypeOption();
    return new SwitchExpression(expression, cases)
      ..expressionType = expressionType
      ..staticType = staticType
      ..fileOffset = fileOffset;
  }

  List<SwitchExpressionCase> _readSwitchExpressionCaseList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfSwitchExpressionCase;
    }
    return new List<SwitchExpressionCase>.generate(
        length, (_) => _readSwitchExpressionCase(),
        growable: useGrowableLists);
  }

  SwitchExpressionCase _readSwitchExpressionCase() {
    int fileOffset = readOffset();
    PatternGuard patternGuard = _readPatternGuard();
    Expression expression = readExpression();
    return new SwitchExpressionCase(patternGuard, expression)
      ..fileOffset = fileOffset;
  }

  PatternGuard _readPatternGuard() {
    int fileOffset = readOffset();
    Pattern pattern = _readPattern();
    Expression? guard = readExpressionOption();
    return new PatternGuard(pattern, guard)..fileOffset = fileOffset;
  }

  IfCaseStatement _readIfCaseStatement() {
    int fileOffset = readOffset();
    Expression expression = readExpression();
    PatternGuard patternGuard = _readPatternGuard();
    Statement then = readStatement();
    Statement? otherwise = readStatementOption();
    DartType? matchedValueType = readDartTypeOption();
    return new IfCaseStatement(expression, patternGuard, then, otherwise)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  PatternAssignment _readPatternAssignment() {
    int fileOffset = readOffset();
    Pattern pattern = _readPattern();
    Expression expression = readExpression();
    DartType? matchedValueType = readDartTypeOption();
    return new PatternAssignment(pattern, expression)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  PatternVariableDeclaration _readPatternVariableDeclaration() {
    int fileOffset = readOffset();
    Pattern pattern = _readPattern();
    Expression expression = readExpression();
    bool isFinal = readByte() == 1;
    DartType? matchedValueType = readDartTypeOption();
    return new PatternVariableDeclaration(pattern, expression, isFinal: isFinal)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  PatternSwitchStatement _readPatternSwitchStatement() {
    int fileOffset = readOffset();
    Expression expression = readExpression();
    DartType? expressionType = readDartTypeOption();
    int count = readUInt30();
    List<PatternSwitchCase> cases;
    if (!useGrowableLists && count == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      cases = emptyListOfPatternSwitchCase;
    } else {
      cases = new List<PatternSwitchCase>.generate(
          count,
          (_) => new PatternSwitchCase([], [], dummyStatement,
              isDefault: false,
              hasLabel: false,
              jointVariables: [],
              jointVariableFirstUseOffsets: null),
          growable: useGrowableLists);
    }
    switchCaseStack.addAll(cases);
    for (int i = 0; i < cases.length; ++i) {
      _readPatternSwitchCaseInto(cases[i]);
    }
    switchCaseStack.length -= count;
    return new PatternSwitchStatement(expression, cases)
      ..expressionTypeInternal = expressionType
      ..fileOffset = fileOffset;
  }

  void _readPatternSwitchCaseInto(PatternSwitchCase caseNode) {
    int variableCount = readUInt30();
    for (int i = 0; i < variableCount; ++i) {
      caseNode.jointVariables.add(readVariableDeclaration()..parent = caseNode);
    }
    int caseCount = readUInt30();
    for (int i = 0; i < caseCount; ++i) {
      caseNode.caseOffsets.add(readOffset());
      caseNode.patternGuards.add(_readPatternGuard()..parent = caseNode);
    }
    int flags = readByte();
    caseNode.isDefault = (flags & 0x1) != 0;
    caseNode.hasLabel = (flags & 0x2) != 0;
    caseNode.body = readStatement()..parent = caseNode;
  }

  List<Statement> readStatementListAlwaysGrowable() {
    int length = readUInt30();
    return new List<Statement>.generate(length, (_) => readStatement(),
        growable: true);
  }

  Statement? readStatementOrNullIfEmpty() {
    Statement node = readStatement();
    if (node is EmptyStatement) {
      return null;
    } else {
      return node;
    }
  }

  Statement? readStatementOption() {
    return readAndCheckOptionTag() ? readStatement() : null;
  }

  Statement readStatement() {
    int tag = readByte();
    switch (tag) {
      // 23.90% (14.98% - 41.04%).
      case Tag.ReturnStatement:
        return _readReturnStatement();

      // 22.74% (15.27% - 32.36%).
      case Tag.ExpressionStatement:
        return _readExpressionStatement();

      // 21.29% (17.70% - 25.00%).
      case Tag.Block:
        return _readBlock();

      // 9.62% (6.92% - 12.64%).
      case Tag.VariableDeclaration:
        return _readVariableDeclaration();

      // 9.28% (6.69% - 11.18%).
      case Tag.EmptyStatement:
        return _readEmptyStatement();

      // 9.06% (6.03% - 11.58%).
      case Tag.IfStatement:
        return _readIfStatement();

      // The rest is < 2% on average in sampled dills.
      case Tag.AssertBlock:
        return _readAssertBlock();
      case Tag.AssertStatement:
        return _readAssertStatement();
      case Tag.LabeledStatement:
        return _readLabeledStatement();
      case Tag.BreakStatement:
        return _readBreakStatement();
      case Tag.WhileStatement:
        return _readWhileStatement();
      case Tag.DoStatement:
        return _readDoStatement();
      case Tag.ForStatement:
        return _readForStatement();
      case Tag.ForInStatement:
      case Tag.AsyncForInStatement:
        return _readForInStatement(tag);
      case Tag.SwitchStatement:
        return _readSwitchStatement();
      case Tag.ContinueSwitchStatement:
        return _readContinueSwitchStatement();
      case Tag.TryCatch:
        return _readTryCatch();
      case Tag.TryFinally:
        return _readTryFinally();
      case Tag.YieldStatement:
        return _readYieldStatement();
      case Tag.FunctionDeclaration:
        return _readFunctionDeclaration();
      case Tag.IfCaseStatement:
        return _readIfCaseStatement();
      case Tag.PatternVariableDeclaration:
        return _readPatternVariableDeclaration();
      case Tag.PatternSwitchStatement:
        return _readPatternSwitchStatement();
      default:
        throw fail('unexpected statement tag: $tag');
    }
  }

  Statement _readExpressionStatement() {
    return new ExpressionStatement(readExpression());
  }

  Statement _readEmptyStatement() {
    return new EmptyStatement();
  }

  Statement _readAssertStatement() {
    return new AssertStatement(readExpression(),
        conditionStartOffset: readOffset(),
        conditionEndOffset: readOffset(),
        message: readExpressionOption());
  }

  Statement _readLabeledStatement() {
    LabeledStatement label = new LabeledStatement(null);
    labelStack.add(label);
    int offset = readOffset();
    label.fileOffset = offset;
    label.body = readStatement()..parent = label;
    labelStack.removeLast();
    return label;
  }

  Statement _readBreakStatement() {
    int offset = readOffset();
    int index = readUInt30();
    return new BreakStatement(labelStack[labelStackBase + index])
      ..fileOffset = offset;
  }

  Statement _readWhileStatement() {
    int offset = readOffset();
    return new WhileStatement(readExpression(), readStatement())
      ..fileOffset = offset;
  }

  Statement _readDoStatement() {
    int offset = readOffset();
    return new DoStatement(readStatement(), readExpression())
      ..fileOffset = offset;
  }

  Statement _readForStatement() {
    int variableStackHeight = variableStack.length;
    int offset = readOffset();
    List<VariableDeclaration> variables = readAndPushVariableDeclarationList();
    Expression? condition = readExpressionOption();
    List<Expression> updates = readExpressionList();
    Statement body = readStatement();
    variableStack.length = variableStackHeight;
    return new ForStatement(variables, condition, updates, body)
      ..fileOffset = offset;
  }

  Statement _readForInStatement(int tag) {
    bool isAsync = tag == Tag.AsyncForInStatement;
    int variableStackHeight = variableStack.length;
    int offset = readOffset();
    int bodyOffset = readOffset();
    VariableDeclaration variable = readAndPushVariableDeclaration();
    Expression iterable = readExpression();
    Statement body = readStatement();
    variableStack.length = variableStackHeight;
    return new ForInStatement(variable, iterable, body, isAsync: isAsync)
      ..fileOffset = offset
      ..bodyOffset = bodyOffset;
  }

  Statement _readSwitchStatement() {
    int offset = readOffset();
    bool isExplicitlyExhaustive = readByte() == 1;
    Expression expression = readExpression();
    DartType? expressionType = readDartTypeOption();
    int count = readUInt30();
    List<SwitchCase> cases;
    if (!useGrowableLists && count == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      cases = emptyListOfSwitchCase;
    } else {
      cases = new List<SwitchCase>.generate(
          count,
          (_) => new SwitchCase(<Expression>[], <int>[], dummyStatement,
              isDefault: false),
          growable: useGrowableLists);
    }
    switchCaseStack.addAll(cases);
    for (int i = 0; i < cases.length; ++i) {
      _readSwitchCaseInto(cases[i]);
    }
    switchCaseStack.length -= count;
    return new SwitchStatement(expression, cases,
        isExplicitlyExhaustive: isExplicitlyExhaustive)
      ..expressionTypeInternal = expressionType
      ..fileOffset = offset;
  }

  Statement _readContinueSwitchStatement() {
    int offset = readOffset();
    int index = readUInt30();
    return new ContinueSwitchStatement(
        switchCaseStack[switchCaseStackBase + index])
      ..fileOffset = offset;
  }

  Statement _readIfStatement() {
    int offset = readOffset();
    return new IfStatement(
        readExpression(), readStatement(), readStatementOrNullIfEmpty())
      ..fileOffset = offset;
  }

  Statement _readReturnStatement() {
    int offset = readOffset();
    return new ReturnStatement(readExpressionOption())..fileOffset = offset;
  }

  Statement _readTryCatch() {
    int offset = readOffset();
    Statement body = readStatement();
    int flags = readByte();
    return new TryCatch(body, readCatchList(), isSynthetic: flags & 2 == 2)
      ..fileOffset = offset;
  }

  Statement _readTryFinally() {
    int offset = readOffset();
    return new TryFinally(readStatement(), readStatement())
      ..fileOffset = offset;
  }

  Statement _readYieldStatement() {
    int offset = readOffset();
    int flags = readByte();
    return new YieldStatement(readExpression(),
        isYieldStar: flags & YieldStatement.FlagYieldStar != 0)
      ..fileOffset = offset;
  }

  Statement _readVariableDeclaration() {
    VariableDeclaration variable = readVariableDeclaration();
    variableStack.add(variable); // Will be popped by the enclosing scope.
    return variable;
  }

  Statement _readFunctionDeclaration() {
    int offset = readOffset();
    VariableDeclaration variable = readVariableDeclaration();
    variableStack.add(variable); // Will be popped by the enclosing scope.
    return new FunctionDeclaration(variable, readFunctionNode())
      ..fileOffset = offset;
  }

  void _readSwitchCaseInto(SwitchCase caseNode) {
    int offset = readOffset();
    caseNode.fileOffset = offset;
    int length = readUInt30();
    for (int i = 0; i < length; ++i) {
      caseNode.expressionOffsets.add(readOffset());
      caseNode.expressions.add(readExpression()..parent = caseNode);
    }
    caseNode.isDefault = readByte() == 1;
    caseNode.body = readStatement()..parent = caseNode;
  }

  List<Catch> readCatchList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfCatch;
    }
    return new List<Catch>.generate(length, (_) => readCatch(),
        growable: useGrowableLists);
  }

  Catch readCatch() {
    int variableStackHeight = variableStack.length;
    int offset = readOffset();
    DartType guard = readDartType();
    VariableDeclaration? exception = readAndPushVariableDeclarationOption();
    VariableDeclaration? stackTrace = readAndPushVariableDeclarationOption();
    Statement body = readStatement();
    variableStack.length = variableStackHeight;
    return new Catch(exception, body, guard: guard, stackTrace: stackTrace)
      ..fileOffset = offset;
  }

  Block _readBlock() {
    int stackHeight = variableStack.length;
    int offset = readOffset();
    int endOffset = readOffset();
    List<Statement> body = readStatementListAlwaysGrowable();
    variableStack.length = stackHeight;
    return new Block(body)
      ..fileOffset = offset
      ..fileEndOffset = endOffset;
  }

  AssertBlock _readAssertBlock() {
    int stackHeight = variableStack.length;
    List<Statement> body = readStatementListAlwaysGrowable();
    variableStack.length = stackHeight;
    return new AssertBlock(body);
  }

  Supertype readSupertype() {
    InterfaceType type = readDartType(forSupertype: true) as InterfaceType;
    assert(
        type.nullability == _currentLibrary!.nonNullable,
        "In serialized form supertypes should have Nullability.legacy if they "
        "are in a library that is opted out of the NNBD feature.  If they are "
        "in an opted-in library, they should have Nullability.nonNullable.");
    return new Supertype.byReference(type.classReference, type.typeArguments);
  }

  Supertype? readSupertypeOption() {
    return readAndCheckOptionTag() ? readSupertype() : null;
  }

  List<Supertype> readSupertypeList([List<Supertype>? result]) {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfSupertype;
    }
    if (result != null) {
      for (int i = 0; i < length; ++i) {
        result.add(readSupertype());
      }
      return result;
    } else {
      return new List<Supertype>.generate(length, (_) => readSupertype(),
          growable: useGrowableLists);
    }
  }

  List<DartType> readDartTypeList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfDartType;
    }
    return new List<DartType>.generate(length, (_) => readDartType(),
        growable: useGrowableLists);
  }

  List<NamedType> readNamedTypeList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use a
      // constant one for the empty list.
      return emptyListOfNamedType;
    }
    return new List<NamedType>.generate(length, (_) => readNamedType(),
        growable: useGrowableLists);
  }

  NamedType readNamedType() {
    String name = readStringReference();
    DartType type = readDartType();
    int flags = readByte();
    return new NamedType(name, type,
        isRequired: (flags & NamedType.FlagRequiredNamedType) != 0);
  }

  DartType? readDartTypeOption() {
    return readAndCheckOptionTag() ? readDartType() : null;
  }

  DartType readDartType({bool forSupertype = false}) {
    int tag = readByte();
    switch (tag) {
      // 67.66% (59.53% - 77.94%).
      case Tag.SimpleInterfaceType:
        return _readSimpleInterfaceType(forSupertype);

      // 11.64% (9.11% - 15.49%).
      case Tag.SimpleFunctionType:
        return _readSimpleFunctionType();

      // 7.33% (5.11% - 8.76%).
      case Tag.InterfaceType:
        return _readInterfaceType();

      // 5.84% (4.13% - 8.86%).
      case Tag.VoidType:
        return _readVoidType();

      // 3.64% (1.20% - 7.55%).
      case Tag.TypeParameterType:
        return _readTypeParameterType();

      // 2.75% (1.03% - 4.13%).
      case Tag.DynamicType:
        return _readDynamicType();

      // The rest is < 2% on average in sampled dills.
      case Tag.TypedefType:
        return _readTypedefType();
      case Tag.InvalidType:
        return _readInvalidType();
      case Tag.NeverType:
        return _readNeverType();
      case Tag.NullType:
        return _readNullType();
      case Tag.ExtensionType:
        return _readExtensionType();
      case Tag.FunctionType:
        return _readFunctionType();
      case Tag.IntersectionType:
        return _readIntersectionType();
      case Tag.RecordType:
        return _readRecordType();
      case Tag.FutureOrType:
        return _readFutureOrType();
      default:
        throw fail('unexpected dart type tag: $tag');
    }
  }

  DartType _readTypedefType() {
    int nullabilityIndex = readByte();
    return new TypedefType.byReference(readNonNullTypedefReference(),
        Nullability.values[nullabilityIndex], readDartTypeList());
  }

  DartType _readInvalidType() {
    return const InvalidType();
  }

  DartType _readDynamicType() {
    return const DynamicType();
  }

  DartType _readVoidType() {
    return const VoidType();
  }

  DartType _readNeverType() {
    int nullabilityIndex = readByte();
    return NeverType.fromNullability(Nullability.values[nullabilityIndex]);
  }

  DartType _readNullType() {
    return const NullType();
  }

  DartType _readInterfaceType() {
    int nullabilityIndex = readByte();
    Reference reference = readNonNullClassReference();
    List<DartType> typeArguments = readDartTypeList();
    return new InterfaceType.byReference(
        reference, Nullability.values[nullabilityIndex], typeArguments);
  }

  DartType _readSimpleInterfaceType(bool forSupertype) {
    final int nullabilityIndex = readByte();
    final int classReferenceIndex = readUInt30();
    final CanonicalName? canonicalName =
        getNullableCanonicalNameReferenceFromInt(classReferenceIndex);
    if (canonicalName == null) {
      throw 'Expected a class reference to be valid but was `null`.';
    }

    // Check cache.
    final int cacheIndex =
        (classReferenceIndex - 1) * Nullability.values.length +
            nullabilityIndex;
    final DartType? cached = _cachedSimpleInterfaceTypes[cacheIndex];
    if (cached != null) {
      return cached;
    }

    // Not in cache.
    final Reference classReference = canonicalName.reference;
    final DartType result = new InterfaceType.byReference(classReference,
        Nullability.values[nullabilityIndex], const <DartType>[]);
    _cachedSimpleInterfaceTypes[cacheIndex] = result;
    return result;
  }

  DartType _readFutureOrType() {
    int nullabilityIndex = readByte();
    DartType typeArgument = readDartType();
    return new FutureOrType(typeArgument, Nullability.values[nullabilityIndex]);
  }

  DartType _readExtensionType() {
    int nullabilityIndex = readByte();
    Reference reference = readNonNullExtensionTypeDeclarationReference();
    List<DartType> typeArguments = readDartTypeList();
    readDartType(); // Read type erasure.
    return new ExtensionType.byReference(
        reference, Nullability.values[nullabilityIndex], typeArguments);
  }

  DartType _readFunctionType() {
    int typeParameterStackHeight = typeParameterStack.length;
    int nullabilityIndex = readByte();
    List<StructuralParameter> typeParameters =
        readAndPushStructuralParameterList();
    int requiredParameterCount = readUInt30();
    int totalParameterCount = readUInt30();
    List<DartType> positional = readDartTypeList();
    List<NamedType> named = readNamedTypeList();
    assert(positional.length + named.length == totalParameterCount);
    DartType returnType = readDartType();
    typeParameterStack.length = typeParameterStackHeight;
    return new FunctionType(
        positional, returnType, Nullability.values[nullabilityIndex],
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount,
        namedParameters: named);
  }

  DartType _readSimpleFunctionType() {
    int nullabilityIndex = readByte();
    List<DartType> positional = readDartTypeList();
    DartType returnType = readDartType();
    if (positional.isEmpty && returnType is VoidType) {
      // "FunctionType(void Function())" with different nullabilities.
      assert(
          _voidFunctionFunctionTypesCache.length == Nullability.values.length);
      FunctionType? cached = _voidFunctionFunctionTypesCache[nullabilityIndex];
      if (cached != null) {
        return cached;
      }
      FunctionType result = new FunctionType(
          const [], const VoidType(), Nullability.values[nullabilityIndex]);
      _voidFunctionFunctionTypesCache[nullabilityIndex] = result;
      return result;
    }
    return new FunctionType(
        positional, returnType, Nullability.values[nullabilityIndex]);
  }

  DartType _readTypeParameterType() {
    int declaredNullabilityIndex = readByte();
    int index = readUInt30();
    Object typeParameter = typeParameterStack[index];
    if (typeParameter is TypeParameter) {
      return new TypeParameterType(
          typeParameter, Nullability.values[declaredNullabilityIndex]);
    } else {
      typeParameter as StructuralParameter;
      return new StructuralParameterType(
          typeParameter, Nullability.values[declaredNullabilityIndex]);
    }
  }

  DartType _readIntersectionType() {
    TypeParameterType left = readDartType() as TypeParameterType;
    DartType right = readDartType();
    return new IntersectionType(left, right);
  }

  DartType _readRecordType() {
    int nullabilityIndex = readByte();
    List<DartType> positional = readDartTypeList();
    List<NamedType> named = readNamedTypeList();
    return new RecordType(
        positional, named, Nullability.values[nullabilityIndex]);
  }

  List<TypeParameter> readAndPushTypeParameterList(
      [List<TypeParameter>? list, GenericDeclaration? declaration]) {
    int length = readUInt30();
    if (length == 0) {
      if (list != null) return list;
      if (useGrowableLists) {
        return <TypeParameter>[];
      } else {
        return emptyListOfTypeParameter;
      }
    }
    if (list == null) {
      list = new List<TypeParameter>.generate(length,
          (_) => new TypeParameter(null, null)..declaration = declaration,
          growable: useGrowableLists);
    } else if (list.length != length) {
      for (int i = 0; i < length; ++i) {
        list.add(new TypeParameter(null, null)..declaration = declaration);
      }
    }
    typeParameterStack.addAll(list);
    for (int i = 0; i < list.length; ++i) {
      readTypeParameter(list[i]);
    }
    return list;
  }

  List<StructuralParameter> readAndPushStructuralParameterList(
      [List<StructuralParameter>? list]) {
    int length = readUInt30();
    if (length == 0) {
      if (list != null) return list;
      if (useGrowableLists) {
        return <StructuralParameter>[];
      } else {
        return emptyListOfStructuralParameter;
      }
    }
    if (list == null) {
      list = new List<StructuralParameter>.generate(
          length, (_) => new StructuralParameter(null, null),
          growable: useGrowableLists);
    } else if (list.length != length) {
      for (int i = 0; i < length; ++i) {
        list.add(new StructuralParameter(null, null));
      }
    }
    typeParameterStack.addAll(list);
    for (int i = 0; i < list.length; ++i) {
      readStructuralParameter(list[i]);
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
    node.defaultType = readDartType();
  }

  void readStructuralParameter(StructuralParameter node) {
    node.flags = readByte();
    // For now, [StructuralParameter] objects are encoded as
    // [TypeParameter] objects, to preserve compatibility with the binary format
    // consumers.
    // TODO(cstefantsova): Eventually remove the annotations from the binary
    // encoding of [StructuralParameter] objects.
    readAnnotationList();
    int variance = readByte();
    if (variance == TypeParameter.legacyCovariantSerializationMarker) {
      node.variance = null;
    } else {
      node.variance = variance;
    }
    node.name = readStringOrNullIfEmpty();
    node.bound = readDartType();
    node.defaultType = readDartType();
  }

  Arguments readArguments() {
    int numArguments = readUInt30();
    List<DartType> typeArguments = readDartTypeList();
    List<Expression> positional = readExpressionList();
    List<NamedExpression> named = readNamedExpressionList();
    assert(numArguments == positional.length + named.length);
    return new Arguments(positional, types: typeArguments, named: named);
  }

  List<NamedExpression> readNamedExpressionList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost-constant one for the empty list.
      return emptyListOfNamedExpression;
    }
    return new List<NamedExpression>.generate(
        length, (_) => readNamedExpression(),
        growable: useGrowableLists);
  }

  NamedExpression readNamedExpression() {
    return new NamedExpression(readStringReference(), readExpression());
  }

  List<VariableDeclaration> readAndPushVariableDeclarationList() {
    int length = readUInt30();
    if (!useGrowableLists && length == 0) {
      // When lists don't have to be growable anyway, we might as well use an
      // almost constant one for the empty list.
      return emptyListOfVariableDeclaration;
    }
    return new List<VariableDeclaration>.generate(
        length, (_) => readAndPushVariableDeclaration(),
        growable: useGrowableLists);
  }

  VariableDeclaration? readAndPushVariableDeclarationOption() {
    return readAndCheckOptionTag() ? readAndPushVariableDeclaration() : null;
  }

  VariableDeclaration readAndPushVariableDeclaration() {
    VariableDeclaration variable = readVariableDeclaration();
    variableStack.add(variable);
    return variable;
  }

  VariableDeclaration readVariableDeclaration() {
    int offset = readOffset();
    int fileEqualsOffset = readOffset();
    // The [VariableDeclaration] instance is not created at this point yet,
    // so `null` is temporarily set as the parent of the annotation nodes.
    List<Expression> annotations = readAnnotationList(null);
    int flags = readUInt30();
    VariableDeclaration node = new VariableDeclaration(
        readStringOrNullIfEmpty(),
        type: readDartType(),
        initializer: readExpressionOption(),
        flags: flags)
      ..fileOffset = offset
      ..fileEqualsOffset = fileEqualsOffset;
    if (annotations.isNotEmpty) {
      for (int i = 0; i < annotations.length; ++i) {
        Expression annotation = annotations[i];
        annotation.parent = node;
      }
      node.annotations = annotations;
    }
    return node;
  }

  int readOffset() {
    // Offset is saved as unsigned,
    // but actually ranges from -1 and up (thus the -1)
    return readUInt30() - 1;
  }
}

class BinaryBuilderWithMetadata extends BinaryBuilder implements BinarySource {
  /// List of metadata subsections that have corresponding [MetadataRepository]
  /// and are awaiting to be parsed and attached to nodes.
  List<_MetadataSubsection>? _subsections;

  BinaryBuilderWithMetadata(List<int> bytes,
      {String? filename,
      bool disableLazyReading = false,
      bool disableLazyClassReading = false,
      bool? alwaysCreateNewNamedNodes})
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
    final int subSectionCount = readUint32();

    int endOffset = _byteOffset - 4; // End offset of the current subsection.
    for (int i = 0; i < subSectionCount; i++) {
      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      _byteOffset = endOffset - 4;
      final int mappingLength = readUint32();
      final int mappingStart = (endOffset - 4) - 4 * 2 * mappingLength;
      _byteOffset = mappingStart - 4;

      // UInt32 tag (fixed size StringReference)
      final String tag = _stringTable[readUint32()];

      final MetadataRepository<dynamic>? repository = component.metadata[tag];
      if (repository != null) {
        // Read nodeOffsetToMetadataOffset mapping.
        final Map<int, int> mapping = <int, int>{};
        _byteOffset = mappingStart;
        for (int j = 0; j < mappingLength; j++) {
          final int nodeOffset = readUint32();
          final int metadataOffset =
              binaryOffsetForMetadataPayloads + readUint32();
          mapping[nodeOffset] = metadataOffset;
        }

        (_subsections ??= <_MetadataSubsection>[])
            .add(new _MetadataSubsection(repository, mapping));
      }

      // Start of the subsection and the end of the previous one.
      endOffset = mappingStart - 4;
    }
  }

  Object _readMetadata(Node node, MetadataRepository repository, int offset) {
    final int savedOffset = _byteOffset;
    _byteOffset = offset;

    final Object metadata = repository.readFromBinary(node, this);

    _byteOffset = savedOffset;
    return metadata;
  }

  @override
  T _associateMetadata<T extends Node>(T node, int nodeOffset) {
    if (_subsections == null) {
      return node;
    }

    for (_MetadataSubsection subsection in _subsections!) {
      // First check if there is any metadata associated with this node.
      final int? metadataOffset = subsection.mapping[nodeOffset];
      if (metadataOffset != null) {
        subsection.repository.mapping[node] =
            _readMetadata(node, subsection.repository, metadataOffset);
      }
    }

    return node;
  }

  @override
  DartType readDartType({bool forSupertype = false}) {
    final int nodeOffset = _byteOffset;
    final DartType result = super.readDartType(forSupertype: forSupertype);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Library readLibrary(Component component, int endOffset) {
    final int nodeOffset = _byteOffset;
    final Library result = super.readLibrary(component, endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Typedef readTypedef() {
    final int nodeOffset = _byteOffset;
    final Typedef result = super.readTypedef();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Class readClass(int endOffset) {
    final int nodeOffset = _byteOffset;
    final Class result = super.readClass(endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Extension readExtension() {
    final int nodeOffset = _byteOffset;
    final Extension result = super.readExtension();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  ExtensionTypeDeclaration readExtensionTypeDeclaration() {
    final int nodeOffset = _byteOffset;
    final ExtensionTypeDeclaration result =
        super.readExtensionTypeDeclaration();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Field readField() {
    final int nodeOffset = _byteOffset;
    final Field result = super.readField();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Constructor readConstructor() {
    final int nodeOffset = _byteOffset;
    final Constructor result = super.readConstructor();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Procedure readProcedure(int endOffset) {
    final int nodeOffset = _byteOffset;
    final Procedure result = super.readProcedure(endOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Initializer readInitializer() {
    final int nodeOffset = _byteOffset;
    final Initializer result = super.readInitializer();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  FunctionNode readFunctionNode(
      {bool lazyLoadBody = false, int outerEndOffset = -1}) {
    final int nodeOffset = _byteOffset;
    final FunctionNode result = super.readFunctionNode(
        lazyLoadBody: lazyLoadBody, outerEndOffset: outerEndOffset);
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Expression readExpression() {
    final int nodeOffset = _byteOffset;
    final Expression result = super.readExpression();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Arguments readArguments() {
    final int nodeOffset = _byteOffset;
    final Arguments result = super.readArguments();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  NamedExpression readNamedExpression() {
    final int nodeOffset = _byteOffset;
    final NamedExpression result = super.readNamedExpression();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  VariableDeclaration readVariableDeclaration() {
    final int nodeOffset = _byteOffset;
    final VariableDeclaration result = super.readVariableDeclaration();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Statement readStatement() {
    final int nodeOffset = _byteOffset;
    final Statement result = super.readStatement();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  Combinator readCombinator() {
    final int nodeOffset = _byteOffset;
    final Combinator result = super.readCombinator();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  LibraryDependency readLibraryDependency() {
    final int nodeOffset = _byteOffset;
    final LibraryDependency result = super.readLibraryDependency();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  LibraryPart readLibraryPart() {
    final int nodeOffset = _byteOffset;
    final LibraryPart result = super.readLibraryPart();
    return _associateMetadata(result, nodeOffset);
  }

  @override
  void _readSwitchCaseInto(SwitchCase caseNode) {
    _associateMetadata(caseNode, _byteOffset);
    super._readSwitchCaseInto(caseNode);
  }

  @override
  void readTypeParameter(TypeParameter param) {
    _associateMetadata(param, _byteOffset);
    super.readTypeParameter(param);
  }

  @override
  Supertype readSupertype() {
    final int nodeOffset = _byteOffset;
    InterfaceType type =
        super.readDartType(forSupertype: true) as InterfaceType;
    return _associateMetadata(
        new Supertype.byReference(type.classReference, type.typeArguments),
        nodeOffset);
  }

  @override
  Name readName() {
    final int nodeOffset = _byteOffset;
    final Name result = super.readName();
    return _associateMetadata(result, nodeOffset);
  }
}

/// Deserialized MetadataMapping corresponding to the given metadata repository.
class _MetadataSubsection {
  /// [MetadataRepository] that can read this subsection.
  final MetadataRepository repository;

  /// Deserialized mapping from node offsets to metadata offsets.
  final Map<int, int> mapping;

  _MetadataSubsection(this.repository, this.mapping);
}

/// Merges two compilation modes or throws if they are not compatible.
NonNullableByDefaultCompiledMode mergeCompilationModeOrThrow(
    NonNullableByDefaultCompiledMode? a, NonNullableByDefaultCompiledMode b) {
  if (a == null || a == b) {
    return b;
  }

  // If something is invalid, it should always merge as invalid.
  if (a == NonNullableByDefaultCompiledMode.Invalid) {
    return a;
  }
  if (b == NonNullableByDefaultCompiledMode.Invalid) {
    return b;
  }

  if (a == NonNullableByDefaultCompiledMode.Agnostic) {
    return b;
  }
  if (b == NonNullableByDefaultCompiledMode.Agnostic) {
    // Keep as-is.
    return a;
  }

  // Mixed mode where agnostic isn't involved.
  throw new CompilationModeError("Mixed compilation mode found: $a and $b");
}
