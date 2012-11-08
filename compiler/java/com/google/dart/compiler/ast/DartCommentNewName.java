// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;

/**
 * <code>[new Class.name]</code> in {@link DartComment}.
 */
public final class DartCommentNewName extends DartNode {
  private final String className;
  private final int classOffset;
  private final String constructorName;
  private ClassElement classElement;
  private final int constructorOffset;
  private ConstructorElement constructorElement;

  public DartCommentNewName(String className, int classOffset, String constructorName,
      int constructorOffset) {
    assert className != null;
    assert constructorName != null;
    this.className = className;
    this.classOffset = classOffset;
    this.constructorName = constructorName;
    this.constructorOffset = constructorOffset;
  }

  @Override
  public String toString() {
    if (constructorName.isEmpty()) {
      return className;
    }
    return className + "." + constructorName;
  }

  public void setElements(ClassElement classElement, ConstructorElement constructorElement) {
    this.classElement = classElement;
    this.constructorElement = constructorElement;
  }

  public String getClassName() {
    return className;
  }

  public int getClassOffset() {
    return classOffset;
  }

  public ClassElement getClassElement() {
    return classElement;
  }

  public String getConstructorName() {
    return constructorName;
  }

  public int getConstructorOffset() {
    return constructorOffset;
  }

  public ConstructorElement getConstructorElement() {
    return constructorElement;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitCommentNewName(this);
  }
}
