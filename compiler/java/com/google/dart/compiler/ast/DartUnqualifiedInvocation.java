// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.VariableElement;

import java.util.List;

/**
 * Unqualified function invocation AST node.
 * <p>
 * {@link DartUnqualifiedInvocation} may be invocation of real method, or invocation of function
 * object in field, or invocation of function object in variable. So, its {@link Element} may be
 * {@link MethodElement}, or {@link FieldElement}, or {@link VariableElement}.
 */
public class DartUnqualifiedInvocation extends DartInvocation {

  private DartIdentifier target;

  public DartUnqualifiedInvocation(DartIdentifier target, List<DartExpression> args) {
    super(args);
    this.target = becomeParentOf(target);
  }

  @Override
  public DartIdentifier getTarget() {
    return target;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(target, visitor);
    visitor.visit(getArguments());
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitUnqualifiedInvocation(this);
  }
}
