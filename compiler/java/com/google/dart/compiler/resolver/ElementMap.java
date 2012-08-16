// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;

import java.util.ArrayList;
import java.util.List;

/**
 * A more efficient version of {@link com.google.common.collect.Multimap} specifically for
 * {@link NodeElement}
 */
class ElementMap {

  /**
   * A synthetic place holder for an element where the name given to the element map does not match
   * the value returned by {@link NodeElement#getName()} or where there are multiple elements associated
   * with the same name.
   */
  static class ElementHolder implements NodeElement {
    private static final String INTERNAL_ONLY_ERROR =
        "ElementHolder should not be accessed outside this class";

    final String name;
    final NodeElement element;
    ElementHolder nextHolder;

    ElementHolder(String name, NodeElement element) {
      this.name = name;
      this.element = element;
    }
    
    @Override
    public SourceInfo getNameLocation() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public EnclosingElement getEnclosingElement() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public ElementKind getKind() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public DartObsoleteMetadata getMetadata() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public Modifiers getModifiers() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public String getName() {
      return name;
    }

    @Override
    public DartNode getNode() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public String getOriginalName() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public Type getType() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public boolean isDynamic() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

    @Override
    public SourceInfo getSourceInfo() {
      throw new AssertionError(INTERNAL_ONLY_ERROR);
    }

  }

  // Array indexed by hashed name ... length is always power of 2
  private NodeElement[] elements;
  private List<NodeElement> ordered = new ArrayList<NodeElement>();

  ElementMap() {
    clear();
  }

  /**
   * Associate the specified element with the specified name. If the element is already associated
   * with that name, do not associate it again.
   */
  void add(String name, NodeElement element) {

    // Most of the time name equals getName() thus holder == element
    NodeElement newHolder;
    if (name.equals(element.getName())) {
      newHolder = element;
    } else {
      newHolder = new ElementHolder(name, element);
    }

    // 75% fill rate which anecdotal evidence claims is a good threshold for growing
    if ((elements.length >> 2) * 3 <= size()) {
      grow();
    }
    int index = internalAdd(newHolder);
    if (index == -1) {
      ordered.add(element);
      return;
    }

    // Handle existing element with the same name
    NodeElement existingHolder = elements[index];
    if (existingHolder == element) {
      return;
    }
    if (!(existingHolder instanceof ElementHolder)) {
      existingHolder = new ElementHolder(name, existingHolder);
      elements[index] = existingHolder;
    }

    // Check the list for a duplicate element entry, and append if none found
    ElementHolder holder = (ElementHolder) existingHolder;
    while (true) {
      if (holder.element == element) {
        return;
      }
      if (holder.nextHolder == null) {
        holder.nextHolder = new ElementHolder(name, element);
        ordered.add(element);
        return;
      }
      holder = holder.nextHolder;
    }
  }

  void clear() {
    elements = new NodeElement[16];
    ordered.clear();
  }

  /**
   * Answer the element last associated with the specified name.
   * 
   * @return the element or <code>null</code> if none
   */
  NodeElement get(String name) {
    NodeElement element = internalGet(name);
    if (element instanceof ElementHolder) {
      return ((ElementHolder) element).element;
    } else {
      return element;
    }
  }

  /**
   * Answer the element associated with the specified name and kind
   * 
   * @return the element of that kind or <code>null</code> if none
   */
  NodeElement get(String name, ElementKind kind) {
    NodeElement element = internalGet(name);
    if (element instanceof ElementHolder) {
      ElementHolder holder = (ElementHolder) element;
      while (true) {
        element = holder.element;
        if (ElementKind.of(element).equals(kind)) {
          return element;
        }
        holder = holder.nextHolder;
        if (holder == null) {
          break;
        }
      }
    } else {
      if (ElementKind.of(element).equals(kind)) {
        return element;
      }
    }
    return null;
  }

  boolean isEmpty() {
    return ordered.isEmpty();
  }

  int size() {
    return ordered.size();
  }

  List<NodeElement> values() {
    return ordered;
  }

  private void grow() {
    NodeElement[] old = elements;
    elements = new NodeElement[elements.length << 2];
    for (NodeElement element : old) {
      if (element != null) {
        if (internalAdd(element) != -1) {
          // Every element in the array should have a unique name, so there should not be any collision
          throw new RuntimeException("Failed to grow: " + element.getName());
        }
      }
    }
  }

  /**
   * If an element with the given name does not exist in the array, then add the element and return
   * -1 otherwise nothing is added and the index of the existing element returned.
   */
  private int internalAdd(NodeElement element) {
    String name = element.getName();
    int mask = elements.length - 1;
    int probe = name.hashCode() & mask;
    for (int i = probe; i < probe + mask + 1; i++) {
      int index = i & mask;
      NodeElement current = elements[index];
      if (current == null) {
        elements[index] = element;
        return -1;
      }
      if (current.getName().equals(name)) {
        return index;
      }
    }
    throw new AssertionError("overfilled array");
  }

  private NodeElement internalGet(String name) {
    NodeElement element;
    int mask = elements.length - 1;
    int probe = name.hashCode() & mask;
    for (int i = probe; i < probe + mask + 1; i++) {
      element = elements[i & mask];
      if (element == null || element.getName().equals(name)) {
        return element;
      }
    }
    throw new AssertionError("overfilled array");
  }
}
