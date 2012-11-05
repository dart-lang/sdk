// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.Source;
import com.google.dart.compiler.common.SourceInfo;

public class DartComment extends DartNode {
  private final NodeList<DartIdentifier> identifiers = NodeList.create(this);

  @SuppressWarnings("unused")
  private static final long serialVersionUID = 6066713446767517627L;

  public static enum Style {
    END_OF_LINE, BLOCK, DART_DOC;
  }

  private Style style;

  public DartComment(Source source, int start, int length, Style style) {
    setSourceInfo(new SourceInfo(source, start, length));
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
  
  /**
   * Adds <code>[id]</code> reference.
   */
  public void addTokenIdentifier(DartIdentifier id) {
    identifiers.add(id);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    identifiers.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitComment(this);
  }

}
