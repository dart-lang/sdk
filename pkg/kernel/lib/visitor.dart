// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast.visitor;

import 'dart:core' hide MapEntry;
import 'dart:collection';

import 'ast.dart';

abstract class ExpressionVisitor<R> {
  const ExpressionVisitor();

  R defaultExpression(Expression node) => null;
  R defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  R visitInvalidExpression(InvalidExpression node) => defaultExpression(node);
  R visitVariableGet(VariableGet node) => defaultExpression(node);
  R visitVariableSet(VariableSet node) => defaultExpression(node);
  R visitDynamicGet(DynamicGet node) => defaultExpression(node);
  R visitDynamicSet(DynamicSet node) => defaultExpression(node);
  R visitFunctionTearOff(FunctionTearOff node) => defaultExpression(node);
  R visitInstanceGet(InstanceGet node) => defaultExpression(node);
  R visitInstanceSet(InstanceSet node) => defaultExpression(node);
  R visitInstanceTearOff(InstanceTearOff node) => defaultExpression(node);
  R visitPropertyGet(PropertyGet node) => defaultExpression(node);
  R visitPropertySet(PropertySet node) => defaultExpression(node);
  R visitSuperPropertyGet(SuperPropertyGet node) => defaultExpression(node);
  R visitSuperPropertySet(SuperPropertySet node) => defaultExpression(node);
  R visitStaticGet(StaticGet node) => defaultExpression(node);
  R visitStaticSet(StaticSet node) => defaultExpression(node);
  R visitStaticTearOff(StaticTearOff node) => defaultExpression(node);
  R visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      defaultExpression(node);
  R visitDynamicInvocation(DynamicInvocation node) => defaultExpression(node);
  R visitFunctionInvocation(FunctionInvocation node) => defaultExpression(node);
  R visitInstanceInvocation(InstanceInvocation node) => defaultExpression(node);
  R visitEqualsNull(EqualsNull node) => defaultExpression(node);
  R visitEqualsCall(EqualsCall node) => defaultExpression(node);
  R visitMethodInvocation(MethodInvocation node) => defaultExpression(node);
  R visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);
  R visitStaticInvocation(StaticInvocation node) => defaultExpression(node);
  R visitConstructorInvocation(ConstructorInvocation node) =>
      defaultExpression(node);
  R visitNot(Not node) => defaultExpression(node);
  R visitNullCheck(NullCheck node) => defaultExpression(node);
  R visitLogicalExpression(LogicalExpression node) => defaultExpression(node);
  R visitConditionalExpression(ConditionalExpression node) =>
      defaultExpression(node);
  R visitStringConcatenation(StringConcatenation node) =>
      defaultExpression(node);
  R visitListConcatenation(ListConcatenation node) => defaultExpression(node);
  R visitSetConcatenation(SetConcatenation node) => defaultExpression(node);
  R visitMapConcatenation(MapConcatenation node) => defaultExpression(node);
  R visitInstanceCreation(InstanceCreation node) => defaultExpression(node);
  R visitFileUriExpression(FileUriExpression node) => defaultExpression(node);
  R visitIsExpression(IsExpression node) => defaultExpression(node);
  R visitAsExpression(AsExpression node) => defaultExpression(node);
  R visitSymbolLiteral(SymbolLiteral node) => defaultExpression(node);
  R visitTypeLiteral(TypeLiteral node) => defaultExpression(node);
  R visitThisExpression(ThisExpression node) => defaultExpression(node);
  R visitRethrow(Rethrow node) => defaultExpression(node);
  R visitThrow(Throw node) => defaultExpression(node);
  R visitListLiteral(ListLiteral node) => defaultExpression(node);
  R visitSetLiteral(SetLiteral node) => defaultExpression(node);
  R visitMapLiteral(MapLiteral node) => defaultExpression(node);
  R visitAwaitExpression(AwaitExpression node) => defaultExpression(node);
  R visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  R visitConstantExpression(ConstantExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitBlockExpression(BlockExpression node) => defaultExpression(node);
  R visitInstantiation(Instantiation node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
}

abstract class StatementVisitor<R> {
  const StatementVisitor();

  R defaultStatement(Statement node) => null;

  R visitExpressionStatement(ExpressionStatement node) =>
      defaultStatement(node);
  R visitBlock(Block node) => defaultStatement(node);
  R visitAssertBlock(AssertBlock node) => defaultStatement(node);
  R visitEmptyStatement(EmptyStatement node) => defaultStatement(node);
  R visitAssertStatement(AssertStatement node) => defaultStatement(node);
  R visitLabeledStatement(LabeledStatement node) => defaultStatement(node);
  R visitBreakStatement(BreakStatement node) => defaultStatement(node);
  R visitWhileStatement(WhileStatement node) => defaultStatement(node);
  R visitDoStatement(DoStatement node) => defaultStatement(node);
  R visitForStatement(ForStatement node) => defaultStatement(node);
  R visitForInStatement(ForInStatement node) => defaultStatement(node);
  R visitSwitchStatement(SwitchStatement node) => defaultStatement(node);
  R visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      defaultStatement(node);
  R visitIfStatement(IfStatement node) => defaultStatement(node);
  R visitReturnStatement(ReturnStatement node) => defaultStatement(node);
  R visitTryCatch(TryCatch node) => defaultStatement(node);
  R visitTryFinally(TryFinally node) => defaultStatement(node);
  R visitYieldStatement(YieldStatement node) => defaultStatement(node);
  R visitVariableDeclaration(VariableDeclaration node) =>
      defaultStatement(node);
  R visitFunctionDeclaration(FunctionDeclaration node) =>
      defaultStatement(node);
}

abstract class MemberVisitor<R> {
  const MemberVisitor();

  R defaultMember(Member node) => null;

  R visitConstructor(Constructor node) => defaultMember(node);
  R visitProcedure(Procedure node) => defaultMember(node);
  R visitField(Field node) => defaultMember(node);
  R visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    return defaultMember(node);
  }
}

