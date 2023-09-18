// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.ast.visitor;

import 'dart:collection';

import 'ast.dart';

abstract class ExpressionVisitor<R> {
  const ExpressionVisitor();

  R visitAuxiliaryExpression(AuxiliaryExpression node);
  R visitInvalidExpression(InvalidExpression node);
  R visitVariableGet(VariableGet node);
  R visitVariableSet(VariableSet node);
  R visitDynamicGet(DynamicGet node);
  R visitDynamicSet(DynamicSet node);
  R visitFunctionTearOff(FunctionTearOff node);
  R visitInstanceGet(InstanceGet node);
  R visitInstanceSet(InstanceSet node);
  R visitInstanceTearOff(InstanceTearOff node);
  R visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node);
  R visitAbstractSuperPropertySet(AbstractSuperPropertySet node);
  R visitSuperPropertyGet(SuperPropertyGet node);
  R visitSuperPropertySet(SuperPropertySet node);
  R visitStaticGet(StaticGet node);
  R visitStaticSet(StaticSet node);
  R visitStaticTearOff(StaticTearOff node);
  R visitLocalFunctionInvocation(LocalFunctionInvocation node);
  R visitDynamicInvocation(DynamicInvocation node);
  R visitFunctionInvocation(FunctionInvocation node);
  R visitInstanceInvocation(InstanceInvocation node);
  R visitInstanceGetterInvocation(InstanceGetterInvocation node);
  R visitEqualsNull(EqualsNull node);
  R visitEqualsCall(EqualsCall node);
  R visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node);
  R visitSuperMethodInvocation(SuperMethodInvocation node);
  R visitStaticInvocation(StaticInvocation node);
  R visitConstructorInvocation(ConstructorInvocation node);
  R visitNot(Not node);
  R visitNullCheck(NullCheck node);
  R visitLogicalExpression(LogicalExpression node);
  R visitConditionalExpression(ConditionalExpression node);
  R visitStringConcatenation(StringConcatenation node);
  R visitListConcatenation(ListConcatenation node);
  R visitSetConcatenation(SetConcatenation node);
  R visitMapConcatenation(MapConcatenation node);
  R visitInstanceCreation(InstanceCreation node);
  R visitFileUriExpression(FileUriExpression node);
  R visitIsExpression(IsExpression node);
  R visitAsExpression(AsExpression node);
  R visitSymbolLiteral(SymbolLiteral node);
  R visitTypeLiteral(TypeLiteral node);
  R visitThisExpression(ThisExpression node);
  R visitRethrow(Rethrow node);
  R visitThrow(Throw node);
  R visitListLiteral(ListLiteral node);
  R visitSetLiteral(SetLiteral node);
  R visitMapLiteral(MapLiteral node);
  R visitRecordLiteral(RecordLiteral node);
  R visitAwaitExpression(AwaitExpression node);
  R visitFunctionExpression(FunctionExpression node);
  R visitConstantExpression(ConstantExpression node);
  R visitStringLiteral(StringLiteral node);
  R visitIntLiteral(IntLiteral node);
  R visitDoubleLiteral(DoubleLiteral node);
  R visitBoolLiteral(BoolLiteral node);
  R visitNullLiteral(NullLiteral node);
  R visitLet(Let node);
  R visitBlockExpression(BlockExpression node);
  R visitInstantiation(Instantiation node);
  R visitLoadLibrary(LoadLibrary node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node);
  R visitConstructorTearOff(ConstructorTearOff node);
  R visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node);
  R visitTypedefTearOff(TypedefTearOff node);
  R visitRecordIndexGet(RecordIndexGet node);
  R visitRecordNameGet(RecordNameGet node);
  R visitSwitchExpression(SwitchExpression node);
  R visitPatternAssignment(PatternAssignment node);
}

/// Helper mixin for [ExpressionVisitor] that implements visit methods by
/// delegating to the [defaultBasicLiteral] and [defaultExpression] methods.
mixin ExpressionVisitorDefaultMixin<R> implements ExpressionVisitor<R> {
  R defaultExpression(Expression node);
  R defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  @override
  R visitAuxiliaryExpression(AuxiliaryExpression node) =>
      defaultExpression(node);
  @override
  R visitInvalidExpression(InvalidExpression node) => defaultExpression(node);
  @override
  R visitVariableGet(VariableGet node) => defaultExpression(node);
  @override
  R visitVariableSet(VariableSet node) => defaultExpression(node);
  @override
  R visitDynamicGet(DynamicGet node) => defaultExpression(node);
  @override
  R visitDynamicSet(DynamicSet node) => defaultExpression(node);
  @override
  R visitFunctionTearOff(FunctionTearOff node) => defaultExpression(node);
  @override
  R visitInstanceGet(InstanceGet node) => defaultExpression(node);
  @override
  R visitInstanceSet(InstanceSet node) => defaultExpression(node);
  @override
  R visitInstanceTearOff(InstanceTearOff node) => defaultExpression(node);
  @override
  R visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) =>
      defaultExpression(node);
  @override
  R visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      defaultExpression(node);
  @override
  R visitSuperPropertyGet(SuperPropertyGet node) => defaultExpression(node);
  @override
  R visitSuperPropertySet(SuperPropertySet node) => defaultExpression(node);
  @override
  R visitStaticGet(StaticGet node) => defaultExpression(node);
  @override
  R visitStaticSet(StaticSet node) => defaultExpression(node);
  @override
  R visitStaticTearOff(StaticTearOff node) => defaultExpression(node);
  @override
  R visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      defaultExpression(node);
  @override
  R visitDynamicInvocation(DynamicInvocation node) => defaultExpression(node);
  @override
  R visitFunctionInvocation(FunctionInvocation node) => defaultExpression(node);
  @override
  R visitInstanceInvocation(InstanceInvocation node) => defaultExpression(node);
  @override
  R visitInstanceGetterInvocation(InstanceGetterInvocation node) =>
      defaultExpression(node);
  @override
  R visitEqualsNull(EqualsNull node) => defaultExpression(node);
  @override
  R visitEqualsCall(EqualsCall node) => defaultExpression(node);
  @override
  R visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node) =>
      defaultExpression(node);
  @override
  R visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);
  @override
  R visitStaticInvocation(StaticInvocation node) => defaultExpression(node);
  @override
  R visitConstructorInvocation(ConstructorInvocation node) =>
      defaultExpression(node);
  @override
  R visitNot(Not node) => defaultExpression(node);
  @override
  R visitNullCheck(NullCheck node) => defaultExpression(node);
  @override
  R visitLogicalExpression(LogicalExpression node) => defaultExpression(node);
  @override
  R visitConditionalExpression(ConditionalExpression node) =>
      defaultExpression(node);
  @override
  R visitStringConcatenation(StringConcatenation node) =>
      defaultExpression(node);
  @override
  R visitListConcatenation(ListConcatenation node) => defaultExpression(node);
  @override
  R visitSetConcatenation(SetConcatenation node) => defaultExpression(node);
  @override
  R visitMapConcatenation(MapConcatenation node) => defaultExpression(node);
  @override
  R visitInstanceCreation(InstanceCreation node) => defaultExpression(node);
  @override
  R visitFileUriExpression(FileUriExpression node) => defaultExpression(node);
  @override
  R visitIsExpression(IsExpression node) => defaultExpression(node);
  @override
  R visitAsExpression(AsExpression node) => defaultExpression(node);
  @override
  R visitSymbolLiteral(SymbolLiteral node) => defaultExpression(node);
  @override
  R visitTypeLiteral(TypeLiteral node) => defaultExpression(node);
  @override
  R visitThisExpression(ThisExpression node) => defaultExpression(node);
  @override
  R visitRethrow(Rethrow node) => defaultExpression(node);
  @override
  R visitThrow(Throw node) => defaultExpression(node);
  @override
  R visitListLiteral(ListLiteral node) => defaultExpression(node);
  @override
  R visitSetLiteral(SetLiteral node) => defaultExpression(node);
  @override
  R visitMapLiteral(MapLiteral node) => defaultExpression(node);
  @override
  R visitRecordLiteral(RecordLiteral node) => defaultExpression(node);
  @override
  R visitAwaitExpression(AwaitExpression node) => defaultExpression(node);
  @override
  R visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  @override
  R visitConstantExpression(ConstantExpression node) => defaultExpression(node);
  @override
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  @override
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  @override
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  @override
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  @override
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  @override
  R visitLet(Let node) => defaultExpression(node);
  @override
  R visitBlockExpression(BlockExpression node) => defaultExpression(node);
  @override
  R visitInstantiation(Instantiation node) => defaultExpression(node);
  @override
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  @override
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
  @override
  R visitConstructorTearOff(ConstructorTearOff node) => defaultExpression(node);
  @override
  R visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) =>
      defaultExpression(node);
  @override
  R visitTypedefTearOff(TypedefTearOff node) => defaultExpression(node);
  @override
  R visitRecordIndexGet(RecordIndexGet node) => defaultExpression(node);
  @override
  R visitRecordNameGet(RecordNameGet node) => defaultExpression(node);
  @override
  R visitSwitchExpression(SwitchExpression node) => defaultExpression(node);
  @override
  R visitPatternAssignment(PatternAssignment node) => defaultExpression(node);
}

abstract class PatternVisitor<R> {
  R visitAndPattern(AndPattern node);
  R visitAssignedVariablePattern(AssignedVariablePattern node);
  R visitCastPattern(CastPattern node);
  R visitConstantPattern(ConstantPattern node);
  R visitInvalidPattern(InvalidPattern node);
  R visitListPattern(ListPattern node);
  R visitMapPattern(MapPattern node);
  R visitNamedPattern(NamedPattern node);
  R visitNullAssertPattern(NullAssertPattern node);
  R visitNullCheckPattern(NullCheckPattern node);
  R visitObjectPattern(ObjectPattern node);
  R visitOrPattern(OrPattern node);
  R visitRecordPattern(RecordPattern node);
  R visitRelationalPattern(RelationalPattern node);
  R visitRestPattern(RestPattern node);
  R visitVariablePattern(VariablePattern node);
  R visitWildcardPattern(WildcardPattern node);
}

