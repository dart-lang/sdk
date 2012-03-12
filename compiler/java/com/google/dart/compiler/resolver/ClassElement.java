// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

import java.util.List;

public interface ClassElement extends EnclosingElement {
  void setType(InterfaceType type);

  @Override
  InterfaceType getType();

  List<Type> getTypeParameters();

  InterfaceType getSupertype();

  InterfaceType getDefaultClass();

  void setSupertype(InterfaceType element);

  List<ConstructorElement> getConstructors();

  LibraryElement getLibrary();

  List<InterfaceType> getInterfaces();

  List<InterfaceType> getAllSupertypes()
      throws CyclicDeclarationException, DuplicatedInterfaceException;

  String getNativeName();
  
  /**
   * FIXME(scheglov) We use this in {@link Resolver} to check that "factory" clause is exactly
   * same as declaration of factory class.
   */
  String getDeclarationNameWithTypeParameters();

  boolean isObject();

  boolean isObjectChild();

  /**
   * @return <code>true</code> if this class is abstract - has explicit "abstract" modifier or has
   *         abstract method. Note, that "abstract" is different from "has unimplemented members".
   */
  boolean isAbstract();

  ConstructorElement lookupConstructor(String name);
}
