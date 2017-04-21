// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast_to_binary;

import '../ast.dart';
import '../import_table.dart';
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
  final StringIndexer _stringIndexer = new StringIndexer();
  final StringIndexer _sourceUriIndexer = new StringIndexer();
  Map<DeferredImport, int> _deferredImportIndexer = <DeferredImport, int>{};

  final BufferedSink _sink;

  /// Create a printer that writes to the given [sink].
  ///
  /// The BinaryPrinter will use its own buffer, so the [sink] does not need
  /// one.
  ///
  /// If multiple binaries are to be written based on the same IR, a shared
  /// [globalIndexer] may be passed in to avoid rebuilding the same indices
  /// in every printer.
  BinaryPrinter(Sink<List<int>> sink) : _sink = new BufferedSink(sink);

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

  void writeMagicWord(int value) {
    writeByte((value >> 24) & 0xFF);
    writeByte((value >> 16) & 0xFF);
    writeByte((value >> 8) & 0xFF);
    writeByte(value & 0xFF);
  }

  void writeUtf8Bytes(List<int> utf8Bytes) {
    writeUInt30(utf8Bytes.length);
    writeBytes(utf8Bytes);
  }

  void writeStringTableEntry(String string) {
    List<int> utf8Bytes = const Utf8Encoder().convert(string);
    writeUInt30(utf8Bytes.length);
    writeBytes(utf8Bytes);
  }

  void writeStringTable(StringIndexer indexer) {
    writeUInt30(indexer.numberOfStrings);
    for (var entry in indexer.entries) {
      writeStringTableEntry(entry.value);
    }
  }

  void writeStringReference(String string) {
    writeUInt30(_stringIndexer[string]);
  }

  void writeUriReference(String string) {
    int index = _sourceUriIndexer[string];
    if (index == null) {
      // Assume file was loaded without linking. Bail out to empty string.
      index = _sourceUriIndexer[""];
    }
    writeUInt30(index);
  }

  void writeList(List items, writeItem(x)) {
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
    List<CanonicalName> list = <CanonicalName>[];
    void visitCanonicalName(CanonicalName node) {
      node.index = list.length;
      list.add(node);
      node.children.forEach(visitCanonicalName);
    }

    for (var library in program.libraries) {
      visitCanonicalName(library.canonicalName);
    }
    writeList(list, writeCanonicalNameEntry);
  }

  void writeCanonicalNameEntry(CanonicalName node) {
    var parent = node.parent;
    if (parent.isRoot) {
      writeByte(0);
    } else {
      writeUInt30(parent.index + 1);
    }
    writeStringReference(node.name);
  }

  void writeProgramFile(Program program) {
    program.computeCanonicalNames();
    writeMagicWord(Tag.ProgramFile);
    _stringIndexer.scanProgram(program);
    writeStringTable(_stringIndexer);
    writeUriToSource(program);
    writeLinkTable(program);
    writeList(program.libraries, writeNode);
    writeMemberReference(program.mainMethod, allowNull: true);
    _flush();
  }

  void writeUriToSource(Program program) {
    program.uriToSource.keys.forEach((uri) {
      _sourceUriIndexer.put(uri);
    });
    writeStringTable(_sourceUriIndexer);
    for (int i = 0; i < _sourceUriIndexer.entries.length; i++) {
      String uri = _sourceUriIndexer.entries[i].value;
      Source source =
          program.uriToSource[uri] ?? new Source(<int>[], const <int>[]);
      writeUtf8Bytes(source.source);
      List<int> lineStarts = source.lineStarts;
      writeUInt30(lineStarts.length);
      int previousLineStart = 0;
      lineStarts.forEach((lineStart) {
        writeUInt30(lineStart - previousLineStart);
        previousLineStart = lineStart;
      });
    }
  }

  void writeDeferredImportReference(DeferredImport node) {
    int index = _deferredImportIndexer[node];
    if (index == null) {
      throw 'Reference to deferred import $node out of scope';
    }
    writeUInt30(index);
  }

  void writeReference(Reference reference) {
    if (reference == null) {
      writeByte(0);
    } else {
      CanonicalName name = reference.canonicalName;
      if (name == null) {
        throw 'Missing canonical name for $reference';
      }
      writeUInt30(name.index + 1);
    }
  }

  void writeCanonicalNameReference(CanonicalName name) {
    if (name == null) {
      writeByte(0);
    } else {
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
    writeByte(insideExternalLibrary ? 1 : 0);
    writeCanonicalNameReference(getCanonicalNameOfLibrary(node));
    writeStringReference(node.name ?? '');
    // TODO(jensj): We save (almost) the same URI twice.
    writeUriReference(node.fileUri ?? '');
    writeDeferredImports(node);
    writeNodeList(node.classes);
    writeNodeList(node.fields);
    writeNodeList(node.procedures);
  }

  void writeDeferredImports(Library library) {
    _deferredImportIndexer = library.deferredImports.isEmpty
        ? const <DeferredImport, int>{}
        : <DeferredImport, int>{};
    writeUInt30(library.deferredImports.length);
    for (int i = 0; i < library.deferredImports.length; ++i) {
      var importNode = library.deferredImports[i];
      _deferredImportIndexer[importNode] = i;
      writeDeferredImport(importNode);
    }
  }

  void writeDeferredImport(DeferredImport node) {
    writeLibraryReference(node.importedLibrary);
    writeStringReference(node.name);
  }

  void writeAnnotation(Expression annotation) {
    _variableIndexer ??= new VariableIndexer();
    writeNode(annotation);
  }

  void writeAnnotationList(List<Expression> annotations) {
    writeList(annotations, writeAnnotation);
  }

  int _encodeClassFlags(bool isAbstract, ClassLevel level) {
    int abstactFlag = isAbstract ? 1 : 0;
    int levelFlags = (level.index - 1) << 1;
    return abstactFlag | levelFlags;
  }

  visitClass(Class node) {
    int flags = _encodeClassFlags(node.isAbstract, node.level);
    if (node.canonicalName == null) {
      throw 'Missing canonical name for $node';
    }
    writeByte(Tag.Class);
    writeCanonicalNameReference(getCanonicalNameOfClass(node));
    writeOffset(node.fileOffset);
    writeByte(flags);
    writeStringReference(node.name ?? '');
    writeUriReference(node.fileUri ?? '');
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
    writeAnnotationList(node.annotations);
    writeNode(node.type);
    writeOptionalNode(node.initializer);
    _variableIndexer = null;
  }

  visitInvalidInitializer(InvalidInitializer node) {
    writeByte(Tag.InvalidInitializer);
  }

  visitFieldInitializer(FieldInitializer node) {
    writeByte(Tag.FieldInitializer);
    writeReference(node.fieldReference);
    writeNode(node.value);
  }

  visitSuperInitializer(SuperInitializer node) {
    writeByte(Tag.SuperInitializer);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitRedirectingInitializer(RedirectingInitializer node) {
    writeByte(Tag.RedirectingInitializer);
    writeReference(node.targetReference);
    writeNode(node.arguments);
  }

  visitLocalInitializer(LocalInitializer node) {
    writeByte(Tag.LocalInitializer);
    writeVariableDeclaration(node.variable);
  }

  visitFunctionNode(FunctionNode node) {
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
    } else {
      writeByte(Tag.VariableGet);
      writeOffset(node.fileOffset);
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
      writeNode(node.value);
    } else {
      writeByte(Tag.VariableSet);
      writeOffset(node.fileOffset);
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
    writeDeferredImportReference(node.import);
  }

  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    writeByte(Tag.CheckLibraryIsLoaded);
    writeDeferredImportReference(node.import);
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
    writeNode(node.condition);
    writeNode(node.body);
  }

  visitDoStatement(DoStatement node) {
    writeByte(Tag.DoStatement);
    writeNode(node.body);
    writeNode(node.condition);
  }

  visitForStatement(ForStatement node) {
    _variableIndexer.pushScope();
    writeByte(Tag.ForStatement);
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
    writeVariableDeclaration(node.variable);
    writeNode(node.iterable);
    writeNode(node.body);
    _variableIndexer.popScope();
  }

  visitSwitchStatement(SwitchStatement node) {
    _switchCaseIndexer.enter(node);
    writeByte(Tag.SwitchStatement);
    writeNode(node.expression);
    writeNodeList(node.cases);
    _switchCaseIndexer.exit(node);
  }

  visitSwitchCase(SwitchCase node) {
    // Note: there is no tag on SwitchCase.
    writeNodeList(node.expressions);
    node.expressionOffsets.forEach(writeOffset);
    writeByte(node.isDefault ? 1 : 0);
    writeNode(node.body);
  }

  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    writeByte(Tag.ContinueSwitchStatement);
    writeUInt30(_switchCaseIndexer[node.target]);
  }

  visitIfStatement(IfStatement node) {
    writeByte(Tag.IfStatement);
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
        node.namedParameters.isEmpty) {
      writeByte(Tag.SimpleFunctionType);
      writeNodeList(node.positionalParameters);
      writeNode(node.returnType);
    } else {
      writeByte(Tag.FunctionType);
      _typeParameterIndexer.enter(node.typeParameters);
      writeNodeList(node.typeParameters);
      writeUInt30(node.requiredParameterCount);
      writeNodeList(node.positionalParameters);
      writeNodeList(node.namedParameters);
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
  }

  visitVectorType(VectorType node) {
    writeByte(Tag.VectorType);
  }

  visitTypeParameter(TypeParameter node) {
    writeStringReference(node.name ?? '');
    writeNode(node.bound);
  }

  defaultNode(Node node) {
    throw 'Unsupported node: $node';
  }
}

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