abstract class InitializerVisitor<R> {
  const InitializerVisitor();

  R defaultInitializer(Initializer node) => null;

  R visitInvalidInitializer(InvalidInitializer node) =>
      defaultInitializer(node);
  R visitFieldInitializer(FieldInitializer node) => defaultInitializer(node);
  R visitSuperInitializer(SuperInitializer node) => defaultInitializer(node);
  R visitRedirectingInitializer(RedirectingInitializer node) =>
      defaultInitializer(node);
  R visitLocalInitializer(LocalInitializer node) => defaultInitializer(node);
  R visitAssertInitializer(AssertInitializer node) => defaultInitializer(node);
}

class TreeVisitor<R>
    implements
        ExpressionVisitor<R>,
        StatementVisitor<R>,
        MemberVisitor<R>,
        InitializerVisitor<R> {
  const TreeVisitor();

  R defaultTreeNode(TreeNode node) => null;

  // Expressions
  R defaultExpression(Expression node) => defaultTreeNode(node);
  R defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);
  R visitInvalidExpression(InvalidExpression node) => defaultExpression(node);
  R visitVariableGet(VariableGet node) => defaultExpression(node);
  R visitVariableSet(VariableSet node) => defaultExpression(node);
  R visitDynamicGet(DynamicGet node) => defaultExpression(node);
  R visitDynamicSet(DynamicSet node) => defaultExpression(node);
  R visitFunctionTearOff(FunctionTearOff node) => defaultExpression(node);
  R visitInstanceGet(InstanceGet node) => defaultExpression(node);
  R visitInstanceSet(InstanceSet node) => defaultExpression(node);
  R visitInstanceTearOff(InstanceTearOff node) => defaultExpression(node);
  R visitPropertyGet(PropertyGet node) => defaultExpression(node);
  R visitPropertySet(PropertySet node) => defaultExpression(node);
  R visitSuperPropertyGet(SuperPropertyGet node) => defaultExpression(node);
  R visitSuperPropertySet(SuperPropertySet node) => defaultExpression(node);
  R visitStaticGet(StaticGet node) => defaultExpression(node);
  R visitStaticSet(StaticSet node) => defaultExpression(node);
  R visitStaticTearOff(StaticTearOff node) => defaultExpression(node);
  R visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      defaultExpression(node);
  R visitDynamicInvocation(DynamicInvocation node) => defaultExpression(node);
  R visitFunctionInvocation(FunctionInvocation node) => defaultExpression(node);
  R visitInstanceInvocation(InstanceInvocation node) => defaultExpression(node);
  R visitEqualsNull(EqualsNull node) => defaultExpression(node);
  R visitEqualsCall(EqualsCall node) => defaultExpression(node);
  R visitMethodInvocation(MethodInvocation node) => defaultExpression(node);
  R visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);
  R visitStaticInvocation(StaticInvocation node) => defaultExpression(node);
  R visitConstructorInvocation(ConstructorInvocation node) =>
      defaultExpression(node);
  R visitNot(Not node) => defaultExpression(node);
  R visitNullCheck(NullCheck node) => defaultExpression(node);
  R visitLogicalExpression(LogicalExpression node) => defaultExpression(node);
  R visitConditionalExpression(ConditionalExpression node) =>
      defaultExpression(node);
  R visitStringConcatenation(StringConcatenation node) =>
      defaultExpression(node);
  R visitListConcatenation(ListConcatenation node) => defaultExpression(node);
  R visitSetConcatenation(SetConcatenation node) => defaultExpression(node);
  R visitMapConcatenation(MapConcatenation node) => defaultExpression(node);
  R visitInstanceCreation(InstanceCreation node) => defaultExpression(node);
  R visitFileUriExpression(FileUriExpression node) => defaultExpression(node);
  R visitIsExpression(IsExpression node) => defaultExpression(node);
  R visitAsExpression(AsExpression node) => defaultExpression(node);
  R visitSymbolLiteral(SymbolLiteral node) => defaultExpression(node);
  R visitTypeLiteral(TypeLiteral node) => defaultExpression(node);
  R visitThisExpression(ThisExpression node) => defaultExpression(node);
  R visitRethrow(Rethrow node) => defaultExpression(node);
  R visitThrow(Throw node) => defaultExpression(node);
  R visitListLiteral(ListLiteral node) => defaultExpression(node);
  R visitSetLiteral(SetLiteral node) => defaultExpression(node);
  R visitMapLiteral(MapLiteral node) => defaultExpression(node);
  R visitAwaitExpression(AwaitExpression node) => defaultExpression(node);
  R visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  R visitConstantExpression(ConstantExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitBlockExpression(BlockExpression node) => defaultExpression(node);
  R visitInstantiation(Instantiation node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);

  // Statements
  R defaultStatement(Statement node) => defaultTreeNode(node);
  R visitExpressionStatement(ExpressionStatement node) =>
      defaultStatement(node);
  R visitBlock(Block node) => defaultStatement(node);
  R visitAssertBlock(AssertBlock node) => defaultStatement(node);
  R visitEmptyStatement(EmptyStatement node) => defaultStatement(node);
  R visitAssertStatement(AssertStatement node) => defaultStatement(node);
  R visitLabeledStatement(LabeledStatement node) => defaultStatement(node);
  R visitBreakStatement(BreakStatement node) => defaultStatement(node);
  R visitWhileStatement(WhileStatement node) => defaultStatement(node);
  R visitDoStatement(DoStatement node) => defaultStatement(node);
  R visitForStatement(ForStatement node) => defaultStatement(node);
  R visitForInStatement(ForInStatement node) => defaultStatement(node);
  R visitSwitchStatement(SwitchStatement node) => defaultStatement(node);
  R visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      defaultStatement(node);
  R visitIfStatement(IfStatement node) => defaultStatement(node);
  R visitReturnStatement(ReturnStatement node) => defaultStatement(node);
  R visitTryCatch(TryCatch node) => defaultStatement(node);
  R visitTryFinally(TryFinally node) => defaultStatement(node);
  R visitYieldStatement(YieldStatement node) => defaultStatement(node);
  R visitVariableDeclaration(VariableDeclaration node) =>
      defaultStatement(node);
  R visitFunctionDeclaration(FunctionDeclaration node) =>
      defaultStatement(node);

  // Members
  R defaultMember(Member node) => defaultTreeNode(node);
  R visitConstructor(Constructor node) => defaultMember(node);
  R visitProcedure(Procedure node) => defaultMember(node);
  R visitField(Field node) => defaultMember(node);
  R visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    return defaultMember(node);
  }

  // Classes
  R visitClass(Class node) => defaultTreeNode(node);
  R visitExtension(Extension node) => defaultTreeNode(node);

  // Initializers
  R defaultInitializer(Initializer node) => defaultTreeNode(node);
  R visitInvalidInitializer(InvalidInitializer node) =>
      defaultInitializer(node);
  R visitFieldInitializer(FieldInitializer node) => defaultInitializer(node);
  R visitSuperInitializer(SuperInitializer node) => defaultInitializer(node);
  R visitRedirectingInitializer(RedirectingInitializer node) =>
      defaultInitializer(node);
  R visitLocalInitializer(LocalInitializer node) => defaultInitializer(node);
  R visitAssertInitializer(AssertInitializer node) => defaultInitializer(node);

  // Other tree nodes
  R visitLibrary(Library node) => defaultTreeNode(node);
  R visitLibraryDependency(LibraryDependency node) => defaultTreeNode(node);
  R visitCombinator(Combinator node) => defaultTreeNode(node);
  R visitLibraryPart(LibraryPart node) => defaultTreeNode(node);
  R visitTypedef(Typedef node) => defaultTreeNode(node);
  R visitTypeParameter(TypeParameter node) => defaultTreeNode(node);
  R visitFunctionNode(FunctionNode node) => defaultTreeNode(node);
  R visitArguments(Arguments node) => defaultTreeNode(node);
  R visitNamedExpression(NamedExpression node) => defaultTreeNode(node);
  R visitSwitchCase(SwitchCase node) => defaultTreeNode(node);
  R visitCatch(Catch node) => defaultTreeNode(node);
  R visitMapEntry(MapEntry node) => defaultTreeNode(node);
  R visitComponent(Component node) => defaultTreeNode(node);
}

