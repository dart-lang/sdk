// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.MethodNodeElement;

/**
 * Represents a Dart array access expression (a[b]).
 */
public class DartArrayAccess extends DartExpression {

  private DartExpression target;
  private boolean isCascade;
  private DartExpression key;
  private MethodNodeElement element;

  public DartArrayAccess(DartExpression target, DartExpression key) {
    this(target, false, key);
  }

  public DartArrayAccess(DartExpression target, boolean isCascade, DartExpression key) {
    this.target = becomeParentOf(target);
    this.isCascade = isCascade;
    this.key = becomeParentOf(key);
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public boolean isCascade() {
    return isCascade;
  }

  public DartExpression getKey() {
    return key;
  }

  public DartExpression getTarget() {
    return target;
  }

  public DartExpression getRealTarget() {
    if (isCascade) {
      DartNode ancestor = getParent();
      while (!(ancestor instanceof DartCascadeExpression)) {
        if (ancestor == null) {
          return target;
        }
        ancestor = ancestor.getParent();
      }
      return ((DartCascadeExpression) ancestor).getTarget();
    }
    return target;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(target, visitor);
    safelyVisitChild(key, visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitArrayAccess(this);
  }

  @Override
  public MethodNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (MethodNodeElement) element;
  }
}
