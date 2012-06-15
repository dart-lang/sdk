// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.NodeElement;

/**
 * Represents a Dart identifier expression.
 */
public class DartIdentifier extends DartExpression {

  private final String name;
  private NodeElement element;
  private boolean hasResolutionError;

  public DartIdentifier(String name) {
    assert name != null;
    this.name = name;
  }

  public DartIdentifier(DartIdentifier original) {
    this.name = original.name;
  }

  @Override
  public NodeElement getElement() {
    return element;
  }

  @Override
  public boolean isAssignable() {
    return true;
  }

  public String getName() {
    return name;
  }

  @Override
  public void setElement(Element element) {
    this.element = (NodeElement) element;
  }

  /**
   * Specifies that this name was not found it enclosing {@link Element}.
   */
  public void markResolutionError() {
    this.hasResolutionError = true;
  }
  
  /**
   * @return <code>true</code> if we know that this name was not found in its enclosing
   *         {@link Element}, and error was already reported.
   */
  public boolean hasResolutionError() {
    return hasResolutionError;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitIdentifier(this);
  }

  public static boolean isPrivateName(String name) {
    return name.startsWith("_");
  }
}
