// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;

import java.util.List;

class DuplicateElementImplementation implements DuplicateElement {
  private final String name;
  private final List<String> locations = Lists.newArrayList();

  public DuplicateElementImplementation(Element oldElement, Element newElement) {
    name = oldElement.getName();
    locations.addAll(getLocations(oldElement));
    locations.addAll(getLocations(newElement));
  }

  @Override
  public String getOriginalName() {
    return name;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.DUPLICATE;
  }

  @Override
  public Type getType() {
    return null;
  }

  @Override
  public boolean isDynamic() {
    return false;
  }

  @Override
  public Modifiers getModifiers() {
    return Modifiers.NONE;
  }

  @Override
  public DartObsoleteMetadata getMetadata() {
    return null;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return null;
  }

  @Override
  public SourceInfo getNameLocation() {
    return null;
  }

  @Override
  public SourceInfo getSourceInfo() {
    return null;
  }

  @Override
  public List<String> getLocations() {
    return locations;
  }

  private static List<String> getLocations(Element element) {
    if (element instanceof DuplicateElement) {
      return ((DuplicateElement) element).getLocations();
    } else {
      return ImmutableList.of(Elements.getLibraryUnitLocation(element));
    }
  }
}