class DartTypeVisitor<R> {
  const DartTypeVisitor();

  R defaultDartType(DartType node) => null;

  R visitInvalidType(InvalidType node) => defaultDartType(node);
  R visitDynamicType(DynamicType node) => defaultDartType(node);
  R visitVoidType(VoidType node) => defaultDartType(node);
  R visitBottomType(BottomType node) => defaultDartType(node);
  R visitInterfaceType(InterfaceType node) => defaultDartType(node);
  R visitFutureOrType(FutureOrType node) => defaultDartType(node);
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);
  R visitTypedefType(TypedefType node) => defaultDartType(node);
  R visitNeverType(NeverType node) => defaultDartType(node);
  R visitNullType(NullType node) => defaultDartType(node);
}

class DartTypeVisitor1<R, T> {
  R defaultDartType(DartType node, T arg) => null;

  R visitInvalidType(InvalidType node, T arg) => defaultDartType(node, arg);
  R visitDynamicType(DynamicType node, T arg) => defaultDartType(node, arg);
  R visitVoidType(VoidType node, T arg) => defaultDartType(node, arg);
  R visitBottomType(BottomType node, T arg) => defaultDartType(node, arg);
  R visitInterfaceType(InterfaceType node, T arg) => defaultDartType(node, arg);
  R visitFutureOrType(FutureOrType node, T arg) => defaultDartType(node, arg);
  R visitFunctionType(FunctionType node, T arg) => defaultDartType(node, arg);
  R visitTypeParameterType(TypeParameterType node, T arg) =>
      defaultDartType(node, arg);
  R visitTypedefType(TypedefType node, T arg) => defaultDartType(node, arg);
  R visitNeverType(NeverType node, T arg) => defaultDartType(node, arg);
  R visitNullType(NullType node, T arg) => defaultDartType(node, arg);
}