class StringTableEntry implements Comparable<StringTableEntry> {
  final String value;
  int frequency = 0;

  StringTableEntry(this.value);

  int compareTo(StringTableEntry other) => other.frequency - frequency;
}

class StringIndexer extends RecursiveVisitor<Null> {
  final List<StringTableEntry> entries = <StringTableEntry>[];
  final LinkedHashMap<String, int> index = new LinkedHashMap<String, int>();

  StringIndexer() {
    put('');
  }

  int get numberOfStrings => index.length;

  void scanProgram(Node node) {
    node.accept(this);
    entries.sort();
    for (int i = 0; i < entries.length; ++i) {
      index[entries[i].value] = i;
    }
  }

  void visitCanonicalName(CanonicalName name) {
    put(name.name);
    name.children.forEach(visitCanonicalName);
  }

  void put(String string) {
    int i = index.putIfAbsent(string, () {
      entries.add(new StringTableEntry(string));
      return index.length;
    });
    ++entries[i].frequency;
  }

  void putOptional(String string) {
    if (string != null) {
      put(string);
    }
  }

  int operator [](String string) => index[string];

  void addLibraryImports(LibraryImportTable imports) {
    imports.importPaths.forEach(put);
  }

  visitName(Name node) {
    put(node.name);
  }

  visitLibrary(Library node) {
    visitCanonicalName(node.canonicalName);
    putOptional(node.name);
    put('${node.importUri}');
    node.visitChildren(this);
  }

