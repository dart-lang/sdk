// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * A visitor for abstract syntax tree.
 *
 * <pre>
 *
 * public R visitArrayAccess(DartArrayAccess node) {
 *   // Actions before visiting subnodes.
 *   node.visitChildren(this);
 *   // Actions after visiting subnodes.
 *   return node;
 * }
 * </pre>
 *
 * <p>
 * In addition, this visitor takes advantage of the AST-node class hierarchy and makes it easy to
 * perform an action for, for example, all statements:
 *
 * <pre>
 *
 * public R visitStatement(DartStatement node) {
 *   // Action that must be performed for all statements.
 * }
 * </pre>
 */
public class ASTVisitor<R> {

  public R visitNode(DartNode node) {
    node.visitChildren(this);
    return null;
  }

  public R visitDirective(DartDirective node) {
    return visitNode(node);
  }

  public R visitInvocation(DartInvocation node) {
    return visitExpression(node);
  }

  public R visitExpression(DartExpression node) {
    return visitNode(node);
  }

  public R visitStatement(DartStatement node) {
    return visitNode(node);
  }

  public R visitLiteral(DartLiteral node) {
    return visitExpression(node);
  }

  public R visitGotoStatement(DartGotoStatement node) {
    return visitStatement(node);
  }

  public R visitSwitchMember(DartSwitchMember node) {
    return visitNode(node);
  }

  public R visitDeclaration(DartDeclaration<?> node) {
    return visitNode(node);
  }

  public R visitClassMember(DartClassMember<?> node) {
    return visitDeclaration(node);
  }

  public R visitComment(DartComment node) {
    return visitNode(node);
  }

  public R visitAnnotation(DartAnnotation node) {
    return visitNode(node);
  }

  public R visitArrayAccess(DartArrayAccess node) {
    return visitExpression(node);
  }

  public R visitArrayLiteral(DartArrayLiteral node) {
    return visitTypedLiteral(node);
  }

  public R visitBinaryExpression(DartBinaryExpression node) {
    return visitExpression(node);
  }

  public R visitBlock(DartBlock node) {
    return visitStatement(node);
  }
  
  public R visitReturnBlock(DartReturnBlock node) {
    return visitBlock(node);
  }

  public R visitBooleanLiteral(DartBooleanLiteral node) {
    return visitLiteral(node);
  }

  public R visitBreakStatement(DartBreakStatement node) {
    return visitGotoStatement(node);
  }

