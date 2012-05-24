// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;

class VariableElementImplementation extends AbstractNodeElement implements VariableElement {
  private final EnclosingElement owner;
  private final ElementKind kind;
  private final Modifiers modifiers;
  private final boolean isNamed;
  private final DartExpression defaultValue;
  private final SourceInfo nameLocation;

  // The field element is set for constructor parameters of the form
  // this.foo by the resolver.
  private FieldElement fieldElement;
  private Type type;
  private boolean typeInferred;

  VariableElementImplementation(EnclosingElement owner,
      DartNode node,
      SourceInfo nameLocation,
      String name,
      ElementKind kind,
      Modifiers modifiers,
      boolean isNamed,
      DartExpression defaultValue) {
    super(node, name);
    this.owner = owner;
    this.isNamed = isNamed;
    this.kind = kind;
    this.modifiers = modifiers;
    this.defaultValue = defaultValue;
    this.nameLocation = nameLocation;
  }

  @Override
  public ElementKind getKind() {
    return kind;
  }

  @Override
  public SourceInfo getNameLocation() {
    return nameLocation;
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
  
  public void setTypeInferred(boolean typeInferred) {
    this.typeInferred = typeInferred;
  }
  
  @Override
  public boolean isTypeInferred() {
    return typeInferred;
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

  @Override
  public EnclosingElement getEnclosingElement() {
    return owner;
  }
}
