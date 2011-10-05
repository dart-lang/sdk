// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Base class that can be extended to visit all child nodes of a given root
 * node.
 */
public class DartVisitor {

  protected static final DartContext LVALUE_CONTEXT = new DartContext() {

    @Override
    public boolean canInsert() {
      return false;
    }

    @Override
    public boolean canRemove() {
      return false;
    }

    @Override
    public void insertAfter(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    @Override
    public void insertBefore(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    @Override
    public boolean isLvalue() {
      return true;
    }

    @Override
    public void removeMe() {
      throw new UnsupportedOperationException();
    }

    @Override
    public void replaceMe(DartVisitable node) {
      throw new UnsupportedOperationException();
    }
  };

  protected static final DartContext UNMODIFIABLE_CONTEXT = new DartContext() {

    @Override
    public boolean canInsert() {
      return false;
    }

    @Override
    public boolean canRemove() {
      return false;
    }

    @Override
    public void insertAfter(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    @Override
    public void insertBefore(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    @Override
    public boolean isLvalue() {
      return false;
    }

    @Override
    public void removeMe() {
      throw new UnsupportedOperationException();
    }

    @Override
    public void replaceMe(DartVisitable node) {
      throw new UnsupportedOperationException();
    }
  };

  public final <T extends DartVisitable> T accept(T node) {
    return this.<T>doAccept(node);
  }

  public final <T extends DartVisitable> void acceptList(List<T> collection) {
    doAcceptList(collection);
  }

  public DartExpression acceptLvalue(DartExpression expr) {
    return doAcceptLvalue(expr);
  }

  public final <T extends DartVisitable> List<T> acceptWithInsertRemove(
      DartNode parent, List<T> collection) {
    return doAcceptWithInsertRemove(parent, collection);
  }

  public boolean didChange() {
    throw new UnsupportedOperationException();
  }

  public void endVisit(DartArrayAccess x, DartContext ctx) {
  }

  public void endVisit(DartArrayLiteral x, DartContext ctx) {
  }

  public void endVisit(DartAssertion x, DartContext ctx) {
  }

  public void endVisit(DartBinaryExpression x, DartContext ctx) {
  }

  public void endVisit(DartBlock x, DartContext ctx) {
  }

  public void endVisit(DartBooleanLiteral x, DartContext ctx) {
  }

  public void endVisit(DartBreakStatement x, DartContext ctx) {
  }

  public void endVisit(DartInvocation x, DartContext ctx) {
  }

  public void endVisit(DartFunctionObjectInvocation x, DartContext ctx) {
  }

  public void endVisit(DartMethodInvocation x, DartContext ctx) {
  }

  public void endVisit(DartUnqualifiedInvocation x, DartContext ctx) {
  }

  public void endVisit(DartSuperConstructorInvocation x, DartContext ctx) {
  }

  public void endVisit(DartRedirectConstructorInvocation x, DartContext ctx) {
  }

  public void endVisit(DartCase x, DartContext ctx) {
  }

  public void endVisit(DartClass x, DartContext ctx) {
  }

  public void endVisit(DartConditional x, DartContext ctx) {
  }

  public void endVisit(DartContinueStatement x, DartContext ctx) {
  }

  public void endVisit(DartDefault x, DartContext ctx) {
  }

  public void endVisit(DartDoubleLiteral x, DartContext ctx) {
  }

  public void endVisit(DartDoWhileStatement x, DartContext ctx) {
  }

  public void endVisit(DartEmptyStatement x, DartContext ctx) {
  }

  public void endVisit(DartExprStmt x, DartContext ctx) {
  }

  public void endVisit(DartField x, DartContext ctx) {
  }

  public void endVisit(DartFieldDefinition x, DartContext ctx) {
  }

  public void endVisit(DartForInStatement x, DartContext ctx) {
  }

  public void endVisit(DartForStatement x, DartContext ctx) {
  }

  public void endVisit(DartFunction x, DartContext ctx) {
  }

  public void endVisit(DartFunctionExpression x, DartContext ctx) {
  }

  public void endVisit(DartFunctionTypeAlias node, DartContext ctx) {
  }

  public void endVisit(DartIdentifier x, DartContext ctx) {
  }

  public void endVisit(DartIfStatement x, DartContext ctx) {
  }

  public void endVisit(DartImportDirective x, DartContext ctx) {
  }

  public void endVisit(DartInitializer dartInitializer, DartContext ctx) {
  }

  public void endVisit(DartIntegerLiteral x, DartContext ctx) {
  }

  public void endVisit(DartLabel x, DartContext ctx) {
  }

  public void endVisit(DartLibraryDirective x, DartContext ctx) {
  }

  public void endVisit(DartMapLiteral x, DartContext ctx) {
  }

  public void endVisit(DartMapLiteralEntry x, DartContext ctx) {
  }

  public void endVisit(DartMethodDefinition x, DartContext ctx) {
  }

  public void endVisit(DartNativeBlock x, DartContext ctx) {
  }

  public void endVisit(DartNativeDirective x, DartContext ctx) {
  }

  public void endVisit(DartNewExpression x, DartContext ctx) {
  }

  public void endVisit(DartNullLiteral x, DartContext ctx) {
  }

  public void endVisit(DartParameter x, DartContext ctx) {
  }

  public void endVisit(DartParameterizedNode x, DartContext ctx) {
  }

  public void endVisit(DartParenthesizedExpression x, DartContext ctx) {
  }

  public void endVisit(DartPropertyAccess x, DartContext ctx) {
  }

  public void endVisit(DartResourceDirective x, DartContext ctx) {
  }

  public void endVisit(DartReturnStatement x, DartContext ctx) {
  }

  public void endVisit(DartSourceDirective x, DartContext ctx) {
  }

  public void endVisit(DartStringLiteral x, DartContext ctx) {
  }

  public void endVisit(DartStringInterpolation x, DartContext ctx) {
  }

  public void endVisit(DartSuperExpression x, DartContext ctx) {
  }

  public void endVisit(DartSwitchStatement x, DartContext ctx) {
  }

  public void endVisit(DartSyntheticErrorExpression node, DartContext ctx) {
  }

  public void endVisit(DartSyntheticErrorStatement x, DartContext ctx) {
  }

  public void endVisit(DartThisExpression x, DartContext ctx) {
  }

  public void endVisit(DartThrowStatement x, DartContext ctx) {
  }

  public void endVisit(DartCatchBlock x, DartContext ctx) {
  }

  public void endVisit(DartTryStatement x, DartContext ctx) {
  }

  public void endVisit(DartTypeNode x, DartContext ctx) {
  }

  public void endVisit(DartTypeParameter x, DartContext ctx) {
  }

  public void endVisit(DartUnaryExpression x, DartContext ctx) {
  }

  public void endVisit(DartUnit x, DartContext ctx) {
  }

  public void endVisit(DartVariable x, DartContext ctx) {
  }

  public void endVisit(DartVariableStatement x, DartContext ctx) {
  }

  public void endVisit(DartWhileStatement x, DartContext ctx) {
  }

  public void endVisit(DartNamedExpression x, DartContext ctx) {
  }

  public void endVisit(DartTypeExpression x, DartContext ctx) {
  }

  public boolean visit(DartArrayAccess x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartArrayLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartAssertion x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartBinaryExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartBlock x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartBooleanLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartBreakStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartFunctionObjectInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartMethodInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartUnqualifiedInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSuperConstructorInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartRedirectConstructorInvocation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartCase x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartClass x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartConditional x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartContinueStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartDefault x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartDoubleLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartDoWhileStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartEmptyStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartExprStmt x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartField x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartFieldDefinition x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartForInStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartForStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartFunction x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartFunctionExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartFunctionTypeAlias node, DartContext ctx) {
    return true;
  }

  public boolean visit(DartIdentifier x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartIfStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartImportDirective x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartInitializer x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartIntegerLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartLabel x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartLibraryDirective x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartMapLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartMapLiteralEntry x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartMethodDefinition x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartNativeBlock x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartNativeDirective x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartNewExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartNullLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartParameter x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartParameterizedNode x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartParenthesizedExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartPropertyAccess x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartResourceDirective x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartReturnStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSourceDirective x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartStringLiteral x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartStringInterpolation x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSuperExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSwitchStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSyntheticErrorExpression node, DartContext ctx) {
    return true;
  }

  public boolean visit(DartSyntheticErrorStatement x, DartContext ctx) {
    return true;    
  }

  public boolean visit(DartThisExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartThrowStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartCatchBlock x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartTryStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartTypeNode x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartTypeParameter x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartUnaryExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartUnit x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartVariable x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartVariableStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartWhileStatement x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartNamedExpression x, DartContext ctx) {
    return true;
  }

  public boolean visit(DartTypeExpression x, DartContext ctx) {
    return true;
  }

  protected <T extends DartVisitable> T doAccept(T node) {
    doTraverse(node, UNMODIFIABLE_CONTEXT);
    return node;
  }

  protected void doAcceptList(List<? extends DartVisitable> collection) {
    for (DartVisitable node : collection) {
      doTraverse(node, UNMODIFIABLE_CONTEXT);
    }
  }

  protected DartExpression doAcceptLvalue(DartExpression expr) {
    doTraverse(expr, LVALUE_CONTEXT);
    return expr;
  }

  protected <T extends DartVisitable> List<T> doAcceptWithInsertRemove(
      DartNode parent, List<T> collection) {
    for (T node : collection) {
      doTraverse(node, UNMODIFIABLE_CONTEXT);
    }
    return collection;
  }

  protected void doTraverse(DartVisitable node, DartContext ctx) {
    node.traverse(this, ctx);
  }
}
