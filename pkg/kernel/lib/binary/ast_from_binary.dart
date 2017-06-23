// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_from_binary;

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

class BinaryBuilder {
  final List<VariableDeclaration> variableStack = <VariableDeclaration>[];
  final List<LabeledStatement> labelStack = <LabeledStatement>[];
  int labelStackBase = 0;
  final List<SwitchCase> switchCaseStack = <SwitchCase>[];
  final List<TypeParameter> typeParameterStack = <TypeParameter>[];
  final String filename;
  final List<int> _bytes;
  int _byteIndex = 0;
  final List<String> _stringTable = <String>[];
  final List<String> _sourceUriTable = <String>[];
  List<CanonicalName> _linkTable;
  int _transformerFlags = 0;
  Library _currentLibrary;

  // If something goes wrong, this list should indicate what library,
  // class, and member was being built.
  List<String> debugPath = <String>[];

  bool _isReadingLibraryImplementation = false;

  BinaryBuilder(this._bytes, [this.filename]);

  fail(String message) {
    throw new ParseError(message,
        byteIndex: _byteIndex, filename: filename, path: debugPath.join('::'));
  }

  int readByte() => _bytes[_byteIndex++];

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

  int readMagicWord() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  List<int> readUtf8Bytes() {
    List<int> bytes = new Uint8List(readUInt());
    bytes.setRange(0, bytes.length, _bytes, _byteIndex);
    _byteIndex += bytes.length;
    return bytes;
  }

