// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

abstract class AbstractNodeElement implements Element, NodeElement {
  private final DartNode node;
  private final String name;
  private SourceInfo sourceInfo;

  AbstractNodeElement(DartNode node, String name) {
    // TODO(scheglov) in the future we will not use ASTNode and remove null check
    this.sourceInfo = node != null ? node.getSourceInfo() : SourceInfo.UNKNOWN;
    this.node = node;
    this.name = name;
  }

  @Override
  public DartNode getNode() {
    return node;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public String getOriginalName() {
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
  public DartObsoleteMetadata getMetadata() {
    return DartObsoleteMetadata.EMPTY;
  }

  @Override
  public Modifiers getModifiers() {
    return Modifiers.NONE;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return null;
  }

  @Override
  public SourceInfo getNameLocation() {
    return sourceInfo;
  }
  
  @Override
  public final SourceInfo getSourceInfo() {
    return sourceInfo;
  }
}