/// Helper mixin for [PatternVisitor] that implements visit methods by
/// delegating to the [defaultPattern] method.
mixin PatternVisitorDefaultMixin<R> implements PatternVisitor<R> {
  R defaultPattern(Pattern node);
  @override
  R visitAndPattern(AndPattern node) => defaultPattern(node);
  @override
  R visitAssignedVariablePattern(AssignedVariablePattern node) =>
      defaultPattern(node);
  @override
  R visitCastPattern(CastPattern node) => defaultPattern(node);
  @override
  R visitConstantPattern(ConstantPattern node) => defaultPattern(node);
  @override
  R visitInvalidPattern(InvalidPattern node) => defaultPattern(node);
  @override
  R visitListPattern(ListPattern node) => defaultPattern(node);
  @override
  R visitMapPattern(MapPattern node) => defaultPattern(node);
  @override
  R visitNamedPattern(NamedPattern node) => defaultPattern(node);
  @override
  @override
  R visitNullAssertPattern(NullAssertPattern node) => defaultPattern(node);
  @override
  R visitNullCheckPattern(NullCheckPattern node) => defaultPattern(node);
  @override
  R visitObjectPattern(ObjectPattern node) => defaultPattern(node);
  @override
  R visitOrPattern(OrPattern node) => defaultPattern(node);
  @override
  R visitRecordPattern(RecordPattern node) => defaultPattern(node);
  @override
  R visitRelationalPattern(RelationalPattern node) => defaultPattern(node);
  @override
  R visitRestPattern(RestPattern node) => defaultPattern(node);
  @override
  R visitVariablePattern(VariablePattern node) => defaultPattern(node);
  @override
  R visitWildcardPattern(WildcardPattern node) => defaultPattern(node);
}

abstract class StatementVisitor<R> {
  const StatementVisitor();

  R visitAuxiliaryStatement(AuxiliaryStatement node);
  R visitExpressionStatement(ExpressionStatement node);
  R visitBlock(Block node);
  R visitAssertBlock(AssertBlock node);
  R visitEmptyStatement(EmptyStatement node);
  R visitAssertStatement(AssertStatement node);
  R visitLabeledStatement(LabeledStatement node);
  R visitBreakStatement(BreakStatement node);
  R visitWhileStatement(WhileStatement node);
  R visitDoStatement(DoStatement node);
  R visitForStatement(ForStatement node);
  R visitForInStatement(ForInStatement node);
  R visitSwitchStatement(SwitchStatement node);
  R visitPatternSwitchStatement(PatternSwitchStatement node);
  R visitContinueSwitchStatement(ContinueSwitchStatement node);
  R visitIfStatement(IfStatement node);
  R visitIfCaseStatement(IfCaseStatement node);
  R visitReturnStatement(ReturnStatement node);
  R visitTryCatch(TryCatch node);
  R visitTryFinally(TryFinally node);
  R visitYieldStatement(YieldStatement node);
  R visitVariableDeclaration(VariableDeclaration node);
  R visitPatternVariableDeclaration(PatternVariableDeclaration node);
  R visitFunctionDeclaration(FunctionDeclaration node);
}

/// Helper mixin for [StatementVisitor] that implements visit methods by
/// delegating to the [defaultStatement] method.
mixin StatementVisitorDefaultMixin<R> implements StatementVisitor<R> {
  R defaultStatement(Statement node);

  @override
  R visitAuxiliaryStatement(AuxiliaryStatement node) => defaultStatement(node);
  @override
  R visitExpressionStatement(ExpressionStatement node) =>
      defaultStatement(node);
  @override
  R visitBlock(Block node) => defaultStatement(node);
  @override
  R visitAssertBlock(AssertBlock node) => defaultStatement(node);
  @override
  R visitEmptyStatement(EmptyStatement node) => defaultStatement(node);
  @override
  R visitAssertStatement(AssertStatement node) => defaultStatement(node);
  @override
  R visitLabeledStatement(LabeledStatement node) => defaultStatement(node);
  @override
  R visitBreakStatement(BreakStatement node) => defaultStatement(node);
  @override
  R visitWhileStatement(WhileStatement node) => defaultStatement(node);
  @override
  R visitDoStatement(DoStatement node) => defaultStatement(node);
  @override
  R visitForStatement(ForStatement node) => defaultStatement(node);
  @override
  R visitForInStatement(ForInStatement node) => defaultStatement(node);
  @override
  R visitSwitchStatement(SwitchStatement node) => defaultStatement(node);
  @override
  R visitPatternSwitchStatement(PatternSwitchStatement node) =>
      defaultStatement(node);
  @override
  R visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      defaultStatement(node);
  @override
  R visitIfStatement(IfStatement node) => defaultStatement(node);
  @override
  R visitIfCaseStatement(IfCaseStatement node) => defaultStatement(node);
  @override
  R visitReturnStatement(ReturnStatement node) => defaultStatement(node);
  @override
  R visitTryCatch(TryCatch node) => defaultStatement(node);
  @override
  R visitTryFinally(TryFinally node) => defaultStatement(node);
  @override
  R visitYieldStatement(YieldStatement node) => defaultStatement(node);
  @override
  R visitVariableDeclaration(VariableDeclaration node) =>
      defaultStatement(node);
  @override
  R visitPatternVariableDeclaration(PatternVariableDeclaration node) =>
      defaultStatement(node);
  @override
  R visitFunctionDeclaration(FunctionDeclaration node) =>
      defaultStatement(node);
}

abstract class MemberVisitor<R> {
  const MemberVisitor();

  R visitConstructor(Constructor node);
  R visitProcedure(Procedure node);
  R visitField(Field node);
}

/// Helper mixin for [MemberVisitor] that implements visit methods by
/// delegating to the [defaultMember] method.
mixin MemberVisitorDefaultMixin<R> implements MemberVisitor<R> {
  R defaultMember(Member node);

  @override
  R visitConstructor(Constructor node) => defaultMember(node);
  @override
  R visitProcedure(Procedure node) => defaultMember(node);
  @override
  R visitField(Field node) => defaultMember(node);
}

abstract class MemberVisitor1<R, A> {
  const MemberVisitor1();

  R visitConstructor(Constructor node, A arg);
  R visitProcedure(Procedure node, A arg);
  R visitField(Field node, A arg);
}

/// Helper mixin for [MemberVisitor1] that implements visit methods by
/// delegating to the [defaultMember] method.
mixin MemberVisitor1DefaultMixin<R, A> implements MemberVisitor1<R, A> {
  R defaultMember(Member node, A arg);

  @override
  R visitConstructor(Constructor node, A arg) => defaultMember(node, arg);
  @override
  R visitProcedure(Procedure node, A arg) => defaultMember(node, arg);
  @override
  R visitField(Field node, A arg) => defaultMember(node, arg);
}

abstract class InitializerVisitor<R> {
  const InitializerVisitor();

  R visitAuxiliaryInitializer(AuxiliaryInitializer node);
  R visitInvalidInitializer(InvalidInitializer node);
  R visitFieldInitializer(FieldInitializer node);
  R visitSuperInitializer(SuperInitializer node);
  R visitRedirectingInitializer(RedirectingInitializer node);
  R visitLocalInitializer(LocalInitializer node);
  R visitAssertInitializer(AssertInitializer node);
}

/// Helper mixin for [InitializerVisitor] that implements visit methods by
/// delegating to the [defaultInitializer] method.
mixin InitializerVisitorDefaultMixin<R> implements InitializerVisitor<R> {
  R defaultInitializer(Initializer node);

  @override
  R visitAuxiliaryInitializer(AuxiliaryInitializer node) =>
      defaultInitializer(node);
  @override
  R visitInvalidInitializer(InvalidInitializer node) =>
      defaultInitializer(node);
  @override
  R visitFieldInitializer(FieldInitializer node) => defaultInitializer(node);
  @override
  R visitSuperInitializer(SuperInitializer node) => defaultInitializer(node);
  @override
  R visitRedirectingInitializer(RedirectingInitializer node) =>
      defaultInitializer(node);
  @override
  R visitLocalInitializer(LocalInitializer node) => defaultInitializer(node);
  @override
  R visitAssertInitializer(AssertInitializer node) => defaultInitializer(node);
}

abstract class InitializerVisitor1<R, A> {
  const InitializerVisitor1();

  R visitAuxiliaryInitializer(AuxiliaryInitializer node, A arg);
  R visitInvalidInitializer(InvalidInitializer node, A arg);
  R visitFieldInitializer(FieldInitializer node, A arg);
  R visitSuperInitializer(SuperInitializer node, A arg);
  R visitRedirectingInitializer(RedirectingInitializer node, A arg);
  R visitLocalInitializer(LocalInitializer node, A arg);
  R visitAssertInitializer(AssertInitializer node, A arg);
}

