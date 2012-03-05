// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;

/**
 * Represents a Dart array access expression (a[b]).
 */
public class DartArrayAccess extends DartExpression implements ElementReference {

  private DartExpression target;
  private DartExpression key;
  private Element referencedElement;

  public DartArrayAccess(DartExpression target, DartExpression key) {
    this.target = becomeParentOf(target);
    this.key = becomeParentOf(key);
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public DartExpression getKey() {
    return key;
  }

  public DartExpression getTarget() {
    return target;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    target.accept(visitor);
    key.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitArrayAccess(this);
  }

  @Override
  public Element getReferencedElement() {
    return referencedElement;
  }

  @Override
  public void setReferencedElement(Element element) {
    referencedElement = element;
  }
}
