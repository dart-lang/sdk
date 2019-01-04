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
    throw new UnimplementedError("visitNamedType");
  }

  @override
  void visitSupertype(Supertype node) {
    throw new UnimplementedError("visitSupertype");
  }

  @override
  void visitName(Name node) {
    throw new UnimplementedError("visitName");
  }

  @override
  void visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {
    throw new UnimplementedError("visitRedirectingFactoryConstructorReference");
  }

  @override
  void visitProcedureReference(Procedure node) {
    throw new UnimplementedError("visitProcedureReference");
  }

  @override
  void visitConstructorReference(Constructor node) {
    throw new UnimplementedError("visitConstructorReference");
  }

  @override
  void visitFieldReference(Field node) {
    throw new UnimplementedError("visitFieldReference");
  }

  @override
  void visitTypeLiteralConstantReference(TypeLiteralConstant node) {
    throw new UnimplementedError("visitTypeLiteralConstantReference");
  }

  @override
  void visitTearOffConstantReference(TearOffConstant node) {
    throw new UnimplementedError("visitTearOffConstantReference");
  }

  @override
  void visitPartialInstantiationConstantReference(
      PartialInstantiationConstant node) {
    throw new UnimplementedError("visitPartialInstantiationConstantReference");
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    throw new UnimplementedError("visitInstanceConstantReference");
  }

  @override
  void visitListConstantReference(ListConstant node) {
    throw new UnimplementedError("visitListConstantReference");
  }

  @override
  void visitMapConstantReference(MapConstant node) {
    throw new UnimplementedError("visitMapConstantReference");
  }

  @override
  void visitSymbolConstantReference(SymbolConstant node) {
    throw new UnimplementedError("visitSymbolConstantReference");
  }

  @override
  void visitStringConstantReference(StringConstant node) {
    throw new UnimplementedError("visitStringConstantReference");
  }

  @override
  void visitDoubleConstantReference(DoubleConstant node) {
    throw new UnimplementedError("visitDoubleConstantReference");
  }

  @override
  void visitIntConstantReference(IntConstant node) {
    throw new UnimplementedError("visitIntConstantReference");
  }

  @override
  void visitBoolConstantReference(BoolConstant node) {
    throw new UnimplementedError("visitBoolConstantReference");
  }

  @override
  void visitNullConstantReference(NullConstant node) {
    throw new UnimplementedError("visitNullConstantReference");
  }

  @override
  void visitTypedefReference(Typedef node) {
    throw new UnimplementedError("visitTypedefReference");
  }

  @override
  void visitClassReference(Class node) {
    throw new UnimplementedError("visitClassReference");
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    throw new UnimplementedError("visitTypeLiteralConstant");
  }

  @override
  void visitTearOffConstant(TearOffConstant node) {
    throw new UnimplementedError("visitTearOffConstant");
  }

  @override
  void visitPartialInstantiationConstant(PartialInstantiationConstant node) {
    throw new UnimplementedError("visitPartialInstantiationConstant");
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    throw new UnimplementedError("visitInstanceConstant");
  }

  @override
  void visitListConstant(ListConstant node) {
    throw new UnimplementedError("visitListConstant");
  }

  @override
  void visitMapConstant(MapConstant node) {
    throw new UnimplementedError("visitMapConstant");
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    throw new UnimplementedError("visitSymbolConstant");
  }

  @override
  void visitStringConstant(StringConstant node) {
    throw new UnimplementedError("visitStringConstant");
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    throw new UnimplementedError("visitDoubleConstant");
  }

  @override
  void visitIntConstant(IntConstant node) {
    throw new UnimplementedError("visitIntConstant");
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    throw new UnimplementedError("visitBoolConstant");
  }

  @override
  void visitNullConstant(NullConstant node) {
    throw new UnimplementedError("visitNullConstant");
  }

  @override
  void visitTypedefType(TypedefType node) {
    throw new UnimplementedError("visitTypedefType");
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    throw new UnimplementedError("visitTypeParameterType");
  }

  @override
  void visitFunctionType(FunctionType node) {
    throw new UnimplementedError("visitFunctionType");
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    throw new UnimplementedError("visitInterfaceType");
  }

  @override
  void visitBottomType(BottomType node) {
    throw new UnimplementedError("visitBottomType");
  }

  @override
  void visitVoidType(VoidType node) {
    throw new UnimplementedError("visitVoidType");
  }

  @override
  void visitDynamicType(DynamicType node) {
    throw new UnimplementedError("visitDynamicType");
  }

  @override
  void visitInvalidType(InvalidType node) {
    throw new UnimplementedError("visitInvalidType");
  }

  @override
  void visitComponent(Component node) {
    throw new UnimplementedError("visitComponent");
  }

  @override
  void visitMapEntry(MapEntry node) {
    throw new UnimplementedError("visitMapEntry");
  }

  @override
  void visitCatch(Catch node) {
    throw new UnimplementedError("visitCatch");
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    throw new UnimplementedError("visitSwitchCase");
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    throw new UnimplementedError("visitNamedExpression");
  }

  @override
  void visitArguments(Arguments node) {
    throw new UnimplementedError("visitArguments");
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    throw new UnimplementedError("visitFunctionNode");
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    throw new UnimplementedError("visitTypeParameter");
  }

  @override
  void visitTypedef(Typedef node) {
    throw new UnimplementedError("visitTypedef");
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    throw new UnimplementedError("visitLibraryPart");
  }

  @override
  void visitCombinator(Combinator node) {
    throw new UnimplementedError("visitCombinator");
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    throw new UnimplementedError("visitLibraryDependency");
  }

  @override
  void visitLibrary(Library node) {
    throw new UnimplementedError("visitLibrary");
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    throw new UnimplementedError("visitAssertInitializer");
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    throw new UnimplementedError("visitLocalInitializer");
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnimplementedError("visitRedirectingInitializer");
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    throw new UnimplementedError("visitSuperInitializer");
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    throw new UnimplementedError("visitFieldInitializer");
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    throw new UnimplementedError("visitInvalidInitializer");
  }

  @override
  void visitClass(Class node) {
    throw new UnimplementedError("visitClass");
  }

  @override
  void visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    throw new UnimplementedError("visitRedirectingFactoryConstructor");
  }

  @override
  void visitField(Field node) {
    throw new UnimplementedError("visitField");
  }

  @override
  void visitProcedure(Procedure node) {
    throw new UnimplementedError("visitProcedure");
  }

  @override
  void visitConstructor(Constructor node) {
    throw new UnimplementedError("visitConstructor");
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    throw new UnimplementedError("visitFunctionDeclaration");
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    throw new UnimplementedError("visitVariableDeclaration");
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    throw new UnimplementedError("visitYieldStatement");
  }

  @override
  void visitTryFinally(TryFinally node) {
    throw new UnimplementedError("visitTryFinally");
  }

  @override
  void visitTryCatch(TryCatch node) {
    throw new UnimplementedError("visitTryCatch");
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    throw new UnimplementedError("visitReturnStatement");
  }

  @override
  void visitIfStatement(IfStatement node) {
    throw new UnimplementedError("visitIfStatement");
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    throw new UnimplementedError("visitContinueSwitchStatement");
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    throw new UnimplementedError("visitSwitchStatement");
  }

  @override
  void visitForInStatement(ForInStatement node) {
    throw new UnimplementedError("visitForInStatement");
  }

  @override
  void visitForStatement(ForStatement node) {
    throw new UnimplementedError("visitForStatement");
  }

  @override
  void visitDoStatement(DoStatement node) {
    throw new UnimplementedError("visitDoStatement");
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    throw new UnimplementedError("visitWhileStatement");
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    throw new UnimplementedError("visitBreakStatement");
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    throw new UnimplementedError("visitLabeledStatement");
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    throw new UnimplementedError("visitAssertStatement");
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    throw new UnimplementedError("visitEmptyStatement");
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    throw new UnimplementedError("visitAssertBlock");
  }

  @override
  void visitBlock(Block node) {
    throw new UnimplementedError("visitBlock");
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    throw new UnimplementedError("visitExpressionStatement");
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    throw new UnimplementedError("visitCheckLibraryIsLoaded");
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    throw new UnimplementedError("visitLoadLibrary");
  }

  @override
  void visitInstantiation(Instantiation node) {
    throw new UnimplementedError("visitInstantiation");
  }

  @override
  void visitLet(Let node) {
    throw new UnimplementedError("visitLet");
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    throw new UnimplementedError("visitNullLiteral");
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    throw new UnimplementedError("visitBoolLiteral");
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    throw new UnimplementedError("visitDoubleLiteral");
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    throw new UnimplementedError("visitIntLiteral");
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    throw new UnimplementedError("visitStringLiteral");
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    throw new UnimplementedError("visitConstantExpression");
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    throw new UnimplementedError("visitFunctionExpression");
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    throw new UnimplementedError("visitAwaitExpression");
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    throw new UnimplementedError("visitMapLiteral");
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    throw new UnimplementedError("visitSetLiteral");
  }

  @override
  void visitListLiteral(ListLiteral node) {
    throw new UnimplementedError("visitListLiteral");
  }

  @override
  void visitThrow(Throw node) {
    throw new UnimplementedError("visitThrow");
  }

  @override
  void visitRethrow(Rethrow node) {
    throw new UnimplementedError("visitRethrow");
  }

  @override
  void visitThisExpression(ThisExpression node) {
    throw new UnimplementedError("visitThisExpression");
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    throw new UnimplementedError("visitTypeLiteral");
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    throw new UnimplementedError("visitSymbolLiteral");
  }

  @override
  void visitAsExpression(AsExpression node) {
    throw new UnimplementedError("visitAsExpression");
  }

  @override
  void visitIsExpression(IsExpression node) {
    throw new UnimplementedError("visitIsExpression");
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    throw new UnimplementedError("visitStringConcatenation");
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    throw new UnimplementedError("visitConditionalExpression");
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    throw new UnimplementedError("visitLogicalExpression");
  }

  @override
  void visitNot(Not node) {
    throw new UnimplementedError("visitNot");
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    throw new UnimplementedError("visitConstructorInvocation");
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    throw new UnimplementedError("visitStaticInvocation");
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    throw new UnimplementedError("visitSuperMethodInvocation");
  }

  @override
  void visitDirectMethodInvocation(DirectMethodInvocation node) {
    throw new UnimplementedError("visitDirectMethodInvocation");
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    throw new UnimplementedError("visitMethodInvocation");
  }

  @override
  void visitStaticSet(StaticSet node) {
    throw new UnimplementedError("visitStaticSet");
  }

  @override
  void visitStaticGet(StaticGet node) {
    throw new UnimplementedError("visitStaticGet");
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    throw new UnimplementedError("visitSuperPropertySet");
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    throw new UnimplementedError("visitSuperPropertyGet");
  }

  @override
  void visitDirectPropertySet(DirectPropertySet node) {
    throw new UnimplementedError("visitDirectPropertySet");
  }

  @override
  void visitDirectPropertyGet(DirectPropertyGet node) {
    throw new UnimplementedError("visitDirectPropertyGet");
  }

  @override
  void visitPropertySet(PropertySet node) {
    throw new UnimplementedError("visitPropertySet");
  }

  @override
  void visitPropertyGet(PropertyGet node) {
    throw new UnimplementedError("visitPropertyGet");
  }

  @override
  void visitVariableSet(VariableSet node) {
    throw new UnimplementedError("visitVariableSet");
  }

  @override
  void visitVariableGet(VariableGet node) {
    throw new UnimplementedError("visitVariableGet");
  }

  @override
  void visitInvalidExpression(InvalidExpression node) {
    throw new UnimplementedError("visitInvalidExpression");
  }
}
