// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.Type;

import java.util.ArrayList;
import java.util.List;

class MethodElementImplementation extends AbstractElement implements MethodElement {
  private final Modifiers modifiers;
  private final EnclosingElement holder;
  private final ElementKind kind;
  private final List<VariableElement> parameters = new ArrayList<VariableElement>();
  private FunctionType type;

  // TODO(ngeoffray): name, return type, argument types.
  @VisibleForTesting
  MethodElementImplementation(DartFunctionExpression node, String name, Modifiers modifiers) {
    super(node, name);
    this.modifiers = modifiers;
    this.holder = null;
    this.kind = ElementKind.FUNCTION_OBJECT;
  }

  protected MethodElementImplementation(DartMethodDefinition node, String name,
                                        EnclosingElement holder) {
    super(node, name);
    // TODO(jgw): Pass in modifiers directly, not referencing node.
    if (node != null) {
      modifiers = node.getModifiers();
    } else {
      modifiers = Modifiers.NONE;
    }
    this.holder = holder;
    this.kind = ElementKind.METHOD;
  }

  protected MethodElementImplementation(String name, EnclosingElement holder,
                                        Modifiers modifiers) {
    super(null, name);
    this.modifiers = modifiers;
    this.holder = holder;
    this.kind = ElementKind.METHOD;
  }

  private MethodElementImplementation(DartParameter node) {
    super(node, "<anonymous>");
    this.holder = null;
    this.kind = ElementKind.FUNCTION_OBJECT;
    this.modifiers = Modifiers.NONE;
  }

  @Override
  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  public ElementKind getKind() {
    return kind;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return holder;
  }

  @Override
  public boolean isConstructor() {
    return false;
  }

  @Override
  public boolean isStatic() {
    return getModifiers().isStatic();
  }

  @Override
  public List<VariableElement> getParameters() {
    return parameters;
  }

  void addParameter(VariableElement parameter) {
    parameters.add(parameter);
  }

  @Override
  public Type getReturnType() {
    return getType().getReturnType();
  }

  @Override
  void setType(Type type) {
    this.type = (FunctionType) type;
  }

  @Override
  public FunctionType getType() {
    return type;
  }

  @Override
  public FunctionType getFunctionType() {
    return getType();
  }

  public static MethodElementImplementation fromMethodNode(DartMethodDefinition node,
                                                           EnclosingElement holder) {
    assert node.getName() instanceof DartIdentifier;
    String targetName = ((DartIdentifier) node.getName()).getTargetName();
    return new MethodElementImplementation(node, targetName, holder);
  }

  public static MethodElementImplementation fromFunctionExpression(DartFunctionExpression node,
                                                                   Modifiers modifiers) {
    return new MethodElementImplementation(node, node.getFunctionName(), modifiers);
  }
}