/// Visitor for [Constant] nodes.
///
/// Note: Constant nodes are _not_ trees but directed acyclic graphs. This
/// means that visiting a constant node without tracking which subnodes that
/// have already been visited might lead to exponential running times.
///
/// Use [ComputeOnceConstantVisitor] or [VisitOnceConstantVisitor] to visit
/// a constant node while ensuring each subnode is only visited once.
class ConstantVisitor<R> {
  const ConstantVisitor();

  R defaultConstant(Constant node) => null;

  R visitNullConstant(NullConstant node) => defaultConstant(node);
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  R visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  R visitListConstant(ListConstant node) => defaultConstant(node);
  R visitSetConstant(SetConstant node) => defaultConstant(node);
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  R visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      defaultConstant(node);
  R visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
  R visitUnevaluatedConstant(UnevaluatedConstant node) => defaultConstant(node);
}

abstract class _ConstantCallback<R> {
  R defaultConstant(Constant node);

  R visitNullConstant(NullConstant node);
  R visitBoolConstant(BoolConstant node);
  R visitIntConstant(IntConstant node);
  R visitDoubleConstant(DoubleConstant node);
  R visitStringConstant(StringConstant node);
  R visitSymbolConstant(SymbolConstant node);
  R visitMapConstant(MapConstant node);
  R visitListConstant(ListConstant node);
  R visitSetConstant(SetConstant node);
  R visitInstanceConstant(InstanceConstant node);
  R visitPartialInstantiationConstant(PartialInstantiationConstant node);
  R visitTearOffConstant(TearOffConstant node);
  R visitTypeLiteralConstant(TypeLiteralConstant node);
  R visitUnevaluatedConstant(UnevaluatedConstant node);
}

