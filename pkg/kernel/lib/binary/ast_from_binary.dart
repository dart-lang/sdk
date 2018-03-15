// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_from_binary;

import 'dart:core' hide MapEntry;
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

class _ComponentIndex {
  int binaryOffsetForSourceTable;
  int binaryOffsetForStringTable;
  int binaryOffsetForCanonicalNames;
  int binaryOffsetForConstantTable;
  int mainMethodReference;
  List<int> libraryOffsets;
  int libraryCount;
  int componentFileSizeInBytes;
}

class BinaryBuilder {
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final List<LabeledStatement> labelStack = <LabeledStatement>[];
  int labelStackBase = 0;
  final List<SwitchCase> switchCaseStack = <SwitchCase>[];
  final List<TypeParameter> typeParameterStack = <TypeParameter>[];
  final String filename;
  final List<int> _bytes;
  int _byteOffset = 0;
  final List<String> _stringTable = <String>[];
  final List<Uri> _sourceUriTable = <Uri>[];
  List<Constant> _constantTable;
  List<CanonicalName> _linkTable;
  int _transformerFlags = 0;
  Library _currentLibrary;
  int _componentStartOffset = 0;

  // If something goes wrong, this list should indicate what library,
  // class, and member was being built.
  List<String> debugPath = <String>[];

  bool _isReadingLibraryImplementation = false;

  /// If binary contains metadata section with payloads referencing other nodes
  /// such Kernel binary can't be read lazily because metadata cross references
  /// will not be resolved correctly.
  bool _disableLazyReading = false;

  BinaryBuilder(this._bytes, {this.filename, disableLazyReading = false})
      : _disableLazyReading = disableLazyReading;

