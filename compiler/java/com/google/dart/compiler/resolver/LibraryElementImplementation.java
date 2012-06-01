// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.LibraryUnit;

import java.util.Collection;

class LibraryElementImplementation extends AbstractNodeElement implements LibraryElement {

  private final Scope importScope = new Scope("import", this);
  private final Scope scope = new Scope("library", this, importScope);
  private LibraryUnit libraryUnit;
  private MethodElement entryPoint;

  public LibraryElementImplementation(LibraryUnit libraryUnit) {
    // TODO(ngeoffray): What should we pass the super? Should a LibraryUnit be a node?
    super(null, libraryUnit.getSource().getName());
    this.libraryUnit = libraryUnit;
  }

  @Override
  public boolean isInterface() {
    return false;
  }

  @Override
  public Scope getImportScope() {
    return importScope;
  }

  @Override
  public Scope getScope() {
    return scope;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.LIBRARY;
  }

  @Override
  public LibraryUnit getLibraryUnit() {
    return libraryUnit;
  }

  @Override
  public void setEntryPoint(MethodElement element) {
    this.entryPoint = element;
  }

  @Override
  public MethodElement getEntryPoint() {
    return entryPoint;
  }

  @Override
  public Collection<Element> getMembers() {
    // TODO(ngeoffray): have a proper way to get all the declared top level elements.
    return scope.getElements().values();
  }

  @Override
  public Element lookupLocalElement(String name) {
    return scope.findLocalElement(name);
  }

  void addField(FieldElement field) {
    scope.declareElement(field.getName(), field);
  }

  void addMethod(MethodElement method) {
    scope.declareElement(method.getName(), method);
  }
}
