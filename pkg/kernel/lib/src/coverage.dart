// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: THIS FILE IS GENERATED. DO NOT EDIT.
//
// Run 'dart pkg/front_end/tool/generate_ast_coverage.dart' to update.

import 'package:kernel/ast.dart';

/// Recursive visitor that collects kinds for all visited nodes.
///
/// This can be used to verify that tests have the intended coverage.
class CoverageVisitor implements Visitor<void> {
  Set<Object> visited = {};
  @override
  void defaultNode(Node node) {}
  @override
  void defaultTreeNode(TreeNode node) {}
  @override
  void visitLibrary(Library node) {
    visited.add(NodeKind.Library);
    node.visitChildren(this);
  }

  @override
  void visitTypedef(Typedef node) {
    visited.add(NodeKind.Typedef);
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    visited.add(NodeKind.Class);
    node.visitChildren(this);
  }

  @override
  void visitExtension(Extension node) {
    visited.add(NodeKind.Extension);
    node.visitChildren(this);
  }

  @override
  void defaultMember(Member node) {}
  @override
  void visitField(Field node) {
    visited.add(MemberKind.Field);
    node.visitChildren(this);
  }

  @override
  void visitConstructor(Constructor node) {
    visited.add(MemberKind.Constructor);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactory(RedirectingFactory node) {
    visited.add(MemberKind.RedirectingFactory);
    node.visitChildren(this);
  }

  @override
  void visitProcedure(Procedure node) {
    visited.add(MemberKind.Procedure);
    node.visitChildren(this);
  }

  @override
  void visitLibraryDependency(LibraryDependency node) {
    visited.add(NodeKind.LibraryDependency);
    node.visitChildren(this);
  }

  @override
  void visitLibraryPart(LibraryPart node) {
    visited.add(NodeKind.LibraryPart);
    node.visitChildren(this);
  }

  @override
  void visitCombinator(Combinator node) {
    visited.add(NodeKind.Combinator);
    node.visitChildren(this);
  }

  @override
  void defaultInitializer(Initializer node) {}
  @override
  void visitInvalidInitializer(InvalidInitializer node) {
    visited.add(InitializerKind.InvalidInitializer);
    node.visitChildren(this);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    visited.add(InitializerKind.FieldInitializer);
    node.visitChildren(this);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    visited.add(InitializerKind.SuperInitializer);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    visited.add(InitializerKind.RedirectingInitializer);
    node.visitChildren(this);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    visited.add(InitializerKind.LocalInitializer);
    node.visitChildren(this);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    visited.add(InitializerKind.AssertInitializer);
    node.visitChildren(this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    visited.add(NodeKind.FunctionNode);
    node.visitChildren(this);
  }

  @override
  void defaultExpression(Expression node) {}
  @override
  void visitInvalidExpression(InvalidExpression node) {
    visited.add(ExpressionKind.InvalidExpression);
    node.visitChildren(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    visited.add(ExpressionKind.VariableGet);
    node.visitChildren(this);
  }

  @override
  void visitVariableSet(VariableSet node) {
    visited.add(ExpressionKind.VariableSet);
    node.visitChildren(this);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    visited.add(ExpressionKind.DynamicGet);
    node.visitChildren(this);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    visited.add(ExpressionKind.InstanceGet);
    node.visitChildren(this);
  }

  @override
  void visitFunctionTearOff(FunctionTearOff node) {
    visited.add(ExpressionKind.FunctionTearOff);
    node.visitChildren(this);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    visited.add(ExpressionKind.InstanceTearOff);
    node.visitChildren(this);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    visited.add(ExpressionKind.DynamicSet);
    node.visitChildren(this);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    visited.add(ExpressionKind.InstanceSet);
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    visited.add(ExpressionKind.SuperPropertyGet);
    node.visitChildren(this);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    visited.add(ExpressionKind.SuperPropertySet);
    node.visitChildren(this);
  }

  @override
  void visitStaticGet(StaticGet node) {
    visited.add(ExpressionKind.StaticGet);
    node.visitChildren(this);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    visited.add(ExpressionKind.StaticTearOff);
    node.visitChildren(this);
  }

  @override
  void visitStaticSet(StaticSet node) {
    visited.add(ExpressionKind.StaticSet);
    node.visitChildren(this);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    visited.add(ExpressionKind.DynamicInvocation);
    node.visitChildren(this);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    visited.add(ExpressionKind.InstanceInvocation);
    node.visitChildren(this);
  }

  @override
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    visited.add(ExpressionKind.InstanceGetterInvocation);
    node.visitChildren(this);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    visited.add(ExpressionKind.FunctionInvocation);
    node.visitChildren(this);
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    visited.add(ExpressionKind.LocalFunctionInvocation);
    node.visitChildren(this);
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    visited.add(ExpressionKind.SuperMethodInvocation);
    node.visitChildren(this);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    visited.add(ExpressionKind.StaticInvocation);
    node.visitChildren(this);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    visited.add(ExpressionKind.ConstructorInvocation);
    node.visitChildren(this);
  }

  @override
  void visitEqualsNull(EqualsNull node) {
    visited.add(ExpressionKind.EqualsNull);
    node.visitChildren(this);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    visited.add(ExpressionKind.EqualsCall);
    node.visitChildren(this);
  }

  @override
  void visitInstantiation(Instantiation node) {
    visited.add(ExpressionKind.Instantiation);
    node.visitChildren(this);
  }

  @override
  void visitNot(Not node) {
    visited.add(ExpressionKind.Not);
    node.visitChildren(this);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    visited.add(ExpressionKind.LogicalExpression);
    node.visitChildren(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    visited.add(ExpressionKind.ConditionalExpression);
    node.visitChildren(this);
  }

  @override
  void visitStringConcatenation(StringConcatenation node) {
    visited.add(ExpressionKind.StringConcatenation);
    node.visitChildren(this);
  }

  @override
  void visitListConcatenation(ListConcatenation node) {
    visited.add(ExpressionKind.ListConcatenation);
    node.visitChildren(this);
  }

  @override
  void visitSetConcatenation(SetConcatenation node) {
    visited.add(ExpressionKind.SetConcatenation);
    node.visitChildren(this);
  }

  @override
  void visitMapConcatenation(MapConcatenation node) {
    visited.add(ExpressionKind.MapConcatenation);
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreation(InstanceCreation node) {
    visited.add(ExpressionKind.InstanceCreation);
    node.visitChildren(this);
  }

  @override
  void visitFileUriExpression(FileUriExpression node) {
    visited.add(ExpressionKind.FileUriExpression);
    node.visitChildren(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    visited.add(ExpressionKind.IsExpression);
    node.visitChildren(this);
  }

  @override
  void visitAsExpression(AsExpression node) {
    visited.add(ExpressionKind.AsExpression);
    node.visitChildren(this);
  }

  @override
  void visitNullCheck(NullCheck node) {
    visited.add(ExpressionKind.NullCheck);
    node.visitChildren(this);
  }

  @override
  void defaultBasicLiteral(BasicLiteral node) {}
  @override
  void visitStringLiteral(StringLiteral node) {
    visited.add(ExpressionKind.StringLiteral);
    node.visitChildren(this);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    visited.add(ExpressionKind.IntLiteral);
    node.visitChildren(this);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    visited.add(ExpressionKind.DoubleLiteral);
    node.visitChildren(this);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    visited.add(ExpressionKind.BoolLiteral);
    node.visitChildren(this);
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    visited.add(ExpressionKind.NullLiteral);
    node.visitChildren(this);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    visited.add(ExpressionKind.SymbolLiteral);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
    visited.add(ExpressionKind.TypeLiteral);
    node.visitChildren(this);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    visited.add(ExpressionKind.ThisExpression);
    node.visitChildren(this);
  }

  @override
  void visitRethrow(Rethrow node) {
    visited.add(ExpressionKind.Rethrow);
    node.visitChildren(this);
  }

  @override
  void visitThrow(Throw node) {
    visited.add(ExpressionKind.Throw);
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    visited.add(ExpressionKind.ListLiteral);
    node.visitChildren(this);
  }

  @override
  void visitSetLiteral(SetLiteral node) {
    visited.add(ExpressionKind.SetLiteral);
    node.visitChildren(this);
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    visited.add(ExpressionKind.MapLiteral);
    node.visitChildren(this);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    visited.add(ExpressionKind.AwaitExpression);
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    visited.add(ExpressionKind.FunctionExpression);
    node.visitChildren(this);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    visited.add(ExpressionKind.ConstantExpression);
    node.visitChildren(this);
  }

  @override
  void visitLet(Let node) {
    visited.add(ExpressionKind.Let);
    node.visitChildren(this);
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    visited.add(ExpressionKind.BlockExpression);
    node.visitChildren(this);
  }

  @override
  void visitLoadLibrary(LoadLibrary node) {
    visited.add(ExpressionKind.LoadLibrary);
    node.visitChildren(this);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    visited.add(ExpressionKind.CheckLibraryIsLoaded);
    node.visitChildren(this);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    visited.add(ExpressionKind.ConstructorTearOff);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    visited.add(ExpressionKind.RedirectingFactoryTearOff);
    node.visitChildren(this);
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    visited.add(ExpressionKind.TypedefTearOff);
    node.visitChildren(this);
  }

  @override
  void visitArguments(Arguments node) {
    visited.add(NodeKind.Arguments);
    node.visitChildren(this);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    visited.add(NodeKind.NamedExpression);
    node.visitChildren(this);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    visited.add(NodeKind.MapLiteralEntry);
    node.visitChildren(this);
  }

  @override
  void defaultStatement(Statement node) {}
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    visited.add(StatementKind.ExpressionStatement);
    node.visitChildren(this);
  }

  @override
  void visitBlock(Block node) {
    visited.add(StatementKind.Block);
    node.visitChildren(this);
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    visited.add(StatementKind.AssertBlock);
    node.visitChildren(this);
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    visited.add(StatementKind.EmptyStatement);
    node.visitChildren(this);
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    visited.add(StatementKind.AssertStatement);
    node.visitChildren(this);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    visited.add(StatementKind.LabeledStatement);
    node.visitChildren(this);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    visited.add(StatementKind.BreakStatement);
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    visited.add(StatementKind.WhileStatement);
    node.visitChildren(this);
  }

  @override
  void visitDoStatement(DoStatement node) {
    visited.add(StatementKind.DoStatement);
    node.visitChildren(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    visited.add(StatementKind.ForStatement);
    node.visitChildren(this);
  }

  @override
  void visitForInStatement(ForInStatement node) {
    visited.add(StatementKind.ForInStatement);
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    visited.add(StatementKind.SwitchStatement);
    node.visitChildren(this);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    visited.add(StatementKind.ContinueSwitchStatement);
    node.visitChildren(this);
  }

  @override
  void visitIfStatement(IfStatement node) {
    visited.add(StatementKind.IfStatement);
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    visited.add(StatementKind.ReturnStatement);
    node.visitChildren(this);
  }

  @override
  void visitTryCatch(TryCatch node) {
    visited.add(StatementKind.TryCatch);
    node.visitChildren(this);
  }

  @override
  void visitTryFinally(TryFinally node) {
    visited.add(StatementKind.TryFinally);
    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    visited.add(StatementKind.YieldStatement);
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    visited.add(StatementKind.VariableDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    visited.add(StatementKind.FunctionDeclaration);
    node.visitChildren(this);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    visited.add(NodeKind.SwitchCase);
    node.visitChildren(this);
  }

  @override
  void visitCatch(Catch node) {
    visited.add(NodeKind.Catch);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    visited.add(NodeKind.TypeParameter);
    node.visitChildren(this);
  }

  @override
  void visitComponent(Component node) {
    visited.add(NodeKind.Component);
    node.visitChildren(this);
  }

  @override
  void visitName(Name node) {
    visited.add(NodeKind.Name);
    node.visitChildren(this);
  }

  @override
  void defaultDartType(DartType node) {}
  @override
  void visitInvalidType(InvalidType node) {
    visited.add(DartTypeKind.InvalidType);
    node.visitChildren(this);
  }

  @override
  void visitDynamicType(DynamicType node) {
    visited.add(DartTypeKind.DynamicType);
    node.visitChildren(this);
  }

  @override
  void visitVoidType(VoidType node) {
    visited.add(DartTypeKind.VoidType);
    node.visitChildren(this);
  }

  @override
  void visitNeverType(NeverType node) {
    visited.add(DartTypeKind.NeverType);
    node.visitChildren(this);
  }

  @override
  void visitNullType(NullType node) {
    visited.add(DartTypeKind.NullType);
    node.visitChildren(this);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    visited.add(DartTypeKind.InterfaceType);
    node.visitChildren(this);
  }

  @override
  void visitFunctionType(FunctionType node) {
    visited.add(DartTypeKind.FunctionType);
    node.visitChildren(this);
  }

  @override
  void visitTypedefType(TypedefType node) {
    visited.add(DartTypeKind.TypedefType);
    node.visitChildren(this);
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    visited.add(DartTypeKind.FutureOrType);
    node.visitChildren(this);
  }

  @override
  void visitExtensionType(ExtensionType node) {
    visited.add(DartTypeKind.ExtensionType);
    node.visitChildren(this);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    visited.add(DartTypeKind.TypeParameterType);
    node.visitChildren(this);
  }

  @override
  void visitNamedType(NamedType node) {
    visited.add(NodeKind.NamedType);
    node.visitChildren(this);
  }

  @override
  void visitSupertype(Supertype node) {
    visited.add(NodeKind.Supertype);
    node.visitChildren(this);
  }

  @override
  void defaultConstant(Constant node) {}
  @override
  void visitNullConstant(NullConstant node) {
    visited.add(ConstantKind.NullConstant);
    node.visitChildren(this);
  }

  @override
  void visitBoolConstant(BoolConstant node) {
    visited.add(ConstantKind.BoolConstant);
    node.visitChildren(this);
  }

  @override
  void visitIntConstant(IntConstant node) {
    visited.add(ConstantKind.IntConstant);
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstant(DoubleConstant node) {
    visited.add(ConstantKind.DoubleConstant);
    node.visitChildren(this);
  }

  @override
  void visitStringConstant(StringConstant node) {
    visited.add(ConstantKind.StringConstant);
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstant(SymbolConstant node) {
    visited.add(ConstantKind.SymbolConstant);
    node.visitChildren(this);
  }

  @override
  void visitMapConstant(MapConstant node) {
    visited.add(ConstantKind.MapConstant);
    node.visitChildren(this);
  }

  @override
  void visitListConstant(ListConstant node) {
    visited.add(ConstantKind.ListConstant);
    node.visitChildren(this);
  }

  @override
  void visitSetConstant(SetConstant node) {
    visited.add(ConstantKind.SetConstant);
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstant(InstanceConstant node) {
    visited.add(ConstantKind.InstanceConstant);
    node.visitChildren(this);
  }

  @override
  void visitInstantiationConstant(InstantiationConstant node) {
    visited.add(ConstantKind.InstantiationConstant);
    node.visitChildren(this);
  }

  @override
  void visitStaticTearOffConstant(StaticTearOffConstant node) {
    visited.add(ConstantKind.StaticTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitConstructorTearOffConstant(ConstructorTearOffConstant node) {
    visited.add(ConstantKind.ConstructorTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {
    visited.add(ConstantKind.RedirectingFactoryTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitTypedefTearOffConstant(TypedefTearOffConstant node) {
    visited.add(ConstantKind.TypedefTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteralConstant(TypeLiteralConstant node) {
    visited.add(ConstantKind.TypeLiteralConstant);
    node.visitChildren(this);
  }

  @override
  void visitUnevaluatedConstant(UnevaluatedConstant node) {
    visited.add(ConstantKind.UnevaluatedConstant);
    node.visitChildren(this);
  }

  @override
  void visitTypedefReference(Typedef node) {}
  @override
  void visitClassReference(Class node) {}
  @override
  void visitExtensionReference(Extension node) {}
  @override
  void defaultMemberReference(Member node) {}
  @override
  void visitFieldReference(Field node) {}
  @override
  void visitConstructorReference(Constructor node) {}
  @override
  void visitRedirectingFactoryReference(RedirectingFactory node) {}
  @override
  void visitProcedureReference(Procedure node) {}
  @override
  void defaultConstantReference(Constant node) {}
  @override
  void visitNullConstantReference(NullConstant node) {
    visited.add(ConstantKind.NullConstant);
    node.visitChildren(this);
  }

  @override
  void visitBoolConstantReference(BoolConstant node) {
    visited.add(ConstantKind.BoolConstant);
    node.visitChildren(this);
  }

  @override
  void visitIntConstantReference(IntConstant node) {
    visited.add(ConstantKind.IntConstant);
    node.visitChildren(this);
  }

  @override
  void visitDoubleConstantReference(DoubleConstant node) {
    visited.add(ConstantKind.DoubleConstant);
    node.visitChildren(this);
  }

  @override
  void visitStringConstantReference(StringConstant node) {
    visited.add(ConstantKind.StringConstant);
    node.visitChildren(this);
  }

  @override
  void visitSymbolConstantReference(SymbolConstant node) {
    visited.add(ConstantKind.SymbolConstant);
    node.visitChildren(this);
  }

  @override
  void visitMapConstantReference(MapConstant node) {
    visited.add(ConstantKind.MapConstant);
    node.visitChildren(this);
  }

  @override
  void visitListConstantReference(ListConstant node) {
    visited.add(ConstantKind.ListConstant);
    node.visitChildren(this);
  }

  @override
  void visitSetConstantReference(SetConstant node) {
    visited.add(ConstantKind.SetConstant);
    node.visitChildren(this);
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    visited.add(ConstantKind.InstanceConstant);
    node.visitChildren(this);
  }

  @override
  void visitInstantiationConstantReference(InstantiationConstant node) {
    visited.add(ConstantKind.InstantiationConstant);
    node.visitChildren(this);
  }

  @override
  void visitStaticTearOffConstantReference(StaticTearOffConstant node) {
    visited.add(ConstantKind.StaticTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitConstructorTearOffConstantReference(
      ConstructorTearOffConstant node) {
    visited.add(ConstantKind.ConstructorTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingFactoryTearOffConstantReference(
      RedirectingFactoryTearOffConstant node) {
    visited.add(ConstantKind.RedirectingFactoryTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitTypedefTearOffConstantReference(TypedefTearOffConstant node) {
    visited.add(ConstantKind.TypedefTearOffConstant);
    node.visitChildren(this);
  }

  @override
  void visitTypeLiteralConstantReference(TypeLiteralConstant node) {
    visited.add(ConstantKind.TypeLiteralConstant);
    node.visitChildren(this);
  }

  @override
  void visitUnevaluatedConstantReference(UnevaluatedConstant node) {
    visited.add(ConstantKind.UnevaluatedConstant);
    node.visitChildren(this);
  }
}

enum NodeKind {
  Arguments,
  Catch,
  Class,
  Combinator,
  Component,
  Extension,
  FunctionNode,
  Library,
  LibraryDependency,
  LibraryPart,
  MapLiteralEntry,
  Name,
  NamedExpression,
  NamedType,
  Supertype,
  SwitchCase,
  TypeParameter,
  Typedef,
}

enum MemberKind {
  Constructor,
  Field,
  Procedure,
  RedirectingFactory,
}

enum InitializerKind {
  AssertInitializer,
  FieldInitializer,
  InvalidInitializer,
  LocalInitializer,
  RedirectingInitializer,
  SuperInitializer,
}

enum ExpressionKind {
  AsExpression,
  AwaitExpression,
  BlockExpression,
  BoolLiteral,
  CheckLibraryIsLoaded,
  ConditionalExpression,
  ConstantExpression,
  ConstructorInvocation,
  ConstructorTearOff,
  DoubleLiteral,
  DynamicGet,
  DynamicInvocation,
  DynamicSet,
  EqualsCall,
  EqualsNull,
  FileUriExpression,
  FunctionExpression,
  FunctionInvocation,
  FunctionTearOff,
  InstanceCreation,
  InstanceGet,
  InstanceGetterInvocation,
  InstanceInvocation,
  InstanceSet,
  InstanceTearOff,
  Instantiation,
  IntLiteral,
  InvalidExpression,
  IsExpression,
  Let,
  ListConcatenation,
  ListLiteral,
  LoadLibrary,
  LocalFunctionInvocation,
  LogicalExpression,
  MapConcatenation,
  MapLiteral,
  Not,
  NullCheck,
  NullLiteral,
  RedirectingFactoryTearOff,
  Rethrow,
  SetConcatenation,
  SetLiteral,
  StaticGet,
  StaticInvocation,
  StaticSet,
  StaticTearOff,
  StringConcatenation,
  StringLiteral,
  SuperMethodInvocation,
  SuperPropertyGet,
  SuperPropertySet,
  SymbolLiteral,
  ThisExpression,
  Throw,
  TypeLiteral,
  TypedefTearOff,
  VariableGet,
  VariableSet,
}

enum StatementKind {
  AssertBlock,
  AssertStatement,
  Block,
  BreakStatement,
  ContinueSwitchStatement,
  DoStatement,
  EmptyStatement,
  ExpressionStatement,
  ForInStatement,
  ForStatement,
  FunctionDeclaration,
  IfStatement,
  LabeledStatement,
  ReturnStatement,
  SwitchStatement,
  TryCatch,
  TryFinally,
  VariableDeclaration,
  WhileStatement,
  YieldStatement,
}

enum DartTypeKind {
  DynamicType,
  ExtensionType,
  FunctionType,
  FutureOrType,
  InterfaceType,
  InvalidType,
  NeverType,
  NullType,
  TypeParameterType,
  TypedefType,
  VoidType,
}

enum ConstantKind {
  BoolConstant,
  ConstructorTearOffConstant,
  DoubleConstant,
  InstanceConstant,
  InstantiationConstant,
  IntConstant,
  ListConstant,
  MapConstant,
  NullConstant,
  RedirectingFactoryTearOffConstant,
  SetConstant,
  StaticTearOffConstant,
  StringConstant,
  SymbolConstant,
  TypeLiteralConstant,
  TypedefTearOffConstant,
  UnevaluatedConstant,
}

/// Returns the set of node kinds that were not visited by [visitor].
Set<Object> missingNodes(CoverageVisitor visitor) {
  Set<Object> all = {
    ...NodeKind.values,
    ...MemberKind.values,
    ...InitializerKind.values,
    ...ExpressionKind.values,
    ...StatementKind.values,
    ...DartTypeKind.values,
    ...ConstantKind.values,
  };
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [MemberKind]s that were not visited by [visitor].
Set<MemberKind> missingMembers(CoverageVisitor visitor) {
  Set<MemberKind> all = new Set<MemberKind>.of(MemberKind.values);
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [InitializerKind]s that were not visited by [visitor].
Set<InitializerKind> missingInitializers(CoverageVisitor visitor) {
  Set<InitializerKind> all =
      new Set<InitializerKind>.of(InitializerKind.values);
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [ExpressionKind]s that were not visited by [visitor].
Set<ExpressionKind> missingExpressions(CoverageVisitor visitor) {
  Set<ExpressionKind> all = new Set<ExpressionKind>.of(ExpressionKind.values);
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [StatementKind]s that were not visited by [visitor].
Set<StatementKind> missingStatements(CoverageVisitor visitor) {
  Set<StatementKind> all = new Set<StatementKind>.of(StatementKind.values);
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [DartTypeKind]s that were not visited by [visitor].
Set<DartTypeKind> missingDartTypes(CoverageVisitor visitor) {
  Set<DartTypeKind> all = new Set<DartTypeKind>.of(DartTypeKind.values);
  all.removeAll(visitor.visited);
  return all;
}

/// Returns the set of [ConstantKind]s that were not visited by [visitor].
Set<ConstantKind> missingConstants(CoverageVisitor visitor) {
  Set<ConstantKind> all = new Set<ConstantKind>.of(ConstantKind.values);
  all.removeAll(visitor.visited);
  return all;
}