  public R visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
    return visitInvocation(node);
  }

  public R visitMethodInvocation(DartMethodInvocation node) {
    return visitInvocation(node);
  }

  public R visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
    return visitInvocation(node);
  }

  public R visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
    return visitInvocation(node);
  }

  public R visitCase(DartCase node) {
    return visitSwitchMember(node);
  }

  public R visitClass(DartClass node) {
    return visitDeclaration(node);
  }

  public R visitConditional(DartConditional node) {
    return visitExpression(node);
  }

  public R visitContinueStatement(DartContinueStatement node) {
    return visitGotoStatement(node);
  }

  public R visitDefault(DartDefault node) {
    return visitSwitchMember(node);
  }

  public R visitDoubleLiteral(DartDoubleLiteral node) {
    return visitLiteral(node);
  }

  public R visitDoWhileStatement(DartDoWhileStatement node) {
    return visitStatement(node);
  }

  public R visitEmptyStatement(DartEmptyStatement node) {
    return visitStatement(node);
  }

  public R visitExprStmt(DartExprStmt node) {
    return visitStatement(node);
  }

  public R visitField(DartField node) {
    return visitClassMember(node);
  }

  public R visitFieldDefinition(DartFieldDefinition node) {
    return visitNode(node);
  }

  public R visitForInStatement(DartForInStatement node) {
    return visitStatement(node);
  }

  public R visitForStatement(DartForStatement node) {
    return visitStatement(node);
  }

  public R visitFunction(DartFunction node) {
    return visitNode(node);
  }

  public R visitFunctionExpression(DartFunctionExpression node) {
    return visitExpression(node);
  }

  public R visitFunctionTypeAlias(DartFunctionTypeAlias node) {
    return visitDeclaration(node);
  }

  public R visitIdentifier(DartIdentifier node) {
    return visitExpression(node);
  }

  public R visitIfStatement(DartIfStatement node) {
    return visitStatement(node);
  }

  public R visitImportCombinator(ImportCombinator node) {
    return visitNode(node);
  } 

  public R visitImportDirective(DartImportDirective node) {
    return visitDirective(node);
  }

  public R visitImportHideCombinator(ImportHideCombinator node) {
    return visitImportCombinator(node);
  } 

  public R visitImportShowCombinator(ImportShowCombinator node) {
    return visitImportCombinator(node);
  } 

  public R visitInitializer(DartInitializer node) {
    return visitNode(node);
  }

  public R visitIntegerLiteral(DartIntegerLiteral node) {
    return visitLiteral(node);
  }

  public R visitLabel(DartLabel node) {
    return visitStatement(node);
  }

  public R visitLibraryDirective(DartLibraryDirective node) {
    return visitDirective(node);
  }

  public R visitTypedLiteral(DartTypedLiteral node) {
    return visitExpression(node);
  }
  
  public R visitMapLiteral(DartMapLiteral node) {
    return visitTypedLiteral(node);
  }

  public R visitMapLiteralEntry(DartMapLiteralEntry node) {
    return visitNode(node);
  }

  public R visitMethodDefinition(DartMethodDefinition node) {
    return visitClassMember(node);
  }

  public R visitNativeDirective(DartNativeDirective node) {
    return visitDirective(node);
  }

  public R visitNewExpression(DartNewExpression node) {
    return visitInvocation(node);
  }

  public R visitNullLiteral(DartNullLiteral node) {
    return visitLiteral(node);
  }

  public R visitParameter(DartParameter node) {
    return visitDeclaration(node);
  }

  public R visitParameterizedTypeNode(DartParameterizedTypeNode node) {
    return visitExpression(node);
  }

  public R visitParenthesizedExpression(DartParenthesizedExpression node) {
    return visitExpression(node);
  }

  public R visitPartOfDirective(DartPartOfDirective node) {
    return visitDirective(node);
  }

  public R visitPropertyAccess(DartPropertyAccess node) {
    return visitExpression(node);
  }

  public R visitTypeNode(DartTypeNode node) {
    return visitNode(node);
  }

  public R visitReturnStatement(DartReturnStatement node) {
    return visitStatement(node);
  }

  public R visitSourceDirective(DartSourceDirective node) {
    return visitDirective(node);
  }

  public R visitStringLiteral(DartStringLiteral node) {
    return visitLiteral(node);
  }

  public R visitStringInterpolation(DartStringInterpolation node) {
    return visitLiteral(node);
  }

  public R visitSuperExpression(DartSuperExpression node) {
    return visitExpression(node);
  }

  public R visitSwitchStatement(DartSwitchStatement node) {
    return visitStatement(node);
  }

  public R visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
    return visitExpression(node);
  }

  public R visitSyntheticErrorIdentifier(DartSyntheticErrorIdentifier node) {
    return visitIdentifier(node);
  }

  public R visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
    return visitStatement(node);
  }

  public R visitThisExpression(DartThisExpression node) {
    return visitExpression(node);
  }

  public R visitThrowStatement(DartThrowStatement node) {
    return visitStatement(node);
  }

  public R visitCatchBlock(DartCatchBlock node) {
    return visitStatement(node);
  }

  public R visitTryStatement(DartTryStatement node) {
    return visitStatement(node);
  }

  public R visitUnaryExpression(DartUnaryExpression node) {
    return visitExpression(node);
  }

  public R visitUnit(DartUnit node) {
    return visitNode(node);
  }

  public R visitVariable(DartVariable node) {
    return visitDeclaration(node);
  }

  public R visitVariableStatement(DartVariableStatement node) {
    return visitStatement(node);
  }

  public R visitWhileStatement(DartWhileStatement node) {
    return visitStatement(node);
  }

  public void visit(List<? extends DartNode> nodes) {
    if (nodes != null) {
      for (DartNode node : nodes) {
        node.accept(this);
      }
    }
  }

  public R visitNamedExpression(DartNamedExpression node) {
    return visitExpression(node);
  }

  public R visitTypeExpression(DartTypeExpression node) {
    return visitExpression(node);
  }

  public R visitTypeParameter(DartTypeParameter node) {
    return visitDeclaration(node);
  }

  public R visitNativeBlock(DartNativeBlock node) {
    return visitBlock(node);
  }

  public R visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
    return visitInvocation(node);
  }
}