  String readStringEntry(int numBytes) {
    // Utf8Decoder will skip leading BOM characters, but we must preserve them.
    // Collect leading BOMs before passing the bytes onto Utf8Decoder.
    int numByteOrderMarks = 0;
    while (_byteIndex + 2 < _bytes.length &&
        _bytes[_byteIndex] == 0xef &&
        _bytes[_byteIndex + 1] == 0xbb &&
        _bytes[_byteIndex + 2] == 0xbf) {
      ++numByteOrderMarks;
      _byteIndex += 3;
      numBytes -= 3;
    }
    String string =
        const Utf8Decoder().convert(_bytes, _byteIndex, _byteIndex + numBytes);
    _byteIndex += numBytes;
    if (numByteOrderMarks > 0) {
      return '\ufeff' * numByteOrderMarks + string;
    }
    return string;
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

  String readUriReference() {
    return _sourceUriTable[readUInt()];
  }

  String readStringReference() {
    return _stringTable[readUInt()];
  }

  List<String> readStringReferenceList() {
    return new List<String>.generate(readUInt(), (i) => readStringReference());
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
      List<TreeNode> list, TreeNode buildObject(), TreeNode parent) {
    list.length = readUInt();
    for (int i = 0; i < list.length; ++i) {
      list[i] = buildObject()..parent = parent;
    }
  }

  void _fillNonTreeNodeList(List<Node> list, Node buildObject()) {
    list.length = readUInt();
    for (int i = 0; i < list.length; ++i) {
      list[i] = buildObject();
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
      List<NamedNode> list, NamedNode readObject(), TreeNode parent) {
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
        var value = readObject();
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

  /// Deserializes a kernel program and stores it in [program].
  ///
  /// When linking with a non-empty program, canonical names must have been
  /// computed ahead of time.
  ///
  /// The input bytes may contain multiple files concatenated.
  void readProgram(Program program) {
    while (_byteIndex < _bytes.length) {
      _readOneProgram(program);
    }
  }

  /// Reads a single program file from the input and loads it into [program],
  /// overwriting and reusing any existing data in the program.
  ///
  /// When linking with a non-empty program, canonical names must have been
  /// computed ahead of time.
  ///
  /// This should *only* be used when there is a reason to not allow
  /// concatenated files.
  void readSingleFileProgram(Program program) {
    _readOneProgram(program);
    if (_byteIndex < _bytes.length) {
      if (_byteIndex + 3 < _bytes.length) {
        int magic = readMagicWord();
        if (magic == Tag.ProgramFile) {
          throw 'Concatenated program file given when a single program '
              'was expected.';
        }
      }
      throw 'Unrecognized bytes following program data';
    }
  }

  void _readOneProgram(Program program) {
    int magic = readMagicWord();
    if (magic != Tag.ProgramFile) {
      throw fail('This is not a binary dart file. '
          'Magic number was: ${magic.toRadixString(16)}');
    }
    readStringTable(_stringTable);
    Map<String, Source> uriToSource = readUriToSource();
    program.uriToSource.addAll(uriToSource);
    readLinkTable(program.root);
    int numberOfLibraries = readUInt();
    List<Library> libraries = new List<Library>(numberOfLibraries);
    for (int i = 0; i < numberOfLibraries; ++i) {
      libraries[i] = readLibrary(program);
    }
    var mainMethod = readMemberReference(allowNull: true);
    program.mainMethodName ??= mainMethod;
  }

  Map<String, Source> readUriToSource() {
    readStringTable(_sourceUriTable);
    int length = _sourceUriTable.length;
    Map<String, Source> uriToSource = <String, Source>{};
    for (int i = 0; i < length; ++i) {
      String uri = _sourceUriTable[i];
      List<int> sourceCode = readUtf8Bytes();
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
    return uriToSource;
  }

  CanonicalName readCanonicalNameReference() {
    var index = readUInt();
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

  Reference readTypedefReference() {
    return readCanonicalNameReference().getReference();
  }

  Name readName() {
    String text = readStringReference();
    if (text.isNotEmpty && text[0] == '_') {
      return new Name.byReference(text, readLibraryReference());
    } else {
      return new Name(text);
    }
  }

  Library readLibrary(Program program) {
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
      program.libraries.add(library..parent = program);
    }
    _currentLibrary = library;
    String name = readStringOrNullIfEmpty();
    // TODO(jensj): We currently save (almost the same) uri twice.
    String fileUri = readUriReference();

    if (shouldWriteData) {
      library.isExternal = isExternal;
      library.name = name;
      library.fileUri = fileUri;
    }

    debugPath.add(library.name ?? library.importUri?.toString() ?? 'library');

    _fillTreeNodeList(library.annotations, readExpression, library);
    _readLibraryDependencies(library);
    _mergeNamedNodeList(library.typedefs, readTypedef, library);
    _mergeNamedNodeList(library.classes, readClass, library);
    _mergeNamedNodeList(library.fields, readField, library);
    _mergeNamedNodeList(library.procedures, readProcedure, library);

    debugPath.removeLast();
    _currentLibrary = null;
    return library;
  }

  void _readLibraryDependencies(Library library) {
    int length = readUInt();
    if (library.isExternal) {
      assert(length == 0);
      return;
    }
    library.dependencies.length = length;
    for (int i = 0; i < length; ++i) {
      var flags = readByte();
      var annotations = readExpressionList();
      var targetLibrary = readLibraryReference();
      var prefixName = readStringOrNullIfEmpty();
      var names = readCombinatorList();
      library.dependencies[i] = new LibraryDependency.byReference(
          flags, annotations, targetLibrary, prefixName, names)
        ..parent = library;
    }
  }

  Combinator readCombinator() {
    var isShow = readUInt() == 1;
    var names = readStringReferenceList();
    return new Combinator(isShow, names);
  }

  List<Combinator> readCombinatorList() {
    return new List<Combinator>.generate(readUInt(), (i) => readCombinator());
  }

  Typedef readTypedef() {
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Typedef node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Typedef(null, null, reference: reference);
    }
    int fileOffset = readOffset();
    String name = readStringReference();
    String fileUri = readUriReference();
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

  Class readClass() {
    int tag = readByte();
    assert(tag == Tag.Class);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Class node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Class(reference: reference)..level = ClassLevel.Temporary;
    }
    node.fileOffset = readOffset();
    int flags = readByte();
    node.isAbstract = flags & 0x1 != 0;
    int levelIndex = (flags >> 1) & 0x3;
    var level = ClassLevel.values[levelIndex + 1];
    if (level.index >= node.level.index) {
      node.level = level;
    }
    var name = readStringOrNullIfEmpty();
    var fileUri = readUriReference();
    var annotations = readAnnotationList(node);
    debugPath.add(node.name ?? 'normal-class');
    readAndPushTypeParameterList(node.typeParameters, node);
    var supertype = readSupertypeOption();
    var mixedInType = readSupertypeOption();
    _fillNonTreeNodeList(node.implementedTypes, readSupertype);
    _mergeNamedNodeList(node.fields, readField, node);
    _mergeNamedNodeList(node.constructors, readConstructor, node);
    _mergeNamedNodeList(node.procedures, readProcedure, node);
    typeParameterStack.length = 0;
    debugPath.removeLast();
    if (shouldWriteData) {
      node.name = name;
      node.fileUri = fileUri;
      node.annotations = annotations;
      node.supertype = supertype;
      node.mixedInType = mixedInType;
    }
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
    int fileOffset = readOffset();
    int fileEndOffset = readOffset();
    int flags = readByte();
    readUInt(); // parent class binary offset.
    var name = readName();
    var fileUri = readUriReference();
    var annotations = readAnnotationList(node);
    debugPath.add(node.name?.name ?? 'field');
    var type = readDartType();
    var initializer = readExpressionOption();
    int transformerFlags = getAndResetTransformerFlags();
    debugPath.removeLast();
    if (shouldWriteData) {
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
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    var flags = readByte();
    readUInt(); // parent class binary offset.
    var name = readName();
    var annotations = readAnnotationList(node);
    debugPath.add(node.name?.name ?? 'constructor');
    var function = readFunctionNode();
    pushVariableDeclarations(function.positionalParameters);
    pushVariableDeclarations(function.namedParameters);
    _fillTreeNodeList(node.initializers, readInitializer, node);
    variableStack.length = 0;
    var transformerFlags = getAndResetTransformerFlags();
    debugPath.removeLast();
    if (shouldWriteData) {
      node.fileOffset = fileOffset;
      node.fileEndOffset = fileEndOffset;
      node.flags = flags;
      node.name = name;
      node.annotations = annotations;
      node.function = function..parent = node;
      node.transformerFlags = transformerFlags;
    }
    return node;
  }

  Procedure readProcedure() {
    int tag = readByte();
    assert(tag == Tag.Procedure);
    var canonicalName = readCanonicalNameReference();
    var reference = canonicalName.getReference();
    Procedure node = reference.node;
    bool shouldWriteData = node == null || _isReadingLibraryImplementation;
    if (node == null) {
      node = new Procedure(null, null, null, reference: reference);
    }
    var fileOffset = readOffset();
    var fileEndOffset = readOffset();
    int kindIndex = readByte();
    var kind = ProcedureKind.values[kindIndex];
    var flags = readByte();
    readUInt(); // parent class binary offset.
    var name = readName();
    var fileUri = readUriReference();
    var annotations = readAnnotationList(node);
    debugPath.add(node.name?.name ?? 'procedure');
    var function = readFunctionNodeOption();
    var transformerFlags = getAndResetTransformerFlags();
    debugPath.removeLast();
    if (shouldWriteData) {
      node.fileOffset = fileOffset;
      node.fileEndOffset = fileEndOffset;
      node.kind = kind;
      node.flags = flags;
      node.name = name;
      node.fileUri = fileUri;
      node.annotations = annotations;
      node.function = function;
      node.function?.parent = node;
      node.transformerFlags = transformerFlags;
    }
    return node;
  }

  Initializer readInitializer() {
    int tag = readByte();
    switch (tag) {
      case Tag.InvalidInitializer:
        return new InvalidInitializer();
      case Tag.FieldInitializer:
        return new FieldInitializer.byReference(
            readMemberReference(), readExpression());
      case Tag.SuperInitializer:
        return new SuperInitializer.byReference(
            readMemberReference(), readArguments());
      case Tag.RedirectingInitializer:
        return new RedirectingInitializer.byReference(
            readMemberReference(), readArguments());
      case Tag.LocalInitializer:
        return new LocalInitializer(readAndPushVariableDeclaration());
      default:
        throw fail('Invalid initializer tag: $tag');
    }
  }

  FunctionNode readFunctionNodeOption() {
    return readAndCheckOptionTag() ? readFunctionNode() : null;
  }

  FunctionNode readFunctionNode() {
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
    labelStackBase = labelStack.length;
    var body = readStatementOption();
    labelStackBase = oldLabelStackBase;
    variableStack.length = variableStackHeight;
    typeParameterStack.length = typeParameterStackHeight;
    return new FunctionNode(body,
        typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount,
        positionalParameters: positional,
        namedParameters: named,
        returnType: returnType,
        asyncMarker: asyncMarker,
        dartAsyncMarker: dartAsyncMarker)
      ..fileOffset = offset
      ..fileEndOffset = endOffset;
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
    return new List<Expression>.generate(readUInt(), (i) => readExpression());
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
        return new InvalidExpression();
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
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperPropertyGet.byReference(
            readName(), readMemberReference(allowNull: true));
      case Tag.SuperPropertySet:
        addTransformerFlag(TransformerFlag.superCalls);
        return new SuperPropertySet.byReference(
            readName(), readExpression(), readMemberReference(allowNull: true));
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
        return new DirectMethodInvocation.byReference(
            readExpression(), readMemberReference(), readArguments());
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
        return new AsExpression(readExpression(), readDartType())
          ..fileOffset = offset;
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
        return new FunctionExpression(readFunctionNode());
      case Tag.Let:
        var variable = readVariableDeclaration();
        int stackHeight = variableStack.length;
        pushVariableDeclaration(variable);
        var body = readExpression();
        variableStack.length = stackHeight;
        return new Let(variable, body);
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
        return new ClosureCreation.byReference(
            topLevelFunctionReference, contextVector, functionType);
      default:
        throw fail('Invalid expression tag: $tag');
    }
  }

  List<MapEntry> readMapEntryList() {
    return new List<MapEntry>.generate(readUInt(), (i) => readMapEntry());
  }

  MapEntry readMapEntry() {
    return new MapEntry(readExpression(), readExpression());
  }

  List<Statement> readStatementList() {
    return new List<Statement>.generate(readUInt(), (i) => readStatement());
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
      case Tag.InvalidStatement:
        return new InvalidStatement();
      case Tag.ExpressionStatement:
        return new ExpressionStatement(readExpression());
      case Tag.Block:
        return readBlock();
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
        return new WhileStatement(readExpression(), readStatement());
      case Tag.DoStatement:
        return new DoStatement(readStatement(), readExpression());
      case Tag.ForStatement:
        int variableStackHeight = variableStack.length;
        var variables = readAndPushVariableDeclarationList();
        var condition = readExpressionOption();
        var updates = readExpressionList();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForStatement(variables, condition, updates, body);
      case Tag.ForInStatement:
      case Tag.AsyncForInStatement:
        bool isAsync = tag == Tag.AsyncForInStatement;
        int variableStackHeight = variableStack.length;
        var offset = readOffset();
        var variable = readAndPushVariableDeclaration();
        var iterable = readExpression();
        var body = readStatement();
        variableStack.length = variableStackHeight;
        return new ForInStatement(variable, iterable, body, isAsync: isAsync)
          ..fileOffset = offset;
      case Tag.SwitchStatement:
        var expression = readExpression();
        int count = readUInt();
        List<SwitchCase> cases =
            new List<SwitchCase>.generate(count, (i) => new SwitchCase.empty());
        switchCaseStack.addAll(cases);
        for (int i = 0; i < cases.length; ++i) {
          var caseNode = cases[i];
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
        switchCaseStack.length -= count;
        return new SwitchStatement(expression, cases);
      case Tag.ContinueSwitchStatement:
        int index = readUInt();
        return new ContinueSwitchStatement(switchCaseStack[index]);
      case Tag.IfStatement:
        return new IfStatement(
            readExpression(), readStatement(), readStatementOrNullIfEmpty());
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
        var function = readFunctionNode();
        return new FunctionDeclaration(variable, function)..fileOffset = offset;
      default:
        throw fail('Invalid statement tag: $tag');
    }
  }

  List<Catch> readCatchList() {
    return new List<Catch>.generate(readUInt(), (i) => readCatch());
  }

  Catch readCatch() {
    int variableStackHeight = variableStack.length;
    var guard = readDartType();
    var exception = readAndPushVariableDeclarationOption();
    var stackTrace = readAndPushVariableDeclarationOption();
    var body = readStatement();
    variableStack.length = variableStackHeight;
    return new Catch(exception, body, guard: guard, stackTrace: stackTrace);
  }

  Block readBlock() {
    int stackHeight = variableStack.length;
    var body = readStatementList();
    variableStack.length = stackHeight;
    return new Block(body);
  }

  Supertype readSupertype() {
    InterfaceType type = readDartType();
    return new Supertype.byReference(type.className, type.typeArguments);
  }

  Supertype readSupertypeOption() {
    return readAndCheckOptionTag() ? readSupertype() : null;
  }

  List<Supertype> readSupertypeList() {
    return new List<Supertype>.generate(readUInt(), (i) => readSupertype());
  }

  List<DartType> readDartTypeList() {
    return new List<DartType>.generate(readUInt(), (i) => readDartType());
  }

  List<NamedType> readNamedTypeList() {
    return new List<NamedType>.generate(readUInt(), (i) => readNamedType());
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
        assert(positional.length + named.length == totalParameterCount);
        var returnType = readDartType();
        typeParameterStack.length = typeParameterStackHeight;
        return new FunctionType(positional, returnType,
            typeParameters: typeParameters,
            requiredParameterCount: requiredParameterCount,
            namedParameters: named);
      case Tag.SimpleFunctionType:
        var positional = readDartTypeList();
        var returnType = readDartType();
        return new FunctionType(positional, returnType);
      case Tag.TypeParameterType:
        int index = readUInt();
        readUInt(); // offset of parameter list in the binary.
        readUInt(); // index in the list.
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
      list = new List<TypeParameter>.generate(
          length, (i) => new TypeParameter(null, null)..parent = parent);
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
    return new List<NamedExpression>.generate(
        readUInt(), (i) => readNamedExpression());
  }

  NamedExpression readNamedExpression() {
    return new NamedExpression(readStringReference(), readExpression());
  }

  List<VariableDeclaration> readAndPushVariableDeclarationList() {
    return new List<VariableDeclaration>.generate(
        readUInt(), (i) => readAndPushVariableDeclaration());
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
    int flags = readByte();
    return new VariableDeclaration(readStringOrNullIfEmpty(),
        type: readDartType(),
        initializer: readExpressionOption(),
        isFinal: flags & 0x1 != 0,
        isConst: flags & 0x2 != 0)
      ..fileOffset = offset
      ..fileEqualsOffset = fileEqualsOffset;
  }

  int readOffset() {
    // Offset is saved as unsigned,
    // but actually ranges from -1 and up (thus the -1)
    return readUInt() - 1;
  }
}