  fail(String message) {
    throw new ParseError(message,
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

  List<int> readByteList() {
    List<int> bytes = new Uint8List(readUInt());
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return bytes;
  }

  String readStringEntry(int numBytes) {
    // Utf8Decoder will skip leading BOM characters, but we must preserve them.
    // Collect leading BOMs before passing the bytes onto Utf8Decoder.
    int numByteOrderMarks = 0;
    while (_byteOffset + 2 < _bytes.length &&
        _bytes[_byteOffset] == 0xef &&
        _bytes[_byteOffset + 1] == 0xbb &&
        _bytes[_byteOffset + 2] == 0xbf) {
      ++numByteOrderMarks;
      _byteOffset += 3;
      numBytes -= 3;
    }
    String string = const Utf8Decoder()
        .convert(_bytes, _byteOffset, _byteOffset + numBytes);
    _byteOffset += numBytes;
    if (numByteOrderMarks > 0) {
      return '\ufeff' * numByteOrderMarks + string;
    }
    return string;
  }

  /// Read metadataMappings section from the binary. Return [true] if
  /// any metadata mapping contains metadata with node references.
  /// In this case we need to disable lazy loading of the binary.
  bool _readMetadataSection(Component component) {
    // Default reader ignores metadata section entirely.
    return false;
  }

  /// Process any pending metadata associations. Called once the Component
  /// is fully deserialized and metadata containing references to nodes can
  /// be safely parsed.
  void _processPendingMetadataAssociations(Component component) {
    // Default reader ignores metadata section entirely.
  }

  void readStringTable(List<String> table) {
    // Read the table of end offsets.
    int length = readUInt();
    List<int> endOffsets = new List<int>(length);
    for (int i = 0; i < length; ++i) {
      endOffsets[i] = readUInt();
    }
    // Read the UTF-8 encoded strings.
    table.length = length;
    int startOffset = 0;
    for (int i = 0; i < length; ++i) {
      table[i] = readStringEntry(endOffsets[i] - startOffset);
      startOffset = endOffsets[i];
    }
  }

  void readConstantTable() {
    final int length = readUInt();
    _constantTable = new List<Constant>(length);
    for (int i = 0; i < length; i++) {
      _constantTable[i] = readConstantTableEntry();
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
        return new DoubleConstant(double.parse(readStringReference()));
      case ConstantTag.StringConstant:
        return new StringConstant(readStringReference());
      case ConstantTag.MapConstant:
        final DartType keyType = readDartType();
        final DartType valueType = readDartType();
        final int length = readUInt();
        final List<ConstantMapEntry> entries =
            new List<ConstantMapEntry>(length);
        for (int i = 0; i < length; i++) {
          final Constant key = readConstantReference();
          final Constant value = readConstantReference();
          entries[i] = new ConstantMapEntry(key, value);
        }
        return new MapConstant(keyType, valueType, entries);
      case ConstantTag.ListConstant:
        final DartType typeArgument = readDartType();
        final int length = readUInt();
        final List<Constant> entries = new List<Constant>(length);
        for (int i = 0; i < length; i++) {
          entries[i] = readConstantReference();
        }
        return new ListConstant(typeArgument, entries);
      case ConstantTag.InstanceConstant:
        final Reference classReference = readClassReference();
        final int typeArgumentCount = readUInt();
        final List<DartType> typeArguments =
            new List<DartType>(typeArgumentCount);
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
      case ConstantTag.TearOffConstant:
        final Reference reference = readCanonicalNameReference().getReference();
        return new TearOffConstant.byReference(reference);
      case ConstantTag.TypeLiteralConstant:
        final DartType type = readDartType();
        return new TypeLiteralConstant(type);
    }

    throw 'Invalid constant tag $constantTag';
  }

  Constant readConstantReference() {
    final int index = readUInt();
    Constant constant = _constantTable[index];
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
    List<String> result = new List<String>(length);
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
      throw fail('Invalid Option tag: $tag');
    }
  }

  List<Expression> readAnnotationList(TreeNode parent) {
    int length = readUInt();
    if (length == 0) return const <Expression>[];
    List<Expression> list = new List<Expression>(length);
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

  void _skipNodeList(Node skipObject()) {
    var length = readUInt();
    for (int i = 0; i < length; ++i) {
      skipObject();
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
    if (_isReadingLibraryImplementation) {
      // When reading the library implementation, overwrite the whole list
      // with the new one.
      _fillTreeNodeList(list, readObject, parent);
    } else {
      // When reading an external library, the results should either be:
      // - merged with the existing external library definition (if any)
      // - ignored if the library implementation is already in memory
      int numberOfNodes = readUInt();
      for (int i = 0; i < numberOfNodes; ++i) {
        var value = readObject(i);
        // We use the parent pointer of a node to determine if it already is in
        // the AST and hence should not be added again.
        if (value.parent == null) {
          list.add(value..parent = parent);
        }
      }
    }
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
    int savedByteOffset = _byteOffset;
    _byteOffset = _bytes.length - 4;
    List<int> index = <int>[];
    while (_byteOffset > 0) {
      int size = readUint32();
      int start = _byteOffset - size;
      if (start < 0) throw "Invalid component file: Indicated size is invalid.";
      index.add(size);
      _byteOffset = start - 4;
    }
    _byteOffset = savedByteOffset;
    return new List.from(index.reversed);
  }

  /// Deserializes a kernel component and stores it in [component].
  ///
  /// When linking with a non-empty component, canonical names must have been
  /// computed ahead of time.
  ///
  /// The input bytes may contain multiple files concatenated.
  void readComponent(Component component) {
    List<int> componentFileSizes = _indexComponents();
    if (componentFileSizes.length > 1) {
      _disableLazyReading = true;
    }
    int componentFileIndex = 0;
    while (_byteOffset < _bytes.length) {
      _readOneComponent(component, componentFileSizes[componentFileIndex]);
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
  void readSingleFileComponent(Component component) {
    List<int> componentFileSizes = _indexComponents();
    if (componentFileSizes.isEmpty) throw "Invalid component data.";
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
      throw 'Malformed binary: This component file\'s component index indicates that'
          ' the filesize should be $componentFileSize but other component indexes'
          ' has indicated that the size should be '
          '${result.componentFileSizeInBytes}.';
    }

    // Skip to the start of the index.
    // There are these fields: file size, library count, library count + 1
    // offsets, main reference, string table offset, canonical name offset and
    // source table offset. That's 6 fields + number of libraries.
    _byteOffset -= (result.libraryCount + 8) * 4;

    // Now read the component index.
    result.binaryOffsetForSourceTable = _componentStartOffset + readUint32();
    result.binaryOffsetForCanonicalNames = _componentStartOffset + readUint32();
    result.binaryOffsetForStringTable = _componentStartOffset + readUint32();
    result.binaryOffsetForConstantTable = _componentStartOffset + readUint32();
    result.mainMethodReference = readUint32();
    for (int i = 0; i < result.libraryCount + 1; ++i) {
      result.libraryOffsets[i] = _componentStartOffset + readUint32();
    }

    _byteOffset = savedByteIndex;

    return result;
  }

  void _readOneComponent(Component component, int componentFileSize) {
    _componentStartOffset = _byteOffset;

    final int magic = readUint32();
    if (magic != Tag.ComponentFile) {
      throw fail('This is not a binary dart file. '
          'Magic number was: ${magic.toRadixString(16)}');
    }

    final int formatVersion = readUint32();
    if (formatVersion != Tag.BinaryFormatVersion) {
      throw fail('Invalid kernel binary format version '
          '(found ${formatVersion}, expected ${Tag.BinaryFormatVersion})');
    }

    // Read component index from the end of this ComponentFiles serialized data.
    _ComponentIndex index = _readComponentIndex(componentFileSize);

    _byteOffset = index.binaryOffsetForStringTable;
    readStringTable(_stringTable);

    _byteOffset = index.binaryOffsetForCanonicalNames;
    readLinkTable(component.root);

    _byteOffset = index.binaryOffsetForStringTable;
    _disableLazyReading =
        _readMetadataSection(component) || _disableLazyReading;

    _byteOffset = index.binaryOffsetForSourceTable;
    Map<Uri, Source> uriToSource = readUriToSource();
    component.uriToSource.addAll(uriToSource);

    _byteOffset = index.binaryOffsetForConstantTable;
    readConstantTable();

    int numberOfLibraries = index.libraryCount;
    for (int i = 0; i < numberOfLibraries; ++i) {
      _byteOffset = index.libraryOffsets[i];
      readLibrary(component, index.libraryOffsets[i + 1]);
    }

    var mainMethod =
        getMemberReferenceFromInt(index.mainMethodReference, allowNull: true);
    component.mainMethodName ??= mainMethod;

    _processPendingMetadataAssociations(component);

    _byteOffset = _componentStartOffset + componentFileSize;
  }

  Map<Uri, Source> readUriToSource() {
    int length = readUint32();

    // Read data.
    _sourceUriTable.length = length;
    Map<Uri, Source> uriToSource = <Uri, Source>{};
    for (int i = 0; i < length; ++i) {
      List<int> uriBytes = readByteList();
      Uri uri = Uri.parse(const Utf8Decoder().convert(uriBytes));
      _sourceUriTable[i] = uri;
      List<int> sourceCode = readByteList();
      int lineCount = readUInt();
      List<int> lineStarts = new List<int>(lineCount);
      int previousLineStart = 0;
      for (int j = 0; j < lineCount; ++j) {
        int lineStart = readUInt() + previousLineStart;
        lineStarts[j] = lineStart;
        previousLineStart = lineStart;
      }
      uriToSource[uri] = new Source(lineStarts, sourceCode);
    }

    // Read index.
    for (int i = 0; i < length; ++i) {
      readUint32();
    }
    return uriToSource;
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

  Reference readLibraryReference() {
    return readCanonicalNameReference().getReference();
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
    bool isExternal = (flags & 0x1) != 0;
    _isReadingLibraryImplementation = !isExternal;
    var canonicalName = readCanonicalNameReference();
    Reference reference = canonicalName.getReference();
    Library library = reference.node;
    bool shouldWriteData = library == null || _isReadingLibraryImplementation;
    if (library == null) {
      library =
          new Library(Uri.parse(canonicalName.name), reference: reference);
      component.libraries.add(library..parent = component);
    }
    _currentLibrary = library;
    String name = readStringOrNullIfEmpty();

    // TODO(jensj): We currently save (almost the same) uri twice.
    Uri fileUri = readUriReference();

    if (shouldWriteData) {
      library.isExternal = isExternal;
      library.name = name;
      library.fileUri = fileUri;
    }

    assert(() {
      debugPath.add(library.name ?? library.importUri?.toString() ?? 'library');
      return true;
    }());

    if (shouldWriteData) {
      _fillTreeNodeList(
          library.annotations, (index) => readExpression(), library);
    } else {
      _skipNodeList(readExpression);
    }
    _readLibraryDependencies(library);
    _readAdditionalExports(library);
    _readLibraryParts(library);
    _mergeNamedNodeList(library.typedefs, (index) => readTypedef(), library);

    _mergeNamedNodeList(library.classes, (index) {
      _byteOffset = classOffsets[index];
      return readClass(classOffsets[index + 1]);
    }, library);
    _byteOffset = classOffsets.last;
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
    var targetLibrary = readLibraryReference();
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
    List<Combinator> result = new List<Combinator>(length);
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
    var fileUri = readUriReference();
    var annotations = readExpressionList();
    return new LibraryPart(annotations, fileUri)..parent = library;
  }

  Typedef readTypedef() {
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Typedef node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Typedef(null, null, reference: reference);
    }
    Uri fileUri = readUriReference();
    int fileOffset = readOffset();
    String name = readStringReference();
    node.annotations = readAnnotationList(node);
    readAndPushTypeParameterList(node.typeParameters, node);
    var type = readDartType();
    typeParameterStack.length = 0;
    if (shouldWriteData) {
      node.fileOffset = fileOffset;
      node.name = name;
      node.fileUri = fileUri;
      node.type = type;
    }
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
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Class(reference: reference)..level = ClassLevel.Temporary;
    }

    var fileUri = readUriReference();
    node.fileOffset = readOffset();
    node.fileEndOffset = readOffset();
    int flags = readByte();
    node.isAbstract = flags & 0x1 != 0;
    node.isEnum = flags & 0x2 != 0;
    node.isSyntheticMixinImplementation = flags & 0x4 != 0;
    int levelIndex = (flags >> 3) & 0x3;
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
    readAndPushTypeParameterList(node.typeParameters, node);
    var supertype = readSupertypeOption();
    var mixedInType = readSupertypeOption();
    if (shouldWriteData) {
      _fillNonTreeNodeList(node.implementedTypes, readSupertype);
    } else {
      _skipNodeList(readSupertype);
    }
    _mergeNamedNodeList(node.fields, (index) => readField(), node);
    _mergeNamedNodeList(node.constructors, (index) => readConstructor(), node);

    _mergeNamedNodeList(node.procedures, (index) {
      _byteOffset = procedureOffsets[index];
      return readProcedure(procedureOffsets[index + 1]);
    }, node);
    _byteOffset = procedureOffsets.last;
    _mergeNamedNodeList(node.redirectingFactoryConstructors,
        (index) => readRedirectingFactoryConstructor(), node);
    typeParameterStack.length = 0;
    assert(debugPath.removeLast() != null);
    if (shouldWriteData) {
      node.name = name;
      node.fileUri = fileUri;
      node.annotations = annotations;
      node.supertype = supertype;
      node.mixedInType = mixedInType;
    }

    _byteOffset = endOffset;

    return node;
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
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Field(null, reference: reference);
    }
    var fileUri = readUriReference();
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readByte();
    int flags2 = readByte();
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
    if (shouldWriteData) {
      node.fileOffset = fileOffset;
      node.fileEndOffset = fileEndOffset;
      node.flags = flags;
      node.flags2 = flags2;
      node.name = name;
      node.fileUri = fileUri;
      node.annotations = annotations;
      node.type = type;
      node.initializer = initializer;
      node.initializer?.parent = node;
      node.transformerFlags = transformerFlags;
    }
    return node;
  }

  Constructor readConstructor() {
    int tag = readByte();
    assert(tag == Tag.Constructor);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Constructor node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Constructor(null, reference: reference);
    }
    var fileUri = readUriReference();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    var flags = readByte();
    var name = readName();
    var annotations = readAnnotationList(node);
    assert(() {
      debugPath.add(node.name?.name ?? 'constructor');
      return true;
    }());
    var function = readFunctionNode(false, -1);
    pushVariableDeclarations(function.positionalParameters);
    pushVariableDeclarations(function.namedParameters);
    if (shouldWriteData) {
      _fillTreeNodeList(node.initializers, (index) => readInitializer(), node);
    } else {
      _skipNodeList(readInitializer);
    }
    variableStack.length = 0;
    var transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    if (shouldWriteData) {
      node.fileOffset = fileOffset;
      node.fileEndOffset = fileEndOffset;
      node.flags = flags;
      node.name = name;
      node.fileUri = fileUri;
      node.annotations = annotations;
      node.function = function..parent = node;
      node.transformerFlags = transformerFlags;
    }
    return node;
  }

  Procedure readProcedure(int endOffset) {
    int tag = readByte();
    assert(tag == Tag.Procedure);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Procedure node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Procedure(null, null, null, reference: reference);
    }
    var fileUri = readUriReference();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    int kindIndex = readByte();
    var kind = ProcedureKind.values[kindIndex];
    var flags = readByte();
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
        readAndCheckOptionTag() ? readMemberReference() : null;
    var forwardingStubInterfaceTargetReference =
        readAndCheckOptionTag() ? readMemberReference() : null;
    var function = readFunctionNodeOption(!readFunctionNodeNow, endOffset);
    var transformerFlags = getAndResetTransformerFlags();
    assert(((_) => true)(debugPath.removeLast()));
    if (shouldWriteData) {
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
    }
    _byteOffset = endOffset;
    return node;
  }

