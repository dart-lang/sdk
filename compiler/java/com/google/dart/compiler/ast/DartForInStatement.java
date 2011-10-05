// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Represents a Dart 'for (.. in ..)' statement.
 */
public class DartForInStatement extends DartStatement {

  private DartStatement setup;
  private DartExpression iterable;
  private DartStatement body;

  private DartStatement normalizedNode = this;

  public DartForInStatement(DartStatement setup,
                            DartExpression iterable,
                            DartStatement body) {
    this.setup = becomeParentOf(setup);
    this.iterable = becomeParentOf(iterable);
    this.body = becomeParentOf(body);
  }

  public DartStatement getBody() {
    return body;
  }

  public DartExpression getIterable() {
    return iterable;
  }

  public void setNormalizedNode(DartStatement statement) {
    normalizedNode = statement;
  }

  @Override
  public DartStatement getNormalizedNode() {
    return normalizedNode;
  }

  public boolean introducesVariable() {
    return setup instanceof DartVariableStatement;
  }

  public DartIdentifier getIdentifier() {
    assert !introducesVariable();
    return (DartIdentifier) ((DartExprStmt) setup).getExpression();
  }

  public DartVariableStatement getVariableStatement() {
    assert introducesVariable();
    return (DartVariableStatement) setup;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      setup = becomeParentOf(v.accept(setup));
      iterable = becomeParentOf(v.accept(iterable));
      body = becomeParentOf(v.accept(body));
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    setup.accept(visitor);
    iterable.accept(visitor);
    body.accept(visitor);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitForInStatement(this);
  }
}
