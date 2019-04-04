// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

import '../text/serializer_combinators.dart'
    show DeserializationState, SerializationState, TextSerializer;

import '../text/text_reader.dart' show TextIterator;

import '../text/text_serializer.dart'
    show
        dartTypeSerializer,
        expressionSerializer,
        initializeSerializers,
        statementSerializer;

import '../visitor.dart' show Visitor;

const Uri noUri = null;

const int noOffset = -1;

abstract class TextSerializationVerificationFailure {
  /// [Uri] of the file containing the expression that produced an error during
  /// the round trip.
  final Uri uri;

  /// Offset within the file with [uri] of the expression that produced an error
  /// during the round trip.
  final int offset;

  TextSerializationVerificationFailure(this.uri, this.offset);
}

class TextSerializationFailure extends TextSerializationVerificationFailure {
  final String message;

  TextSerializationFailure(this.message, Uri uri, int offset)
      : super(uri, offset);
}

class TextDeserializationFailure extends TextSerializationVerificationFailure {
  final String message;

  TextDeserializationFailure(this.message, Uri uri, int offset)
      : super(uri, offset);
}

class TextRoundTripFailure extends TextSerializationVerificationFailure {
  final String initial;
  final String serialized;

  TextRoundTripFailure(this.initial, this.serialized, Uri uri, int offset)
      : super(uri, offset);
}

class TextSerializationVerifier implements Visitor<void> {
  /// List of errors produced during round trips on the visited nodes.
  final List<TextSerializationVerificationFailure> failures =
      <TextSerializationVerificationFailure>[];

  Uri lastSeenUri = noUri;

  int lastSeenOffset = noOffset;

  TextSerializationVerifier() {
    initializeSerializers();
  }

  void storeLastSeenUriAndOffset(Node node) {
    if (node is TreeNode) {
      Location location = node.location;
      if (location != null) {
        lastSeenUri = location.file;
        lastSeenOffset = node.fileOffset;
      }
    }
  }

  T readNode<T extends Node>(
      String input, TextSerializer<T> serializer, Uri uri, int offset) {
    TextIterator stream = new TextIterator(input, 0);
    stream.moveNext();
    T result;
    try {
      result = serializer.readFrom(
          stream, new DeserializationState(null, new CanonicalName.root()));
    } catch (exception) {
      failures.add(
          new TextDeserializationFailure(exception.toString(), uri, offset));
    }
    if (stream.moveNext()) {
      failures.add(new TextDeserializationFailure(
          "unexpected trailing text", uri, offset));
    }
    return result;
  }

  String writeNode<T extends Node>(
      T node, TextSerializer<T> serializer, Uri uri, int offset) {
    StringBuffer buffer = new StringBuffer();
    try {
      serializer.writeTo(buffer, node, new SerializationState(null));
    } catch (exception) {
      failures
          .add(new TextSerializationFailure(exception.toString(), uri, offset));
    }
    return buffer.toString();
  }

  void makeExpressionRoundTrip(Expression node) {
    Uri uri = noUri;
    int offset = noOffset;
    Location location = node.location;
    if (location != null) {
      uri = location.file;
      offset = node.fileOffset;
    }

    String initial = writeNode(node, expressionSerializer, uri, offset);

    // Do the round trip.
    Expression deserialized =
        readNode(initial, expressionSerializer, uri, offset);
    String serialized =
        writeNode(deserialized, expressionSerializer, uri, offset);

    if (initial != serialized) {
      failures.add(new TextRoundTripFailure(initial, serialized, uri, offset));
    }
  }

  void makeDartTypeRoundTrip(DartType node) {
    Uri uri = lastSeenUri;
    int offset = lastSeenOffset;

    String initial = writeNode(node, dartTypeSerializer, uri, offset);

    // Do the round trip.
    DartType deserialized = readNode(initial, dartTypeSerializer, uri, offset);
    String serialized =
        writeNode(deserialized, dartTypeSerializer, uri, offset);

    if (initial != serialized) {
      failures.add(new TextRoundTripFailure(initial, serialized, uri, offset));
    }
  }

