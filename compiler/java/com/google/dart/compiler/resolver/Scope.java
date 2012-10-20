// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Sets;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartVariableStatement;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * A scope used by {@link Resolver}.
 */
public class Scope {

  private final Map<String, Element> elements = new LinkedHashMap<String, Element>();
  private final Set<String> declaredButNotReachedVariables = Sets.newHashSet();
  private final Scope parent;
  private final String name;
  private List<LabelElement> labels;
  private LibraryElement library;
  private boolean stateProgress;
  private boolean stateReady;

  @VisibleForTesting
  public Scope(String name, LibraryElement library, Scope parent) {
    this.name = name;
    this.parent = parent;
    this.library = library;
  }

  @VisibleForTesting
  public Scope(String name, LibraryElement element) {
    this(name, element, null);
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

  public Element findElement(LibraryElement fromLibrary, String name) {
    Element element = null;
    // Only lookup a private name in this scope if we are in the correct library
    // or we are ignoring libraries (i.e., fromLibrary == null).
    if (fromLibrary == null
        || !DartIdentifier.isPrivateName(name)
        || fromLibrary.equals(library)) {
      element = findLocalElement(name);
    }
    if (element == null) {
      if (parent != null) {
        element = parent.findElement(fromLibrary, name);
      } else {
        element = null;
      }
    }
    return element;
  }

  public LibraryElement getLibrary() {
    return library;
  }

  public Element findLabel(String targetName, MethodElement innermostFunction) {
    if (labels != null) {
      for (LabelElement label : labels) {
        if (label.getName().equals(targetName)
          && innermostFunction == label.getEnclosingFunction()) {
          return label;
        }
      }
    }
    return parent == null ? null :
      parent.findLabel(targetName, innermostFunction);
  }

  public boolean hasLocalLabel(String labelName) {
    if (labels != null) {
      for (LabelElement label : labels) {
        if (label.getName().equals(labelName)) {
            return true;
        }
      }
    }
    return false;
  }
  
  public void markStateReady() {
    this.stateReady = true;
  }
  
  public boolean isStateReady() {
    return stateReady;
  }

  public Map<String, Element> getElements() {
    return elements;
  }

  /**
   * @return <code>true</code> if local variable with given name is declared in the lexical context
   *         of {@link DartBlock}, but corresponding {@link DartVariableStatement} is not visited
   *         yet. So, using this variable is error.
   */
  public boolean isDeclaredButNotReachedVariable(String name) {
    return declaredButNotReachedVariables.contains(name);
  }

  /**
   * @see #isDeclaredButNotReachedVariable(String)
   */
  public void addDeclaredButNotReachedVariable(String name) {
    declaredButNotReachedVariables.add(name);
  }

  /**
   * @see #isDeclaredButNotReachedVariable(String)
   */
  public void removeDeclaredButNotReachedVariable(String name) {
    declaredButNotReachedVariables.remove(name);
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

  public void addLabel(LabelElement label) {
    if (labels == null) {
      labels = new ArrayList<LabelElement>();
    }
    labels.add(label);
  }

  @Override
  public String toString() {
    return getName() + " : \n" + elements.toString();
  }
}
