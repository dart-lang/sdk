// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.Type;

class VariableElementImplementation extends AbstractElement implements VariableElement {
  private final ElementKind kind;
  private final Modifiers modifiers;
  private final boolean isNamed;
  private final DartExpression defaultValue;

  // The field element is set for constructor parameters of the form
  // this.foo by the resolver.
  private FieldElement fieldElement;
  private Type type;

  VariableElementImplementation(DartNode node, String name, ElementKind kind, Modifiers modifiers,
                                boolean isNamed, DartExpression defaultValue) {
    super(node, name);
    this.isNamed = isNamed;
    this.kind = kind;
    this.modifiers = modifiers;
    this.defaultValue = defaultValue;
  }

  @Override
  public ElementKind getKind() {
    return kind;
  }

  @Override
  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  void setType(Type type) {
    this.type = type;
  }

  @Override
  public Type getType() {
    return type;
  }

  @Override
  public boolean isNamed() {
    return isNamed;
  }

  @Override
  public DartExpression getDefaultValue() {
    return defaultValue;
  }

  void setParameterInitializerElement(FieldElement element) {
    this.fieldElement = element;
  }

  @Override
  public FieldElement getParameterInitializerElement() {
    return fieldElement;
  }
}
