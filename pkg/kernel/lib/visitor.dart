// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast.visitor;

import 'ast.dart';

abstract class ExpressionVisitor<R> {
  R defaultExpression(Expression node) => null;
  R defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);

  R visitInvalidExpression(InvalidExpression node) => defaultExpression(node);
  R visitVariableGet(VariableGet node) => defaultExpression(node);
  R visitVariableSet(VariableSet node) => defaultExpression(node);
  R visitPropertyGet(PropertyGet node) => defaultExpression(node);
  R visitPropertySet(PropertySet node) => defaultExpression(node);
  R visitDirectPropertyGet(DirectPropertyGet node) => defaultExpression(node);
  R visitDirectPropertySet(DirectPropertySet node) => defaultExpression(node);
  R visitSuperPropertyGet(SuperPropertyGet node) => defaultExpression(node);
  R visitSuperPropertySet(SuperPropertySet node) => defaultExpression(node);
  R visitStaticGet(StaticGet node) => defaultExpression(node);
  R visitStaticSet(StaticSet node) => defaultExpression(node);
  R visitMethodInvocation(MethodInvocation node) => defaultExpression(node);
  R visitDirectMethodInvocation(DirectMethodInvocation node) =>
      defaultExpression(node);
  R visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);
  R visitStaticInvocation(StaticInvocation node) => defaultExpression(node);
  R visitConstructorInvocation(ConstructorInvocation node) =>
      defaultExpression(node);
  R visitNot(Not node) => defaultExpression(node);
  R visitLogicalExpression(LogicalExpression node) => defaultExpression(node);
  R visitConditionalExpression(ConditionalExpression node) =>
      defaultExpression(node);
  R visitStringConcatenation(StringConcatenation node) =>
      defaultExpression(node);
  R visitIsExpression(IsExpression node) => defaultExpression(node);
  R visitAsExpression(AsExpression node) => defaultExpression(node);
  R visitSymbolLiteral(SymbolLiteral node) => defaultExpression(node);
  R visitTypeLiteral(TypeLiteral node) => defaultExpression(node);
  R visitThisExpression(ThisExpression node) => defaultExpression(node);
  R visitRethrow(Rethrow node) => defaultExpression(node);
  R visitThrow(Throw node) => defaultExpression(node);
  R visitListLiteral(ListLiteral node) => defaultExpression(node);
  R visitMapLiteral(MapLiteral node) => defaultExpression(node);
  R visitAwaitExpression(AwaitExpression node) => defaultExpression(node);
  R visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
  R visitVectorCreation(VectorCreation node) => defaultExpression(node);
  R visitVectorGet(VectorGet node) => defaultExpression(node);
  R visitVectorSet(VectorSet node) => defaultExpression(node);
  R visitVectorCopy(VectorCopy node) => defaultExpression(node);
}

abstract class StatementVisitor<R> {
  R defaultStatement(Statement node) => null;

  R visitInvalidStatement(InvalidStatement node) => defaultStatement(node);
  R visitExpressionStatement(ExpressionStatement node) =>
      defaultStatement(node);
  R visitBlock(Block node) => defaultStatement(node);
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
  R defaultMember(Member node) => null;

  R visitConstructor(Constructor node) => defaultMember(node);
  R visitProcedure(Procedure node) => defaultMember(node);
  R visitField(Field node) => defaultMember(node);
}

abstract class InitializerVisitor<R> {
  R defaultInitializer(Initializer node) => null;

  R visitInvalidInitializer(InvalidInitializer node) =>
      defaultInitializer(node);
  R visitFieldInitializer(FieldInitializer node) => defaultInitializer(node);
  R visitSuperInitializer(SuperInitializer node) => defaultInitializer(node);
  R visitRedirectingInitializer(RedirectingInitializer node) =>
      defaultInitializer(node);
  R visitLocalInitializer(LocalInitializer node) => defaultInitializer(node);
}

