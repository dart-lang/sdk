// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.Source;
import com.google.dart.compiler.common.SourceInfo;

import java.util.List;

public class DartComment extends DartNode {
  private final NodeList<DartCommentRefName> refNames = NodeList.create(this);
  private final NodeList<DartCommentNewName> newNames = NodeList.create(this);

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
  public void addRefName(DartCommentRefName name) {
    refNames.add(name);
  }

  public NodeList<DartCommentRefName> getRefNames() {
    return refNames;
  }

  /**
   * Adds <code>[new Class]</code> or <b>[new Class.name]</b> reference.
   */
  public void addNewName(DartCommentNewName name) {
    newNames.add(name);
  }

  /**
   * @return the <code>[new Class]</code> or <b>[new Class.name]</b> references.
   */
  public List<DartCommentNewName> getNewNames() {
    return newNames;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    refNames.accept(visitor);
    newNames.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitComment(this);
  }

}
