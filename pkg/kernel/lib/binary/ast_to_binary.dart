// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_to_binary;

import '../ast.dart';
import 'tag.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';

/// Writes to a binary file.
///
/// A [BinaryPrinter] can be used to write one file and must then be
/// discarded.
class BinaryPrinter extends Visitor {
  VariableIndexer _variableIndexer;
  LabelIndexer _labelIndexer;
  SwitchCaseIndexer _switchCaseIndexer;
  final TypeParameterIndexer _typeParameterIndexer = new TypeParameterIndexer();
  final StringIndexer stringIndexer;
  final StringIndexer _sourceUriIndexer = new StringIndexer();
  final Set<String> _knownSourceUri = new Set<String>();
  Map<LibraryDependency, int> _libraryDependencyIndex =
      <LibraryDependency, int>{};

  final BufferedSink _sink;

  int _binaryOffsetForSourceTable = -1;
  int _binaryOffsetForStringTable = -1;
  int _binaryOffsetForLinkTable = -1;

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
        stringIndexer = stringIndexer ?? new StringIndexer();

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
      writeByte(value);
    } else if (value < 0x4000) {
      writeByte((value >> 8) | 0x80);
      writeByte(value & 0xFF);
    } else {
      writeByte((value >> 24) | 0xC0);
      writeByte((value >> 16) & 0xFF);
      writeByte((value >> 8) & 0xFF);
      writeByte(value & 0xFF);
    }
  }

  void writeUInt32(int value) {
    writeByte((value >> 24) & 0xFF);
    writeByte((value >> 16) & 0xFF);
    writeByte((value >> 8) & 0xFF);
    writeByte(value & 0xFF);
  }

  void writeUtf8Bytes(List<int> utf8Bytes) {
    writeUInt30(utf8Bytes.length);
    writeBytes(utf8Bytes);
  }

  void writeStringTable(StringIndexer indexer, bool updateBinaryOffset) {
    if (updateBinaryOffset) {
      _binaryOffsetForStringTable = _sink.flushedLength + _sink.length;
    }

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

  void writeUriReference(String string) {
    int index = 0; // equivalent to index = _sourceUriIndexer[""];
    if (_knownSourceUri.contains(string)) {
      index = _sourceUriIndexer.put(string);
    }
    writeUInt30(index);
  }

  void writeList<T>(List<T> items, void writeItem(T x)) {
    writeUInt30(items.length);
    items.forEach(writeItem);
  }

  void writeNodeList(List<Node> nodes) {
    writeList(nodes, writeNode);
  }

  void writeNode(Node node) {
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

  void writeLinkTable(Program program) {
    _binaryOffsetForLinkTable = _sink.flushedLength + _sink.length;
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
    writeUInt32(Tag.ProgramFile);
    indexLinkTable(program);
    indexUris(program);
    writeLibraries(program);
    writeUriToSource(program.uriToSource);
    writeLinkTable(program);
    writeStringTable(stringIndexer, true);
    writeProgramIndex(program, program.libraries);

    _flush();
  }

  /// Write all of some of the libraries of the [program].
  void writeLibraries(Program program) {
    writeList(program.libraries, writeNode);
  }

  void writeProgramIndex(Program program, List<Library> libraries) {
    // Fixed-size ints at the end used as an index.
    assert(_binaryOffsetForSourceTable >= 0);
    writeUInt32(_binaryOffsetForSourceTable);
    assert(_binaryOffsetForLinkTable >= 0);
    writeUInt32(_binaryOffsetForLinkTable);
    assert(_binaryOffsetForStringTable >= 0);
    writeUInt32(_binaryOffsetForStringTable);

    CanonicalName main = getCanonicalNameOfMember(program.mainMethod);
    if (main == null) {
      writeUInt32(0);
    } else {
      writeUInt32(main.index + 1);
    }
    for (Library library in libraries) {
      assert(library.binaryOffset >= 0);
      writeUInt32(library.binaryOffset);
    }
    writeUInt32(libraries.length);
    writeUInt32(_sink.flushedLength + _sink.length + 4); // total size.
  }

  void indexUris(Program program) {
    _knownSourceUri.addAll(program.uriToSource.keys);
  }

  void writeUriToSource(Map<String, Source> uriToSource) {
    _binaryOffsetForSourceTable = _sink.flushedLength + _sink.length;

    int length = _sourceUriIndexer.numberOfStrings;
    writeUInt32(length);
    List<int> index = new List<int>(_sourceUriIndexer.entries.length);

    // Write data.
    for (int i = 0; i < length; ++i) {
      index[i] = _sink.flushedLength + _sink.length;

      StringTableEntry uri = _sourceUriIndexer.entries[i];
      Source source =
          uriToSource[uri.value] ?? new Source(<int>[], const <int>[]);

      writeUtf8Bytes(uri.utf8Bytes);
      writeUtf8Bytes(source.source);
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
    node.binaryOffset = _sink.flushedLength + _sink.length;
    writeByte(insideExternalLibrary ? 1 : 0);
    writeCanonicalNameReference(getCanonicalNameOfLibrary(node));
    writeStringReference(node.name ?? '');
    writeStringReference(node.documentationComment ?? '');
    // TODO(jensj): We save (almost) the same URI twice.
    writeUriReference(node.fileUri ?? '');
    writeAnnotationList(node.annotations);
    writeLibraryDependencies(node);
    writeAdditionalExports(node.additionalExports);
    writeLibraryParts(node);
    writeNodeList(node.typedefs);
    writeNodeList(node.classes);
    writeNodeList(node.fields);
    writeNodeList(node.procedures);
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
    writeNodeList(node.annotations);
    writeStringReference(node.fileUri ?? '');
  }

  void visitTypedef(Typedef node) {
    writeCanonicalNameReference(getCanonicalNameOfTypedef(node));
    writeOffset(node.fileOffset);
    writeStringReference(node.name);
    writeUriReference(node.fileUri ?? '');
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
    writeList(annotations, writeAnnotation);
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
    writeUriReference(node.fileUri ?? '');
    writeStringReference(node.documentationComment ?? '');
    writeAnnotationList(node.annotations);
    _typeParameterIndexer.enter(node.typeParameters);
    writeNodeList(node.typeParameters);
    writeOptionalNode(node.supertype);
    writeOptionalNode(node.mixedInType);
    writeNodeList(node.implementedTypes);
    writeNodeList(node.fields);
    writeNodeList(node.constructors);
    writeNodeList(node.procedures);
    _typeParameterIndexer.exit(node.typeParameters);
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
    writeStringReference(node.documentationComment ?? '');
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
    writeUriReference(node.fileUri ?? '');
    writeStringReference(node.documentationComment ?? '');
    writeAnnotationList(node.annotations);
    writeOptionalNode(node.function);
    _variableIndexer = null;
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
    writeName(node.name);
    writeUriReference(node.fileUri ?? '');
    writeStringReference(node.documentationComment ?? '');
    writeAnnotationList(node.annotations);
    writeNode(node.type);
    writeOptionalNode(node.initializer);
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

  visitFunctionNode(FunctionNode node) {
    writeByte(Tag.FunctionNode);
    assert(_variableIndexer != null);
    _variableIndexer.pushScope();
    var oldLabels = _labelIndexer;
    _labelIndexer = new LabelIndexer();
    var oldCases = _switchCaseIndexer;
    _switchCaseIndexer = new SwitchCaseIndexer();
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
    writeNode(node.receiver);
    writeName(node.name);
    writeReference(node.interfaceTargetReference);
  }

  visitPropertySet(PropertySet node) {
    writeByte(Tag.PropertySet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeName(node.name);
    writeNode(node.value);
    writeReference(node.interfaceTargetReference);
  }

  visitSuperPropertyGet(SuperPropertyGet node) {
    writeByte(Tag.SuperPropertyGet);
    writeName(node.name);
    writeReference(node.interfaceTargetReference);
  }

  visitSuperPropertySet(SuperPropertySet node) {
    writeByte(Tag.SuperPropertySet);
    writeName(node.name);
    writeNode(node.value);
    writeReference(node.interfaceTargetReference);
  }

  visitDirectPropertyGet(DirectPropertyGet node) {
    writeByte(Tag.DirectPropertyGet);
    writeOffset(node.fileOffset);
    writeNode(node.receiver);
    writeReference(node.targetReference);
  }

  visitDirectPropertySet(DirectPropertySet node) {
    writeByte(Tag.DirectPropertySet);
    writeOffset(node.fileOffset);
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
    writeNode(node.operand);
    writeNode(node.type);
  }

  visitStringLiteral(StringLiteral node) {
    writeByte(Tag.StringLiteral);
    writeStringReference(node.value);
  }

  visitIntLiteral(IntLiteral node) {
    int value = node.value;
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
      writeStringReference('${node.value}');
    }
  }

  visitDoubleLiteral(DoubleLiteral node) {
    // TODO: Pick a better format for double literals.
    writeByte(Tag.DoubleLiteral);
    writeStringReference('${node.value}');
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

  visitInvalidStatement(InvalidStatement node) {
    writeByte(Tag.InvalidStatement);
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
    _labelIndexer.enter(node);
    writeByte(Tag.LabeledStatement);
    writeNode(node.body);
    _labelIndexer.exit();
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
    node.binaryOffsetNoTag = _sink.flushedLength + _sink.length;
    writeOffset(node.fileOffset);
    writeOffset(node.fileEqualsOffset);
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
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
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
    return index.putIfAbsent(string, () {
      entries.add(new StringTableEntry(string));
      return index.length;
    });
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
