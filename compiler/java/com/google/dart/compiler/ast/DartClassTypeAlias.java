// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.resolver.ClassNodeElement;
import com.google.dart.compiler.resolver.Element;

import java.util.List;

/**
 * Instances of the class {@code DartClassTypeAlias} represent a class type alias.
 */
public class DartClassTypeAlias extends DartDeclaration<DartIdentifier> {
  private final NodeList<DartTypeParameter> typeParameters = NodeList.create(this);
  private final Modifiers modifiers;
  private final DartTypeNode superclass;
  private final NodeList<DartTypeNode> mixins = NodeList.create(this);
  private final NodeList<DartTypeNode> interfaces = NodeList.create(this);
  private ClassNodeElement element;

  public DartClassTypeAlias(DartIdentifier name, List<DartTypeParameter> typeParameters,
      Modifiers modifiers, DartTypeNode superclass, List<DartTypeNode> mixins,
      List<DartTypeNode> interfaces) {
    super(name);
    this.typeParameters.addAll(typeParameters);
    this.modifiers = modifiers;
    this.superclass = becomeParentOf(superclass);
    this.mixins.addAll(mixins);
    this.interfaces.addAll(interfaces);
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  public Modifiers getModifiers() {
    return modifiers;
  }

  public boolean isAbstract() {
    return modifiers.isAbstract();
  }

  public DartTypeNode getSuperclass() {
    return superclass;
  }

  public NodeList<DartTypeNode> getMixins() {
    return mixins;
  }

  public List<DartTypeNode> getInterfaces() {
    return interfaces;
  }

  public String getClassName() {
    if (getName() == null) {
      return null;
    }
    return getName().getName();
  }

  @Override
  public ClassNodeElement getElement() {
    return element;
  }

  @Override
  public void setElement(Element element) {
    this.element = (ClassNodeElement) element;
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    super.visitChildren(visitor);
    typeParameters.accept(visitor);
    superclass.accept(visitor);
    mixins.accept(visitor);
    interfaces.accept(visitor);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitClassTypeAlias(this);
  }
}
