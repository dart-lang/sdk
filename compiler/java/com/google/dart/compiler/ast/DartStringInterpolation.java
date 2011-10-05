// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Preconditions;

import java.util.List;

/**
 * Represents a Dart string interpolation of the form: "1 ${a} 2 ${b} 3".
 */
public class DartStringInterpolation extends DartLiteral {

  /**
   * Literal string portions. The interpolation alternates between strings and
   * expressions. We preserve the invariant that {@code string.size() =
   * expressions.size() + 1}. Empty string constants are used to represent
   * adjacent expressions (e.g. $"${a} ${b}${c}" is represented by 4 strings
   * ("", " ", "", "") and 3 expressions (#(){a}, #(){b}, #(){c}).
   */
  private List<DartStringLiteral> strings;

  /** Embedded expressions (see {@link strings} for details). */
  private List<DartExpression> expressions;

  public DartStringInterpolation(List<DartStringLiteral> strings,
      List<DartExpression> expressions) {
    Preconditions.checkNotNull(strings);
    Preconditions.checkNotNull(expressions);
    Preconditions.checkArgument(strings.size() == expressions.size() + 1);
    this.strings = becomeParentOf(strings);
    this.expressions = becomeParentOf(expressions);
  }

  public List<DartStringLiteral> getStrings() {
    return strings;
  }

  public List<DartExpression> getExpressions() {
    return expressions;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      v.acceptWithInsertRemove(this, strings);
      v.acceptWithInsertRemove(this, expressions);
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    visitor.visit(strings);
    visitor.visit(expressions);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitStringInterpolation(this);
  }
}
