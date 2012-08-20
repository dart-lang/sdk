// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * The abstract class {@code DartNodeWithMetadata} defines the behavior of nodes that can have
 * metadata associated with them.
 */
public abstract class DartNodeWithMetadata extends DartNode {
  private NodeList<DartAnnotation> metadata = NodeList.create(this);

  protected DartNodeWithMetadata() {
    super();
  }

  public NodeList<DartAnnotation> getMetadata() {
    return metadata;
  }

  public void setMetadata(List<DartAnnotation> metadata) {
    this.metadata.addAll(metadata);
  }

  @Override
  public void visitChildren(ASTVisitor<?> visitor) {
    metadata.accept(visitor);
  }
}
