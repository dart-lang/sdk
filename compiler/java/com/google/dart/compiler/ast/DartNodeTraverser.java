// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * An alternative visitor implementation to {@link DartVisitor}.
 *
 * <p>With DartVisitor, you would write:
 *
 * <pre>
 * @Override
 * public boolean visit(DartArrayAccess node, DartContext ctx) {
 *   // Actions before visiting subnodes.
 *   return true;
 * }
 *
 * @Override
 * public R endVisit(DartArrayAccess x, DartContext ctx) {
 *   // Actions after visiting subnodes.
 * }
 * </pre>
 *
 * <p>With DartNodeTraverser, the pre- and post-actions are combined
 * in the same method:
 *
 * <pre>
 * @Override
 * public R visitArrayAccess(DartArrayAccess node) {
 *   // Actions before visiting subnodes.
 *   node.visitChildren(this);
 *   // Actions after visiting subnodes.
 *   return node;
 * }
 * </pre>
 *
 * <p>In addition, this visitor takes advantage of the AST-node class
 * hierarchy and makes it easy to perform an action for, for example,
 * all statements:
 *
 * <pre>
 * @Override
 * public R visitStatement(DartStatement node) {
 *   // Action that must be performed for all statements.
 * }
 * </pre>
 */
public class DartNodeTraverser<R> implements DartPlainVisitor<R> {

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

  @Override
  public R visitArrayAccess(DartArrayAccess node) {
    return visitExpression(node);
  }

  @Override
  public R visitArrayLiteral(DartArrayLiteral node) {
    return visitExpression(node);
  }

  @Override
  public R visitAssertion(DartAssertion node) {
    return visitStatement(node);
  }

  @Override
  public R visitBinaryExpression(DartBinaryExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitBlock(DartBlock node) {
    return visitStatement(node);
  }

  @Override
  public R visitBooleanLiteral(DartBooleanLiteral node) {
    return visitLiteral(node);
  }

  @Override
  public R visitBreakStatement(DartBreakStatement node) {
    return visitGotoStatement(node);
  }

  @Override
  public R visitFunctionObjectInvocation(DartFunctionObjectInvocation node) {
    return visitInvocation(node);
  }

  @Override
  public R visitMethodInvocation(DartMethodInvocation node) {
    return visitInvocation(node);
  }

  @Override
  public R visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
    return visitInvocation(node);
  }

  @Override
  public R visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
    return visitInvocation(node);
  }

  @Override
  public R visitCase(DartCase node) {
    return visitSwitchMember(node);
  }

  @Override
  public R visitClass(DartClass node) {
    return visitDeclaration(node);
  }

  @Override
  public R visitConditional(DartConditional node) {
    return visitExpression(node);
  }

  @Override
  public R visitContinueStatement(DartContinueStatement node) {
    return visitGotoStatement(node);
  }

  @Override
  public R visitDefault(DartDefault node) {
    return visitSwitchMember(node);
  }

  @Override
  public R visitDoubleLiteral(DartDoubleLiteral node) {
    return visitLiteral(node);
  }

  @Override
  public R visitDoWhileStatement(DartDoWhileStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitEmptyStatement(DartEmptyStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitExprStmt(DartExprStmt node) {
    return visitStatement(node);
  }

  @Override
  public R visitField(DartField node) {
    return visitClassMember(node);
  }

  @Override
  public R visitFieldDefinition(DartFieldDefinition node) {
    return visitNode(node);
  }

  @Override
  public R visitForInStatement(DartForInStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitForStatement(DartForStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitFunction(DartFunction node) {
    return visitNode(node);
  }

  @Override
  public R visitFunctionExpression(DartFunctionExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitFunctionTypeAlias(DartFunctionTypeAlias node) {
    return visitDeclaration(node);
  }

  @Override
  public R visitIdentifier(DartIdentifier node) {
    return visitExpression(node);
  }

  @Override
  public R visitIfStatement(DartIfStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitImportDirective(DartImportDirective node) {
    return visitDirective(node);
  }

  @Override
  public R visitInitializer(DartInitializer node) {
    return visitNode(node);
  }

  @Override
  public R visitIntegerLiteral(DartIntegerLiteral node) {
    return visitLiteral(node);
  }

  @Override
  public R visitLabel(DartLabel node) {
    return visitStatement(node);
  }

  @Override
  public R visitLibraryDirective(DartLibraryDirective node) {
    return visitDirective(node);
  }

  @Override
  public R visitMapLiteral(DartMapLiteral node) {
    return visitExpression(node);
  }

  @Override
  public R visitMapLiteralEntry(DartMapLiteralEntry node) {
    return visitNode(node);
  }

  @Override
  public R visitMethodDefinition(DartMethodDefinition node) {
    return visitClassMember(node);
  }

  @Override
  public R visitNativeDirective(DartNativeDirective node) {
    return visitDirective(node);
  }

  @Override
  public R visitNewExpression(DartNewExpression node) {
    return visitInvocation(node);
  }

  @Override
  public R visitNullLiteral(DartNullLiteral node) {
    return visitLiteral(node);
  }

  @Override
  public R visitParameter(DartParameter node) {
    return visitDeclaration(node);
  }

  @Override
  public R visitParameterizedNode(DartParameterizedNode node) {
    return visitExpression(node);
  }

  @Override
  public R visitParenthesizedExpression(DartParenthesizedExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitPropertyAccess(DartPropertyAccess node) {
    return visitExpression(node);
  }

  @Override
  public R visitTypeNode(DartTypeNode node) {
    return visitNode(node);
  }

  @Override
  public R visitResourceDirective(DartResourceDirective node) {
    return visitDirective(node);
  }

  @Override
  public R visitReturnStatement(DartReturnStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitSourceDirective(DartSourceDirective node) {
    return visitDirective(node);
  }

  @Override
  public R visitStringLiteral(DartStringLiteral node) {
    return visitLiteral(node);
  }

  @Override
  public R visitStringInterpolation(DartStringInterpolation node) {
    return visitLiteral(node);
  }

  @Override
  public R visitSuperExpression(DartSuperExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitSwitchStatement(DartSwitchStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitSyntheticErrorExpression(DartSyntheticErrorExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitSyntheticErrorStatement(DartSyntheticErrorStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitThisExpression(DartThisExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitThrowStatement(DartThrowStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitCatchBlock(DartCatchBlock node) {
    return visitStatement(node);
  }

  @Override
  public R visitTryStatement(DartTryStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitUnaryExpression(DartUnaryExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitUnit(DartUnit node) {
    return visitNode(node);
  }

  @Override
  public R visitVariable(DartVariable node) {
    return visitDeclaration(node);
  }

  @Override
  public R visitVariableStatement(DartVariableStatement node) {
    return visitStatement(node);
  }

  @Override
  public R visitWhileStatement(DartWhileStatement node) {
    return visitStatement(node);
  }

  @Override
  public void visit(List<? extends DartNode> nodes) {
    if (nodes != null) {
      for (DartNode node : nodes) {
        node.accept(this);
      }
    }
  }

  @Override
  public R visitNamedExpression(DartNamedExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitTypeExpression(DartTypeExpression node) {
    return visitExpression(node);
  }

  @Override
  public R visitTypeParameter(DartTypeParameter node) {
    return visitDeclaration(node);
  }

  @Override
  public R visitNativeBlock(DartNativeBlock node) {
    return visitBlock(node);
  }

  @Override
  public R visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
    return visitInvocation(node);
  }
}
