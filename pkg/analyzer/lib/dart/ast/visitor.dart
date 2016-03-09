// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines AST visitors that support useful patterns for visiting the nodes in
 * an [AST structure](ast.dart).
 *
 * Dart is an evolving language, and the AST structure must evolved with it.
 * When the AST structure changes, the visitor interface will sometimes change
 * as well. If it is desirable to get a compilation error when the structure of
 * the AST has been modified, then you should consider implementing the
 * interface [AstVisitor] directly. Doing so will ensure that changes that
 * introduce new classes of nodes will be flagged. (Of course, not all changes
 * to the AST structure require the addition of a new class of node, and hence
 * cannot be caught this way.)
 *
 * But if automatic detection of these kinds of changes is not necessary then
 * you will probably want to extend one of the classes in this library because
 * doing so will simplify the task of writing your visitor and guard against
 * future changes to the AST structure. For example, the [RecursiveAstVisitor]
 * automates the process of visiting all of the descendants of a node.
 */
library analyzer.dart.ast.visitor;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure, similar to [GeneralizingAstVisitor]. This visitor uses a
 * breadth-first ordering rather than the depth-first ordering of
 * [GeneralizingAstVisitor].
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general visit method. Failure to
 * do so will cause the visit methods for superclasses of the node to not be
 * invoked and will cause the children of the visited node to not be visited.
 *
 * In addition, subclasses should <b>not</b> explicitly visit the children of a
 * node, but should ensure that the method [visitNode] is used to visit the
 * children (either directly or indirectly). Failure to do will break the order
 * in which nodes are visited.
 *
 * Note that, unlike other visitors that begin to visit a structure of nodes by
 * asking the root node in the structure to accept the visitor, this visitor
 * requires that clients start the visit by invoking the method [visitAllNodes]
 * defined on the visitor with the root node as the argument:
 *
 *     visitor.visitAllNodes(rootNode);
 *
 * Clients may extend or implement this class.
 */
class BreadthFirstVisitor<R> extends GeneralizingAstVisitor<R> {
  /**
   * A queue holding the nodes that have not yet been visited in the order in
   * which they ought to be visited.
   */
  Queue<AstNode> _queue = new Queue<AstNode>();

  /**
   * A visitor, used to visit the children of the current node, that will add
   * the nodes it visits to the [_queue].
   */
  _BreadthFirstChildVisitor _childVisitor;

  /**
   * Initialize a newly created visitor.
   */
  BreadthFirstVisitor() {
    _childVisitor = new _BreadthFirstChildVisitor(this);
  }

  /**
   * Visit all nodes in the tree starting at the given [root] node, in
   * breadth-first order.
   */
  void visitAllNodes(AstNode root) {
    _queue.add(root);
    while (!_queue.isEmpty) {
      AstNode next = _queue.removeFirst();
      next.accept(this);
    }
  }