class TreeVisitor<R>
    implements
        ExpressionVisitor<R>,
        StatementVisitor<R>,
        MemberVisitor<R>,
        InitializerVisitor<R> {
  R defaultTreeNode(TreeNode node) => null;

  // Expressions
  R defaultExpression(Expression node) => defaultTreeNode(node);
  R defaultBasicLiteral(BasicLiteral node) => defaultExpression(node);
  R visitInvalidExpression(InvalidExpression node) => defaultExpression(node);
  R visitVariableGet(VariableGet node) => defaultExpression(node);
  R visitVariableSet(VariableSet node) => defaultExpression(node);
  R visitPropertyGet(PropertyGet node) => defaultExpression(node);
  R visitPropertySet(PropertySet node) => defaultExpression(node);
  R visitDirectPropertyGet(DirectPropertyGet node) => defaultExpression(node);
  R visitDirectPropertySet(DirectPropertySet node) => defaultExpression(node);
  R visitSuperPropertyGet(SuperPropertyGet node) => defaultExpression(node);
  R visitSuperPropertySet(SuperPropertySet node) => defaultExpression(node);
  R visitStaticGet(StaticGet node) => defaultExpression(node);
  R visitStaticSet(StaticSet node) => defaultExpression(node);
  R visitMethodInvocation(MethodInvocation node) => defaultExpression(node);
  R visitDirectMethodInvocation(DirectMethodInvocation node) =>
      defaultExpression(node);
  R visitSuperMethodInvocation(SuperMethodInvocation node) =>
      defaultExpression(node);
  R visitStaticInvocation(StaticInvocation node) => defaultExpression(node);
  R visitConstructorInvocation(ConstructorInvocation node) =>
      defaultExpression(node);
  R visitNot(Not node) => defaultExpression(node);
  R visitLogicalExpression(LogicalExpression node) => defaultExpression(node);
  R visitConditionalExpression(ConditionalExpression node) =>
      defaultExpression(node);
  R visitStringConcatenation(StringConcatenation node) =>
      defaultExpression(node);
  R visitIsExpression(IsExpression node) => defaultExpression(node);
  R visitAsExpression(AsExpression node) => defaultExpression(node);
  R visitSymbolLiteral(SymbolLiteral node) => defaultExpression(node);
  R visitTypeLiteral(TypeLiteral node) => defaultExpression(node);
  R visitThisExpression(ThisExpression node) => defaultExpression(node);
  R visitRethrow(Rethrow node) => defaultExpression(node);
  R visitThrow(Throw node) => defaultExpression(node);
  R visitListLiteral(ListLiteral node) => defaultExpression(node);
  R visitMapLiteral(MapLiteral node) => defaultExpression(node);
  R visitAwaitExpression(AwaitExpression node) => defaultExpression(node);
  R visitFunctionExpression(FunctionExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
  R visitVectorCreation(VectorCreation node) => defaultExpression(node);
  R visitVectorGet(VectorGet node) => defaultExpression(node);
  R visitVectorSet(VectorSet node) => defaultExpression(node);
  R visitVectorCopy(VectorCopy node) => defaultExpression(node);

  // Statements
  R defaultStatement(Statement node) => defaultTreeNode(node);
  R visitInvalidStatement(InvalidStatement node) => defaultStatement(node);
  R visitExpressionStatement(ExpressionStatement node) =>
      defaultStatement(node);
  R visitBlock(Block node) => defaultStatement(node);
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

  // Classes
  R visitClass(Class node) => defaultTreeNode(node);

  // Initializers
  R defaultInitializer(Initializer node) => defaultTreeNode(node);
  R visitInvalidInitializer(InvalidInitializer node) =>
      defaultInitializer(node);
  R visitFieldInitializer(FieldInitializer node) => defaultInitializer(node);
  R visitSuperInitializer(SuperInitializer node) => defaultInitializer(node);
  R visitRedirectingInitializer(RedirectingInitializer node) =>
      defaultInitializer(node);
  R visitLocalInitializer(LocalInitializer node) => defaultInitializer(node);

  // Other tree nodes
  R visitLibrary(Library node) => defaultTreeNode(node);
  R visitDeferredImport(DeferredImport node) => defaultTreeNode(node);
  R visitTypeParameter(TypeParameter node) => defaultTreeNode(node);
  R visitFunctionNode(FunctionNode node) => defaultTreeNode(node);
  R visitArguments(Arguments node) => defaultTreeNode(node);
  R visitNamedExpression(NamedExpression node) => defaultTreeNode(node);
  R visitSwitchCase(SwitchCase node) => defaultTreeNode(node);
  R visitCatch(Catch node) => defaultTreeNode(node);
  R visitMapEntry(MapEntry node) => defaultTreeNode(node);
  R visitProgram(Program node) => defaultTreeNode(node);
}

class DartTypeVisitor<R> {
  R defaultDartType(DartType node) => null;

  R visitInvalidType(InvalidType node) => defaultDartType(node);
  R visitDynamicType(DynamicType node) => defaultDartType(node);
  R visitVoidType(VoidType node) => defaultDartType(node);
  R visitBottomType(BottomType node) => defaultDartType(node);
  R visitInterfaceType(InterfaceType node) => defaultDartType(node);
  R visitVectorType(VectorType node) => defaultDartType(node);
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);
}