  visitDeferredImport(DeferredImport node) {
    put(node.name);
  }

  visitClass(Class node) {
    putOptional(node.name);
    node.visitChildren(this);
  }

  visitNamedExpression(NamedExpression node) {
    put(node.name);
    node.visitChildren(this);
  }

  visitStringLiteral(StringLiteral node) {
    put(node.value);
  }

  visitIntLiteral(IntLiteral node) {
    if (node.value.abs() >> 30 != 0) {
      put('${node.value}');
    }
  }

  visitDoubleLiteral(DoubleLiteral node) {
    put('${node.value}');
  }

  visitSymbolLiteral(SymbolLiteral node) {
    put(node.value);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    putOptional(node.name);
    node.visitChildren(this);
  }

  visitNamedType(NamedType node) {
    put(node.name);
    node.visitChildren(this);
  }

  visitTypeParameter(TypeParameter node) {
    putOptional(node.name);
    node.visitChildren(this);
  }
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

  BufferedSink(this._sink);

  void addByte(int byte) {
    _buffer[length++] = byte;
    if (length == SIZE) {
      _sink.add(_buffer);
      _buffer = new Uint8List(SIZE);
      length = 0;
    }
  }

  void addBytes(List<int> bytes) {
    // Avoid copying a large buffer into the another large buffer. Also, if
    // the bytes buffer is too large to fit in our own buffer, just emit both.
    if (length + bytes.length < SIZE &&
        (bytes.length < SMALL || length < SMALL)) {
      if (length == 0) {
        _sink.add(bytes);
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
    } else {
      _sink.add(_buffer.sublist(0, length));
      _sink.add(bytes);
      _buffer = new Uint8List(SIZE);
      length = 0;
    }
  }

  void flush() {
    _sink.add(_buffer.sublist(0, length));
    _buffer = new Uint8List(SIZE);
    length = 0;
  }

  void flushAndDestroy() {
    _sink.add(_buffer.sublist(0, length));
  }
}