  @override
  R visitNode(AstNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure. For each node that is visited, the corresponding visit method on
 * one or more other visitors (the 'delegates') will be invoked.
 *
 * For example, if an instance of this class is created with two delegates V1
 * and V2, and that instance is used to visit the expression 'x + 1', then the
 * following visit methods will be invoked:
 * 1. V1.visitBinaryExpression
 * 2. V2.visitBinaryExpression
 * 3. V1.visitSimpleIdentifier
 * 4. V2.visitSimpleIdentifier
 * 5. V1.visitIntegerLiteral
 * 6. V2.visitIntegerLiteral
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DelegatingAstVisitor<T> implements AstVisitor<T> {
  /**
   * The delegates whose visit methods will be invoked.
   */
  final Iterable<AstVisitor<T>> _delegates;

  /**
   * Initialize a newly created visitor to use each of the given delegate
   * visitors to visit the nodes of an AST structure.
   */
  DelegatingAstVisitor(this._delegates);

  @override
  T visitAdjacentStrings(AdjacentStrings node) {
    _delegates.forEach((delegate) => delegate.visitAdjacentStrings(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAnnotation(Annotation node) {
    _delegates.forEach((delegate) => delegate.visitAnnotation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitArgumentList(ArgumentList node) {
    _delegates.forEach((delegate) => delegate.visitArgumentList(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAsExpression(AsExpression node) {
    _delegates.forEach((delegate) => delegate.visitAsExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAssertStatement(AssertStatement node) {
    _delegates.forEach((delegate) => delegate.visitAssertStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAssignmentExpression(AssignmentExpression node) {
    _delegates.forEach((delegate) => delegate.visitAssignmentExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitAwaitExpression(AwaitExpression node) {
    _delegates.forEach((delegate) => delegate.visitAwaitExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitBinaryExpression(BinaryExpression node) {
    _delegates.forEach((delegate) => delegate.visitBinaryExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitBlock(Block node) {
    _delegates.forEach((delegate) => delegate.visitBlock(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitBlockFunctionBody(BlockFunctionBody node) {
    _delegates.forEach((delegate) => delegate.visitBlockFunctionBody(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitBooleanLiteral(BooleanLiteral node) {
    _delegates.forEach((delegate) => delegate.visitBooleanLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitBreakStatement(BreakStatement node) {
    _delegates.forEach((delegate) => delegate.visitBreakStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitCascadeExpression(CascadeExpression node) {
    _delegates.forEach((delegate) => delegate.visitCascadeExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitCatchClause(CatchClause node) {
    _delegates.forEach((delegate) => delegate.visitCatchClause(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitClassDeclaration(ClassDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitClassDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitClassTypeAlias(ClassTypeAlias node) {
    _delegates.forEach((delegate) => delegate.visitClassTypeAlias(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitComment(Comment node) {
    _delegates.forEach((delegate) => delegate.visitComment(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitCommentReference(CommentReference node) {
    _delegates.forEach((delegate) => delegate.visitCommentReference(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitCompilationUnit(CompilationUnit node) {
    _delegates.forEach((delegate) => delegate.visitCompilationUnit(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitConditionalExpression(ConditionalExpression node) {
    _delegates.forEach((delegate) => delegate.visitConditionalExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitConfiguration(Configuration node) {
    _delegates.forEach((delegate) => delegate.visitConfiguration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitConstructorDeclaration(ConstructorDeclaration node) {
    _delegates
        .forEach((delegate) => delegate.visitConstructorDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _delegates
        .forEach((delegate) => delegate.visitConstructorFieldInitializer(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitConstructorName(ConstructorName node) {
    _delegates.forEach((delegate) => delegate.visitConstructorName(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitContinueStatement(ContinueStatement node) {
    _delegates.forEach((delegate) => delegate.visitContinueStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitDeclaredIdentifier(DeclaredIdentifier node) {
    _delegates.forEach((delegate) => delegate.visitDeclaredIdentifier(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitDefaultFormalParameter(DefaultFormalParameter node) {
    _delegates
        .forEach((delegate) => delegate.visitDefaultFormalParameter(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitDoStatement(DoStatement node) {
    _delegates.forEach((delegate) => delegate.visitDoStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitDottedName(DottedName node) {
    _delegates.forEach((delegate) => delegate.visitDottedName(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitDoubleLiteral(DoubleLiteral node) {
    _delegates.forEach((delegate) => delegate.visitDoubleLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitEmptyFunctionBody(EmptyFunctionBody node) {
    _delegates.forEach((delegate) => delegate.visitEmptyFunctionBody(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitEmptyStatement(EmptyStatement node) {
    _delegates.forEach((delegate) => delegate.visitEmptyStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _delegates
        .forEach((delegate) => delegate.visitEnumConstantDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitEnumDeclaration(EnumDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitEnumDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitExportDirective(ExportDirective node) {
    _delegates.forEach((delegate) => delegate.visitExportDirective(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _delegates
        .forEach((delegate) => delegate.visitExpressionFunctionBody(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitExpressionStatement(ExpressionStatement node) {
    _delegates.forEach((delegate) => delegate.visitExpressionStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitExtendsClause(ExtendsClause node) {
    _delegates.forEach((delegate) => delegate.visitExtendsClause(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFieldDeclaration(FieldDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitFieldDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFieldFormalParameter(FieldFormalParameter node) {
    _delegates.forEach((delegate) => delegate.visitFieldFormalParameter(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitForEachStatement(ForEachStatement node) {
    _delegates.forEach((delegate) => delegate.visitForEachStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFormalParameterList(FormalParameterList node) {
    _delegates.forEach((delegate) => delegate.visitFormalParameterList(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitForStatement(ForStatement node) {
    _delegates.forEach((delegate) => delegate.visitForStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionDeclaration(FunctionDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitFunctionDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _delegates.forEach(
        (delegate) => delegate.visitFunctionDeclarationStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionExpression(FunctionExpression node) {
    _delegates.forEach((delegate) => delegate.visitFunctionExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _delegates.forEach(
        (delegate) => delegate.visitFunctionExpressionInvocation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionTypeAlias(FunctionTypeAlias node) {
    _delegates.forEach((delegate) => delegate.visitFunctionTypeAlias(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _delegates.forEach(
        (delegate) => delegate.visitFunctionTypedFormalParameter(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitHideCombinator(HideCombinator node) {
    _delegates.forEach((delegate) => delegate.visitHideCombinator(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitIfStatement(IfStatement node) {
    _delegates.forEach((delegate) => delegate.visitIfStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitImplementsClause(ImplementsClause node) {
    _delegates.forEach((delegate) => delegate.visitImplementsClause(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitImportDirective(ImportDirective node) {
    _delegates.forEach((delegate) => delegate.visitImportDirective(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitIndexExpression(IndexExpression node) {
    _delegates.forEach((delegate) => delegate.visitIndexExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitInstanceCreationExpression(InstanceCreationExpression node) {
    _delegates
        .forEach((delegate) => delegate.visitInstanceCreationExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitIntegerLiteral(IntegerLiteral node) {
    _delegates.forEach((delegate) => delegate.visitIntegerLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitInterpolationExpression(InterpolationExpression node) {
    _delegates
        .forEach((delegate) => delegate.visitInterpolationExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitInterpolationString(InterpolationString node) {
    _delegates.forEach((delegate) => delegate.visitInterpolationString(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitIsExpression(IsExpression node) {
    _delegates.forEach((delegate) => delegate.visitIsExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitLabel(Label node) {
    _delegates.forEach((delegate) => delegate.visitLabel(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitLabeledStatement(LabeledStatement node) {
    _delegates.forEach((delegate) => delegate.visitLabeledStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitLibraryDirective(LibraryDirective node) {
    _delegates.forEach((delegate) => delegate.visitLibraryDirective(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitLibraryIdentifier(LibraryIdentifier node) {
    _delegates.forEach((delegate) => delegate.visitLibraryIdentifier(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitListLiteral(ListLiteral node) {
    _delegates.forEach((delegate) => delegate.visitListLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitMapLiteral(MapLiteral node) {
    _delegates.forEach((delegate) => delegate.visitMapLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitMapLiteralEntry(MapLiteralEntry node) {
    _delegates.forEach((delegate) => delegate.visitMapLiteralEntry(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitMethodDeclaration(MethodDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitMethodDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitMethodInvocation(MethodInvocation node) {
    _delegates.forEach((delegate) => delegate.visitMethodInvocation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitNamedExpression(NamedExpression node) {
    _delegates.forEach((delegate) => delegate.visitNamedExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitNativeClause(NativeClause node) {
    _delegates.forEach((delegate) => delegate.visitNativeClause(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitNativeFunctionBody(NativeFunctionBody node) {
    _delegates.forEach((delegate) => delegate.visitNativeFunctionBody(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitNullLiteral(NullLiteral node) {
    _delegates.forEach((delegate) => delegate.visitNullLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitParenthesizedExpression(ParenthesizedExpression node) {
    _delegates
        .forEach((delegate) => delegate.visitParenthesizedExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPartDirective(PartDirective node) {
    _delegates.forEach((delegate) => delegate.visitPartDirective(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPartOfDirective(PartOfDirective node) {
    _delegates.forEach((delegate) => delegate.visitPartOfDirective(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPostfixExpression(PostfixExpression node) {
    _delegates.forEach((delegate) => delegate.visitPostfixExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPrefixedIdentifier(PrefixedIdentifier node) {
    _delegates.forEach((delegate) => delegate.visitPrefixedIdentifier(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPrefixExpression(PrefixExpression node) {
    _delegates.forEach((delegate) => delegate.visitPrefixExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitPropertyAccess(PropertyAccess node) {
    _delegates.forEach((delegate) => delegate.visitPropertyAccess(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _delegates.forEach(
        (delegate) => delegate.visitRedirectingConstructorInvocation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitRethrowExpression(RethrowExpression node) {
    _delegates.forEach((delegate) => delegate.visitRethrowExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitReturnStatement(ReturnStatement node) {
    _delegates.forEach((delegate) => delegate.visitReturnStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitScriptTag(ScriptTag node) {
    _delegates.forEach((delegate) => delegate.visitScriptTag(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitShowCombinator(ShowCombinator node) {
    _delegates.forEach((delegate) => delegate.visitShowCombinator(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSimpleFormalParameter(SimpleFormalParameter node) {
    _delegates.forEach((delegate) => delegate.visitSimpleFormalParameter(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSimpleIdentifier(SimpleIdentifier node) {
    _delegates.forEach((delegate) => delegate.visitSimpleIdentifier(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSimpleStringLiteral(SimpleStringLiteral node) {
    _delegates.forEach((delegate) => delegate.visitSimpleStringLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitStringInterpolation(StringInterpolation node) {
    _delegates.forEach((delegate) => delegate.visitStringInterpolation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _delegates
        .forEach((delegate) => delegate.visitSuperConstructorInvocation(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSuperExpression(SuperExpression node) {
    _delegates.forEach((delegate) => delegate.visitSuperExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSwitchCase(SwitchCase node) {
    _delegates.forEach((delegate) => delegate.visitSwitchCase(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSwitchDefault(SwitchDefault node) {
    _delegates.forEach((delegate) => delegate.visitSwitchDefault(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSwitchStatement(SwitchStatement node) {
    _delegates.forEach((delegate) => delegate.visitSwitchStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitSymbolLiteral(SymbolLiteral node) {
    _delegates.forEach((delegate) => delegate.visitSymbolLiteral(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitThisExpression(ThisExpression node) {
    _delegates.forEach((delegate) => delegate.visitThisExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitThrowExpression(ThrowExpression node) {
    _delegates.forEach((delegate) => delegate.visitThrowExpression(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _delegates
        .forEach((delegate) => delegate.visitTopLevelVariableDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTryStatement(TryStatement node) {
    _delegates.forEach((delegate) => delegate.visitTryStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTypeArgumentList(TypeArgumentList node) {
    _delegates.forEach((delegate) => delegate.visitTypeArgumentList(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTypeName(TypeName node) {
    _delegates.forEach((delegate) => delegate.visitTypeName(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTypeParameter(TypeParameter node) {
    _delegates.forEach((delegate) => delegate.visitTypeParameter(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitTypeParameterList(TypeParameterList node) {
    _delegates.forEach((delegate) => delegate.visitTypeParameterList(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitVariableDeclaration(VariableDeclaration node) {
    _delegates.forEach((delegate) => delegate.visitVariableDeclaration(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitVariableDeclarationList(VariableDeclarationList node) {
    _delegates
        .forEach((delegate) => delegate.visitVariableDeclarationList(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _delegates.forEach(
        (delegate) => delegate.visitVariableDeclarationStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitWhileStatement(WhileStatement node) {
    _delegates.forEach((delegate) => delegate.visitWhileStatement(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitWithClause(WithClause node) {
    _delegates.forEach((delegate) => delegate.visitWithClause(node));
    node.visitChildren(this);
    return null;
  }

  @override
  T visitYieldStatement(YieldStatement node) {
    _delegates.forEach((delegate) => delegate.visitYieldStatement(node));
    node.visitChildren(this);
    return null;
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure (like instances of the class [RecursiveAstVisitor]). In addition,
 * when a node of a specific type is visited not only will the visit method for
 * that specific type of node be invoked, but additional methods for the
 * superclasses of that node will also be invoked. For example, using an
 * instance of this class to visit a [Block] will cause the method [visitBlock]
 * to be invoked but will also cause the methods [visitStatement] and
 * [visitNode] to be subsequently invoked. This allows visitors to be written
 * that visit all statements without needing to override the visit method for
 * each of the specific subclasses of [Statement].
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general visit method. Failure to
 * do so will cause the visit methods for superclasses of the node to not be
 * invoked and will cause the children of the visited node to not be visited.
 *
 * Clients may extend or implement this class.
 */
class GeneralizingAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => visitStringLiteral(node);

  R visitAnnotatedNode(AnnotatedNode node) => visitNode(node);

  @override
  R visitAnnotation(Annotation node) => visitNode(node);

  @override
  R visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R visitAsExpression(AsExpression node) => visitExpression(node);

  @override
  R visitAssertStatement(AssertStatement node) => visitStatement(node);

  @override
  R visitAssignmentExpression(AssignmentExpression node) =>
      visitExpression(node);

  @override
  R visitAwaitExpression(AwaitExpression node) => visitExpression(node);

  @override
  R visitBinaryExpression(BinaryExpression node) => visitExpression(node);

  @override
  R visitBlock(Block node) => visitStatement(node);

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => visitFunctionBody(node);

  @override
  R visitBooleanLiteral(BooleanLiteral node) => visitLiteral(node);

  @override
  R visitBreakStatement(BreakStatement node) => visitStatement(node);

  @override
  R visitCascadeExpression(CascadeExpression node) => visitExpression(node);

  @override
  R visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R visitClassDeclaration(ClassDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  R visitClassMember(ClassMember node) => visitDeclaration(node);

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => visitTypeAlias(node);

  R visitCombinator(Combinator node) => visitNode(node);

  @override
  R visitComment(Comment node) => visitNode(node);

  @override
  R visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R visitCompilationUnit(CompilationUnit node) => visitNode(node);

  R visitCompilationUnitMember(CompilationUnitMember node) =>
      visitDeclaration(node);

  @override
  R visitConditionalExpression(ConditionalExpression node) =>
      visitExpression(node);

  @override
  R visitConfiguration(Configuration node) => visitNode(node);

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) =>
      visitClassMember(node);

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitConstructorInitializer(node);

  R visitConstructorInitializer(ConstructorInitializer node) => visitNode(node);

  @override
  R visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R visitContinueStatement(ContinueStatement node) => visitStatement(node);

  R visitDeclaration(Declaration node) => visitAnnotatedNode(node);

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitDeclaration(node);

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) =>
      visitFormalParameter(node);

  R visitDirective(Directive node) => visitAnnotatedNode(node);

  @override
  R visitDoStatement(DoStatement node) => visitStatement(node);

  @override
  R visitDottedName(DottedName node) => visitNode(node);

  @override
  R visitDoubleLiteral(DoubleLiteral node) => visitLiteral(node);

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitFunctionBody(node);

  @override
  R visitEmptyStatement(EmptyStatement node) => visitStatement(node);

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitDeclaration(node);

  @override
  R visitEnumDeclaration(EnumDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R visitExportDirective(ExportDirective node) => visitNamespaceDirective(node);

  R visitExpression(Expression node) => visitNode(node);

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      visitFunctionBody(node);

  @override
  R visitExpressionStatement(ExpressionStatement node) => visitStatement(node);

  @override
  R visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R visitFieldDeclaration(FieldDeclaration node) => visitClassMember(node);

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitForEachStatement(ForEachStatement node) => visitStatement(node);

  R visitFormalParameter(FormalParameter node) => visitNode(node);

  @override
  R visitFormalParameterList(FormalParameterList node) => visitNode(node);

  @override
  R visitForStatement(ForStatement node) => visitStatement(node);

  R visitFunctionBody(FunctionBody node) => visitNode(node);

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitStatement(node);

  @override
  R visitFunctionExpression(FunctionExpression node) => visitExpression(node);

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitExpression(node);

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitTypeAlias(node);

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitHideCombinator(HideCombinator node) => visitCombinator(node);

  R visitIdentifier(Identifier node) => visitExpression(node);

  @override
  R visitIfStatement(IfStatement node) => visitStatement(node);

  @override
  R visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R visitImportDirective(ImportDirective node) => visitNamespaceDirective(node);

  @override
  R visitIndexExpression(IndexExpression node) => visitExpression(node);

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitExpression(node);

  @override
  R visitIntegerLiteral(IntegerLiteral node) => visitLiteral(node);

  R visitInterpolationElement(InterpolationElement node) => visitNode(node);

  @override
  R visitInterpolationExpression(InterpolationExpression node) =>
      visitInterpolationElement(node);

  @override
  R visitInterpolationString(InterpolationString node) =>
      visitInterpolationElement(node);

  @override
  R visitIsExpression(IsExpression node) => visitExpression(node);

  @override
  R visitLabel(Label node) => visitNode(node);

  @override
  R visitLabeledStatement(LabeledStatement node) => visitStatement(node);

  @override
  R visitLibraryDirective(LibraryDirective node) => visitDirective(node);

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => visitIdentifier(node);

  @override
  R visitListLiteral(ListLiteral node) => visitTypedLiteral(node);

  R visitLiteral(Literal node) => visitExpression(node);

  @override
  R visitMapLiteral(MapLiteral node) => visitTypedLiteral(node);

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  @override
  R visitMethodDeclaration(MethodDeclaration node) => visitClassMember(node);

  @override
  R visitMethodInvocation(MethodInvocation node) => visitExpression(node);

  R visitNamedCompilationUnitMember(NamedCompilationUnitMember node) =>
      visitCompilationUnitMember(node);

  @override
  R visitNamedExpression(NamedExpression node) => visitExpression(node);

  R visitNamespaceDirective(NamespaceDirective node) =>
      visitUriBasedDirective(node);

  @override
  R visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => visitFunctionBody(node);

  R visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  R visitNormalFormalParameter(NormalFormalParameter node) =>
      visitFormalParameter(node);

  @override
  R visitNullLiteral(NullLiteral node) => visitLiteral(node);

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitExpression(node);

  @override
  R visitPartDirective(PartDirective node) => visitUriBasedDirective(node);

  @override
  R visitPartOfDirective(PartOfDirective node) => visitDirective(node);

  @override
  R visitPostfixExpression(PostfixExpression node) => visitExpression(node);

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitIdentifier(node);

  @override
  R visitPrefixExpression(PrefixExpression node) => visitExpression(node);

  @override
  R visitPropertyAccess(PropertyAccess node) => visitExpression(node);

  @override
  R visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      visitConstructorInitializer(node);

  @override
  R visitRethrowExpression(RethrowExpression node) => visitExpression(node);

  @override
  R visitReturnStatement(ReturnStatement node) => visitStatement(node);

  @override
  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  R visitShowCombinator(ShowCombinator node) => visitCombinator(node);

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => visitIdentifier(node);

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) =>
      visitSingleStringLiteral(node);

  R visitSingleStringLiteral(SingleStringLiteral node) =>
      visitStringLiteral(node);

  R visitStatement(Statement node) => visitNode(node);

  @override
  R visitStringInterpolation(StringInterpolation node) =>
      visitSingleStringLiteral(node);

  R visitStringLiteral(StringLiteral node) => visitLiteral(node);

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitConstructorInitializer(node);

  @override
  R visitSuperExpression(SuperExpression node) => visitExpression(node);

  @override
  R visitSwitchCase(SwitchCase node) => visitSwitchMember(node);

  @override
  R visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);

  R visitSwitchMember(SwitchMember node) => visitNode(node);

  @override
  R visitSwitchStatement(SwitchStatement node) => visitStatement(node);

  @override
  R visitSymbolLiteral(SymbolLiteral node) => visitLiteral(node);

  @override
  R visitThisExpression(ThisExpression node) => visitExpression(node);

  @override
  R visitThrowExpression(ThrowExpression node) => visitExpression(node);

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitCompilationUnitMember(node);

  @override
  R visitTryStatement(TryStatement node) => visitStatement(node);

  R visitTypeAlias(TypeAlias node) => visitNamedCompilationUnitMember(node);

  @override
  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  R visitTypedLiteral(TypedLiteral node) => visitLiteral(node);

  @override
  R visitTypeName(TypeName node) => visitNode(node);

  @override
  R visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R visitTypeParameterList(TypeParameterList node) => visitNode(node);

  R visitUriBasedDirective(UriBasedDirective node) => visitDirective(node);

  @override
  R visitVariableDeclaration(VariableDeclaration node) =>
      visitDeclaration(node);

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitStatement(node);

  @override
  R visitWhileStatement(WhileStatement node) => visitStatement(node);

  @override
  R visitWithClause(WithClause node) => visitNode(node);

  @override
  R visitYieldStatement(YieldStatement node) => visitStatement(node);
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure. For example, using an instance of this class to visit a [Block]
 * will also cause all of the statements in the block to be visited.
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or must explicitly ask the visited node to visit its children.
 * Failure to do so will cause the children of the visited node to not be
 * visited.
 *
 * Clients may extend or implement this class.
 */
class RecursiveAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAnnotation(Annotation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAsExpression(AsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAwaitExpression(AwaitExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBlock(Block node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCatchClause(CatchClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitComment(Comment node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCommentReference(CommentReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConfiguration(Configuration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDoStatement(DoStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDottedName(DottedName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEnumDeclaration(EnumDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExportDirective(ExportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitForEachStatement(ForEachStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitForStatement(ForStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitHideCombinator(HideCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIfStatement(IfStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitImportDirective(ImportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInterpolationString(InterpolationString node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIsExpression(IsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLabel(Label node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMapLiteral(MapLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNativeClause(NativeClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNullLiteral(NullLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPartDirective(PartDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitScriptTag(ScriptTag node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSuperExpression(SuperExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSymbolLiteral(SymbolLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitThisExpression(ThisExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTryStatement(TryStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeName(TypeName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitWithClause(WithClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitYieldStatement(YieldStatement node) {
    node.visitChildren(this);
    return null;
  }
}

/**
 * An AST visitor that will do nothing when visiting an AST node. It is intended
 * to be a superclass for classes that use the visitor pattern primarily as a
 * dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 *
 * Clients may extend or implement this class.
 */
class SimpleAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => null;

  @override
  R visitAnnotation(Annotation node) => null;

  @override
  R visitArgumentList(ArgumentList node) => null;

  @override
  R visitAsExpression(AsExpression node) => null;

  @override
  R visitAssertStatement(AssertStatement node) => null;

  @override
  R visitAssignmentExpression(AssignmentExpression node) => null;

  @override
  R visitAwaitExpression(AwaitExpression node) => null;

  @override
  R visitBinaryExpression(BinaryExpression node) => null;

  @override
  R visitBlock(Block node) => null;

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => null;

  @override
  R visitBooleanLiteral(BooleanLiteral node) => null;

  @override
  R visitBreakStatement(BreakStatement node) => null;

  @override
  R visitCascadeExpression(CascadeExpression node) => null;

  @override
  R visitCatchClause(CatchClause node) => null;

  @override
  R visitClassDeclaration(ClassDeclaration node) => null;

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => null;

  @override
  R visitComment(Comment node) => null;

  @override
  R visitCommentReference(CommentReference node) => null;

  @override
  R visitCompilationUnit(CompilationUnit node) => null;

  @override
  R visitConditionalExpression(ConditionalExpression node) => null;

  @override
  R visitConfiguration(Configuration node) => null;

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) => null;

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) => null;

  @override
  R visitConstructorName(ConstructorName node) => null;

  @override
  R visitContinueStatement(ContinueStatement node) => null;

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => null;

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) => null;

  @override
  R visitDoStatement(DoStatement node) => null;

  @override
  R visitDottedName(DottedName node) => null;

  @override
  R visitDoubleLiteral(DoubleLiteral node) => null;

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => null;

  @override
  R visitEmptyStatement(EmptyStatement node) => null;

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) => null;

  @override
  R visitEnumDeclaration(EnumDeclaration node) => null;

  @override
  R visitExportDirective(ExportDirective node) => null;

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => null;

  @override
  R visitExpressionStatement(ExpressionStatement node) => null;

  @override
  R visitExtendsClause(ExtendsClause node) => null;

  @override
  R visitFieldDeclaration(FieldDeclaration node) => null;

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) => null;

  @override
  R visitForEachStatement(ForEachStatement node) => null;

  @override
  R visitFormalParameterList(FormalParameterList node) => null;

  @override
  R visitForStatement(ForStatement node) => null;

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) => null;

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      null;

  @override
  R visitFunctionExpression(FunctionExpression node) => null;

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      null;

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => null;

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      null;

  @override
  R visitHideCombinator(HideCombinator node) => null;

  @override
  R visitIfStatement(IfStatement node) => null;

  @override
  R visitImplementsClause(ImplementsClause node) => null;

  @override
  R visitImportDirective(ImportDirective node) => null;

  @override
  R visitIndexExpression(IndexExpression node) => null;

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) => null;

  @override
  R visitIntegerLiteral(IntegerLiteral node) => null;

  @override
  R visitInterpolationExpression(InterpolationExpression node) => null;

  @override
  R visitInterpolationString(InterpolationString node) => null;

  @override
  R visitIsExpression(IsExpression node) => null;

  @override
  R visitLabel(Label node) => null;

  @override
  R visitLabeledStatement(LabeledStatement node) => null;

  @override
  R visitLibraryDirective(LibraryDirective node) => null;

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  R visitListLiteral(ListLiteral node) => null;

  @override
  R visitMapLiteral(MapLiteral node) => null;

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => null;

  @override
  R visitMethodDeclaration(MethodDeclaration node) => null;

  @override
  R visitMethodInvocation(MethodInvocation node) => null;

  @override
  R visitNamedExpression(NamedExpression node) => null;

  @override
  R visitNativeClause(NativeClause node) => null;

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => null;

  @override
  R visitNullLiteral(NullLiteral node) => null;

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) => null;

  @override
  R visitPartDirective(PartDirective node) => null;

  @override
  R visitPartOfDirective(PartOfDirective node) => null;

  @override
  R visitPostfixExpression(PostfixExpression node) => null;

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => null;

  @override
  R visitPrefixExpression(PrefixExpression node) => null;

  @override
  R visitPropertyAccess(PropertyAccess node) => null;

  @override
  R visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      null;

  @override
  R visitRethrowExpression(RethrowExpression node) => null;

  @override
  R visitReturnStatement(ReturnStatement node) => null;

  @override
  R visitScriptTag(ScriptTag node) => null;

  @override
  R visitShowCombinator(ShowCombinator node) => null;

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) => null;

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => null;

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) => null;

  @override
  R visitStringInterpolation(StringInterpolation node) => null;

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) => null;

  @override
  R visitSuperExpression(SuperExpression node) => null;

  @override
  R visitSwitchCase(SwitchCase node) => null;

  @override
  R visitSwitchDefault(SwitchDefault node) => null;

  @override
  R visitSwitchStatement(SwitchStatement node) => null;

  @override
  R visitSymbolLiteral(SymbolLiteral node) => null;

  @override
  R visitThisExpression(ThisExpression node) => null;

  @override
  R visitThrowExpression(ThrowExpression node) => null;

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => null;

  @override
  R visitTryStatement(TryStatement node) => null;

  @override
  R visitTypeArgumentList(TypeArgumentList node) => null;

  @override
  R visitTypeName(TypeName node) => null;

  @override
  R visitTypeParameter(TypeParameter node) => null;

  @override
  R visitTypeParameterList(TypeParameterList node) => null;

  @override
  R visitVariableDeclaration(VariableDeclaration node) => null;

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) => null;

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      null;

  @override
  R visitWhileStatement(WhileStatement node) => null;

  @override
  R visitWithClause(WithClause node) => null;

  @override
  R visitYieldStatement(YieldStatement node) => null;
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure (like instances of the class [RecursiveAstVisitor]). In addition,
 * every node will also be visited by using a single unified [visitNode] method.
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general [visitNode] method.
 * Failure to do so will cause the children of the visited node to not be
 * visited.
 *
 * Clients may extend or implement this class.
 */
class UnifyingAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => visitNode(node);

  @override
  R visitAnnotation(Annotation node) => visitNode(node);

  @override
  R visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R visitAsExpression(AsExpression node) => visitNode(node);

  @override
  R visitAssertStatement(AssertStatement node) => visitNode(node);

  @override
  R visitAssignmentExpression(AssignmentExpression node) => visitNode(node);

  @override
  R visitAwaitExpression(AwaitExpression node) => visitNode(node);

  @override
  R visitBinaryExpression(BinaryExpression node) => visitNode(node);

  @override
  R visitBlock(Block node) => visitNode(node);

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => visitNode(node);

  @override
  R visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  R visitBreakStatement(BreakStatement node) => visitNode(node);

  @override
  R visitCascadeExpression(CascadeExpression node) => visitNode(node);

  @override
  R visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R visitClassDeclaration(ClassDeclaration node) => visitNode(node);

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => visitNode(node);

  @override
  R visitComment(Comment node) => visitNode(node);

  @override
  R visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R visitCompilationUnit(CompilationUnit node) => visitNode(node);

  @override
  R visitConditionalExpression(ConditionalExpression node) => visitNode(node);

  @override
  R visitConfiguration(Configuration node) => visitNode(node);

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) => visitNode(node);

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitNode(node);

  @override
  R visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R visitContinueStatement(ContinueStatement node) => visitNode(node);

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitNode(node);

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) => visitNode(node);

  @override
  R visitDoStatement(DoStatement node) => visitNode(node);

  @override
  R visitDottedName(DottedName node) => visitNode(node);

  @override
  R visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  R visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitNode(node);

  @override
  R visitEnumDeclaration(EnumDeclaration node) => visitNode(node);

  @override
  R visitExportDirective(ExportDirective node) => visitNode(node);

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => visitNode(node);

  @override
  R visitExpressionStatement(ExpressionStatement node) => visitNode(node);

  @override
  R visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R visitFieldDeclaration(FieldDeclaration node) => visitNode(node);

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) => visitNode(node);

  @override
  R visitForEachStatement(ForEachStatement node) => visitNode(node);

  @override
  R visitFormalParameterList(FormalParameterList node) => visitNode(node);

  @override
  R visitForStatement(ForStatement node) => visitNode(node);

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) => visitNode(node);

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitNode(node);

  @override
  R visitFunctionExpression(FunctionExpression node) => visitNode(node);

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitNode(node);

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitNode(node);

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNode(node);

  @override
  R visitHideCombinator(HideCombinator node) => visitNode(node);

  @override
  R visitIfStatement(IfStatement node) => visitNode(node);

  @override
  R visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R visitImportDirective(ImportDirective node) => visitNode(node);

  @override
  R visitIndexExpression(IndexExpression node) => visitNode(node);

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitNode(node);

  @override
  R visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  R visitInterpolationExpression(InterpolationExpression node) =>
      visitNode(node);

  @override
  R visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  R visitIsExpression(IsExpression node) => visitNode(node);

  @override
  R visitLabel(Label node) => visitNode(node);

  @override
  R visitLabeledStatement(LabeledStatement node) => visitNode(node);

  @override
  R visitLibraryDirective(LibraryDirective node) => visitNode(node);

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => visitNode(node);

  @override
  R visitListLiteral(ListLiteral node) => visitNode(node);

  @override
  R visitMapLiteral(MapLiteral node) => visitNode(node);

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  @override
  R visitMethodDeclaration(MethodDeclaration node) => visitNode(node);

  @override
  R visitMethodInvocation(MethodInvocation node) => visitNode(node);

  @override
  R visitNamedExpression(NamedExpression node) => visitNode(node);

  @override
  R visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => visitNode(node);

  R visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitNode(node);

  @override
  R visitPartDirective(PartDirective node) => visitNode(node);

  @override
  R visitPartOfDirective(PartOfDirective node) => visitNode(node);

  @override
  R visitPostfixExpression(PostfixExpression node) => visitNode(node);

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitNode(node);

  @override
  R visitPrefixExpression(PrefixExpression node) => visitNode(node);

  @override
  R visitPropertyAccess(PropertyAccess node) => visitNode(node);

  @override
  R visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      visitNode(node);

  @override
  R visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  R visitReturnStatement(ReturnStatement node) => visitNode(node);

  @override
  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  R visitShowCombinator(ShowCombinator node) => visitNode(node);

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) => visitNode(node);

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  R visitStringInterpolation(StringInterpolation node) => visitNode(node);

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitNode(node);

  @override
  R visitSuperExpression(SuperExpression node) => visitNode(node);

  @override
  R visitSwitchCase(SwitchCase node) => visitNode(node);

  @override
  R visitSwitchDefault(SwitchDefault node) => visitNode(node);

  @override
  R visitSwitchStatement(SwitchStatement node) => visitNode(node);

  @override
  R visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  R visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  R visitThrowExpression(ThrowExpression node) => visitNode(node);

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitNode(node);

  @override
  R visitTryStatement(TryStatement node) => visitNode(node);

  @override
  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  @override
  R visitTypeName(TypeName node) => visitNode(node);

  @override
  R visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R visitTypeParameterList(TypeParameterList node) => visitNode(node);

  @override
  R visitVariableDeclaration(VariableDeclaration node) => visitNode(node);

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitNode(node);

  @override
  R visitWhileStatement(WhileStatement node) => visitNode(node);

  @override
  R visitWithClause(WithClause node) => visitNode(node);

  @override
  R visitYieldStatement(YieldStatement node) => visitNode(node);
}

/**
 * A helper class used to implement the correct order of visits for a
 * [BreadthFirstVisitor].
 */
class _BreadthFirstChildVisitor extends UnifyingAstVisitor<Object> {
  /**
   * The [BreadthFirstVisitor] being helped by this visitor.
   */
  final BreadthFirstVisitor outerVisitor;

  /**
   * Initialize a newly created visitor to help the [outerVisitor].
   */
  _BreadthFirstChildVisitor(this.outerVisitor);

  @override
  Object visitNode(AstNode node) {
    outerVisitor._queue.add(node);
    return null;
  }
}
