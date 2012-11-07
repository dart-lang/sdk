// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.NodeElement;

/**
 * <code>[new name]</code> in {@link DartComment}.
 */
public final class DartCommentRefName extends DartNode {
  private final String name;
  private NodeElement element;

  public DartCommentRefName(String name) {
    assert name != null;
    this.name = name;
  }

  @Override
  public String toString() {
    return name;
  }

  @Override
  public NodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (NodeElement) element;
  }

  public String getName() {
    return name;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitCommentRefName(this);
  }
}