/// Helper mixin for [InitializerVisitor1] that implements visit methods by
/// delegating to the [defaultInitializer] method.
mixin InitializerVisitor1DefaultMixin<R, A>
    implements InitializerVisitor1<R, A> {
  R defaultInitializer(Initializer node, A arg);

  @override
  R visitAuxiliaryInitializer(AuxiliaryInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitInvalidInitializer(InvalidInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitFieldInitializer(FieldInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitSuperInitializer(SuperInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitRedirectingInitializer(RedirectingInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitLocalInitializer(LocalInitializer node, A arg) =>
      defaultInitializer(node, arg);
  @override
  R visitAssertInitializer(AssertInitializer node, A arg) =>
      defaultInitializer(node, arg);
}

abstract class TreeVisitor<R>
    implements
        ExpressionVisitor<R>,
        PatternVisitor<R>,
        StatementVisitor<R>,
        MemberVisitor<R>,
        InitializerVisitor<R> {
  const TreeVisitor();

  // Classes
  R visitClass(Class node);
  R visitExtension(Extension node);
  R visitExtensionTypeDeclaration(ExtensionTypeDeclaration node);

  // Other tree nodes
  R visitLibrary(Library node);
  R visitLibraryDependency(LibraryDependency node);
  R visitCombinator(Combinator node);
  R visitLibraryPart(LibraryPart node);
  R visitTypedef(Typedef node);
  R visitTypeParameter(TypeParameter node);
  R visitFunctionNode(FunctionNode node);
  R visitArguments(Arguments node);
  R visitNamedExpression(NamedExpression node);
  R visitSwitchCase(SwitchCase node);
  R visitPatternSwitchCase(PatternSwitchCase node);
  R visitSwitchExpressionCase(SwitchExpressionCase node);
  R visitCatch(Catch node);
  R visitMapLiteralEntry(MapLiteralEntry node);
  R visitMapPatternEntry(MapPatternEntry node);
  R visitMapPatternRestEntry(MapPatternRestEntry node);
  R visitPatternGuard(PatternGuard node);
  R visitComponent(Component node);
}

/// Helper mixin for [TreeVisitor] that implements visit methods by delegating
/// to the [defaultTreeNode] method.
mixin TreeVisitorDefaultMixin<R> implements TreeVisitor<R> {
  R defaultTreeNode(TreeNode node);

  // Classes
  @override
  R visitClass(Class node) => defaultTreeNode(node);
  @override
  R visitExtension(Extension node) => defaultTreeNode(node);
  @override
  R visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      defaultTreeNode(node);

  // Other tree nodes
  @override
  R visitLibrary(Library node) => defaultTreeNode(node);
  @override
  R visitLibraryDependency(LibraryDependency node) => defaultTreeNode(node);
  @override
  R visitCombinator(Combinator node) => defaultTreeNode(node);
  @override
  R visitLibraryPart(LibraryPart node) => defaultTreeNode(node);
  @override
  R visitTypedef(Typedef node) => defaultTreeNode(node);
  @override
  R visitTypeParameter(TypeParameter node) => defaultTreeNode(node);
  @override
  R visitFunctionNode(FunctionNode node) => defaultTreeNode(node);
  @override
  R visitArguments(Arguments node) => defaultTreeNode(node);
  @override
  R visitNamedExpression(NamedExpression node) => defaultTreeNode(node);
  @override
  R visitSwitchCase(SwitchCase node) => defaultTreeNode(node);
  @override
  R visitPatternSwitchCase(PatternSwitchCase node) => defaultTreeNode(node);
  @override
  R visitSwitchExpressionCase(SwitchExpressionCase node) =>
      defaultTreeNode(node);
  @override
  R visitCatch(Catch node) => defaultTreeNode(node);
  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => defaultTreeNode(node);
  @override
  R visitMapPatternEntry(MapPatternEntry node) => defaultTreeNode(node);
  @override
  R visitMapPatternRestEntry(MapPatternRestEntry node) => defaultTreeNode(node);
  @override
  R visitPatternGuard(PatternGuard node) => defaultTreeNode(node);
  @override
  R visitComponent(Component node) => defaultTreeNode(node);
}

/// Base class for implementing [TreeVisitor1] that implements visit methods
/// mixing in the various `DefaultMixin` mixins and delegating their `default`
/// methods to the [defaultTreeNode] method.
abstract class TreeVisitorDefault<R>
    with
        ExpressionVisitorDefaultMixin<R>,
        StatementVisitorDefaultMixin<R>,
        PatternVisitorDefaultMixin<R>,
        InitializerVisitorDefaultMixin<R>,
        MemberVisitorDefaultMixin<R>,
        TreeVisitorDefaultMixin<R>
    implements TreeVisitor<R> {
  const TreeVisitorDefault();

  @override
  R defaultExpression(Expression node) => defaultTreeNode(node);
  @override
  R defaultPattern(Pattern node) => defaultTreeNode(node);
  @override
  R defaultStatement(Statement node) => defaultTreeNode(node);
  @override
  R defaultInitializer(Initializer node) => defaultTreeNode(node);
  @override
  R defaultMember(Member node) => defaultTreeNode(node);
}

abstract class TreeVisitor1<R, A>
    implements
        ExpressionVisitor1<R, A>,
        PatternVisitor1<R, A>,
        StatementVisitor1<R, A>,
        MemberVisitor1<R, A>,
        InitializerVisitor1<R, A> {
  const TreeVisitor1();

  // Classes
  R visitClass(Class node, A arg);
  R visitExtension(Extension node, A arg);
  R visitExtensionTypeDeclaration(ExtensionTypeDeclaration node, A arg);

  // Other tree nodes
  R visitLibrary(Library node, A arg);
  R visitLibraryDependency(LibraryDependency node, A arg);
  R visitCombinator(Combinator node, A arg);
  R visitLibraryPart(LibraryPart node, A arg);
  R visitTypedef(Typedef node, A arg);
  R visitTypeParameter(TypeParameter node, A arg);
  R visitFunctionNode(FunctionNode node, A arg);
  R visitArguments(Arguments node, A arg);
  R visitNamedExpression(NamedExpression node, A arg);
  R visitSwitchCase(SwitchCase node, A arg);
  R visitPatternSwitchCase(PatternSwitchCase node, A arg);
  R visitSwitchExpressionCase(SwitchExpressionCase node, A arg);
  R visitCatch(Catch node, A arg);
  R visitMapLiteralEntry(MapLiteralEntry node, A arg);
  R visitMapPatternEntry(MapPatternEntry node, A arg);
  R visitMapPatternRestEntry(MapPatternRestEntry node, A arg);
  R visitPatternGuard(PatternGuard node, A arg);
  R visitComponent(Component node, A arg);
}

/// Helper mixin for [TreeVisitor1] that implements visit methods by delegating
/// to the [defaultTreeNode] method.
mixin TreeVisitor1DefaultMixin<R, A> implements TreeVisitor1<R, A> {
  R defaultTreeNode(TreeNode node, A arg);

  // Classes
  @override
  R visitClass(Class node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitExtension(Extension node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitExtensionTypeDeclaration(ExtensionTypeDeclaration node, A arg) =>
      defaultTreeNode(node, arg);

  // Other tree nodes
  @override
  R visitLibrary(Library node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitLibraryDependency(LibraryDependency node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitCombinator(Combinator node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitLibraryPart(LibraryPart node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitTypedef(Typedef node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitTypeParameter(TypeParameter node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitFunctionNode(FunctionNode node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitArguments(Arguments node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitNamedExpression(NamedExpression node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitSwitchCase(SwitchCase node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitPatternSwitchCase(PatternSwitchCase node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitSwitchExpressionCase(SwitchExpressionCase node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitCatch(Catch node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitMapLiteralEntry(MapLiteralEntry node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitMapPatternEntry(MapPatternEntry node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitMapPatternRestEntry(MapPatternRestEntry node, A arg) =>
      defaultTreeNode(node, arg);
  @override
  R visitPatternGuard(PatternGuard node, A arg) => defaultTreeNode(node, arg);
  @override
  R visitComponent(Component node, A arg) => defaultTreeNode(node, arg);
}

/// Base class for implementing [TreeVisitor1] that implements visit methods
/// mixing in the various `DefaultMixin` mixins and delegating their `default`
/// methods to the [defaultTreeNode] method.
abstract class TreeVisitor1Default<R, A>
    with
        TreeVisitor1DefaultMixin<R, A>,
        ExpressionVisitor1DefaultMixin<R, A>,
        PatternVisitor1DefaultMixin<R, A>,
        StatementVisitor1DefaultMixin<R, A>,
        InitializerVisitor1DefaultMixin<R, A>,
        MemberVisitor1DefaultMixin<R, A>
    implements TreeVisitor1<R, A> {
  const TreeVisitor1Default();

  @override
  R defaultExpression(Expression node, A arg) => defaultTreeNode(node, arg);
  @override
  R defaultPattern(Pattern node, A arg) => defaultTreeNode(node, arg);
  @override
  R defaultStatement(Statement node, A arg) => defaultTreeNode(node, arg);
  @override
  R defaultInitializer(Initializer node, A arg) => defaultTreeNode(node, arg);
  @override
  R defaultMember(Member node, A arg) => defaultTreeNode(node, arg);
}

typedef DartTypeVisitorAuxiliaryFunction<R> = R Function(
    AuxiliaryType node, R Function(AuxiliaryType node) recursor);

abstract class DartTypeVisitor<R> {
  const DartTypeVisitor();

  R visitAuxiliaryType(AuxiliaryType node);
  R visitInvalidType(InvalidType node);
  R visitDynamicType(DynamicType node);
  R visitVoidType(VoidType node);
  R visitInterfaceType(InterfaceType node);
  R visitFutureOrType(FutureOrType node);
  R visitFunctionType(FunctionType node);
  R visitTypeParameterType(TypeParameterType node);
  R visitTypedefType(TypedefType node);
  R visitNeverType(NeverType node);
  R visitNullType(NullType node);
  R visitExtensionType(ExtensionType node);
  R visitIntersectionType(IntersectionType node);
  R visitRecordType(RecordType node);
}

/// Helper mixin for [DartTypeVisitor] that implements visit methods by
/// delegating to the [defaultDartType] method.
mixin DartTypeVisitorDefaultMixin<R> implements DartTypeVisitor<R> {
  R defaultDartType(DartType node);

  @override
  R visitAuxiliaryType(AuxiliaryType node) => defaultDartType(node);
  @override
  R visitInvalidType(InvalidType node) => defaultDartType(node);
  @override
  R visitDynamicType(DynamicType node) => defaultDartType(node);
  @override
  R visitVoidType(VoidType node) => defaultDartType(node);
  @override
  R visitInterfaceType(InterfaceType node) => defaultDartType(node);
  @override
  R visitFutureOrType(FutureOrType node) => defaultDartType(node);
  @override
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  @override
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);
  @override
  R visitTypedefType(TypedefType node) => defaultDartType(node);
  @override
  R visitNeverType(NeverType node) => defaultDartType(node);
  @override
  R visitNullType(NullType node) => defaultDartType(node);
  @override
  R visitExtensionType(ExtensionType node) => defaultDartType(node);
  @override
  R visitIntersectionType(IntersectionType node) => defaultDartType(node);
  @override
  R visitRecordType(RecordType node) => defaultDartType(node);
}

typedef DartTypeVisitor1AuxiliaryFunction<R, A> = R Function(
    AuxiliaryType node, A arg, R Function(AuxiliaryType node, A arg) recursor);

abstract class DartTypeVisitor1<R, A> {
  const DartTypeVisitor1();

  R visitAuxiliaryType(AuxiliaryType node, A arg);
  R visitInvalidType(InvalidType node, A arg);
  R visitDynamicType(DynamicType node, A arg);
  R visitVoidType(VoidType node, A arg);
  R visitInterfaceType(InterfaceType node, A arg);
  R visitFutureOrType(FutureOrType node, A arg);
  R visitFunctionType(FunctionType node, A arg);
  R visitTypeParameterType(TypeParameterType node, A arg);
  R visitTypedefType(TypedefType node, A arg);
  R visitNeverType(NeverType node, A arg);
  R visitNullType(NullType node, A arg);
  R visitExtensionType(ExtensionType node, A arg);
  R visitIntersectionType(IntersectionType node, A arg);
  R visitRecordType(RecordType node, A arg);
}

/// Helper mixin for [DartTypeVisitor1] that implements visit methods by
/// delegating to the [defaultDartType] method.
mixin DartTypeVisitor1DefaultMixin<R, A> implements DartTypeVisitor1<R, A> {
  R defaultDartType(DartType node, A arg);

  @override
  R visitAuxiliaryType(AuxiliaryType node, A arg) => defaultDartType(node, arg);
  @override
  R visitInvalidType(InvalidType node, A arg) => defaultDartType(node, arg);
  @override
  R visitDynamicType(DynamicType node, A arg) => defaultDartType(node, arg);
  @override
  R visitVoidType(VoidType node, A arg) => defaultDartType(node, arg);
  @override
  R visitInterfaceType(InterfaceType node, A arg) => defaultDartType(node, arg);
  @override
  R visitFutureOrType(FutureOrType node, A arg) => defaultDartType(node, arg);
  @override
  R visitFunctionType(FunctionType node, A arg) => defaultDartType(node, arg);
  @override
  R visitTypeParameterType(TypeParameterType node, A arg) =>
      defaultDartType(node, arg);
  @override
  R visitTypedefType(TypedefType node, A arg) => defaultDartType(node, arg);
  @override
  R visitNeverType(NeverType node, A arg) => defaultDartType(node, arg);
  @override
  R visitNullType(NullType node, A arg) => defaultDartType(node, arg);
  @override
  R visitExtensionType(ExtensionType node, A arg) => defaultDartType(node, arg);
  @override
  R visitIntersectionType(IntersectionType node, A arg) =>
      defaultDartType(node, arg);
  @override
  R visitRecordType(RecordType node, A arg) => defaultDartType(node, arg);
}

/// Visitor for [Constant] nodes.
///
/// Note: Constant nodes are _not_ trees but directed acyclic graphs. This
/// means that visiting a constant node without tracking which subnodes that
/// have already been visited might lead to exponential running times.
///
/// Use [ComputeOnceConstantVisitor] or [VisitOnceConstantVisitor] to visit
/// a constant node while ensuring each subnode is only visited once.
abstract class ConstantVisitor<R> {
  const ConstantVisitor();

  R visitAuxiliaryConstant(AuxiliaryConstant node);
  R visitNullConstant(NullConstant node);
  R visitBoolConstant(BoolConstant node);
  R visitIntConstant(IntConstant node);
  R visitDoubleConstant(DoubleConstant node);
  R visitStringConstant(StringConstant node);
  R visitSymbolConstant(SymbolConstant node);
  R visitMapConstant(MapConstant node);
  R visitListConstant(ListConstant node);
  R visitSetConstant(SetConstant node);
  R visitRecordConstant(RecordConstant node);
  R visitInstanceConstant(InstanceConstant node);
  R visitInstantiationConstant(InstantiationConstant node);
  R visitTypedefTearOffConstant(TypedefTearOffConstant node);
  R visitStaticTearOffConstant(StaticTearOffConstant node);
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node);
  R visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node);
  R visitTypeLiteralConstant(TypeLiteralConstant node);
  R visitUnevaluatedConstant(UnevaluatedConstant node);
}

/// Helper mixin for [ConstantVisitor] that implements visit methods by
/// delegating to the [defaultConstant] method.
mixin ConstantVisitorDefaultMixin<R> implements ConstantVisitor<R> {
  R defaultConstant(Constant node);

  @override
  R visitAuxiliaryConstant(AuxiliaryConstant node) => defaultConstant(node);
  @override
  R visitNullConstant(NullConstant node) => defaultConstant(node);
  @override
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  @override
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  @override
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  @override
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  @override
  R visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  @override
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  @override
  R visitListConstant(ListConstant node) => defaultConstant(node);
  @override
  R visitSetConstant(SetConstant node) => defaultConstant(node);
  @override
  R visitRecordConstant(RecordConstant node) => defaultConstant(node);
  @override
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  @override
  R visitInstantiationConstant(InstantiationConstant node) =>
      defaultConstant(node);
  @override
  R visitTypedefTearOffConstant(TypedefTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitStaticTearOffConstant(StaticTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
  @override
  R visitUnevaluatedConstant(UnevaluatedConstant node) => defaultConstant(node);
}

abstract class ConstantVisitor1<R, A> {
  const ConstantVisitor1();

  R visitAuxiliaryConstant(AuxiliaryConstant node, A arg);
  R visitNullConstant(NullConstant node, A arg);
  R visitBoolConstant(BoolConstant node, A arg);
  R visitIntConstant(IntConstant node, A arg);
  R visitDoubleConstant(DoubleConstant node, A arg);
  R visitStringConstant(StringConstant node, A arg);
  R visitSymbolConstant(SymbolConstant node, A arg);
  R visitMapConstant(MapConstant node, A arg);
  R visitListConstant(ListConstant node, A arg);
  R visitSetConstant(SetConstant node, A arg);
  R visitRecordConstant(RecordConstant node, A arg);
  R visitInstanceConstant(InstanceConstant node, A arg);
  R visitInstantiationConstant(InstantiationConstant node, A arg);
  R visitStaticTearOffConstant(StaticTearOffConstant node, A arg);
  R visitTypedefTearOffConstant(TypedefTearOffConstant node, A arg);
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node, A arg);
  R visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node, A arg);
  R visitTypeLiteralConstant(TypeLiteralConstant node, A arg);
  R visitUnevaluatedConstant(UnevaluatedConstant node, A arg);
}

/// Helper mixin for [ConstantVisitor1] that implements visit methods by
/// delegating to the [defaultConstant] method.
mixin ConstantVisitor1DefaultMixin<R, A> implements ConstantVisitor1<R, A> {
  R defaultConstant(Constant node, A arg);

  @override
  R visitAuxiliaryConstant(AuxiliaryConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitNullConstant(NullConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitBoolConstant(BoolConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitIntConstant(IntConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitDoubleConstant(DoubleConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitStringConstant(StringConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitSymbolConstant(SymbolConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitMapConstant(MapConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitListConstant(ListConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitSetConstant(SetConstant node, A arg) => defaultConstant(node, arg);
  @override
  R visitRecordConstant(RecordConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitInstanceConstant(InstanceConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitInstantiationConstant(InstantiationConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitStaticTearOffConstant(StaticTearOffConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitTypedefTearOffConstant(TypedefTearOffConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitTypeLiteralConstant(TypeLiteralConstant node, A arg) =>
      defaultConstant(node, arg);
  @override
  R visitUnevaluatedConstant(UnevaluatedConstant node, A arg) =>
      defaultConstant(node, arg);
}

abstract class ConstantReferenceVisitor<R> {
  R visitAuxiliaryConstantReference(AuxiliaryConstant node);
  R visitNullConstantReference(NullConstant node);
  R visitBoolConstantReference(BoolConstant node);
  R visitIntConstantReference(IntConstant node);
  R visitDoubleConstantReference(DoubleConstant node);
  R visitStringConstantReference(StringConstant node);
  R visitSymbolConstantReference(SymbolConstant node);
  R visitMapConstantReference(MapConstant node);
  R visitListConstantReference(ListConstant node);
  R visitSetConstantReference(SetConstant node);
  R visitRecordConstantReference(RecordConstant node);
  R visitInstanceConstantReference(InstanceConstant node);
  R visitInstantiationConstantReference(InstantiationConstant node);
  R visitStaticTearOffConstantReference(StaticTearOffConstant node);
  R visitConstructorTearOffConstantReference(ConstructorTearOffConstant node);
  R visitRedirectingFactoryTearOffConstantReference(
      RedirectingFactoryTearOffConstant node);
  R visitTypedefTearOffConstantReference(TypedefTearOffConstant node);
  R visitTypeLiteralConstantReference(TypeLiteralConstant node);
  R visitUnevaluatedConstantReference(UnevaluatedConstant node);
}

/// Helper mixin for [ConstantReferenceVisitor] that implements visit methods
/// by delegating to the [defaultConstantReference] method.
mixin ConstantReferenceVisitorDefaultMixin<R>
    implements ConstantReferenceVisitor<R> {
  R defaultConstantReference(Constant node);

  @override
  R visitAuxiliaryConstantReference(AuxiliaryConstant node) =>
      defaultConstantReference(node);
  @override
  R visitNullConstantReference(NullConstant node) =>
      defaultConstantReference(node);
  @override
  R visitBoolConstantReference(BoolConstant node) =>
      defaultConstantReference(node);
  @override
  R visitIntConstantReference(IntConstant node) =>
      defaultConstantReference(node);
  @override
  R visitDoubleConstantReference(DoubleConstant node) =>
      defaultConstantReference(node);
  @override
  R visitStringConstantReference(StringConstant node) =>
      defaultConstantReference(node);
  @override
  R visitSymbolConstantReference(SymbolConstant node) =>
      defaultConstantReference(node);
  @override
  R visitMapConstantReference(MapConstant node) =>
      defaultConstantReference(node);
  @override
  R visitListConstantReference(ListConstant node) =>
      defaultConstantReference(node);
  @override
  R visitSetConstantReference(SetConstant node) =>
      defaultConstantReference(node);
  @override
  R visitRecordConstantReference(RecordConstant node) =>
      defaultConstantReference(node);
  @override
  R visitInstanceConstantReference(InstanceConstant node) =>
      defaultConstantReference(node);
  @override
  R visitInstantiationConstantReference(InstantiationConstant node) =>
      defaultConstantReference(node);
  @override
  R visitStaticTearOffConstantReference(StaticTearOffConstant node) =>
      defaultConstantReference(node);
  @override
  R visitConstructorTearOffConstantReference(ConstructorTearOffConstant node) =>
      defaultConstantReference(node);
  @override
  R visitRedirectingFactoryTearOffConstantReference(
          RedirectingFactoryTearOffConstant node) =>
      defaultConstantReference(node);
  @override
  R visitTypedefTearOffConstantReference(TypedefTearOffConstant node) =>
      defaultConstantReference(node);
  @override
  R visitTypeLiteralConstantReference(TypeLiteralConstant node) =>
      defaultConstantReference(node);
  @override
  R visitUnevaluatedConstantReference(UnevaluatedConstant node) =>
      defaultConstantReference(node);
}

abstract class ConstantReferenceVisitor1<R, A> {
  R visitAuxiliaryConstantReference(AuxiliaryConstant node, A arg);
  R visitNullConstantReference(NullConstant node, A arg);
  R visitBoolConstantReference(BoolConstant node, A arg);
  R visitIntConstantReference(IntConstant node, A arg);
  R visitDoubleConstantReference(DoubleConstant node, A arg);
  R visitStringConstantReference(StringConstant node, A arg);
  R visitSymbolConstantReference(SymbolConstant node, A arg);
  R visitMapConstantReference(MapConstant node, A arg);
  R visitListConstantReference(ListConstant node, A arg);
  R visitSetConstantReference(SetConstant node, A arg);
  R visitRecordConstantReference(RecordConstant node, A arg);
  R visitInstanceConstantReference(InstanceConstant node, A arg);
  R visitInstantiationConstantReference(InstantiationConstant node, A arg);
  R visitConstructorTearOffConstantReference(
      ConstructorTearOffConstant node, A arg);
  R visitRedirectingFactoryTearOffConstantReference(
      RedirectingFactoryTearOffConstant node, A arg);
  R visitStaticTearOffConstantReference(StaticTearOffConstant node, A arg);
  R visitTypedefTearOffConstantReference(TypedefTearOffConstant node, A arg);
  R visitTypeLiteralConstantReference(TypeLiteralConstant node, A arg);
  R visitUnevaluatedConstantReference(UnevaluatedConstant node, A arg);
}

/// Helper mixin for [ConstantReferenceVisitor1] that implements visit methods
/// by delegating to the [defaultConstantReference] method.
mixin ConstantReferenceVisitor1DefaultMixin<R, A>
    implements ConstantReferenceVisitor1<R, A> {
  R defaultConstantReference(Constant node, A arg);

  @override
  R visitAuxiliaryConstantReference(AuxiliaryConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitNullConstantReference(NullConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitBoolConstantReference(BoolConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitIntConstantReference(IntConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitDoubleConstantReference(DoubleConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitStringConstantReference(StringConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitSymbolConstantReference(SymbolConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitMapConstantReference(MapConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitListConstantReference(ListConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitSetConstantReference(SetConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitRecordConstantReference(RecordConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitInstanceConstantReference(InstanceConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitInstantiationConstantReference(InstantiationConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitConstructorTearOffConstantReference(
          ConstructorTearOffConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitRedirectingFactoryTearOffConstantReference(
          RedirectingFactoryTearOffConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitStaticTearOffConstantReference(StaticTearOffConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitTypedefTearOffConstantReference(TypedefTearOffConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitTypeLiteralConstantReference(TypeLiteralConstant node, A arg) =>
      defaultConstantReference(node, arg);
  @override
  R visitUnevaluatedConstantReference(UnevaluatedConstant node, A arg) =>
      defaultConstantReference(node, arg);
}

abstract class _ConstantCallback<R> {
  R visitAuxiliaryConstant(AuxiliaryConstant node);
  R visitNullConstant(NullConstant node);
  R visitBoolConstant(BoolConstant node);
  R visitIntConstant(IntConstant node);
  R visitDoubleConstant(DoubleConstant node);
  R visitStringConstant(StringConstant node);
  R visitSymbolConstant(SymbolConstant node);
  R visitMapConstant(MapConstant node);
  R visitListConstant(ListConstant node);
  R visitSetConstant(SetConstant node);
  R visitRecordConstant(RecordConstant node);
  R visitInstanceConstant(InstanceConstant node);
  R visitInstantiationConstant(InstantiationConstant node);
  R visitTypedefTearOffConstant(TypedefTearOffConstant node);
  R visitStaticTearOffConstant(StaticTearOffConstant node);
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node);
  R visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node);
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
  R visitStaticTearOffConstant(StaticTearOffConstant node) =>
      _callback.visitStaticTearOffConstant(node);

  @override
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node) =>
      _callback.visitConstructorTearOffConstant(node);

  @override
  R visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant node) =>
      _callback.visitRedirectingFactoryTearOffConstant(node);

  @override
  R visitInstantiationConstant(InstantiationConstant node) =>
      _callback.visitInstantiationConstant(node);

  @override
  R visitTypedefTearOffConstant(TypedefTearOffConstant node) =>
      _callback.visitTypedefTearOffConstant(node);

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
  R visitRecordConstant(RecordConstant node) =>
      _callback.visitRecordConstant(node);

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
  R visitAuxiliaryConstant(AuxiliaryConstant node) =>
      _callback.visitAuxiliaryConstant(node);
}

/// Helper mixin for [ComputeOnceConstantVisitor] and [VisitOnceConstantVisitor]
/// that implements the visit methods by delegating to the [defaultConstant]
/// method.
mixin OnceConstantVisitorDefaultMixin<R> implements _ConstantCallback<R> {
  R defaultConstant(Constant node);

  @override
  R visitAuxiliaryConstant(AuxiliaryConstant node) => defaultConstant(node);
  @override
  R visitNullConstant(NullConstant node) => defaultConstant(node);
  @override
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  @override
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  @override
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  @override
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  @override
  R visitSymbolConstant(SymbolConstant node) => defaultConstant(node);
  @override
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  @override
  R visitListConstant(ListConstant node) => defaultConstant(node);
  @override
  R visitSetConstant(SetConstant node) => defaultConstant(node);
  @override
  R visitRecordConstant(RecordConstant node) => defaultConstant(node);
  @override
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  @override
  R visitInstantiationConstant(InstantiationConstant node) =>
      defaultConstant(node);
  @override
  R visitTypedefTearOffConstant(TypedefTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitStaticTearOffConstant(StaticTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitConstructorTearOffConstant(ConstructorTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitRedirectingFactoryTearOffConstant(
          RedirectingFactoryTearOffConstant node) =>
      defaultConstant(node);
  @override
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
  @override
  R visitUnevaluatedConstant(UnevaluatedConstant node) => defaultConstant(node);
}

/// Visitor-like class used for visiting a [Constant] node while computing a
/// value for each subnode. The visitor caches the computed values ensuring that
/// each subnode is only visited once.
abstract class ComputeOnceConstantVisitor<R> implements _ConstantCallback<R> {
  late final _ConstantCallbackVisitor<R> _visitor;
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
}

/// Visitor-like class used for visiting each subnode of a [Constant] node once.
///
/// The visitor records the visited node to ensure that each subnode is only
/// visited once.
abstract class VisitOnceConstantVisitor implements _ConstantCallback<void> {
  late final _ConstantCallbackVisitor<void> _visitor;
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
}

abstract class MemberReferenceVisitor<R> {
  const MemberReferenceVisitor();

  R visitFieldReference(Field node);
  R visitConstructorReference(Constructor node);
  R visitProcedureReference(Procedure node);
}

/// Helper mixin for [MemberReferenceVisitor] that implements visit methods by
/// delegating to the [defaultMemberReference] method.
mixin MemberReferenceVisitorDefaultMixin<R>
    implements MemberReferenceVisitor<R> {
  R defaultMemberReference(Member node);

  @override
  R visitFieldReference(Field node) => defaultMemberReference(node);
  @override
  R visitConstructorReference(Constructor node) => defaultMemberReference(node);
  @override
  R visitProcedureReference(Procedure node) => defaultMemberReference(node);
}

abstract class MemberReferenceVisitor1<R, A> {
  const MemberReferenceVisitor1();

  R visitFieldReference(Field node, A arg);
  R visitConstructorReference(Constructor node, A arg);
  R visitProcedureReference(Procedure node, A arg);
}

/// Helper mixin for [MemberReferenceVisitor1] that implements visit methods by
/// delegating to the [defaultMemberReference] method.
mixin MemberReferenceVisitor1DefaultMixin<R, A>
    implements MemberReferenceVisitor1<R, A> {
  R defaultMemberReference(Member node, A arg);

  @override
  R visitFieldReference(Field node, A arg) => defaultMemberReference(node, arg);
  @override
  R visitConstructorReference(Constructor node, A arg) =>
      defaultMemberReference(node, arg);
  @override
  R visitProcedureReference(Procedure node, A arg) =>
      defaultMemberReference(node, arg);
}

abstract class Visitor<R>
    implements
        TreeVisitor<R>,
        DartTypeVisitor<R>,
        ConstantVisitor<R>,
        MemberReferenceVisitor<R>,
        ConstantReferenceVisitor<R> {
  const Visitor();

  // TODO(johnniwinther): Move these to [MemberReferenceVisitor].
  R visitClassReference(Class node);
  R visitTypedefReference(Typedef node);
  R visitExtensionReference(Extension node);
  R visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node);

  R visitName(Name node);
  R visitSupertype(Supertype node);
  R visitNamedType(NamedType node);
}

mixin VisitorDefaultMixin<R> implements Visitor<R> {
  /// The catch-all case, except for references.
  R defaultNode(Node node);

  @override
  R visitName(Name node) => defaultNode(node);
  @override
  R visitSupertype(Supertype node) => defaultNode(node);
  @override
  R visitNamedType(NamedType node) => defaultNode(node);
}

/// Base class for implementing [Visitor] that implements visit methods mixing
/// in the various `DefaultMixin` mixins and delegating their `default` methods
/// to the [defaultNode] method.
abstract class VisitorDefault<R> extends TreeVisitorDefault<R>
    with
        VisitorDefaultMixin<R>,
        DartTypeVisitorDefaultMixin<R>,
        ConstantVisitorDefaultMixin<R>,
        MemberReferenceVisitorDefaultMixin<R>,
        ConstantReferenceVisitorDefaultMixin<R> {
  const VisitorDefault();

  @override
  R defaultTreeNode(TreeNode node) => defaultNode(node);

  @override
  R defaultDartType(DartType node) => defaultNode(node);

  @override
  R defaultConstant(Constant node) => defaultNode(node);
}

abstract class Visitor1<R, A> extends TreeVisitor1<R, A>
    implements
        DartTypeVisitor1<R, A>,
        ConstantVisitor1<R, A>,
        MemberReferenceVisitor1<R, A>,
        ConstantReferenceVisitor1<R, A> {
  const Visitor1();

  // TODO(johnniwinther): Move these to [MemberReferenceVisitor1].
  R visitClassReference(Class node, A arg);
  R visitTypedefReference(Typedef node, A arg);
  R visitExtensionReference(Extension node, A arg);
  R visitExtensionTypeDeclarationReference(
      ExtensionTypeDeclaration node, A arg);

  R visitName(Name node, A arg);
  R visitSupertype(Supertype node, A arg);
  R visitNamedType(NamedType node, A arg);
}

mixin Visitor1DefaultMixin<R, A> implements Visitor1<R, A> {
  /// The catch-all case, except for references.
  R defaultNode(Node node, A arg);

  @override
  R visitName(Name node, A arg) => defaultNode(node, arg);

  @override
  R visitSupertype(Supertype node, A arg) => defaultNode(node, arg);

  @override
  R visitNamedType(NamedType node, A arg) => defaultNode(node, arg);
}

/// Base class for implementing [Visitor1] that implements visit methods mixing
/// in the various `DefaultMixin` mixins and delegating their `default` methods
/// to the [defaultNode] method.
abstract class Visitor1Default<R, A> extends TreeVisitor1Default<R, A>
    with
        Visitor1DefaultMixin<R, A>,
        DartTypeVisitor1DefaultMixin<R, A>,
        ConstantVisitor1DefaultMixin<R, A>,
        MemberReferenceVisitor1DefaultMixin<R, A>,
        ConstantReferenceVisitor1DefaultMixin<R, A> {
  const Visitor1Default();

  @override
  R defaultTreeNode(TreeNode node, A arg) => defaultNode(node, arg);

  @override
  R defaultDartType(DartType node, A arg) => defaultNode(node, arg);

  @override
  R defaultConstant(Constant node, A arg) => defaultNode(node, arg);
}

/// Visitor mixin that throws as its base case.
mixin VisitorThrowingMixin<R> implements VisitorDefault<R> {
  @override
  R defaultNode(Node node) {
    throw new UnimplementedError('Unimplemented ${runtimeType}.defaultNode for '
        '${node} (${node.runtimeType})');
  }

  @override
  R visitClassReference(Class node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.visitClassReference for '
        '${node} (${node.runtimeType})');
  }

  @override
  R visitTypedefReference(Typedef node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.visitTypedefReference for '
        '${node} (${node.runtimeType})');
  }

  @override
  R visitExtensionReference(Extension node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.visitExtensionReference for '
        '${node} (${node.runtimeType})');
  }

  @override
  R visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.visitExtensionTypeDeclarationReference '
        'for ${node} (${node.runtimeType})');
  }

  @override
  R defaultConstantReference(Constant node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.defaultConstantReference for '
        '${node} (${node.runtimeType})');
  }

  @override
  R defaultMemberReference(Member node) {
    throw new UnimplementedError(
        'Unimplemented ${runtimeType}.defaultMemberReference for '
        '${node} (${node.runtimeType})');
  }
}

/// Visitor mixin that returns a value of type [R] or `null` and uses `null` as
/// its base case.
mixin VisitorNullMixin<R> implements VisitorDefault<R?> {
  @override
  R? defaultNode(Node node) => null;

  @override
  R? visitClassReference(Class node) => null;

  @override
  R? visitTypedefReference(Typedef node) => null;

  @override
  R? visitExtensionReference(Extension node) => null;

  @override
  R? visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node) =>
      null;

  @override
  R? defaultConstantReference(Constant node) => null;

  @override
  R? defaultMemberReference(Member node) => null;
}

/// Visitor mixin that returns void.
mixin VisitorVoidMixin implements VisitorDefault<void> {
  @override
  void defaultNode(Node node) {}

  @override
  void visitClassReference(Class node) {}

  @override
  void visitTypedefReference(Typedef node) {}

  @override
  void visitExtensionReference(Extension node) {}

  @override
  void visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node) {}

  @override
  void defaultConstantReference(Constant node) {}

  @override
  void defaultMemberReference(Member node) {}
}

/// Visitor mixin that returns a [defaultValue] of type [R] as its base case.
mixin VisitorDefaultValueMixin<R> implements VisitorDefault<R> {
  R get defaultValue;

  @override
  R defaultNode(Node node) => defaultValue;

  @override
  R visitClassReference(Class node) => defaultValue;

  @override
  R visitTypedefReference(Typedef node) => defaultValue;

  @override
  R visitExtensionReference(Extension node) => defaultValue;

  @override
  R visitExtensionTypeDeclarationReference(ExtensionTypeDeclaration node) =>
      defaultValue;

  @override
  R defaultConstantReference(Constant node) => defaultValue;

  @override
  R defaultMemberReference(Member node) => defaultValue;
}

/// Recursive visitor that doesn't return anything from its visit methods.
// TODO(johnniwinther): Remove type parameter when all subclasses have been
// changed to use [RecursiveVisitor] without type arguments.
class RecursiveVisitor<T> extends VisitorDefault<void> with VisitorVoidMixin {
  const RecursiveVisitor();

  @override
  void defaultNode(Node node) {
    node.visitChildren(this);
  }
}

/// Recursive visitor that returns a result of type [R] or `null` from its
/// visit methods.
class RecursiveResultVisitor<R> extends VisitorDefault<R?>
    with VisitorNullMixin<R> {
  const RecursiveResultVisitor();

  @override
  R? defaultNode(Node node) {
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
///         if (operand is LogicalExpression &&
///             operand.operator == LogicalExpressionOperator.AND) {
///           return new LogicalExpression(
///             new Not(operand.left),
///             LogicalExpressionOperator.OR,
///             new Not(operand.right));
///         }
///         return node;
///       }
///     }
///
class Transformer extends TreeVisitorDefault<TreeNode> {
  const Transformer();

  T transform<T extends TreeNode>(T node) {
    return node.accept<TreeNode>(this) as T;
  }

  void transformDartTypeList(List<DartType> nodes) {
    for (int i = 0; i < nodes.length; ++i) {
      nodes[i] = visitDartType(nodes[i]);
    }
  }

  void transformSupertypeList(List<Supertype> nodes) {
    for (int i = 0; i < nodes.length; ++i) {
      nodes[i] = visitSupertype(nodes[i]);
    }
  }

  void transformList<T extends TreeNode>(List<T> nodes, TreeNode parent) {
    for (int i = 0; i < nodes.length; ++i) {
      T result = transform(nodes[i]);
      result.parent = parent;
      nodes[i] = result;
    }
  }

  /// Replaces a use of a type.
  ///
  /// By default, recursion stops at this point.
  DartType visitDartType(DartType node) => node;

  Constant visitConstant(Constant node) => node;

  Supertype visitSupertype(Supertype node) => node;

  @override
  TreeNode defaultTreeNode(TreeNode node) {
    node.transformChildren(this);
    return node;
  }
}

/// Transformer that recursively rewrites each node in tree and supports removal
/// of nodes.
///
/// Visit methods should return a new node, the visited node (possibly
/// mutated), any node from the visited node's subtree, or the provided
/// removal sentinel, if non-null.
///
/// To support removal of nodes during traversal, while enforcing nullability
/// invariants, this visitor takes an argument, the removal sentinel. If a
/// node is visited in a context where it can be removed, for instance in a
/// list or as an optional child of its parent, a non-null sentinel value is
/// provided, and this value can be returned to signal to the caller that the
/// visited node should be removed. If the sentinel value is `null`, the node
/// cannot be removed from its context, in which case the node itself or a new
/// non-null node must be returned, possibly a sentinel value specific to the
/// particular visitor.
///
/// For instance
///
///     class AssertRemover extends RemovingTransformer {
///        @override
///        TreeNode visitAssertStatement(
///            AssertStatement node,
///            TreeNode? removalSentinel) {
///          return removalSentinel ?? new EmptyStatement();
///        }
///
///        @override
///        TreeNode visitIfStatement(
///            IfStatement node,
///            TreeNode? removalSentinel) {
///          node.transformOrRemoveChildren(this);
///          if (node.then is EmptyStatement) {
///            if (node.otherwise != null) {
///              return new IfStatement(
///                  new Not(node.condition), node.otherwise);
///            } else {
///              return removalSentinel ?? new EmptyStatement();
///            }
///          }
///          return node;
///        }
///     }
///
/// Each subclass is responsible for ensuring that the AST remains a tree.
///
/// For example, the following transformer replaces every occurrence of
/// `!(x && y)` with `(!x || !y)`:
///
///     class NegationSinker extends RemovingTransformer {
///       @override
///       Node visitNot(Not node) {
///         var operand = node.operand.accept(this); // Remember to visit.
///         if (operand is LogicalExpression &&
///             operand.operator == LogicalExpressionOperator.AND) {
///           return new LogicalExpression(
///             new Not(operand.left),
///             LogicalExpressionOperator.OR,
///             new Not(operand.right));
///         }
///         return node;
///       }
///     }
///
class RemovingTransformer extends TreeVisitor1Default<TreeNode, TreeNode?> {
  const RemovingTransformer();

  /// Visits [node], returning the transformation result.
  ///
  /// The transformation cannot result in `null`.
  T transform<T extends TreeNode>(T node) {
    return node.accept1<TreeNode, TreeNode?>(this, cannotRemoveSentinel) as T;
  }

  /// Visits [node], returning the transformation result. Removal of [node] is
  /// supported with `null` as the result.
  ///
  /// This is convenience method for calling [transformOrRemove] with removal
  /// sentinel for [Expression] nodes.
  Expression? transformOrRemoveExpression(Expression node) {
    return transformOrRemove(node, dummyExpression);
  }

  /// Visits [node], returning the transformation result. Removal of [node] is
  /// supported with `null` as the result.
  ///
  /// This is convenience method for calling [transformOrRemove] with removal
  /// sentinel for [Statement] nodes.
  Statement? transformOrRemoveStatement(Statement node) {
    return transformOrRemove(node, dummyStatement);
  }

  /// Visits [node], returning the transformation result. Removal of [node] is
  /// supported with `null` as the result.
  ///
  /// This is convenience method for calling [transformOrRemove] with removal
  /// sentinel for [VariableDeclaration] nodes.
  VariableDeclaration? transformOrRemoveVariableDeclaration(
      VariableDeclaration node) {
    return transformOrRemove(node, dummyVariableDeclaration);
  }

  /// Visits [node] using [removalSentinel] as the removal sentinel.
  ///
  /// If [removalSentinel] is the result of visiting [node], `null` is returned.
  /// Otherwise the result is returned.
  T? transformOrRemove<T extends TreeNode>(T node, T? removalSentinel) {
    T result = node.accept1<TreeNode, TreeNode?>(this, removalSentinel) as T;
    if (identical(result, removalSentinel)) {
      return null;
    } else {
      return result;
    }
  }

  /// Transforms or removes [DartType] nodes in [nodes].
  void transformDartTypeList(List<DartType> nodes) {
    int storeIndex = 0;
    for (int i = 0; i < nodes.length; ++i) {
      DartType result = visitDartType(nodes[i], dummyDartType);
      if (!identical(result, dummyDartType)) {
        nodes[storeIndex] = result;
        ++storeIndex;
      }
    }
    if (storeIndex < nodes.length) {
      nodes.length = storeIndex;
    }
  }

  /// Transforms or removes [Supertype] nodes in [nodes].
  void transformSupertypeList(List<Supertype> nodes) {
    int storeIndex = 0;
    for (int i = 0; i < nodes.length; ++i) {
      Supertype result = visitSupertype(nodes[i], dummySupertype);
      if (!identical(result, dummySupertype)) {
        nodes[storeIndex] = result;
        ++storeIndex;
      }
    }
    if (storeIndex < nodes.length) {
      nodes.length = storeIndex;
    }
  }

  /// Transforms or removes [Library] nodes in [nodes] as children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Library] nodes.
  void transformLibraryList(List<Library> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyLibrary);
  }

  /// Transforms or removes [LibraryDependency] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [LibraryDependency] nodes.
  void transformLibraryDependencyList(
      List<LibraryDependency> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyLibraryDependency);
  }

  /// Transforms or removes [Combinator] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Combinator] nodes.
  void transformCombinatorList(List<Combinator> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyCombinator);
  }

  /// Transforms or removes [LibraryPart] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [LibraryPart] nodes.
  void transformLibraryPartList(List<LibraryPart> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyLibraryPart);
  }

  /// Transforms or removes [Class] nodes in [nodes] as children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Class] nodes.
  void transformClassList(List<Class> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyClass);
  }

  /// Transforms or removes [Extension] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Extension] nodes.
  void transformExtensionList(List<Extension> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyExtension);
  }

  /// Transforms or removes [ExtensionTypeDeclaration] nodes in [nodes] as
  /// children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [ExtensionTypeDeclaration] nodes.
  void transformExtensionTypeDeclarationList(
      List<ExtensionTypeDeclaration> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyExtensionTypeDeclaration);
  }

  /// Transforms or removes [Constructor] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Constructor] nodes.
  void transformConstructorList(List<Constructor> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyConstructor);
  }

  /// Transforms or removes [Procedure] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Procedure] nodes.
  void transformProcedureList(List<Procedure> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyProcedure);
  }

  /// Transforms or removes [Field] nodes in [nodes] as children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Field] nodes.
  void transformFieldList(List<Field> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyField);
  }

  /// Transforms or removes [Typedef] nodes in [nodes] as children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Typedef] nodes.
  void transformTypedefList(List<Typedef> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyTypedef);
  }

  /// Transforms or removes [Initializer] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Initializer] nodes.
  void transformInitializerList(List<Initializer> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyInitializer);
  }

  /// Transforms or removes [Expression] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Expression] nodes.
  void transformExpressionList(List<Expression> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyExpression);
  }

  /// Transforms or removes [NamedExpression] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [NamedExpression] nodes.
  void transformNamedExpressionList(
      List<NamedExpression> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyNamedExpression);
  }

  /// Transforms or removes [MapLiteralEntry] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [MapLiteralEntry] nodes.
  void transformMapEntryList(List<MapLiteralEntry> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyMapLiteralEntry);
  }

  /// Transforms or removes [Statement] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Statement] nodes.
  void transformStatementList(List<Statement> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyStatement);
  }

  /// Transforms or removes [SwitchCase] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [SwitchCase] nodes.
  void transformSwitchCaseList(List<SwitchCase> nodes, TreeNode parent) {
    transformList(nodes, parent, dummySwitchCase);
  }

  /// Transforms or removes [Catch] nodes in [nodes] as children of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [Catch] nodes.
  void transformCatchList(List<Catch> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyCatch);
  }

  /// Transforms or removes [TypeParameter] nodes in [nodes] as children of
  /// [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [TypeParameter] nodes.
  void transformTypeParameterList(List<TypeParameter> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyTypeParameter);
  }

  /// Transforms or removes [VariableDeclaration] nodes in [nodes] as children
  /// of [parent].
  ///
  /// This is convenience method for calling [transformList] with removal
  /// sentinel for [VariableDeclaration] nodes.
  void transformVariableDeclarationList(
      List<VariableDeclaration> nodes, TreeNode parent) {
    transformList(nodes, parent, dummyVariableDeclaration);
  }

  /// Transforms or removes [T] nodes in [nodes] as children of [parent] by
  /// calling [transformOrRemove] using [removalSentinel] as the removal
  /// sentinel.
  void transformList<T extends TreeNode>(
      List<T> nodes, TreeNode parent, T removalSentinel) {
    int storeIndex = 0;
    for (int i = 0; i < nodes.length; ++i) {
      T? result = transformOrRemove(nodes[i], removalSentinel);
      if (result != null) {
        nodes[storeIndex] = result;
        result.parent = parent;
        ++storeIndex;
      }
    }
    if (storeIndex < nodes.length) {
      nodes.length = storeIndex;
    }
  }

  /// Replaces a use of a type.
  ///
  /// By default, recursion stops at this point.
  DartType visitDartType(DartType node, DartType? removalSentinel) => node;

  Constant visitConstant(Constant node, Constant? removalSentinel) => node;

  Supertype visitSupertype(Supertype node, Supertype? removalSentinel) => node;

  @override
  TreeNode defaultTreeNode(TreeNode node, TreeNode? removalSentinel) {
    node.transformOrRemoveChildren(this);
    return node;
  }
}

abstract class ExpressionVisitor1<R, A> {
  const ExpressionVisitor1();

  R visitAuxiliaryExpression(AuxiliaryExpression node, A arg);
  R visitInvalidExpression(InvalidExpression node, A arg);
  R visitVariableGet(VariableGet node, A arg);
  R visitVariableSet(VariableSet node, A arg);
  R visitDynamicGet(DynamicGet node, A arg);
  R visitDynamicSet(DynamicSet node, A arg);
  R visitFunctionTearOff(FunctionTearOff node, A arg);
  R visitInstanceGet(InstanceGet node, A arg);
  R visitInstanceSet(InstanceSet node, A arg);
  R visitInstanceTearOff(InstanceTearOff node, A arg);
  R visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node, A arg);
  R visitAbstractSuperPropertySet(AbstractSuperPropertySet node, A arg);
  R visitSuperPropertyGet(SuperPropertyGet node, A arg);
  R visitSuperPropertySet(SuperPropertySet node, A arg);
  R visitStaticGet(StaticGet node, A arg);
  R visitStaticSet(StaticSet node, A arg);
  R visitStaticTearOff(StaticTearOff node, A arg);
  R visitLocalFunctionInvocation(LocalFunctionInvocation node, A arg);
  R visitDynamicInvocation(DynamicInvocation node, A arg);
  R visitFunctionInvocation(FunctionInvocation node, A arg);
  R visitInstanceInvocation(InstanceInvocation node, A arg);
  R visitInstanceGetterInvocation(InstanceGetterInvocation node, A arg);
  R visitEqualsNull(EqualsNull node, A arg);
  R visitEqualsCall(EqualsCall node, A arg);
  R visitAbstractSuperMethodInvocation(
      AbstractSuperMethodInvocation node, A arg);
  R visitSuperMethodInvocation(SuperMethodInvocation node, A arg);
  R visitStaticInvocation(StaticInvocation node, A arg);
  R visitConstructorInvocation(ConstructorInvocation node, A arg);
  R visitNot(Not node, A arg);
  R visitNullCheck(NullCheck node, A arg);
  R visitLogicalExpression(LogicalExpression node, A arg);
  R visitConditionalExpression(ConditionalExpression node, A arg);
  R visitStringConcatenation(StringConcatenation node, A arg);
  R visitListConcatenation(ListConcatenation node, A arg);
  R visitSetConcatenation(SetConcatenation node, A arg);
  R visitMapConcatenation(MapConcatenation node, A arg);
  R visitInstanceCreation(InstanceCreation node, A arg);
  R visitFileUriExpression(FileUriExpression node, A arg);
  R visitIsExpression(IsExpression node, A arg);
  R visitAsExpression(AsExpression node, A arg);
  R visitSymbolLiteral(SymbolLiteral node, A arg);
  R visitTypeLiteral(TypeLiteral node, A arg);
  R visitThisExpression(ThisExpression node, A arg);
  R visitConstantExpression(ConstantExpression node, A arg);
  R visitRethrow(Rethrow node, A arg);
  R visitThrow(Throw node, A arg);
  R visitListLiteral(ListLiteral node, A arg);
  R visitSetLiteral(SetLiteral node, A arg);
  R visitMapLiteral(MapLiteral node, A arg);
  R visitAwaitExpression(AwaitExpression node, A arg);
  R visitFunctionExpression(FunctionExpression node, A arg);
  R visitIntLiteral(IntLiteral node, A arg);
  R visitStringLiteral(StringLiteral node, A arg);
  R visitDoubleLiteral(DoubleLiteral node, A arg);
  R visitBoolLiteral(BoolLiteral node, A arg);
  R visitNullLiteral(NullLiteral node, A arg);
  R visitLet(Let node, A arg);
  R visitBlockExpression(BlockExpression node, A arg);
  R visitInstantiation(Instantiation node, A arg);
  R visitLoadLibrary(LoadLibrary node, A arg);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, A arg);
  R visitConstructorTearOff(ConstructorTearOff node, A arg);
  R visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node, A arg);
  R visitTypedefTearOff(TypedefTearOff node, A arg);
  R visitRecordIndexGet(RecordIndexGet node, A arg);
  R visitRecordNameGet(RecordNameGet node, A arg);
  R visitRecordLiteral(RecordLiteral node, A arg);
  R visitSwitchExpression(SwitchExpression node, A arg);
  R visitPatternAssignment(PatternAssignment node, A arg);
}

/// Helper mixin for [ExpressionVisitor1] that implements visit methods by
/// delegating to the [defaultBasicLiteral] and [defaultExpression] methods.
mixin ExpressionVisitor1DefaultMixin<R, A> implements ExpressionVisitor1<R, A> {
  R defaultExpression(Expression node, A arg);
  R defaultBasicLiteral(BasicLiteral node, A arg) =>
      defaultExpression(node, arg);

  @override
  R visitAuxiliaryExpression(AuxiliaryExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInvalidExpression(InvalidExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitVariableGet(VariableGet node, A arg) => defaultExpression(node, arg);
  @override
  R visitVariableSet(VariableSet node, A arg) => defaultExpression(node, arg);
  @override
  R visitDynamicGet(DynamicGet node, A arg) => defaultExpression(node, arg);
  @override
  R visitDynamicSet(DynamicSet node, A arg) => defaultExpression(node, arg);
  @override
  R visitFunctionTearOff(FunctionTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInstanceGet(InstanceGet node, A arg) => defaultExpression(node, arg);
  @override
  R visitInstanceSet(InstanceSet node, A arg) => defaultExpression(node, arg);
  @override
  R visitInstanceTearOff(InstanceTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitAbstractSuperPropertySet(AbstractSuperPropertySet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitSuperPropertyGet(SuperPropertyGet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitSuperPropertySet(SuperPropertySet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitStaticGet(StaticGet node, A arg) => defaultExpression(node, arg);
  @override
  R visitStaticSet(StaticSet node, A arg) => defaultExpression(node, arg);
  @override
  R visitStaticTearOff(StaticTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitLocalFunctionInvocation(LocalFunctionInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitDynamicInvocation(DynamicInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitFunctionInvocation(FunctionInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInstanceInvocation(InstanceInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInstanceGetterInvocation(InstanceGetterInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitEqualsNull(EqualsNull node, A arg) => defaultExpression(node, arg);
  @override
  R visitEqualsCall(EqualsCall node, A arg) => defaultExpression(node, arg);
  @override
  R visitAbstractSuperMethodInvocation(
          AbstractSuperMethodInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitSuperMethodInvocation(SuperMethodInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitStaticInvocation(StaticInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitConstructorInvocation(ConstructorInvocation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitNot(Not node, A arg) => defaultExpression(node, arg);
  @override
  R visitNullCheck(NullCheck node, A arg) => defaultExpression(node, arg);
  @override
  R visitLogicalExpression(LogicalExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitConditionalExpression(ConditionalExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitStringConcatenation(StringConcatenation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitListConcatenation(ListConcatenation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitSetConcatenation(SetConcatenation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitMapConcatenation(MapConcatenation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInstanceCreation(InstanceCreation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitFileUriExpression(FileUriExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitIsExpression(IsExpression node, A arg) => defaultExpression(node, arg);
  @override
  R visitAsExpression(AsExpression node, A arg) => defaultExpression(node, arg);
  @override
  R visitSymbolLiteral(SymbolLiteral node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitTypeLiteral(TypeLiteral node, A arg) => defaultExpression(node, arg);
  @override
  R visitThisExpression(ThisExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitConstantExpression(ConstantExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitRethrow(Rethrow node, A arg) => defaultExpression(node, arg);
  @override
  R visitThrow(Throw node, A arg) => defaultExpression(node, arg);
  @override
  @override
  R visitListLiteral(ListLiteral node, A arg) => defaultExpression(node, arg);
  @override
  R visitSetLiteral(SetLiteral node, A arg) => defaultExpression(node, arg);
  @override
  R visitMapLiteral(MapLiteral node, A arg) => defaultExpression(node, arg);
  @override
  R visitAwaitExpression(AwaitExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitFunctionExpression(FunctionExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitIntLiteral(IntLiteral node, A arg) => defaultBasicLiteral(node, arg);
  @override
  R visitStringLiteral(StringLiteral node, A arg) =>
      defaultBasicLiteral(node, arg);
  @override
  R visitDoubleLiteral(DoubleLiteral node, A arg) =>
      defaultBasicLiteral(node, arg);
  @override
  R visitBoolLiteral(BoolLiteral node, A arg) => defaultBasicLiteral(node, arg);
  @override
  R visitNullLiteral(NullLiteral node, A arg) => defaultBasicLiteral(node, arg);
  @override
  R visitLet(Let node, A arg) => defaultExpression(node, arg);
  @override
  R visitBlockExpression(BlockExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitInstantiation(Instantiation node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitLoadLibrary(LoadLibrary node, A arg) => defaultExpression(node, arg);
  @override
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitConstructorTearOff(ConstructorTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitTypedefTearOff(TypedefTearOff node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitRecordIndexGet(RecordIndexGet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitRecordNameGet(RecordNameGet node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitRecordLiteral(RecordLiteral node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitSwitchExpression(SwitchExpression node, A arg) =>
      defaultExpression(node, arg);
  @override
  R visitPatternAssignment(PatternAssignment node, A arg) =>
      defaultExpression(node, arg);
}

abstract class PatternVisitor1<R, A> {
  R visitAndPattern(AndPattern node, A arg);
  R visitAssignedVariablePattern(AssignedVariablePattern node, A arg);
  R visitCastPattern(CastPattern node, A arg);
  R visitConstantPattern(ConstantPattern node, A arg);
  R visitInvalidPattern(InvalidPattern node, A arg);
  R visitListPattern(ListPattern node, A arg);
  R visitMapPattern(MapPattern node, A arg);
  R visitNamedPattern(NamedPattern node, A arg);
  R visitNullAssertPattern(NullAssertPattern node, A arg);
  R visitNullCheckPattern(NullCheckPattern node, A arg);
  R visitObjectPattern(ObjectPattern node, A arg);
  R visitOrPattern(OrPattern node, A arg);
  R visitRecordPattern(RecordPattern node, A arg);
  R visitRelationalPattern(RelationalPattern node, A arg);
  R visitRestPattern(RestPattern node, A arg);
  R visitVariablePattern(VariablePattern node, A arg);
  R visitWildcardPattern(WildcardPattern node, A arg);
}

/// Helper mixin for [PatternVisitor1] that implements visit methods by
/// delegating to the [defaultPattern] method.
mixin PatternVisitor1DefaultMixin<R, A> implements PatternVisitor1<R, A> {
  R defaultPattern(Pattern node, A arg);
  @override
  R visitAndPattern(AndPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitAssignedVariablePattern(AssignedVariablePattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitCastPattern(CastPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitConstantPattern(ConstantPattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitInvalidPattern(InvalidPattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitListPattern(ListPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitMapPattern(MapPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitNamedPattern(NamedPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitNullAssertPattern(NullAssertPattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitNullCheckPattern(NullCheckPattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitObjectPattern(ObjectPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitOrPattern(OrPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitRecordPattern(RecordPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitRelationalPattern(RelationalPattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitRestPattern(RestPattern node, A arg) => defaultPattern(node, arg);
  @override
  R visitVariablePattern(VariablePattern node, A arg) =>
      defaultPattern(node, arg);
  @override
  R visitWildcardPattern(WildcardPattern node, A arg) =>
      defaultPattern(node, arg);
}

abstract class StatementVisitor1<R, A> {
  const StatementVisitor1();

  R visitAuxiliaryStatement(AuxiliaryStatement node, A arg);
  R visitExpressionStatement(ExpressionStatement node, A arg);
  R visitBlock(Block node, A arg);
  R visitAssertBlock(AssertBlock node, A arg);
  R visitEmptyStatement(EmptyStatement node, A arg);
  R visitAssertStatement(AssertStatement node, A arg);
  R visitLabeledStatement(LabeledStatement node, A arg);
  R visitBreakStatement(BreakStatement node, A arg);
  R visitWhileStatement(WhileStatement node, A arg);
  R visitDoStatement(DoStatement node, A arg);
  R visitForStatement(ForStatement node, A arg);
  R visitForInStatement(ForInStatement node, A arg);
  R visitSwitchStatement(SwitchStatement node, A arg);
  R visitPatternSwitchStatement(PatternSwitchStatement node, A arg);
  R visitContinueSwitchStatement(ContinueSwitchStatement node, A arg);
  R visitIfStatement(IfStatement node, A arg);
  R visitIfCaseStatement(IfCaseStatement node, A arg);
  R visitReturnStatement(ReturnStatement node, A arg);
  R visitTryCatch(TryCatch node, A arg);
  R visitTryFinally(TryFinally node, A arg);
  R visitYieldStatement(YieldStatement node, A arg);
  R visitVariableDeclaration(VariableDeclaration node, A arg);
  R visitPatternVariableDeclaration(PatternVariableDeclaration node, A arg);
  R visitFunctionDeclaration(FunctionDeclaration node, A arg);
}

/// Helper mixin for [StatementVisitor1] that implements visit methods by
/// delegating to the [defaultStatement] method.
mixin StatementVisitor1DefaultMixin<R, A> implements StatementVisitor1<R, A> {
  R defaultStatement(Statement node, A arg);

  @override
  R visitAuxiliaryStatement(AuxiliaryStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitExpressionStatement(ExpressionStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitBlock(Block node, A arg) => defaultStatement(node, arg);
  @override
  R visitAssertBlock(AssertBlock node, A arg) => defaultStatement(node, arg);
  @override
  R visitEmptyStatement(EmptyStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitAssertStatement(AssertStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitLabeledStatement(LabeledStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitBreakStatement(BreakStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitWhileStatement(WhileStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitDoStatement(DoStatement node, A arg) => defaultStatement(node, arg);
  @override
  R visitForStatement(ForStatement node, A arg) => defaultStatement(node, arg);
  @override
  R visitForInStatement(ForInStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitSwitchStatement(SwitchStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitPatternSwitchStatement(PatternSwitchStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitContinueSwitchStatement(ContinueSwitchStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitIfStatement(IfStatement node, A arg) => defaultStatement(node, arg);
  @override
  R visitIfCaseStatement(IfCaseStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitReturnStatement(ReturnStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitTryCatch(TryCatch node, A arg) => defaultStatement(node, arg);
  @override
  R visitTryFinally(TryFinally node, A arg) => defaultStatement(node, arg);
  @override
  R visitYieldStatement(YieldStatement node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitVariableDeclaration(VariableDeclaration node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitPatternVariableDeclaration(PatternVariableDeclaration node, A arg) =>
      defaultStatement(node, arg);
  @override
  R visitFunctionDeclaration(FunctionDeclaration node, A arg) =>
      defaultStatement(node, arg);
}