class _ConstantCallbackVisitor<R> implements ConstantVisitor<R> {
  final _ConstantCallback _callback;

  _ConstantCallbackVisitor(this._callback);

  @override
  R visitUnevaluatedConstant(UnevaluatedConstant node) =>
      _callback.visitUnevaluatedConstant(node);

  @override
  R visitTypeLiteralConstant(TypeLiteralConstant node) =>
      _callback.visitTypeLiteralConstant(node);

  @override
  R visitTearOffConstant(TearOffConstant node) =>
      _callback.visitTearOffConstant(node);

  @override
  R visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      _callback.visitPartialInstantiationConstant(node);

  @override
  R visitInstanceConstant(InstanceConstant node) =>
      _callback.visitInstanceConstant(node);

  @override
  R visitSetConstant(SetConstant node) => _callback.visitSetConstant(node);

  @override
  R visitListConstant(ListConstant node) => _callback.visitListConstant(node);

  @override
  R visitMapConstant(MapConstant node) => _callback.visitMapConstant(node);

  @override
  R visitSymbolConstant(SymbolConstant node) =>
      _callback.visitSymbolConstant(node);

  @override
  R visitStringConstant(StringConstant node) =>
      _callback.visitStringConstant(node);

  @override
  R visitDoubleConstant(DoubleConstant node) =>
      _callback.visitDoubleConstant(node);

  @override
  R visitIntConstant(IntConstant node) => _callback.visitIntConstant(node);

  @override
  R visitBoolConstant(BoolConstant node) => _callback.visitBoolConstant(node);

  @override
  R visitNullConstant(NullConstant node) => _callback.visitNullConstant(node);

  @override
  R defaultConstant(Constant node) => _callback.defaultConstant(node);
}

/// Visitor-like class used for visiting a [Constant] node while computing a
/// value for each subnode. The visitor caches the computed values ensuring that
/// each subnode is only visited once.
class ComputeOnceConstantVisitor<R> implements _ConstantCallback<R> {
  _ConstantCallbackVisitor<R> _visitor;
  Map<Constant, R> cache = new LinkedHashMap.identity();

  ComputeOnceConstantVisitor() {
    _visitor = new _ConstantCallbackVisitor<R>(this);
  }

  /// Visits [node] if not already visited to compute a value for [node].
  ///
  /// If the value has already been computed the cached value is returned
  /// immediately.
  ///
  /// Call this method to compute values for subnodes recursively, while only
  /// visiting each subnode once.
  R visitConstant(Constant node) {
    return cache[node] ??= processValue(node, node.accept(_visitor));
  }

  /// Returns the computed [value] for [node].
  ///
  /// Override this method to process the computed value before caching.
  R processValue(Constant node, R value) {
    return value;
  }

  R defaultConstant(Constant node) => null;

  R visitNullConstant(NullConstant node) => defaultConstant(node);
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  R visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  R visitListConstant(ListConstant node) => defaultConstant(node);
  R visitSetConstant(SetConstant node) => defaultConstant(node);
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  R visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      defaultConstant(node);
  R visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
  R visitUnevaluatedConstant(UnevaluatedConstant node) => defaultConstant(node);
}

/// Visitor-like class used for visiting each subnode of a [Constant] node once.
///
/// The visitor records the visited node to ensure that each subnode is only
/// visited once.
class VisitOnceConstantVisitor implements _ConstantCallback<void> {
  _ConstantCallbackVisitor<void> _visitor;
  Set<Constant> cache = new LinkedHashSet.identity();

  VisitOnceConstantVisitor() {
    _visitor = new _ConstantCallbackVisitor<void>(this);
  }

  /// Visits [node] if not already visited.
  ///
  /// Call this method to visit subnodes recursively, while only visiting each
  /// subnode once.
  void visitConstant(Constant node) {
    if (cache.add(node)) {
      node.accept(_visitor);
    }
  }

  void defaultConstant(Constant node) => null;

  void visitNullConstant(NullConstant node) => defaultConstant(node);
  void visitBoolConstant(BoolConstant node) => defaultConstant(node);
  void visitIntConstant(IntConstant node) => defaultConstant(node);
  void visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  void visitStringConstant(StringConstant node) => defaultConstant(node);
  void visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  void visitMapConstant(MapConstant node) => defaultConstant(node);
  void visitListConstant(ListConstant node) => defaultConstant(node);
  void visitSetConstant(SetConstant node) => defaultConstant(node);
  void visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  void visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      defaultConstant(node);
  void visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  void visitTypeLiteralConstant(TypeLiteralConstant node) =>
      defaultConstant(node);
  void visitUnevaluatedConstant(UnevaluatedConstant node) =>
      defaultConstant(node);
}