  void makeStatementRoundTrip(Statement node) {
    Uri uri = noUri;
    int offset = noOffset;
    Location location = node.location;
    if (location != null) {
      uri = location.file;
      offset = node.fileOffset;
    }

    String initial = writeNode(node, statementSerializer, uri, offset);

    // Do the round trip.
    Statement deserialized =
        readNode(initial, statementSerializer, uri, offset);
    String serialized =
        writeNode(deserialized, expressionSerializer, uri, offset);

    if (initial != serialized) {
      failures.add(new TextRoundTripFailure(initial, serialized, uri, offset));
    }
  }

  @override
  void defaultExpression(Expression node) {
    throw new UnsupportedError("defaultExpression");
  }

  @override
  void defaultMemberReference(Member node) {
    throw new UnsupportedError("defaultMemberReference");
  }

  @override
  void defaultConstantReference(Constant node) {
    throw new UnsupportedError("defaultConstantReference");
  }

  @override
  void defaultConstant(Constant node) {
    throw new UnsupportedError("defaultConstant");
  }

  @override
  void defaultDartType(DartType node) {
    throw new UnsupportedError("defaultDartType");
  }

  @override
  void defaultTreeNode(TreeNode node) {
    throw new UnsupportedError("defaultTreeNode");
  }

  @override
  void defaultNode(Node node) {
    throw new UnsupportedError("defaultNode");
  }

  @override
  void defaultInitializer(Initializer node) {
    throw new UnsupportedError("defaultInitializer");
  }

  @override
  void defaultMember(Member node) {
    throw new UnsupportedError("defaultMember");
  }

  @override
  void defaultStatement(Statement node) {
    throw new UnsupportedError("defaultStatement");
  }

  @override
  void defaultBasicLiteral(BasicLiteral node) {
    throw new UnsupportedError("defaultBasicLiteral");
  }

  @override
  void visitNamedType(NamedType node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSupertype(Supertype node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitName(Name node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {}

  @override
  void visitProcedureReference(Procedure node) {}

  @override
  void visitConstructorReference(Constructor node) {}

  @override
  void visitFieldReference(Field node) {}

  @override
  void visitTypeLiteralConstantReference(TypeLiteralConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTearOffConstantReference(TearOffConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitPartialInstantiationConstantReference(
      PartialInstantiationConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitListConstantReference(ListConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSetConstantReference(SetConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitMapConstantReference(MapConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstantReference(SymbolConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitStringConstantReference(StringConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstantReference(DoubleConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitIntConstantReference(IntConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitBoolConstantReference(BoolConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitNullConstantReference(NullConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitUnevaluatedConstantReference(UnevaluatedConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTypedefReference(Typedef node) {}

  @override
  void visitClassReference(Class node) {}

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTearOffConstant(TearOffConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitListConstant(ListConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSetConstant(SetConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitMapConstant(MapConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreation(InstanceCreation node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitStringConstant(StringConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitIntConstant(IntConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitNullConstant(NullConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTypedefType(TypedefType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitFunctionType(FunctionType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitBottomType(BottomType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitVoidType(VoidType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitDynamicType(DynamicType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitInvalidType(InvalidType node) {
    storeLastSeenUriAndOffset(node);
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitComponent(Component node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitMapEntry(MapEntry node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitCatch(Catch node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitArguments(Arguments node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitTypedef(Typedef node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitCombinator(Combinator node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitField(Field node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitProcedure(Procedure node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitConstructor(Constructor node) {
    storeLastSeenUriAndOffset(node);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitTryFinally(TryFinally node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitTryCatch(TryCatch node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitBlock(Block node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    storeLastSeenUriAndOffset(node);
    makeStatementRoundTrip(node);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitInstantiation(Instantiation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLet(Let node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitThrow(Throw node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitRethrow(Rethrow node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitListConcatenation(ListConcatenation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSetConcatenation(SetConcatenation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitMapConcatenation(MapConcatenation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitNot(Not node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticSet(StaticSet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitPropertySet(PropertySet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    storeLastSeenUriAndOffset(node);
    makeExpressionRoundTrip(node);
  }
}
