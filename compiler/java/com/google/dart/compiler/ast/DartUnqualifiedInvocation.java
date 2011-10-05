// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Unqualified function invocation AST node.
 */
public class DartUnqualifiedInvocation extends DartInvocation {

  private DartIdentifier target;

  public DartUnqualifiedInvocation(DartIdentifier target,
                                   List<DartExpression> args) {
    super(args);
    this.target = becomeParentOf(target);
  }

  @Override
  public DartIdentifier getTarget() {
    return target;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      target = becomeParentOf(v.accept(target));
      v.acceptWithInsertRemove(this, getArgs());
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    target.accept(visitor);
    visitor.visit(getArgs());
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitUnqualifiedInvocation(this);
  }
}