class MemberReferenceVisitor<R> {
  const MemberReferenceVisitor();

  R defaultMemberReference(Member node) => null;

  R visitFieldReference(Field node) => defaultMemberReference(node);
  R visitConstructorReference(Constructor node) => defaultMemberReference(node);
  R visitProcedureReference(Procedure node) => defaultMemberReference(node);
  R visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {
    return defaultMemberReference(node);
  }
}

class Visitor<R> extends TreeVisitor<R>
    implements
        DartTypeVisitor<R>,
        ConstantVisitor<R>,
        MemberReferenceVisitor<R> {
  const Visitor();

  /// The catch-all case, except for references.
  R defaultNode(Node node) => null;
  R defaultTreeNode(TreeNode node) => defaultNode(node);

  // DartTypes
  R defaultDartType(DartType node) => defaultNode(node);
  R visitInvalidType(InvalidType node) => defaultDartType(node);
  R visitDynamicType(DynamicType node) => defaultDartType(node);
  R visitVoidType(VoidType node) => defaultDartType(node);
  R visitBottomType(BottomType node) => defaultDartType(node);
  R visitInterfaceType(InterfaceType node) => defaultDartType(node);
  R visitFutureOrType(FutureOrType node) => defaultDartType(node);
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);
  R visitTypedefType(TypedefType node) => defaultDartType(node);
  R visitNeverType(NeverType node) => defaultDartType(node);
  R visitNullType(NullType node) => defaultDartType(node);

  // Constants
  R defaultConstant(Constant node) => defaultNode(node);
  R visitNullConstant(NullConstant node) => defaultConstant(node);
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  R visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  R visitListConstant(ListConstant node) => defaultConstant(node);
  R visitSetConstant(SetConstant node) => defaultConstant(node);
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  R visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      defaultConstant(node);
  R visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
  R visitUnevaluatedConstant(UnevaluatedConstant node) => defaultConstant(node);

  // Class references
  R visitClassReference(Class node) => null;
  R visitTypedefReference(Typedef node) => null;

  // Constant references
  R defaultConstantReference(Constant node) => null;
  R visitNullConstantReference(NullConstant node) =>
      defaultConstantReference(node);
  R visitBoolConstantReference(BoolConstant node) =>
      defaultConstantReference(node);
  R visitIntConstantReference(IntConstant node) =>
      defaultConstantReference(node);
  R visitDoubleConstantReference(DoubleConstant node) =>
      defaultConstantReference(node);
  R visitStringConstantReference(StringConstant node) =>
      defaultConstantReference(node);
  R visitSymbolConstantReference(SymbolConstant node) =>
      defaultConstantReference(node);
  R visitMapConstantReference(MapConstant node) =>
      defaultConstantReference(node);
  R visitListConstantReference(ListConstant node) =>
      defaultConstantReference(node);
  R visitSetConstantReference(SetConstant node) =>
      defaultConstantReference(node);
  R visitInstanceConstantReference(InstanceConstant node) =>
      defaultConstantReference(node);
  R visitPartialInstantiationConstantReference(
          PartialInstantiationConstant node) =>
      defaultConstantReference(node);
  R visitTearOffConstantReference(TearOffConstant node) =>
      defaultConstantReference(node);
  R visitTypeLiteralConstantReference(TypeLiteralConstant node) =>
      defaultConstantReference(node);
  R visitUnevaluatedConstantReference(UnevaluatedConstant node) =>
      defaultConstantReference(node);

  // Member references
  R defaultMemberReference(Member node) => null;
  R visitFieldReference(Field node) => defaultMemberReference(node);
  R visitConstructorReference(Constructor node) => defaultMemberReference(node);
  R visitProcedureReference(Procedure node) => defaultMemberReference(node);
  R visitRedirectingFactoryConstructorReference(
      RedirectingFactoryConstructor node) {
    return defaultMemberReference(node);
  }

  R visitName(Name node) => defaultNode(node);
  R visitSupertype(Supertype node) => defaultNode(node);
  R visitNamedType(NamedType node) => defaultNode(node);
}

class RecursiveVisitor<R> extends Visitor<R> {
  const RecursiveVisitor();

  R defaultNode(Node node) {
    node.visitChildren(this);
    return null;
  }
}

