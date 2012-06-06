// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

public interface DartPlainVisitor<R> {

  void visit(List<? extends DartNode> nodes);

  R visitArrayAccess(DartArrayAccess node);

  R visitArrayLiteral(DartArrayLiteral node);

  R visitBinaryExpression(DartBinaryExpression node);

  R visitBlock(DartBlock node);

  R visitBooleanLiteral(DartBooleanLiteral node);

  R visitBreakStatement(DartBreakStatement node);

  R visitFunctionObjectInvocation(DartFunctionObjectInvocation node);

  R visitMethodInvocation(DartMethodInvocation node);

  R visitSuperConstructorInvocation(DartSuperConstructorInvocation node);

  R visitCase(DartCase node);

  R visitClass(DartClass node);

  R visitConditional(DartConditional node);

  R visitContinueStatement(DartContinueStatement node);

  R visitDefault(DartDefault node);

  R visitDoubleLiteral(DartDoubleLiteral node);

  R visitDoWhileStatement(DartDoWhileStatement node);

  R visitEmptyStatement(DartEmptyStatement node);

  R visitExprStmt(DartExprStmt node);

  R visitField(DartField node);

  R visitFieldDefinition(DartFieldDefinition node);

  R visitForInStatement(DartForInStatement node);

  R visitForStatement(DartForStatement node);

  R visitFunction(DartFunction node);

  R visitFunctionExpression(DartFunctionExpression node);

  R visitFunctionTypeAlias(DartFunctionTypeAlias node);

  R visitIdentifier(DartIdentifier node);

  R visitIfStatement(DartIfStatement node);

  R visitImportDirective(DartImportDirective node);

  R visitInitializer(DartInitializer node);

  R visitIntegerLiteral(DartIntegerLiteral node);

  R visitLabel(DartLabel node);

  R visitLibraryDirective(DartLibraryDirective node);

  R visitMapLiteral(DartMapLiteral node);

  R visitMapLiteralEntry(DartMapLiteralEntry node);

  R visitMethodDefinition(DartMethodDefinition node);

  R visitNativeDirective(DartNativeDirective node);

  R visitNewExpression(DartNewExpression node);

  R visitNullLiteral(DartNullLiteral node);

  R visitParameter(DartParameter node);

  R visitParameterizedTypeNode(DartParameterizedTypeNode node);

  R visitParenthesizedExpression(DartParenthesizedExpression node);

  R visitPropertyAccess(DartPropertyAccess node);

  R visitTypeNode(DartTypeNode node);

  R visitResourceDirective(DartResourceDirective node);

  R visitReturnStatement(DartReturnStatement node);

  R visitSourceDirective(DartSourceDirective node);

  R visitStringLiteral(DartStringLiteral node);

  R visitStringInterpolation(DartStringInterpolation node);

  R visitSuperExpression(DartSuperExpression node);

  R visitSwitchStatement(DartSwitchStatement node);

  R visitSyntheticErrorExpression(DartSyntheticErrorExpression node);

  R visitSyntheticErrorStatement(DartSyntheticErrorStatement node);

  R visitThisExpression(DartThisExpression node);

  R visitThrowStatement(DartThrowStatement node);

  R visitCatchBlock(DartCatchBlock node);

  R visitTryStatement(DartTryStatement node);

  R visitUnaryExpression(DartUnaryExpression node);

  R visitUnit(DartUnit node);

  R visitUnqualifiedInvocation(DartUnqualifiedInvocation node);

  R visitVariable(DartVariable node);

  R visitVariableStatement(DartVariableStatement node);

  R visitWhileStatement(DartWhileStatement node);

  R visitNamedExpression(DartNamedExpression node);

  R visitTypeExpression(DartTypeExpression node);

  R visitTypeParameter(DartTypeParameter node);

  R visitNativeBlock(DartNativeBlock node);

  R visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node);
}
