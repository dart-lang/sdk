// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js.analysis;

import org.mozilla.javascript.ast.AstNode;

import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

/**
 * JavaScript element that could be any subtype of {@link AstNode}. In the cases where the element 
 * is a function any members that are hung off of its prototype chain are also recorded as members.
 */
class JavascriptElement {
  private final JavascriptElement enclosingElement;
  private JavascriptElement inheritsElement;
  private JavascriptElement inheritsInvocation;
  private boolean instantiated;
  private final boolean isVirtual;
  private List<JavascriptElement> members = null;
  private final String name;
  private final AstNode node;
  private final String qualifiedName;

  public JavascriptElement(JavascriptElement enclosingElement, boolean isVirtual,
      String qualifiedName, String name, AstNode node) {
    this.enclosingElement = enclosingElement;
    this.isVirtual = isVirtual;
    this.qualifiedName = qualifiedName;
    this.name = name;
    this.node = node;
    if (enclosingElement != null) {
      enclosingElement.addMember(this);
    }
  }

  /**
   * @param javascriptElement
   */
  private void addMember(JavascriptElement javascriptElement) {
    if (members == null) {
      members = new LinkedList<JavascriptElement>();
    }
    members.add(javascriptElement);
  }

  public JavascriptElement getEnclosingElement() {
    return enclosingElement;
  }

  public JavascriptElement getInheritsElement() {
    return inheritsElement;
  }

  public JavascriptElement getInheritsInvocation() {
    return inheritsInvocation;
  }

  /**
   * Returns the length of this element in characters. 
   */
  public int getLength() {
    return node.getLength();
  }

  public List<JavascriptElement> getMembers() {
    if (members == null) {
      return Collections.emptyList();
    }

    return members;
  }

  public String getName() {
    return name;
  }

  public AstNode getNode() {
    return node;
  }

  public int getOffset() {
    return node.getAbsolutePosition();
  }

  public String getQualifiedName() {
    return qualifiedName;
  }

  /**
   * Returns <code>true</code> if the element was used in a new expression.  For now, we assume that
   * any javascript native element is instantiated. 
   */
  public boolean isInstantiated() {
    // TODO: Assume that natives are always instantiated for now
    return instantiated || isNative();
  }

  /**
   * Returns <code>true</code> if the element was referenced from a top-level expression but was
   * not declared.  For example, we would synthesize a native member if the following top-level 
   * expression is found "Array.prototype.XXX = function(){}".  Array is a native JS object. 
   */
  public boolean isNative() {
    return getNode() == null;
  }

  public boolean isVirtual() {
    return isVirtual;
  }

  public void setInherits(JavascriptElement inherits) {
    this.inheritsElement = inherits;
  }

  public void setInheritsNode(AstNode inheritsNode) {
    this.inheritsInvocation = new JavascriptElement(null,false, "", "", inheritsNode);
  }

  public void setInstantiated(boolean instantiated) {
    this.instantiated = instantiated;

    if (inheritsElement != null) {
      inheritsElement.setInstantiated(instantiated);
    }
  }
}
