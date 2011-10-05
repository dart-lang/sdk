// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.Source;

public class DartComment extends DartNode {

  private static final long serialVersionUID = 6066713446767517627L;

  public static enum Style {
    END_OF_LINE, BLOCK, DART_DOC;
  }

  private Style style;

  public DartComment(Source source, int start, int length, int line, int col, Style style) {
    setSourceLocation(source, line, col, start, length);
    this.style = style;
  }

  /**
   * Return <code>true<code> if this comment is a block comment.
   *
   * @return <code>true<code> if this comment is a block comment
   */
  public boolean isBlock() {
    return style == Style.BLOCK;
  }

  /**
   * Return <code>true<code> if this comment is a DartDoc comment.
   *
   * @return <code>true<code> if this comment is a DartDoc comment
   */
  public boolean isDartDoc() {
    return style == Style.DART_DOC;
  }

  /**
   * Return <code>true<code> if this comment is an end-of-line comment.
   *
   * @return <code>true<code> if this comment is an end-of-line comment
   */
  public boolean isEndOfLine() {
    return style == Style.END_OF_LINE;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return null;
  }

}