/// Visitor that recursively rewrites each node in tree.
///
/// Visit methods should return a new node, or the visited node (possibly
/// mutated), or any node from the visited node's subtree.
///
/// Each subclass is responsible for ensuring that the AST remains a tree.
///
/// For example, the following transformer replaces every occurrence of
/// `!(x && y)` with `(!x || !y)`:
///
///     class NegationSinker extends Transformer {
///       @override
///       Node visitNot(Not node) {
///         var operand = node.operand.accept(this); // Remember to visit.
///         if (operand is LogicalExpression && operand.operator == '&&') {
///           return new LogicalExpression(
///             new Not(operand.left),
///             '||',
///             new Not(operand.right));
///         }
///         return node;
///       }
///     }
///
class Transformer extends TreeVisitor<TreeNode> {
  const Transformer();

  /// Replaces a use of a type.
  ///
  /// By default, recursion stops at this point.
  DartType visitDartType(DartType node) => node;

  Constant visitConstant(Constant node) => node;

  Supertype visitSupertype(Supertype node) => node;

  TreeNode defaultTreeNode(TreeNode node) {
    node.transformChildren(this);
    return node;
  }
}

abstract class ExpressionVisitor1<R, T> {
  const ExpressionVisitor1();

  R defaultExpression(Expression node, T arg) => null;
  R defaultBasicLiteral(BasicLiteral node, T arg) =>
      defaultExpression(node, arg);
  R visitInvalidExpression(InvalidExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitVariableGet(VariableGet node, T arg) => defaultExpression(node, arg);
  R visitVariableSet(VariableSet node, T arg) => defaultExpression(node, arg);
  R visitDynamicGet(DynamicGet node, T arg) => defaultExpression(node, arg);
  R visitDynamicSet(DynamicSet node, T arg) => defaultExpression(node, arg);
  R visitFunctionTearOff(FunctionTearOff node, T arg) =>
      defaultExpression(node, arg);
  R visitInstanceGet(InstanceGet node, T arg) => defaultExpression(node, arg);
  R visitInstanceSet(InstanceSet node, T arg) => defaultExpression(node, arg);
  R visitInstanceTearOff(InstanceTearOff node, T arg) =>
      defaultExpression(node, arg);
  R visitPropertyGet(PropertyGet node, T arg) => defaultExpression(node, arg);
  R visitPropertySet(PropertySet node, T arg) => defaultExpression(node, arg);
  R visitSuperPropertyGet(SuperPropertyGet node, T arg) =>
      defaultExpression(node, arg);
  R visitSuperPropertySet(SuperPropertySet node, T arg) =>
      defaultExpression(node, arg);
  R visitStaticGet(StaticGet node, T arg) => defaultExpression(node, arg);
  R visitStaticSet(StaticSet node, T arg) => defaultExpression(node, arg);
  R visitStaticTearOff(StaticTearOff node, T arg) =>
      defaultExpression(node, arg);
  R visitLocalFunctionInvocation(LocalFunctionInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitDynamicInvocation(DynamicInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitFunctionInvocation(FunctionInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitInstanceInvocation(InstanceInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitEqualsNull(EqualsNull node, T arg) => defaultExpression(node, arg);
  R visitEqualsCall(EqualsCall node, T arg) => defaultExpression(node, arg);
  R visitMethodInvocation(MethodInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitSuperMethodInvocation(SuperMethodInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitStaticInvocation(StaticInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitConstructorInvocation(ConstructorInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitNot(Not node, T arg) => defaultExpression(node, arg);
  R visitNullCheck(NullCheck node, T arg) => defaultExpression(node, arg);
  R visitLogicalExpression(LogicalExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitConditionalExpression(ConditionalExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitStringConcatenation(StringConcatenation node, T arg) =>
      defaultExpression(node, arg);
  R visitListConcatenation(ListConcatenation node, T arg) =>
      defaultExpression(node, arg);
  R visitSetConcatenation(SetConcatenation node, T arg) =>
      defaultExpression(node, arg);
  R visitMapConcatenation(MapConcatenation node, T arg) =>
      defaultExpression(node, arg);
  R visitInstanceCreation(InstanceCreation node, T arg) =>
      defaultExpression(node, arg);
  R visitFileUriExpression(FileUriExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitIsExpression(IsExpression node, T arg) => defaultExpression(node, arg);
  R visitAsExpression(AsExpression node, T arg) => defaultExpression(node, arg);
  R visitSymbolLiteral(SymbolLiteral node, T arg) =>
      defaultExpression(node, arg);
  R visitTypeLiteral(TypeLiteral node, T arg) => defaultExpression(node, arg);
  R visitThisExpression(ThisExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitConstantExpression(ConstantExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitRethrow(Rethrow node, T arg) => defaultExpression(node, arg);
  R visitThrow(Throw node, T arg) => defaultExpression(node, arg);
  R visitListLiteral(ListLiteral node, T arg) => defaultExpression(node, arg);
  R visitSetLiteral(SetLiteral node, T arg) => defaultExpression(node, arg);
  R visitMapLiteral(MapLiteral node, T arg) => defaultExpression(node, arg);
  R visitAwaitExpression(AwaitExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitFunctionExpression(FunctionExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitIntLiteral(IntLiteral node, T arg) => defaultBasicLiteral(node, arg);
  R visitStringLiteral(StringLiteral node, T arg) =>
      defaultBasicLiteral(node, arg);
  R visitDoubleLiteral(DoubleLiteral node, T arg) =>
      defaultBasicLiteral(node, arg);
  R visitBoolLiteral(BoolLiteral node, T arg) => defaultBasicLiteral(node, arg);
  R visitNullLiteral(NullLiteral node, T arg) => defaultBasicLiteral(node, arg);
  R visitLet(Let node, T arg) => defaultExpression(node, arg);
  R visitBlockExpression(BlockExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitInstantiation(Instantiation node, T arg) =>
      defaultExpression(node, arg);
  R visitLoadLibrary(LoadLibrary node, T arg) => defaultExpression(node, arg);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, T arg) =>
      defaultExpression(node, arg);
}

abstract class StatementVisitor1<R, T> {
  const StatementVisitor1();

  R defaultStatement(Statement node, T arg) => null;

  R visitExpressionStatement(ExpressionStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitBlock(Block node, T arg) => defaultStatement(node, arg);
  R visitAssertBlock(AssertBlock node, T arg) => defaultStatement(node, arg);
  R visitEmptyStatement(EmptyStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitAssertStatement(AssertStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitLabeledStatement(LabeledStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitBreakStatement(BreakStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitWhileStatement(WhileStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitDoStatement(DoStatement node, T arg) => defaultStatement(node, arg);
  R visitForStatement(ForStatement node, T arg) => defaultStatement(node, arg);
  R visitForInStatement(ForInStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitSwitchStatement(SwitchStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitContinueSwitchStatement(ContinueSwitchStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitIfStatement(IfStatement node, T arg) => defaultStatement(node, arg);
  R visitReturnStatement(ReturnStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitTryCatch(TryCatch node, T arg) => defaultStatement(node, arg);
  R visitTryFinally(TryFinally node, T arg) => defaultStatement(node, arg);
  R visitYieldStatement(YieldStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitVariableDeclaration(VariableDeclaration node, T arg) =>
      defaultStatement(node, arg);
  R visitFunctionDeclaration(FunctionDeclaration node, T arg) =>
      defaultStatement(node, arg);
}

abstract class BodyVisitor1<R, T> extends ExpressionVisitor1<R, T>
    implements StatementVisitor1<R, T> {
  const BodyVisitor1();

  R defaultStatement(Statement node, T arg) => null;
  R visitExpressionStatement(ExpressionStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitBlock(Block node, T arg) => defaultStatement(node, arg);
  R visitAssertBlock(AssertBlock node, T arg) => defaultStatement(node, arg);
  R visitEmptyStatement(EmptyStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitAssertStatement(AssertStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitLabeledStatement(LabeledStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitBreakStatement(BreakStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitWhileStatement(WhileStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitDoStatement(DoStatement node, T arg) => defaultStatement(node, arg);
  R visitForStatement(ForStatement node, T arg) => defaultStatement(node, arg);
  R visitForInStatement(ForInStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitSwitchStatement(SwitchStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitContinueSwitchStatement(ContinueSwitchStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitIfStatement(IfStatement node, T arg) => defaultStatement(node, arg);
  R visitReturnStatement(ReturnStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitTryCatch(TryCatch node, T arg) => defaultStatement(node, arg);
  R visitTryFinally(TryFinally node, T arg) => defaultStatement(node, arg);
  R visitYieldStatement(YieldStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitVariableDeclaration(VariableDeclaration node, T arg) =>
      defaultStatement(node, arg);
  R visitFunctionDeclaration(FunctionDeclaration node, T arg) =>
      defaultStatement(node, arg);
}
