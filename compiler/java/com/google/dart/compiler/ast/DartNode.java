// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.AbstractNode;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.util.DefaultTextOutput;

import java.util.List;

/**
 * Base class for all Dart AST nodes.
 */
public abstract class DartNode extends AbstractNode {
  private DartNode parent;
  private Type type;

  public final String toSource() {
    DefaultTextOutput out = new DefaultTextOutput(false);
    accept(new DartToSourceVisitor(out));
    return out.toString();
  }

  public Element getElement() {
    return null;
  }

  public void setElement(Element element) {
    throw new UnsupportedOperationException(getClass().getSimpleName());
  }

  public void setType(Type type) {
    this.type = type;
  }

  public Type getType() {
    return type;
  }

  @Override
  public final String toString() {
    return this.toSource();
  }

  /**
   * Returns this node's parent node, or <code>null</code> if this is the
   * root node.
   * <p>
   * Note that the relationship between an AST node and its parent node
   * may change over the lifetime of a node.
   *
   * @return the parent of this node, or <code>null</code> if none
   */
  public final DartNode getParent() {
    return parent;
  }

  /**
   * Return the node at the root of this node's AST structure. Note that this
   * method's performance is linear with respect to the depth of the node in
   * the AST structure (O(depth)).
   *
   * @return the node at the root of this node's AST structure
   */
  public final DartNode getRoot() {
    DartNode root = this;
    DartNode parent = getParent();
    while (parent != null) {
      root = parent;
      parent = root.getParent();
    }
    return root;
  }

  protected <T extends DartNode> T becomeParentOf(T child) {
    if (child != null) {
      DartNode node = child; // Java 7 access rules require a temp of a concrete type.
      node.setParent(this);
    }
    return child;
  }

  protected <L extends List<? extends DartNode>> L becomeParentOf(L children) {
    if (children != null) {
      for (DartNode child : children) {
        child.setParent(this);
      }
    }
    return children;
  }

  private void setParent(DartNode newParent) {
    parent = newParent;
  }

  public abstract void visitChildren(ASTVisitor<?> visitor);

  public abstract <R> R accept(ASTVisitor<R> visitor);

  @Override
  public DartNode clone() {
    // TODO (fabiomfv) - Implement proper cloning when strictly needed.
    return this;
  }

  public String getObjectIdentifier(){
    return super.toString();
  }
}
