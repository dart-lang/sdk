// Copyright 2012, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
// * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
  private final List<E> elements = Lists.newArrayListWithCapacity(0);

  /**
   * The node that is the parent of each of the elements in the list.
   */
  private final DartNode owner;

  /**
   * Initialize a newly created list of nodes to be empty.
   *
   * @param parent the node that is the parent of each of the elements in the list
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
    for (E element : elements) {
      element.accept(visitor);
    }
  }

  @Override
  public void add(int index, E element) {
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
    return elements.get(index);
  }

  @Override
  public E set(int index, E element) {
    E result = elements.set(index, element);
    owner.becomeParentOf(element);
    return result;
  }

  @Override
  public int size() {
    return elements.size();
  }
}
