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
