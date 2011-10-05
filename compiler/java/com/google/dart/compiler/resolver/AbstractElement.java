// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

abstract class AbstractElement implements Element {
  private DartNode node;
  private final String name;

  AbstractElement(DartNode node, String name) {
    this.node = node;
    this.name = name;
  }

  @Override
  public DartNode getNode() {
    return node;
  }

  // This method can be removed if NormalizeAst is integrated in Normalizer.
  @Override
  public void setNode(DartLabel node) {
    this.node = node;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public String getOriginalSymbolName() {
    return name;
  }

  @Override
  public abstract ElementKind getKind();

  @Override
  public final String toString() {
    return getKind() + " " + getName();
  }

  @Override
  public Type getType() {
    return Types.newDynamicType();
  }

  void setType(Type type) {
    throw new UnsupportedOperationException();
  }

  @Override
  public boolean isDynamic() {
    return false;
  }

  @Override
  public Modifiers getModifiers() {
    return Modifiers.NONE;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return null;
  }
}
