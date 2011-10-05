// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.Type;

class FieldElementImplementation extends AbstractElement implements FieldElement {
  private final EnclosingElement holder;
  private Modifiers modifiers;
  private Type type;
  private MethodElement getter;
  private MethodElement setter;

  FieldElementImplementation(DartNode node,
                             String name,
                             EnclosingElement holder,
                             Modifiers modifiers) {
    super(node, name);
    this.holder = holder;
    this.modifiers = modifiers;
  }

  @Override
  public Type getType() {
    return type;
  }

  @Override
  public void setType(Type type) {
    this.type = type;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.FIELD;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return holder;
  }

  @Override
  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  public boolean isStatic() {
    return modifiers.isStatic();
  }

  public static FieldElementImplementation fromNode(DartField node,
                                                    EnclosingElement holder,
                                                    Modifiers modifiers) {
    return new FieldElementImplementation(node, node.getName().getTargetName(), holder, modifiers);
  }

  public static FieldElementImplementation fromNode(DartMethodDefinition node,
                                                    EnclosingElement holder,
                                                    Modifiers modifiers) {
    return new FieldElementImplementation(node,
                                          ((DartIdentifier) node.getName()).getTargetName(),
                                          holder,
                                          modifiers);
  }

  @Override
  public MethodElement getGetter() {
    return getter;
  }

  @Override
  public MethodElement getSetter() {
    return setter;
  }

  void setGetter(MethodElement getter) {
    this.getter = getter;
  }

  void setSetter(MethodElement setter) {
    this.setter = setter;
  }
}
