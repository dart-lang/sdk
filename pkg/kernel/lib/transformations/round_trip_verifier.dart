// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

import '../visitor.dart' show Visitor;

abstract class RoundTripFailure {
  /// [Uri] of the file containing the expression that produced an error during
  /// the round trip.
  final Uri uri;

  /// Offset within the file with [uri] of the expression that produced an error
  /// during the round trip.
  final int offset;

  RoundTripFailure(this.uri, this.offset);
}

class RoundTripSerializationFailure extends RoundTripFailure {
  RoundTripSerializationFailure(Uri uri, int offset) : super(uri, offset);
}

class RoundTripDeserializationFailure extends RoundTripFailure {
  RoundTripDeserializationFailure(Uri uri, int offset) : super(uri, offset);
}

class RoundTripMismatchFailure extends RoundTripFailure {
  RoundTripMismatchFailure(Uri uri, int offset) : super(uri, offset);
}

class RoundTripVerifier implements Visitor<void> {
  /// List of errors produced during round trips on the visited nodes.
  final List<RoundTripFailure> errors = <RoundTripFailure>[];

  RoundTripVerifier();

  void makeExpressionRoundTrip(Expression node) {
    throw new UnimplementedError("makeExpressionRoundTrip");
  }

  void makeDartTypeRoundTrip(DartType node) {
    throw new UnimplementedError("makeDartTypeRoundTrip");
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
    node.visitChildren(this);
  }

  @override
  void visitSupertype(Supertype node) {
    node.visitChildren(this);
  }

  @override
  void visitName(Name node) {
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {
    node.visitChildren(this);
  }

  @override
  void visitProcedureReference(Procedure node) {
    node.visitChildren(this);
  }

  @override
  void visitConstructorReference(Constructor node) {
    node.visitChildren(this);
  }

  @override
  void visitFieldReference(Field node) {
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteralConstantReference(TypeLiteralConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitTearOffConstantReference(TearOffConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitPartialInstantiationConstantReference(
      PartialInstantiationConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitListConstantReference(ListConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitMapConstantReference(MapConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstantReference(SymbolConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitStringConstantReference(StringConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstantReference(DoubleConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitIntConstantReference(IntConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitBoolConstantReference(BoolConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitNullConstantReference(NullConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitTypedefReference(Typedef node) {
    node.visitChildren(this);
  }

  @override
  void visitClassReference(Class node) {
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitTearOffConstant(TearOffConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitListConstant(ListConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitMapConstant(MapConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitStringConstant(StringConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitIntConstant(IntConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitNullConstant(NullConstant node) {
    node.visitChildren(this);
  }

  @override
  void visitTypedefType(TypedefType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitFunctionType(FunctionType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitBottomType(BottomType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitVoidType(VoidType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitDynamicType(DynamicType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitInvalidType(InvalidType node) {
    makeDartTypeRoundTrip(node);
  }

  @override
  void visitComponent(Component node) {
    node.visitChildren(this);
  }

  @override
  void visitMapEntry(MapEntry node) {
    node.visitChildren(this);
  }

  @override
  void visitCatch(Catch node) {
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitArguments(Arguments node) {
    node.visitChildren(this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
  }

  @override
  void visitTypedef(Typedef node) {
    node.visitChildren(this);
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    node.visitChildren(this);
  }

  @override
  void visitCombinator(Combinator node) {
    node.visitChildren(this);
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library node) {
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    node.visitChildren(this);
  }

  @override
  void visitField(Field node) {
    node.visitChildren(this);
  }

  @override
  void visitProcedure(Procedure node) {
    node.visitChildren(this);
  }

  @override
  void visitConstructor(Constructor node) {
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitTryFinally(TryFinally node) {
    node.visitChildren(this);
  }

  @override
  void visitTryCatch(TryCatch node) {
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    node.visitChildren(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitInstantiation(Instantiation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLet(Let node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitThrow(Throw node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitRethrow(Rethrow node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitNot(Not node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticSet(StaticSet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitPropertySet(PropertySet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitVariableGet(VariableGet node) {
    makeExpressionRoundTrip(node);
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    makeExpressionRoundTrip(node);
  }
}
