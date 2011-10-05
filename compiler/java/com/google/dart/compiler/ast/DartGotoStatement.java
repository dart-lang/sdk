// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.Symbol;

/**
 * Base class of {@link DartBreakStatement} and {@link DartContinueStatement}.
 */
public abstract class DartGotoStatement extends DartStatement {

  private DartIdentifier label;
  private Symbol targetSymbol;

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
    return label.getTargetName();
  }

  public Symbol getTargetSymbol() {
    return targetSymbol;
  }

  public void setLabel(DartIdentifier newLabel) {
    label = newLabel;
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.targetSymbol = symbol;
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    if (label != null) {
      label.accept(visitor);
    }
  }
}
