// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.ast.visitor;

// ignore: UNDEFINED_HIDDEN_NAME
import 'dart:core' hide MapEntry;

import 'ast.dart';

abstract class ExpressionVisitor<R> {
  const ExpressionVisitor();

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
  R visitConstantExpression(ConstantExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitInstantiation(Instantiation node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
  R visitVectorCreation(VectorCreation node) => defaultExpression(node);
  R visitVectorGet(VectorGet node) => defaultExpression(node);
  R visitVectorSet(VectorSet node) => defaultExpression(node);
  R visitVectorCopy(VectorCopy node) => defaultExpression(node);
  R visitClosureCreation(ClosureCreation node) => defaultExpression(node);
}

abstract class StatementVisitor<R> {
  const StatementVisitor();

  R defaultStatement(Statement node) => null;

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
  R visitConstantExpression(ConstantExpression node) => defaultExpression(node);
  R visitStringLiteral(StringLiteral node) => defaultBasicLiteral(node);
  R visitIntLiteral(IntLiteral node) => defaultBasicLiteral(node);
  R visitDoubleLiteral(DoubleLiteral node) => defaultBasicLiteral(node);
  R visitBoolLiteral(BoolLiteral node) => defaultBasicLiteral(node);
  R visitNullLiteral(NullLiteral node) => defaultBasicLiteral(node);
  R visitLet(Let node) => defaultExpression(node);
  R visitInstantiation(Instantiation node) => defaultExpression(node);
  R visitLoadLibrary(LoadLibrary node) => defaultExpression(node);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) =>
      defaultExpression(node);
  R visitVectorCreation(VectorCreation node) => defaultExpression(node);
  R visitVectorGet(VectorGet node) => defaultExpression(node);
  R visitVectorSet(VectorSet node) => defaultExpression(node);
  R visitVectorCopy(VectorCopy node) => defaultExpression(node);
  R visitClosureCreation(ClosureCreation node) => defaultExpression(node);

  // Statements
  R defaultStatement(Statement node) => defaultTreeNode(node);
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
  R visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    return defaultMember(node);
  }

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
  R visitTypedefType(TypedefType node) => defaultDartType(node);
}

class ConstantVisitor<R> {
  R defaultConstant(Constant node) => null;

  R visitNullConstant(NullConstant node) => defaultConstant(node);
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  R visitListConstant(ListConstant node) => defaultConstant(node);
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  R visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
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
  R visitVectorType(VectorType node) => defaultDartType(node);
  R visitFunctionType(FunctionType node) => defaultDartType(node);
  R visitTypeParameterType(TypeParameterType node) => defaultDartType(node);
  R visitTypedefType(TypedefType node) => defaultDartType(node);

  // Constants
  R defaultConstant(Constant node) => defaultNode(node);
  R visitNullConstant(NullConstant node) => defaultConstant(node);
  R visitBoolConstant(BoolConstant node) => defaultConstant(node);
  R visitIntConstant(IntConstant node) => defaultConstant(node);
  R visitDoubleConstant(DoubleConstant node) => defaultConstant(node);
  R visitStringConstant(StringConstant node) => defaultConstant(node);
  R visitMapConstant(MapConstant node) => defaultConstant(node);
  R visitListConstant(ListConstant node) => defaultConstant(node);
  R visitInstanceConstant(InstanceConstant node) => defaultConstant(node);
  R visitTearOffConstant(TearOffConstant node) => defaultConstant(node);
  R visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);

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
  R visitMapConstantReference(MapConstant node) =>
      defaultConstantReference(node);
  R visitListConstantReference(ListConstant node) =>
      defaultConstantReference(node);
  R visitInstanceConstantReference(InstanceConstant node) =>
      defaultConstantReference(node);
  R visitTearOffConstantReference(TearOffConstant node) =>
      defaultConstantReference(node);
  R visitTypeLiteralConstantReference(TypeLiteralConstant node) =>
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
  R visitPropertyGet(PropertyGet node, T arg) => defaultExpression(node, arg);
  R visitPropertySet(PropertySet node, T arg) => defaultExpression(node, arg);
  R visitDirectPropertyGet(DirectPropertyGet node, T arg) =>
      defaultExpression(node, arg);
  R visitDirectPropertySet(DirectPropertySet node, T arg) =>
      defaultExpression(node, arg);
  R visitSuperPropertyGet(SuperPropertyGet node, T arg) =>
      defaultExpression(node, arg);
  R visitSuperPropertySet(SuperPropertySet node, T arg) =>
      defaultExpression(node, arg);
  R visitStaticGet(StaticGet node, T arg) => defaultExpression(node, arg);
  R visitStaticSet(StaticSet node, T arg) => defaultExpression(node, arg);
  R visitMethodInvocation(MethodInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitDirectMethodInvocation(DirectMethodInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitSuperMethodInvocation(SuperMethodInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitStaticInvocation(StaticInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitConstructorInvocation(ConstructorInvocation node, T arg) =>
      defaultExpression(node, arg);
  R visitNot(Not node, T arg) => defaultExpression(node, arg);
  R visitLogicalExpression(LogicalExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitConditionalExpression(ConditionalExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitStringConcatenation(StringConcatenation node, T arg) =>
      defaultExpression(node, arg);
  R visitIsExpression(IsExpression node, T arg) => defaultExpression(node, arg);
  R visitAsExpression(AsExpression node, T arg) => defaultExpression(node, arg);
  R visitSymbolLiteral(SymbolLiteral node, T arg) =>
      defaultExpression(node, arg);
  R visitTypeLiteral(TypeLiteral node, T arg) => defaultExpression(node, arg);
  R visitThisExpression(ThisExpression node, T arg) =>
      defaultExpression(node, arg);
  R visitConstantExpression(ConstantExpression node, arg) =>
      defaultExpression(node, arg);
  R visitRethrow(Rethrow node, T arg) => defaultExpression(node, arg);
  R visitThrow(Throw node, T arg) => defaultExpression(node, arg);
  R visitListLiteral(ListLiteral node, T arg) => defaultExpression(node, arg);
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
  R visitInstantiation(Instantiation node, T arg) =>
      defaultExpression(node, arg);
  R visitLoadLibrary(LoadLibrary node, T arg) => defaultExpression(node, arg);
  R visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node, T arg) =>
      defaultExpression(node, arg);
  R visitVectorCreation(VectorCreation node, T arg) =>
      defaultExpression(node, arg);
  R visitVectorGet(VectorGet node, T arg) => defaultExpression(node, arg);
  R visitVectorSet(VectorSet node, T arg) => defaultExpression(node, arg);
  R visitVectorCopy(VectorCopy node, T arg) => defaultExpression(node, arg);
  R visitClosureCreation(ClosureCreation node, T arg) =>
      defaultExpression(node, arg);
}

abstract class StatementVisitor1<R, T> {
  const StatementVisitor1();

  R defaultStatement(Statement node, T arg) => null;

  R visitExpressionStatement(ExpressionStatement node, T arg) =>
      defaultStatement(node, arg);
  R visitBlock(Block node, T arg) => defaultStatement(node, arg);
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
