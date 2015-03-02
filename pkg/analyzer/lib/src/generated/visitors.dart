// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.ast.visitors;

import 'package:analyzer/src/generated/ast.dart';

/// An [AstVisitor] that delegates calls to visit methods to all [delegates]
/// before calling [visitChildren].
class DelegatingAstVisitor<T> implements AstVisitor<T> {
  Iterable<AstVisitor<T>> _delegates;
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
  T visitForStatement(ForStatement node) {
    _delegates.forEach((delegate) => delegate.visitForStatement(node));
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
  T visitPrefixExpression(PrefixExpression node) {
    _delegates.forEach((delegate) => delegate.visitPrefixExpression(node));
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
