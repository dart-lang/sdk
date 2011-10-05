// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A scope used by {@link Resolver}.
 */
public class Scope {

  private final Map<String, Element> elements = new LinkedHashMap<String, Element>();
  private final Scope parent;
  private final String name;
  private LabelElement label;

  @VisibleForTesting
  public Scope(String name, Scope parent) {
    this.name = name;
    this.parent = parent;
  }

  @VisibleForTesting
  public Scope(String name) {
    this(name, null);
  }

  public void clear() {
    elements.clear();
  }

  public Element declareElement(String name, Element element) {
    return elements.put(name, element);
  }

  public Element findLocalElement(String name) {
    return elements.get(name);
  }

  public Element findElement(String name) {
    Element element = findLocalElement(name);
    if (element == null && parent != null) {
      element = parent.findElement(name);
    }
    return element;
  }

  public Element findLabel(String targetName, MethodElement innermostFunction) {
    if (label != null && label.getName().equals(targetName)
        && innermostFunction == label.getEnclosingFunction()) {
        return label;
    }
    return parent == null ? null :
      parent.findLabel(targetName, innermostFunction);
  }

  public Map<String, Element> getElements() {
    return elements;
  }

  public Element getLabel() {
    return label;
  }

  public String getName() {
    return name;
  }

  public Scope getParent() {
    return parent;
  }

  public boolean isClear() {
    return elements.size() == 0;
  }

  public void setLabel(LabelElement label) {
    this.label = label;
  }

  @Override
  public String toString() {
    return getName() + " : \n" + elements.toString();
  }
}
