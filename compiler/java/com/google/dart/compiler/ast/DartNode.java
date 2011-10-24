// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.AbstractNode;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.DefaultTextOutput;

import java.util.List;

/**
 * Base class for all Dart AST nodes.
 */
public abstract class DartNode extends AbstractNode implements DartVisitable {

  private DartNode parent;

  public final String toSource() {
    DefaultTextOutput out = new DefaultTextOutput(false);
    new DartToSourceVisitor(out).accept(this);
    return out.toString();
  }

  public Symbol getSymbol() {
    return  null;
  }

  public void setSymbol(Symbol symbol) {
    throw new UnsupportedOperationException(getClass().getSimpleName());
  }

  public void setType(Type type) {
    throw new UnsupportedOperationException(getClass().getSimpleName());
  }

  public DartNode getNormalizedNode() {
    return this;
  }

  public Type getType() {
    return Types.newDynamicType();
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

  /**
   * Returns the length in characters of the original source file indicating
   * where the source fragment corresponding to this node ends.
   * <p>
   * The parser supplies useful well-defined source ranges to the nodes it
   * creates.
   *
   * @return a (possibly 0) length, or <code>0</code> if no source startPosition
   *         information is recorded for this node
   * @see #getStartPosition()
   * @see #setSourceRange(int, int)
   * @deprecated
   */
  @Deprecated
  public int getLength() {
    return getSourceLength();
  }

  /**
   * Returns the character index into the original source file indicating where
   * the source fragment corresponding to this node begins.
   * <p>
   * The parser supplies useful well-defined source ranges to the nodes it
   * creates. See {@link ASTParser#setKind(int)} for details on precisely where
   * source ranges begin and end.
   *
   * @return the 0-based character index, or <code>-1</code> if no source
   *         startPosition information is recorded for this node
   * @see #getLength()
   * @see #setSourceRange(int, int)
   * @deprecated
   */
  @Deprecated
  public int getStartPosition() {
    return getSourceStart();
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

  public abstract void visitChildren(DartPlainVisitor<?> visitor);

  public abstract <R> R accept(DartPlainVisitor<R> visitor);

  public int computeHash() {
    // TODO(jgw): Remove this altogether in fixing b/5324113.
    //
    // This computes a "hash" of the class' interface by simply serializing it to diet source and
    // computing a hash of the string. This will work for now, but encodes too much information in
    // the hash, and is slower than it should be. It should also cache the result and invalidate it
    // if anything substantive changes.
    //
    // Examples of changes incorrectly captured by this hash, which would cause unnecessary
    // recompiled include:
    // - any change in method/field order would trigger an unnecessary recompile.
    // - purely lexical changes such as {int x; int y;} => {int x, y;}
    //
    DefaultTextOutput out = new DefaultTextOutput(false);
    new DartToSourceVisitor(out, true).accept(this);
    return out.toString().trim().hashCode();
  }

  @Override
  public DartNode clone() {
    // TODO (fabiomfv) - Implement proper cloning when strictly needed.
    return this;
  }
}
