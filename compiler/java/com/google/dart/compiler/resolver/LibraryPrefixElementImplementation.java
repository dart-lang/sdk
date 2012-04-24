// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.Lists;

import java.util.Collection;
import java.util.List;

class LibraryPrefixElementImplementation extends AbstractNodeElement implements
    LibraryPrefixElement {

  private final List<LibraryElement> libraries = Lists.newArrayList();
  private final Scope scope;

  public LibraryPrefixElementImplementation(String name, Scope parent) {
    super(null, name);
    scope = new Scope("prefix:" + name, parent.getLibrary());
  }

  @Override
  public boolean isInterface() {
    return false;
  }

  @Override
  public Scope getScope() {
    return scope;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.LIBRARY_PREFIX;
  }

  @Override
  public Collection<Element> getMembers() {
    return scope.getElements().values();
  }

  @Override
  public Element lookupLocalElement(String name) {
    return scope.findLocalElement(name);
  }

  public void addLibrary(LibraryElement library) {
    libraries.add(library);
  }

  @Override
  public List<LibraryElement> getLibraries() {
    return libraries;
  }
}
