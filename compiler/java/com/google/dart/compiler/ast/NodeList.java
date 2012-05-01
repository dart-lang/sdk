// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.collect.Lists;

import java.util.AbstractList;
import java.util.Collection;
import java.util.List;

/**
 * Instances of the class <code>NodeList</code> represent a list of AST nodes that have a common
 * parent.
 */
public class NodeList<E extends DartNode> extends AbstractList<E> {
  /**
   * @return the new instance of {@link NodeList} with correct type argument.
   */
  public static <E extends DartNode> NodeList<E> create(DartNode owner) {
    return new NodeList<E>(owner);
  }

  /**
   * The underlying list in which the nodes of this list are stored.
   */
  private List<E> elements = null;

  /**
   * The node that is the parent of each of the elements in the list.
   */
  private final DartNode owner;

  /**
   * Initialize a newly created list of nodes to be empty.
   *
   * @param owner the node that is the parent of each of the elements in the list
   */
  public NodeList(DartNode owner) {
    this.owner = owner;
  }

  /**
   * Use the given visitor to visit each of the nodes in this list.
   *
   * @param visitor the visitor to be used to visit the elements of this list
   */
  public void accept(ASTVisitor<?> visitor) {
    if (elements != null) {
      for (E element : elements) {
        element.accept(visitor);
      }
    }
  }

  @Override
  public void add(int index, E element) {
    if (elements == null) {
      elements = Lists.newArrayListWithCapacity(2);
    }
    elements.add(element);
    owner.becomeParentOf(element);
  }

  @Override
  public boolean addAll(Collection<? extends E> c) {
    if (c != null) {
      return super.addAll(c);
    }
    return false;
  }

  @Override
  public E get(int index) {
    if (elements == null) {
      throw new IndexOutOfBoundsException(Integer.toString(index));
    }
    return elements.get(index);
  }

  @Override
  public E set(int index, E element) {
    if (elements == null) {
      elements = Lists.newArrayListWithCapacity(index + 1);
    }
    E result = elements.set(index, element);
    owner.becomeParentOf(element);
    return result;
  }

  @Override
  public int size() {
    if (elements == null) {
      return 0;
    }
    return elements.size();
  }
}
