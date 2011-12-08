// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;

import java.util.Collections;
import java.util.List;

/**
 * {@link ConstructorElement} for implicit default constructor.
 */
public class SyntheticDefaultConstructorElement implements ConstructorElement {
  private final DartMethodDefinition method;
  private final ClassElement enclosingClass;
  private final FunctionType functionType;
  private ConstructorElement defaultConstructor;

  public SyntheticDefaultConstructorElement(DartMethodDefinition method,
      ClassElement enclosingClass,
      CoreTypeProvider typeProvider) {
    this.method = method;
    this.enclosingClass = enclosingClass;
    if (typeProvider != null) {
      this.functionType =
          Types.makeFunctionType(
              null,
              typeProvider.getFunctionType().getElement(),
              getParameters(),
              typeProvider.getDynamicType(),
              Collections.<TypeVariable>emptyList());
    } else {
      functionType = null;
    }
  }

  @Override
  public String getOriginalSymbolName() {
    return getName();
  }

  @Override
  public DartNode getNode() {
    return method;
  }

  @Override
  public void setNode(DartLabel node) {
  }

  @Override
  public boolean isDynamic() {
    return false;
  }

  @Override
  public Type getType() {
    return functionType;
  }

  @Override
  public String getName() {
    return "";
  }

  @Override
  public Modifiers getModifiers() {
    return Modifiers.NONE;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.CONSTRUCTOR;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return enclosingClass;
  }

  @Override
  public boolean isStatic() {
    return false;
  }

  @Override
  public boolean isConstructor() {
    return true;
  }

  @Override
  public ConstructorElement getDefaultConstructor() {
    return defaultConstructor;
  }

  @Override
  public void setDefaultConstructor(ConstructorElement defaultConstructor) {
    this.defaultConstructor = defaultConstructor;
  }

  @Override
  public Type getReturnType() {
    return functionType.getReturnType();
  }

  @Override
  public List<VariableElement> getParameters() {
    return Collections.emptyList();
  }

  @Override
  public FunctionType getFunctionType() {
    return functionType;
  }

  @Override
  public ClassElement getConstructorType() {
    return enclosingClass;
  }

  @Override
  public boolean isInterface() {
    return false;
  }

  @Override
  public Iterable<Element> getMembers() {
    return Collections.emptyList();
  }

  @Override
  public Element lookupLocalElement(String name) {
    return null;
  }
}