  RedirectingFactoryConstructor readRedirectingFactoryConstructor() {
    int tag = readByte();
    assert(tag == Tag.RedirectingFactoryConstructor);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    RedirectingFactoryConstructor node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new RedirectingFactoryConstructor(null, reference: reference);
    }
    var fileUri = readUriReference();
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    var flags = readByte();
    var name = readName();
    var annotations = readAnnotationList(node);
    debugPath.add(node.name?.name ?? 'redirecting-factory-constructor');
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
    if (shouldWriteData) {
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
    }
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
        var reference = readMemberReference();
        var arguments = readArguments();
        return new SuperInitializer.byReference(reference, arguments)
          ..isSynthetic = isSynthetic;
      case Tag.RedirectingInitializer:
        return new RedirectingInitializer.byReference(
            readMemberReference(), readArguments());
      case Tag.LocalInitializer:
        return new LocalInitializer(readAndPushVariableDeclaration());
      case Tag.AssertInitializer:
        return new AssertInitializer(readStatement());
      default:
        throw fail('Invalid initializer tag: $tag');
    }
  }

  FunctionNode readFunctionNodeOption(bool lazyLoadBody, int outerEndOffset) {
    return readAndCheckOptionTag()
        ? readFunctionNode(lazyLoadBody, outerEndOffset)
        : null;
  }

  FunctionNode readFunctionNode(bool lazyLoadBody, int outerEndOffset) {
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

    if (lazyLoadBody && outerEndOffset > 0) {
      lazyLoadBody = outerEndOffset - _byteOffset >
          2; // e.g. outline has Tag.Something and Tag.EmptyStatement
    }

    var body;
    if (!lazyLoadBody) {
      labelStackBase = labelStack.length;
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
      _setLazyLoadFunction(result, oldLabelStackBase, variableStackHeight,
          typeParameterStackHeight);
    }

    labelStackBase = oldLabelStackBase;
    variableStack.length = variableStackHeight;
    typeParameterStack.length = typeParameterStackHeight;

    return result;
  }

  void _setLazyLoadFunction(FunctionNode result, int oldLabelStackBase,
      int variableStackHeight, int typeParameterStackHeight) {
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
      variableStack.length = variableStackHeight;
      typeParameterStack.length = typeParameterStackHeight;
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
      throw fail('Invalid variable index: $index');
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
        throw fail('Invalid logical operator index: $index');
    }
  }

  List<Expression> readExpressionList() {
    int length = readUInt();
    List<Expression> result = new List<Expression>(length);
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
        int flags = readByte();
        return new PropertyGet.byReference(
            readExpression(), readName(), readMemberReference(allowNull: true))
          ..fileOffset = offset
          ..flags = flags;
      case Tag.PropertySet:
        int offset = readOffset();
        int flags = readByte();
        return new PropertySet.byReference(readExpression(), readName(),
            readExpression(), readMemberReference(allowNull: true))
          ..fileOffset = offset
          ..flags = flags;
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
        int flags = readByte();
        return new DirectPropertyGet.byReference(
            readExpression(), readMemberReference())
          ..fileOffset = offset
          ..flags = flags;
      case Tag.DirectPropertySet:
        int offset = readOffset();
        int flags = readByte();
        return new DirectPropertySet.byReference(
            readExpression(), readMemberReference(), readExpression())
          ..fileOffset = offset
          ..flags = flags;
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
        int flags = readByte();
        return new MethodInvocation.byReference(readExpression(), readName(),
            readArguments(), readMemberReference(allowNull: true))
          ..fileOffset = offset
          ..flags = flags;
      case Tag.SuperMethodInvocation:
        int offset = readOffset();
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperMethodInvocation.byReference(
            readName(), readArguments(), readMemberReference(allowNull: true))
          ..fileOffset = offset;
      case Tag.DirectMethodInvocation:
        int offset = readOffset();
        int flags = readByte();
        return new DirectMethodInvocation.byReference(
            readExpression(), readMemberReference(), readArguments())
          ..fileOffset = offset
          ..flags = flags;
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
      case Tag.IsExpression:
        int offset = readOffset();
        return new IsExpression(readExpression(), readDartType())
          ..fileOffset = offset;
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
        return new DoubleLiteral(double.parse(readStringReference()));
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
        return new FunctionExpression(readFunctionNode(false, -1))
          ..fileOffset = offset;
      case Tag.Let:
        var variable = readVariableDeclaration();
        int stackHeight = variableStack.length;
        pushVariableDeclaration(variable);
        var body = readExpression();
        variableStack.length = stackHeight;
        return new Let(variable, body);
      case Tag.Instantiation:
        var expression = readExpression();
        var typeArguments = readDartTypeList();
        return new Instantiation(expression, typeArguments);
      case Tag.VectorCreation:
        var length = readUInt();
        return new VectorCreation(length);
      case Tag.VectorGet:
        var vectorExpression = readExpression();
        var index = readUInt();
        return new VectorGet(vectorExpression, index);
      case Tag.VectorSet:
        var vectorExpression = readExpression();
        var index = readUInt();
        var value = readExpression();
        return new VectorSet(vectorExpression, index, value);
      case Tag.VectorCopy:
        var vectorExpression = readExpression();
        return new VectorCopy(vectorExpression);
      case Tag.ClosureCreation:
        var topLevelFunctionReference = readMemberReference();
        var contextVector = readExpression();
        var functionType = readDartType();
        var typeArgs = readDartTypeList();
        return new ClosureCreation.byReference(
            topLevelFunctionReference, contextVector, functionType, typeArgs);
      case Tag.ConstantExpression:
        return new ConstantExpression(readConstantReference());
      default:
        throw fail('Invalid expression tag: $tag');
    }
  }

  List<MapEntry> readMapEntryList() {
    int length = readUInt();
    List<MapEntry> result = new List<MapEntry>(length);
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
    List<Statement> result = <Statement>[];
    result.length = length;
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
        List<SwitchCase> cases = new List<SwitchCase>(count);
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
        return new ContinueSwitchStatement(switchCaseStack[index])
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
        readByte(); // whether any catch needs a stacktrace.
        return new TryCatch(body, readCatchList());
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
        var function = readFunctionNode(false, -1);
        return new FunctionDeclaration(variable, function)..fileOffset = offset;
      default:
        throw fail('Invalid statement tag: $tag');
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
    List<Catch> result = new List<Catch>(length);
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
    return new Supertype.byReference(type.className, type.typeArguments);
  }

  Supertype readSupertypeOption() {
    return readAndCheckOptionTag() ? readSupertype() : null;
  }

  List<Supertype> readSupertypeList() {
    int length = readUInt();
    List<Supertype> result = new List<Supertype>(length);
    for (int i = 0; i < length; ++i) {
      result[i] = readSupertype();
    }
    return result;
  }

  List<DartType> readDartTypeList() {
    int length = readUInt();
    List<DartType> result = new List<DartType>(length);
    for (int i = 0; i < length; ++i) {
      result[i] = readDartType();
    }
    return result;
  }

  List<NamedType> readNamedTypeList() {
    int length = readUInt();
    List<NamedType> result = new List<NamedType>(length);
    for (int i = 0; i < length; ++i) {
      result[i] = readNamedType();
    }
    return result;
  }

  NamedType readNamedType() {
    return new NamedType(readStringReference(), readDartType());
  }

  DartType readDartTypeOption() {
    return readAndCheckOptionTag() ? readDartType() : null;
  }

  DartType readDartType() {
    int tag = readByte();
    switch (tag) {
      case Tag.TypedefType:
        return new TypedefType.byReference(
            readTypedefReference(), readDartTypeList());
      case Tag.VectorType:
        return const VectorType();
      case Tag.BottomType:
        return const BottomType();
      case Tag.InvalidType:
        return const InvalidType();
      case Tag.DynamicType:
        return const DynamicType();
      case Tag.VoidType:
        return const VoidType();
      case Tag.InterfaceType:
        return new InterfaceType.byReference(
            readClassReference(), readDartTypeList());
      case Tag.SimpleInterfaceType:
        return new InterfaceType.byReference(
            readClassReference(), const <DartType>[]);
      case Tag.FunctionType:
        int typeParameterStackHeight = typeParameterStack.length;
        var typeParameters = readAndPushTypeParameterList();
        var requiredParameterCount = readUInt();
        var totalParameterCount = readUInt();
        var positional = readDartTypeList();
        var named = readNamedTypeList();
        var positionalNames = readStringReferenceList();
        var typedefReference = readTypedefReference();
        assert(positional.length + named.length == totalParameterCount);
        var returnType = readDartType();
        typeParameterStack.length = typeParameterStackHeight;
        return new FunctionType(positional, returnType,
            typeParameters: typeParameters,
            requiredParameterCount: requiredParameterCount,
            namedParameters: named,
            positionalParameterNames: positionalNames,
            typedefReference: typedefReference);
      case Tag.SimpleFunctionType:
        var positional = readDartTypeList();
        var positionalNames = readStringReferenceList();
        var returnType = readDartType();
        return new FunctionType(positional, returnType,
            positionalParameterNames: positionalNames);
      case Tag.TypeParameterType:
        int index = readUInt();
        var bound = readDartTypeOption();
        return new TypeParameterType(typeParameterStack[index], bound);
      default:
        throw fail('Invalid dart type tag: $tag');
    }
  }

  List<TypeParameter> readAndPushTypeParameterList(
      [List<TypeParameter> list, TreeNode parent]) {
    int length = readUInt();
    if (length == 0) return list ?? <TypeParameter>[];
    if (list == null) {
      list = new List<TypeParameter>(length);
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
    node.name = readStringOrNullIfEmpty();
    node.bound = readDartType();
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
    List<NamedExpression> result = new List<NamedExpression>(length);
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
    List<VariableDeclaration> result = new List<VariableDeclaration>(length);
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

  /// Current mapping from node references to nodes used by readNodeReference.
  /// Note: each metadata subsection has its own mapping.
  List<Node> _referencedNodes;

  BinaryBuilderWithMetadata(bytes, [filename])
      : super(bytes, filename: filename);

  @override
  bool _readMetadataSection(Component component) {
    bool containsNodeReferences = false;

    // At the beginning of this function _byteOffset points right past
    // metadataMappings to string table.

    // Read the length of metadataMappings.
    _byteOffset -= 4;
    final subSectionCount = readUint32();

    int endOffset = _byteOffset - 4; // End offset of the current subsection.
    for (var i = 0; i < subSectionCount; i++) {
      // RList<UInt32> nodeReferences
      _byteOffset = endOffset - 4;
      final referencesLength = readUint32();
      final referencesStart = (endOffset - 4) - 4 * referencesLength;

      // RList<Pair<UInt32, UInt32>> nodeOffsetToMetadataOffset
      _byteOffset = referencesStart - 4;
      final mappingLength = readUint32();
      final mappingStart = (referencesStart - 4) - 4 * 2 * mappingLength;
      _byteOffset = mappingStart - 4;

      // UInt32 tag (fixed size StringReference)
      final tag = _stringTable[readUint32()];

      final repository = component.metadata[tag];
      if (repository != null) {
        // Read nodeReferences (if any).
        Map<int, int> offsetToReferenceId;
        List<Node> referencedNodes;
        if (referencesLength > 0) {
          offsetToReferenceId = <int, int>{};
          _byteOffset = referencesStart;
          for (var j = 0; j < referencesLength; j++) {
            final nodeOffset = readUint32();
            offsetToReferenceId[nodeOffset] = j;
          }
          referencedNodes = new List<Node>(referencesLength);
          containsNodeReferences = true;
        }

        // Read nodeOffsetToMetadataOffset mapping.
        final mapping = <int, int>{};
        _byteOffset = mappingStart;
        for (var j = 0; j < mappingLength; j++) {
          final nodeOffset = readUint32();
          final metadataOffset = readUint32();
          mapping[nodeOffset] = metadataOffset;
        }

        _subsections ??= <_MetadataSubsection>[];
        _subsections.add(new _MetadataSubsection(
            repository, mapping, offsetToReferenceId, referencedNodes));
      }

      // Start of the subsection and the end of the previous one.
      endOffset = mappingStart - 4;
    }

    return containsNodeReferences;
  }

  @override
  void _processPendingMetadataAssociations(Component component) {
    if (_subsections == null) {
      return;
    }

    _associateMetadata(component, _componentStartOffset);

    for (var subsection in _subsections) {
      if (subsection.pending == null) {
        continue;
      }

      _referencedNodes = subsection.referencedNodes;
      for (var i = 0; i < subsection.pending.length; i += 2) {
        final Node node = subsection.pending[i];
        final int metadataOffset = subsection.pending[i + 1];
        subsection.repository.mapping[node] =
            _readMetadata(subsection.repository, metadataOffset);
      }
    }
  }

  Object _readMetadata(MetadataRepository repository, int offset) {
    final int savedOffset = _byteOffset;
    _byteOffset = offset;
    final metadata = repository.readFromBinary(this);
    _byteOffset = savedOffset;
    return metadata;
  }

  Node _associateMetadata(Node node, int nodeOffset) {
    if (_subsections == null) {
      return node;
    }

    for (var subsection in _subsections) {
      // First check if there is any metadata associated with this node.
      final metadataOffset = subsection.mapping[nodeOffset];
      if (metadataOffset != null) {
        if (subsection.nodeOffsetToReferenceId == null) {
          // This subsection does not contain any references to nodes from
          // inside the payload. In this case we can deserialize metadata
          // eagerly.
          subsection.repository.mapping[node] =
              _readMetadata(subsection.repository, metadataOffset);
        } else {
          // Metadata payload might contain references to nodes that
          // are not yet deserialized. Postpone association of metadata
          // with this node.
          subsection.pending ??= <Object>[];
          subsection.pending..add(node)..add(metadataOffset);
        }
      }

      // Check if this node is referenced from this section and update
      // referencedNodes array if that is the case.
      if (subsection.nodeOffsetToReferenceId != null) {
        final id = subsection.nodeOffsetToReferenceId[nodeOffset];
        if (id != null) {
          subsection.referencedNodes[id] = node;
        }
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
  FunctionNode readFunctionNode(bool lazyLoadBody, int outerEndOffset) {
    final nodeOffset = _byteOffset;
    final result = super.readFunctionNode(lazyLoadBody, outerEndOffset);
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

  @override
  Node readNodeReference() {
    final id = readUInt();
    return id == 0 ? null : _referencedNodes[id - 1];
  }
}

/// Deserialized MetadataMapping corresponding to the given metadata repository.
class _MetadataSubsection {
  /// [MetadataRepository] that can read this subsection.
  final MetadataRepository repository;

  /// Deserialized mapping from node offsets to metadata offsets.
  final Map<int, int> mapping;

  /// Deserialized mapping from node offset to node reference ids.
  final Map<int, int> nodeOffsetToReferenceId;

  /// Array mapping node reference ids to corresponding nodes.
  /// Will be gradually filled as nodes are deserialized.
  final List<Node> referencedNodes;

  /// A list of pairs (Node, int metadataOffset) that describes pending
  /// metadata associations which will be processed once all nodes
  /// are parsed.
  List<Object> pending;

  _MetadataSubsection(this.repository, this.mapping,
      this.nodeOffsetToReferenceId, this.referencedNodes);
}
