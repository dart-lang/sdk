// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.LabelElement;

/**
 * Base class of {@link DartBreakStatement} and {@link DartContinueStatement}.
 */
public abstract class DartGotoStatement extends DartStatement {

  private DartIdentifier label;
  private LabelElement element;

  public DartGotoStatement(DartIdentifier label) {
    this.label = becomeParentOf(label);
  }

  public DartIdentifier getLabel() {
    return label;
  }

  public String getTargetName() {
    if (label == null) {
      return null;
    }
    return label.getName();
  }

  public void setLabel(DartIdentifier newLabel) {
    label = newLabel;
  }

  @Override
  public LabelElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (LabelElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    safelyVisitChild(label, visitor);
  }
}
