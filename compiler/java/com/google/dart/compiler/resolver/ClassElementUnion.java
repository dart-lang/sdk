// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

import java.util.List;

public class ClassElementUnion implements ClassElement {
  
  private final InterfaceType unionType;
  private final List<InterfaceType> types;
  private final InterfaceType lastType;
  private final ClassElement lastElement;

  public ClassElementUnion(InterfaceType unionType, List<InterfaceType> types) {
    this.unionType = unionType;
    this.types = types;
    this.lastType = types.get(types.size() - 1);
    this.lastElement = lastType.getElement();
  }

  @Override
  public void setType(InterfaceType type) {
    throw new UnsupportedOperationException();
  }

  @Override
  public InterfaceType getType() {
    return unionType;
  }

  @Override
  public List<Type> getTypeParameters() {
    return ImmutableList.<Type>of();
  }

  @Override
  public InterfaceType getSupertype() {
    return lastElement.getSupertype();
  }

  @Override
  public InterfaceType getDefaultClass() {
    throw new UnsupportedOperationException();
  }

  @Override
  public void setSupertype(InterfaceType element) {
    throw new UnsupportedOperationException();
  }

  @Override
  public LibraryElement getLibrary() {
    return null;
  }

  @Override
  public List<InterfaceType> getInterfaces() {
    List<InterfaceType> interfaces = Lists.newArrayList();
    for (InterfaceType type : types) {
      if (type.getElement().isInterface()) {
        interfaces.add(type);
      }
    }
    return interfaces;
  }

  @Override
  public List<InterfaceType> getAllSupertypes() throws CyclicDeclarationException {
    List<InterfaceType> superTypes = Lists.newArrayList();
    for (InterfaceType type : types) {
      superTypes.addAll(type.getElement().getAllSupertypes());
    }
    return superTypes;
  }

  @Override
  public String getNativeName() {
    return lastElement.getNativeName();
  }

  @Override
  public String getDeclarationNameWithTypeParameters() {
    return lastElement.getDeclarationNameWithTypeParameters();
  }

  @Override
  public boolean isObject() {
    return lastElement.isObject();
  }

  @Override
  public boolean isObjectChild() {
    return lastElement.isObjectChild();
  }

  @Override
  public boolean isAbstract() {
    return lastElement.isAbstract();
  }

  @Override
  public ConstructorElement lookupConstructor(String name) {
    throw new UnsupportedOperationException();
  }

  @Override
  public List<Element> getUnimplementedMembers() {
    throw new UnsupportedOperationException();
  }

  @Override
  public Element lookupLocalElement(String name) {
    for (InterfaceType type : types) {
      Element localElement = type.getElement().lookupLocalElement(name);
      if (localElement != null) {
        return localElement;
      }
    }
    return null;
  }

  @Override
  public boolean isInterface() {
    return lastElement.isInterface();
  }

  @Override
  public String getOriginalName() {
    return lastElement.getOriginalName();
  }

  @Override
  public String getName() {
    return lastElement.getName();
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.CLASS;
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
    return lastElement.getEnclosingElement();
  }

  @Override
  public SourceInfo getNameLocation() {
    return lastElement.getNameLocation();
  }

  @Override
  public SourceInfo getSourceInfo() {
    return lastElement.getSourceInfo();
  }

  @Override
  public Iterable<Element> getMembers() {
    List<Iterable<? extends Element>> typeMembers = Lists.newArrayList();
    for (InterfaceType type : types) {
      typeMembers.add(type.getElement().getMembers());
    }
    return Iterables.concat(typeMembers);
  }

  @Override
  public List<ConstructorNodeElement> getConstructors() {
    throw new UnsupportedOperationException();
  }

  @Override
  public int getOpenBraceOffset() {
    return -1;
  }
  
  @Override
  public int getCloseBraceOffset() {
    return -1;
  }
}