class MemberReferenceVisitor<R> {
  R defaultMemberReference(Member node) => null;

  R visitFieldReference(Field node) => defaultMemberReference(node);
  R visitConstructorReference(Constructor node) => defaultMemberReference(node);
  R visitProcedureReference(Procedure node) => defaultMemberReference(node);
}

class Visitor<R> extends TreeVisitor<R>
    implements DartTypeVisitor<R>, MemberReferenceVisitor<R> {
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
  R visitVectorType(VectorType node) => defaultDartType(node);
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);

  // Class references
  R visitClassReference(Class node) => null;

  // Member references
  R defaultMemberReference(Member node) => null;
  R visitFieldReference(Field node) => defaultMemberReference(node);
  R visitConstructorReference(Constructor node) => defaultMemberReference(node);
  R visitProcedureReference(Procedure node) => defaultMemberReference(node);

  R visitName(Name node) => defaultNode(node);
  R visitSupertype(Supertype node) => defaultNode(node);
  R visitNamedType(NamedType node) => defaultNode(node);
}

class RecursiveVisitor<R> extends Visitor<R> {
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
  /// Replaces a use of a type.
  ///
  /// By default, recursion stops at this point.
  DartType visitDartType(DartType node) => node;

  Supertype visitSupertype(Supertype node) => node;

  TreeNode defaultTreeNode(TreeNode node) {
    node.transformChildren(this);
    return node;
  }
}

