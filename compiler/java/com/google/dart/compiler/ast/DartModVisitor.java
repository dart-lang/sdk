// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.util.Hack;

import java.util.List;

/**
 * A visitor for iterating through and modifying an AST.
 */
public class DartModVisitor extends DartVisitor {

  private class ListContext<T extends DartVisitable> implements DartContext {

    private DartNode parent;
    private List<T> collection;
    private int index;
    private boolean removed;
    private boolean replaced;

    public ListContext(DartNode parent) {
      this.parent = parent;
    }

    public boolean canInsert() {
      return true;
    }

    public boolean canRemove() {
      return true;
    }

    public void insertAfter(DartVisitable node) {
      checkRemoved();
      parent.becomeParentOf((DartNode) node);
      collection.add(index + 1, Hack.<T>cast(node));
      didChange = true;
    }

    public void insertBefore(DartVisitable node) {
      checkRemoved();
      parent.becomeParentOf((DartNode) node);
      collection.add(index++, Hack.<T>cast(node));
      didChange = true;
    }

    public boolean isLvalue() {
      return false;
    }

    public void removeMe() {
      checkState();
      collection.remove(index--);
      didChange = removed = true;
    }

    public void replaceMe(DartVisitable node) {
      checkState();
      checkReplacement(collection.get(index), node);
      parent.becomeParentOf((DartNode) node);
      collection.set(index, Hack.<T>cast(node));
      didChange = replaced = true;
    }

    protected void traverse(List<T> collection) {
      this.collection = collection;
      for (index = 0; index < collection.size(); ++index) {
        removed = replaced = false;
        doTraverse(collection.get(index), this);
      }
    }

    private void checkRemoved() {
      if (removed) {
        throw new RuntimeException("Node was already removed");
      }
    }

    private void checkState() {
      checkRemoved();
      if (replaced) {
        throw new RuntimeException("Node was already replaced");
      }
    }
  }

  private class LvalueContext extends NodeContext<DartExpression> {
    @Override
    public boolean isLvalue() {
      return true;
    }
  }

  private class NodeContext<T extends DartVisitable> implements DartContext {
    private T node;
    private boolean replaced;

    public boolean canInsert() {
      return false;
    }

    public boolean canRemove() {
      return false;
    }

    public void insertAfter(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    public void insertBefore(DartVisitable node) {
      throw new UnsupportedOperationException();
    }

    public boolean isLvalue() {
      return false;
    }

    public void removeMe() {
      throw new UnsupportedOperationException();
    }

    public void replaceMe(DartVisitable node) {
      if (replaced) {
        throw new RuntimeException("Node was already replaced");
      }
      checkReplacement(this.node, node);
      this.node = Hack.<T>cast(node);
      didChange = replaced = true;
    }

    protected T traverse(T node) {
      this.node = node;
      replaced = false;
      doTraverse(node, this);
      return this.node;
    }
  }

  protected static <T extends DartVisitable> void checkReplacement(T origNode, T newNode) {
    if (newNode == null) {
      throw new RuntimeException("Cannot replace with null");
    }
    if (newNode == origNode) {
      throw new RuntimeException("The replacement is the same as the original");
    }
  }

  protected boolean didChange = false;

  @Override
  public boolean didChange() {
    return didChange;
  }

  @Override
  protected <T extends DartVisitable> T doAccept(T node) {
    return new NodeContext<T>().traverse(node);
  }

  @Override
  protected void doAcceptList(List<? extends DartVisitable> collection) {
    doAcceptListImpl(collection);
  }

  private <T extends DartVisitable> void doAcceptListImpl(List<T> collection) {
    NodeContext<T> ctx = new NodeContext<T>();
    for (int i = 0, c = collection.size(); i < c; ++i) {
      ctx.traverse(collection.get(i));
      if (ctx.replaced) {
        collection.set(i, ctx.node);
      }
    }
  }

  @Override
  protected DartExpression doAcceptLvalue(DartExpression expr) {
    return new LvalueContext().traverse(expr);
  }

  @Override
  protected <T extends DartVisitable> List<T> doAcceptWithInsertRemove(
      DartNode parent, List<T> collection) {
    ListContext<T> ctx = new ListContext<T>(parent);
    ctx.traverse(collection);
    return ctx.collection;
  }
}
