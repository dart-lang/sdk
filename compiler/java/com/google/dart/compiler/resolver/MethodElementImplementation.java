// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.ImmutableSet;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.Type;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

class MethodElementImplementation extends AbstractNodeElement implements MethodNodeElement {
  private final DartObsoleteMetadata metadata;
  private final Modifiers modifiers;
  private final EnclosingElement holder;
  private final ElementKind kind;
  private final List<VariableElement> parameters = new ArrayList<VariableElement>();
  private FunctionType type;
  private final SourceInfo nameLocation;
  private final boolean hasBody;
  private Set<Element> overridden = ImmutableSet.of();

  // TODO(ngeoffray): name, return type, argument types.
  @VisibleForTesting
  MethodElementImplementation(DartFunctionExpression node, String name, Modifiers modifiers) {
    super(node, name);
    this.metadata = DartObsoleteMetadata.EMPTY;
    this.modifiers = modifiers;
    this.hasBody = true;
    this.holder = findParentEnclosingElement(node);
    this.kind = ElementKind.FUNCTION_OBJECT;
    if (node != null && node.getName() != null) {
      this.nameLocation = node.getName().getSourceInfo();
    } else {
      this.nameLocation = SourceInfo.UNKNOWN;
    }
  }

  protected MethodElementImplementation(DartMethodDefinition node, String name,
                                        EnclosingElement holder) {
    super(node, name);
    if (node != null) {
      this.metadata = node.getObsoleteMetadata();
      this.modifiers = node.getModifiers();
      this.nameLocation = node.getName().getSourceInfo();
      DartBlock body = node.getFunction().getBody();
      this.hasBody = body != null && !(body instanceof DartNativeBlock);
    } else {
      this.metadata = DartObsoleteMetadata.EMPTY;
      this.modifiers = Modifiers.NONE;
      this.nameLocation = SourceInfo.UNKNOWN;
      this.hasBody = false;
    }
    this.holder = holder;
    this.kind = ElementKind.METHOD;
  }

  @Override
  public DartObsoleteMetadata getMetadata() {
    return metadata;
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
  
  @Override
  public boolean hasBody() {
    return hasBody;
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

  public static MethodElementImplementation fromMethodNode(DartMethodDefinition node,
                                                           EnclosingElement holder) {
    String targetName;
    if(node.getName() instanceof DartIdentifier) {
      targetName = ((DartIdentifier) node.getName()).getName();
    } else {
      // Visit the unknown node to generate a string for our use.
      targetName = node.toSource();
    }
    return new MethodElementImplementation(node, targetName, holder);
  }

  public static MethodElementImplementation fromFunctionExpression(DartFunctionExpression node,
                                                                   Modifiers modifiers) {
    return new MethodElementImplementation(node, node.getFunctionName(), modifiers);
  }

  /**
   * @return the innermost {@link EnclosingElement} for given {@link DartNode}, may be
   *         <code>null</code>.
   */
  private static EnclosingElement findParentEnclosingElement(DartNode node) {
    while (node != null && node.getParent() != null) {
      node = node.getParent();
      boolean isEnclosingNode = node instanceof DartClass || node instanceof DartMethodDefinition
          || node instanceof DartFunctionExpression;
      if (isEnclosingNode && node.getElement() instanceof EnclosingElement) {
        return (EnclosingElement) node.getElement();
      }
    }
    return null;
  }
  
  @Override
  public SourceInfo getNameLocation() {
    return nameLocation;
  }

  public void setOverridden(Set<Element> overridden) {
    this.overridden = overridden;
  }
  
  public Set<Element> getOverridden() {
    return overridden;
  }
}