abstract class ExpressionVisitor1<R> {
  R defaultExpression(Expression node, arg) => null;
  R defaultBasicLiteral(BasicLiteral node, arg) => defaultExpression(node, arg);
  R visitInvalidExpression(InvalidExpression node, arg) =>
      defaultExpression(node, arg);
  R visitVariableGet(VariableGet node, arg) => defaultExpression(node, arg);
  R visitVariableSet(VariableSet node, arg) => defaultExpression(node, arg);
  R visitPropertyGet(PropertyGet node, arg) => defaultExpression(node, arg);
  R visitPropertySet(PropertySet node, arg) => defaultExpression(node, arg);
  R visitDirectPropertyGet(DirectPropertyGet node, arg) =>
      defaultExpression(node, arg);
  R visitDirectPropertySet(DirectPropertySet node, arg) =>
      defaultExpression(node, arg);
  R visitSuperPropertyGet(SuperPropertyGet node, arg) =>
      defaultExpression(node, arg);
  R visitSuperPropertySet(SuperPropertySet node, arg) =>
      defaultExpression(node, arg);
  R visitStaticGet(StaticGet node, arg) => defaultExpression(node, arg);
  R visitStaticSet(StaticSet node, arg) => defaultExpression(node, arg);
  R visitMethodInvocation(MethodInvocation node, arg) =>
      defaultExpression(node, arg);
  R visitDirectMethodInvocation(DirectMethodInvocation node, arg) =>
      defaultExpression(node, arg);
  R visitSuperMethodInvocation(SuperMethodInvocation node, arg) =>
      defaultExpression(node, arg);
  R visitStaticInvocation(StaticInvocation node, arg) =>
      defaultExpression(node, arg);
  R visitConstructorInvocation(ConstructorInvocation node, arg) =>
      defaultExpression(node, arg);
  R visitNot(Not node, arg) => defaultExpression(node, arg);
  R visitLogicalExpression(LogicalExpression node, arg) =>
      defaultExpression(node, arg);
  R visitConditionalExpression(ConditionalExpression node, arg) =>
      defaultExpression(node, arg);
  R visitStringConcatenation(StringConcatenation node, arg) =>
      defaultExpression(node, arg);
  R visitIsExpression(IsExpression node, arg) => defaultExpression(node, arg);
  R visitAsExpression(AsExpression node, arg) => defaultExpression(node, arg);
  R visitSymbolLiteral(SymbolLiteral node, arg) => defaultExpression(node, arg);
  R visitTypeLiteral(TypeLiteral node, arg) => defaultExpression(node, arg);
  R visitThisExpression(ThisExpression node, arg) =>
      defaultExpression(node, arg);
  R visitRethrow(Rethrow node, arg) => defaultExpression(node, arg);
  R visitThrow(Throw node, arg) => defaultExpression(node, arg);
  R visitListLiteral(ListLiteral node, arg) => defaultExpression(node, arg);
  R visitMapLiteral(MapLiteral node, arg) => defaultExpression(node, arg);
  R visitAwaitExpression(AwaitExpression node, arg) =>
      defaultExpression(node, arg);
  R visitFunctionExpression(FunctionExpression node, arg) =>
      defaultExpression(node, arg);
  R visitStringLiteral(StringLiteral node, arg) =>
      defaultBasicLiteral(node, arg);
  R visitIntLiteral(IntLiteral node, arg) => defaultBasicLiteral(node, arg);
  R visitDoubleLiteral(DoubleLiteral node, arg) =>
      defaultBasicLiteral(node, arg);
  R visitBoolLiteral(BoolLiteral node, arg) => defaultBasicLiteral(node, arg);
  R visitNullLiteral(NullLiteral node, arg) => defaultBasicLiteral(node, arg);
  R visitLet(Let node, arg) => defaultExpression(node, arg);
  R visitLoadLibrary(LoadLibrary node, arg) => defaultExpression(node, arg);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, arg) =>
      defaultExpression(node, arg);
  R visitVectorCreation(VectorCreation node, arg) =>
      defaultExpression(node, arg);
  R visitVectorGet(VectorGet node, arg) => defaultExpression(node, arg);
  R visitVectorSet(VectorSet node, arg) => defaultExpression(node, arg);
  R visitVectorCopy(VectorCopy node, arg) => defaultExpression(node, arg);
}

abstract class StatementVisitor1<R> {
  R defaultStatement(Statement node, arg) => null;

  R visitInvalidStatement(InvalidStatement node, arg) =>
      defaultStatement(node, arg);
  R visitExpressionStatement(ExpressionStatement node, arg) =>
      defaultStatement(node, arg);
  R visitBlock(Block node, arg) => defaultStatement(node, arg);
  R visitEmptyStatement(EmptyStatement node, arg) =>
      defaultStatement(node, arg);
  R visitAssertStatement(AssertStatement node, arg) =>
      defaultStatement(node, arg);
  R visitLabeledStatement(LabeledStatement node, arg) =>
      defaultStatement(node, arg);
  R visitBreakStatement(BreakStatement node, arg) =>
      defaultStatement(node, arg);
  R visitWhileStatement(WhileStatement node, arg) =>
      defaultStatement(node, arg);
  R visitDoStatement(DoStatement node, arg) => defaultStatement(node, arg);
  R visitForStatement(ForStatement node, arg) => defaultStatement(node, arg);
  R visitForInStatement(ForInStatement node, arg) =>
      defaultStatement(node, arg);
  R visitSwitchStatement(SwitchStatement node, arg) =>
      defaultStatement(node, arg);
  R visitContinueSwitchStatement(ContinueSwitchStatement node, arg) =>
      defaultStatement(node, arg);
  R visitIfStatement(IfStatement node, arg) => defaultStatement(node, arg);
  R visitReturnStatement(ReturnStatement node, arg) =>
      defaultStatement(node, arg);
  R visitTryCatch(TryCatch node, arg) => defaultStatement(node, arg);
  R visitTryFinally(TryFinally node, arg) => defaultStatement(node, arg);
  R visitYieldStatement(YieldStatement node, arg) =>
      defaultStatement(node, arg);
  R visitVariableDeclaration(VariableDeclaration node, arg) =>
      defaultStatement(node, arg);
  R visitFunctionDeclaration(FunctionDeclaration node, arg) =>
      defaultStatement(node, arg);
}
